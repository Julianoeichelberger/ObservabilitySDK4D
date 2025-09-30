{
  *******************************************************************************

  Observability SDK for Delphi.

  Copyright (C) 2025 Juliano Eichelberger 

  License Notice:
  This software is licensed under the terms of the MIT License.

  As required by the license:
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
  The full license text can be found in the LICENSE file at the root of the project.

  For more details on the terms of use, please consult:
  https://opensource.org/licenses/MIT

  *******************************************************************************
}
unit Observability.Provider.Datadog;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON,
  System.Net.HTTPClient, System.Net.URLClient, System.DateUtils,
  Observability.Interfaces, Observability.Provider.Base, Observability.Context;

type
  TDatadogProvider = class(TBaseObservabilityProvider)
  private
    FHttpClient: THttpClient;
    FApiKey: string;
    FAppKey: string;
    FHost: string;
    FPort: Integer;
    FService: string;
    FEnvironment: string;
    FVersion: string;
    
    function CreateHeaders: TArray<TNameValuePair>;
    procedure SendTraces(const Traces: TJSONArray);
    procedure SendLogs(const Log: TJSONObject);
    procedure SendMetrics(const Metrics: TJSONObject);
  protected
    function GetProviderType: TObservabilityProvider; override;
    function GetSupportedTypes: TObservabilityTypeSet; override;
    
    procedure DoInitialize; override;
    procedure DoShutdown; override;
    function CreateTracer: IObservabilityTracer; override;
    function CreateLogger: IObservabilityLogger; override;
    function CreateMetrics: IObservabilityMetrics; override;
    
    procedure ValidateConfiguration; override;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

  TDatadogSpan = class(TBaseObservabilitySpan)
  private
    FDatadogProvider: TDatadogProvider;
    FTraceId128Bit: string;
    FSpanId64Bit: Int64;
    FParentId64Bit: Int64;
    
    function ConvertToDatadogId(const Id: string): Int64;
  protected
    procedure DoFinish; override;
    procedure DoRecordException(const Exception: Exception); override;
    procedure DoAddEvent(const Name, Description: string); override;
  public
    constructor Create(const Name: string; const Context: IObservabilityContext; 
      const DatadogProvider: TDatadogProvider); reintroduce;
    
    function ToDatadogJSON: TJSONObject;
  end;

  TDatadogTracer = class(TBaseObservabilityTracer)
  private
    FDatadogProvider: TDatadogProvider;
  protected
    function DoCreateSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan; override;
  public
    constructor Create(const Context: IObservabilityContext; const DatadogProvider: TDatadogProvider); reintroduce;
    
    procedure InjectHeaders(const Headers: TStrings); override;
    function ExtractContext(const Headers: TStrings): IObservabilityContext; override;
  end;

  TDatadogLogger = class(TBaseObservabilityLogger)
  private
    FDatadogProvider: TDatadogProvider;
    
    function LogLevelToDatadog(const Level: TLogLevel): string;
  protected
    procedure DoLog(const Level: TLogLevel; const Message: string; 
      const Attributes: TDictionary<string, string>; const Exception: Exception); override;
  public
    constructor Create(const Context: IObservabilityContext; const DatadogProvider: TDatadogProvider); reintroduce;
  end;

  TDatadogMetrics = class(TBaseObservabilityMetrics)
  private
    FDatadogProvider: TDatadogProvider;
    
    procedure SendMetricPoint(const MetricName, MetricType: string; const Value: Double; 
      const Tags: TDictionary<string, string>; const Timestamp: TDateTime);
  protected
    procedure DoCounter(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
    procedure DoGauge(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
    procedure DoHistogram(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
    procedure DoSummary(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
  public
    constructor Create(const Context: IObservabilityContext; const DatadogProvider: TDatadogProvider); reintroduce;
  end;

implementation

{ TDatadogProvider }

constructor TDatadogProvider.Create;
begin
  inherited Create;
  FHost := 'api.datadoghq.com';
  FPort := 443;
end;

destructor TDatadogProvider.Destroy;
begin
  FHttpClient.Free;
  inherited Destroy;
end;

function TDatadogProvider.GetProviderType: TObservabilityProvider;
begin
  Result := opDatadog;
end;

function TDatadogProvider.GetSupportedTypes: TObservabilityTypeSet;
begin
  Result := [otTracing, otLogging, otMetrics];
end;

procedure TDatadogProvider.ValidateConfiguration;
begin
  inherited ValidateConfiguration;
  
  if FConfig.ApiKey.IsEmpty then
    raise EConfigurationError.Create('Datadog API key is required');
end;

procedure TDatadogProvider.DoInitialize;
begin
  FHttpClient := THTTPClient.Create;
  FApiKey := FConfig.ApiKey;
  FService := FConfig.ServiceName;
  FEnvironment := FConfig.Environment;
  FVersion := FConfig.ServiceVersion;
  
  // Parse custom properties for app key
  if FConfig.CustomProperties.ContainsKey('app_key') then
    FAppKey := FConfig.CustomProperties['app_key'];
    
  if FConfig.CustomProperties.ContainsKey('host') then
    FHost := FConfig.CustomProperties['host'];
    
  if FConfig.CustomProperties.ContainsKey('port') then
    FPort := StrToIntDef(FConfig.CustomProperties['port'], 443);
    
  FHttpClient.UserAgent := 'ObservabilitySDK4D-Datadog/1.0';
end;

procedure TDatadogProvider.DoShutdown;
begin
  FHttpClient.Free;
  FHttpClient := nil;
end;

function TDatadogProvider.CreateHeaders: TArray<TNameValuePair>;
begin
  SetLength(Result, 2);
  Result[0] := TNameValuePair.Create('DD-API-KEY', FApiKey);
  Result[1] := TNameValuePair.Create('Content-Type', 'application/json');
  
  if not FAppKey.IsEmpty then
  begin
    SetLength(Result, 3);
    Result[2] := TNameValuePair.Create('DD-APPLICATION-KEY', FAppKey);
  end;
end;

function TDatadogProvider.CreateTracer: IObservabilityTracer;
var
  Context: IObservabilityContext;
begin
  Context := TObservabilityContext.CreateNew;
  Context.ServiceName := FConfig.ServiceName;
  Context.ServiceVersion := FConfig.ServiceVersion;
  Context.Environment := FConfig.Environment;
  
  Result := TDatadogTracer.Create(Context, Self);
end;

function TDatadogProvider.CreateLogger: IObservabilityLogger;
var
  Context: IObservabilityContext;
begin
  Context := TObservabilityContext.CreateNew;
  Context.ServiceName := FConfig.ServiceName;
  Context.ServiceVersion := FConfig.ServiceVersion;
  Context.Environment := FConfig.Environment;
  
  Result := TDatadogLogger.Create(Context, Self);
end;

function TDatadogProvider.CreateMetrics: IObservabilityMetrics;
var
  Context: IObservabilityContext;
begin
  Context := TObservabilityContext.CreateNew;
  Context.ServiceName := FConfig.ServiceName;
  Context.ServiceVersion := FConfig.ServiceVersion;
  Context.Environment := FConfig.Environment;
  
  Result := TDatadogMetrics.Create(Context, Self);
end;

procedure TDatadogProvider.SendTraces(const Traces: TJSONArray);
var
  Url: string;
  Response: IHTTPResponse;
  Stream: TStringStream;
begin
  Url := Format('https://%s/v0.3/traces', [FHost]);
  
  Stream := TStringStream.Create(Traces.ToString, TEncoding.UTF8);
  try
    Response := FHttpClient.Put(Url, Stream, nil, CreateHeaders);
    
    if Response.StatusCode <> 200 then
    begin
      // Log error but don't fail application
      System.Writeln(Format('[DATADOG] Failed to send traces: %d - %s', 
        [Response.StatusCode, Response.StatusText]));
    end;
  except
    on E: Exception do
      System.Writeln('[DATADOG] Error sending traces: ' + E.Message);
  end;
  Stream.Free;
end;

procedure TDatadogProvider.SendLogs(const Log: TJSONObject);
var
  Url: string;
  Response: IHTTPResponse;
  Stream: TStringStream;
begin
  Url := Format('https://%s/v1/input/%s', [FHost, FApiKey]);
  
  Stream := TStringStream.Create(Log.ToString, TEncoding.UTF8);
  try
    Response := FHttpClient.Post(Url, Stream);
    
    if Response.StatusCode <> 200 then
    begin
      System.Writeln(Format('[DATADOG] Failed to send log: %d - %s', 
        [Response.StatusCode, Response.StatusText]));
    end;
  except
    on E: Exception do
      System.Writeln('[DATADOG] Error sending log: ' + E.Message);
  end;
  Stream.Free;
end;

procedure TDatadogProvider.SendMetrics(const Metrics: TJSONObject);
var
  Url: string;
  Response: IHTTPResponse;
  Stream: TStringStream;
begin
  Url := Format('https://%s/api/v1/series', [FHost]);
  
  Stream := TStringStream.Create(Metrics.ToString, TEncoding.UTF8);
  try
    Response := FHttpClient.Post(Url, Stream, nil, CreateHeaders);
    
    if Response.StatusCode <> 202 then
    begin
      System.Writeln(Format('[DATADOG] Failed to send metrics: %d - %s', 
        [Response.StatusCode, Response.StatusText]));
    end;
  except
    on E: Exception do
      System.Writeln('[DATADOG] Error sending metrics: ' + E.Message);
  end;
  Stream.Free;
end;

{ TDatadogSpan }

constructor TDatadogSpan.Create(const Name: string; const Context: IObservabilityContext; 
  const DatadogProvider: TDatadogProvider);
begin
  inherited Create(Name, Context);
  FDatadogProvider := DatadogProvider;
  FSpanId64Bit := ConvertToDatadogId(FSpanId);
  FTraceId128Bit := FTraceId.Replace('-', '');
  
  if not FParentSpanId.IsEmpty then
    FParentId64Bit := ConvertToDatadogId(FParentSpanId);
end;

function TDatadogSpan.ConvertToDatadogId(const Id: string): Int64;
var
  CleanId: string;
  HexStr: string;
begin
  CleanId := Id.Replace('-', '');
  // Take first 16 characters for 64-bit ID
  HexStr := Copy(CleanId, 1, 16);
  Result := StrToInt64('$' + HexStr);
end;

procedure TDatadogSpan.DoFinish;
var
  TracesArray: TJSONArray;
  TraceArray: TJSONArray;
begin
  TracesArray := TJSONArray.Create;
  TraceArray := TJSONArray.Create;
  
  TraceArray.AddElement(ToDatadogJSON);
  TracesArray.AddElement(TraceArray);
  
  FDatadogProvider.SendTraces(TracesArray);
  TracesArray.Free;
end;

procedure TDatadogSpan.DoRecordException(const Exception: Exception);
begin
  AddAttribute('error.type', Exception.ClassName);
  AddAttribute('error.message', Exception.Message);
  AddAttribute('error', 'true');
end;

procedure TDatadogSpan.DoAddEvent(const Name, Description: string);
begin
  // Datadog doesn't have direct events, add as tags
  AddAttribute('event.' + Name, Description);
end;

function TDatadogSpan.ToDatadogJSON: TJSONObject;
var
  StartTimeNanos, DurationNanos: Int64;
  Key: string;
begin
  Result := TJSONObject.Create;
  
  // Convert times to nanoseconds
  StartTimeNanos := Trunc((FStartTime - UnixDateDelta) * MSecsPerDay * 1000000);
  DurationNanos := Trunc(GetDuration * 1000000);
  
  Result.AddPair('trace_id', TJSONNumber.Create(ConvertToDatadogId(FTraceId128Bit)));
  Result.AddPair('span_id', TJSONNumber.Create(FSpanId64Bit));
  
  if FParentId64Bit <> 0 then
    Result.AddPair('parent_id', TJSONNumber.Create(FParentId64Bit));
    
  Result.AddPair('name', FName);
  Result.AddPair('resource', FName);
  Result.AddPair('service', FContext.ServiceName);
  Result.AddPair('type', 'custom');
  Result.AddPair('start', TJSONNumber.Create(StartTimeNanos));
  Result.AddPair('duration', TJSONNumber.Create(DurationNanos));
  
  // Add span status based on outcome
  case FOutcome of
    Success: Result.AddPair('error', TJSONNumber.Create(0));
    Failure: Result.AddPair('error', TJSONNumber.Create(1));
  end;
  
  // Add meta tags
  var MetaObj := TJSONObject.Create;
  MetaObj.AddPair('env', FContext.Environment);
  MetaObj.AddPair('version', FContext.ServiceVersion);
  
  // Add custom attributes
  for Key in FAttributes.Keys do
    MetaObj.AddPair(Key, FAttributes[Key]);
    
  Result.AddPair('meta', MetaObj);
end;

{ TDatadogTracer }

constructor TDatadogTracer.Create(const Context: IObservabilityContext; const DatadogProvider: TDatadogProvider);
begin
  inherited Create(Context);
  FDatadogProvider := DatadogProvider;
end;

function TDatadogTracer.DoCreateSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan;
begin
  Result := TDatadogSpan.Create(Name, Context, FDatadogProvider);
end;

procedure TDatadogTracer.InjectHeaders(const Headers: TStrings);
begin
  if Assigned(FContext) then
  begin
    Headers.Values['x-datadog-trace-id'] := FContext.TraceId;
    Headers.Values['x-datadog-parent-id'] := FContext.SpanId;
  end;
end;

function TDatadogTracer.ExtractContext(const Headers: TStrings): IObservabilityContext;
var
  TraceId, ParentId: string;
  Context: IObservabilityContext;
begin
  TraceId := Headers.Values['x-datadog-trace-id'];
  ParentId := Headers.Values['x-datadog-parent-id'];
  
  Context := TObservabilityContext.CreateNew;
  
  if not TraceId.IsEmpty then
  begin
    Context.TraceId := TraceId;
    if not ParentId.IsEmpty then
      Context.SpanId := ParentId;
  end;
  
  Result := Context;
end;

{ TDatadogLogger }

constructor TDatadogLogger.Create(const Context: IObservabilityContext; const DatadogProvider: TDatadogProvider);
begin
  inherited Create(Context);
  FDatadogProvider := DatadogProvider;
end;

function TDatadogLogger.LogLevelToDatadog(const Level: TLogLevel): string;
begin
  case Level of
    llTrace: Result := 'debug';
    llDebug: Result := 'debug';
    llInfo: Result := 'info';
    llWarning: Result := 'warn';
    llError: Result := 'error';
    llCritical: Result := 'critical';
  else
    Result := 'info';
  end;
end;

procedure TDatadogLogger.DoLog(const Level: TLogLevel; const Message: string; 
  const Attributes: TDictionary<string, string>; const Exception: Exception);
var
  LogEntry: TJSONObject;
  Key: string;
  Timestamp: string;
begin
  LogEntry := TJSONObject.Create;
  try
    Timestamp := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', TTimeZone.Local.ToUniversalTime(Now));
    
    LogEntry.AddPair('timestamp', Timestamp);
    LogEntry.AddPair('level', LogLevelToDatadog(Level));
    LogEntry.AddPair('message', Message);
    LogEntry.AddPair('service', FContext.ServiceName);
    LogEntry.AddPair('source', 'delphi');
    LogEntry.AddPair('hostname', FContext.ServiceName);
    
    // Add trace correlation if available
    if not FContext.TraceId.IsEmpty then
    begin
      LogEntry.AddPair('dd.trace_id', FContext.TraceId);
      LogEntry.AddPair('dd.span_id', FContext.SpanId);
    end;
    
    // Add custom attributes
    if Assigned(Attributes) then
    begin
      for Key in Attributes.Keys do
        LogEntry.AddPair(Key, Attributes[Key]);
    end;
    
    // Add global attributes
    for Key in FAttributes.Keys do
      LogEntry.AddPair(Key, FAttributes[Key]);
    
    // Add exception details
    if Assigned(Exception) then
    begin
      LogEntry.AddPair('error.kind', Exception.ClassName);
      LogEntry.AddPair('error.message', Exception.Message);
    end;
    
    // Add environment tags
    LogEntry.AddPair('env', FContext.Environment);
    LogEntry.AddPair('version', FContext.ServiceVersion);
    
    FDatadogProvider.SendLogs(LogEntry);
    
  finally
    LogEntry.Free;
  end;
end;

{ TDatadogMetrics }

constructor TDatadogMetrics.Create(const Context: IObservabilityContext; const DatadogProvider: TDatadogProvider);
begin
  inherited Create(Context);
  FDatadogProvider := DatadogProvider;
end;

procedure TDatadogMetrics.SendMetricPoint(const MetricName, MetricType: string; const Value: Double; 
  const Tags: TDictionary<string, string>; const Timestamp: TDateTime);
var
  Payload: TJSONObject;
  SeriesArray: TJSONArray;
  SeriesObj: TJSONObject;
  PointsArray: TJSONArray;
  PointArray: TJSONArray;
  TagsArray: TJSONArray;
  Key: string;
  UnixTime: Int64;
begin
  UnixTime := DateTimeToUnix(Timestamp);
  
  Payload := TJSONObject.Create;
  SeriesArray := TJSONArray.Create;
  SeriesObj := TJSONObject.Create;
  
  SeriesObj.AddPair('metric', MetricName);
  SeriesObj.AddPair('type', MetricType);
  
  // Add points
  PointsArray := TJSONArray.Create;
  PointArray := TJSONArray.Create;
  PointArray.Add(TJSONNumber.Create(UnixTime));
  PointArray.Add(TJSONNumber.Create(Value));
  PointsArray.AddElement(PointArray);
  SeriesObj.AddPair('points', PointsArray);
  
  // Add tags
  TagsArray := TJSONArray.Create;
  TagsArray.Add('service:' + FContext.ServiceName);
  TagsArray.Add('env:' + FContext.Environment);
  TagsArray.Add('version:' + FContext.ServiceVersion);
  
  // Add custom tags
  if Assigned(Tags) then
  begin
    for Key in Tags.Keys do
      TagsArray.Add(Key + ':' + Tags[Key]);
  end;
  
  // Add global tags
  for Key in FGlobalTags.Keys do
    TagsArray.Add(Key + ':' + FGlobalTags[Key]);
  
  SeriesObj.AddPair('tags', TagsArray);
  SeriesArray.AddElement(SeriesObj);
  Payload.AddPair('series', SeriesArray);
  
  FDatadogProvider.SendMetrics(Payload);
  Payload.Free;
end;

procedure TDatadogMetrics.DoCounter(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  SendMetricPoint(Name, 'count', Value, Tags, Now);
end;

procedure TDatadogMetrics.DoGauge(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  SendMetricPoint(Name, 'gauge', Value, Tags, Now);
end;

procedure TDatadogMetrics.DoHistogram(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  SendMetricPoint(Name, 'histogram', Value, Tags, Now);
end;

procedure TDatadogMetrics.DoSummary(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  // Datadog doesn't have summary type, use histogram
  SendMetricPoint(Name, 'histogram', Value, Tags, Now);
end;

end.