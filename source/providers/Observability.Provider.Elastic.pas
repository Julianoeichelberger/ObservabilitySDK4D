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
unit Observability.Provider.Elastic;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON,
  System.Net.HTTPClient, System.Net.URLClient, System.DateUtils,
  Observability.Interfaces, Observability.Provider.Base, Observability.Context; 

type
  TElasticAPMProvider = class(TBaseObservabilityProvider)
  private
    FHttpClient: THttpClient;
    FApiKey: string;
    FServerUrl: string;
    
    procedure SendToElastic(const JsonData: TJSONObject; const Endpoint: string);
    function CreateElasticHeaders: TArray<TNameValuePair>;
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

  TElasticSpan = class(TBaseObservabilitySpan)
  private
    FElasticProvider: TElasticAPMProvider;
  protected
    procedure DoFinish; override;
    procedure DoRecordException(const Exception: Exception); override;
    procedure DoAddEvent(const Name, Description: string); override;
  public
    constructor Create(const Name: string; const Context: IObservabilityContext; 
      const ElasticProvider: TElasticAPMProvider); reintroduce;
    
    function ToElasticJSON: TJSONObject;
  end;

  TElasticTracer = class(TBaseObservabilityTracer)
  private
    FElasticProvider: TElasticAPMProvider;
  protected
    function DoCreateSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan; override;
  public
    constructor Create(const Context: IObservabilityContext; const ElasticProvider: TElasticAPMProvider); reintroduce;
    
    procedure InjectHeaders(const Headers: TStrings); override;
    function ExtractContext(const Headers: TStrings): IObservabilityContext; override;
  end;

  TElasticLogger = class(TBaseObservabilityLogger)
  private
    FElasticProvider: TElasticAPMProvider;
    
    function LogLevelToElastic(const Level: TLogLevel): string;
  protected
    procedure DoLog(const Level: TLogLevel; const Message: string; 
      const Attributes: TDictionary<string, string>; const Exception: Exception); override;
  public
    constructor Create(const Context: IObservabilityContext; const ElasticProvider: TElasticAPMProvider); reintroduce;
  end;

  TElasticMetrics = class(TBaseObservabilityMetrics)
  private
    FElasticProvider: TElasticAPMProvider;
    
    procedure SendMetricSet(const Metrics: TJSONObject);
  protected
    procedure DoCounter(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
    procedure DoGauge(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
    procedure DoHistogram(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
    procedure DoSummary(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
  public
    constructor Create(const Context: IObservabilityContext; const ElasticProvider: TElasticAPMProvider); reintroduce;
  end;

implementation

{ TElasticAPMProvider }

constructor TElasticAPMProvider.Create;
begin
  inherited Create;
  FServerUrl := 'http://localhost:8200';
end;

destructor TElasticAPMProvider.Destroy;
begin
  FHttpClient.Free;
  inherited Destroy;
end;

function TElasticAPMProvider.GetProviderType: TObservabilityProvider;
begin
  Result := opElastic;
end;

function TElasticAPMProvider.GetSupportedTypes: TObservabilityTypeSet;
begin
  Result := [otTracing, otLogging, otMetrics];
end;

procedure TElasticAPMProvider.ValidateConfiguration;
begin
  inherited ValidateConfiguration;
  
  if FConfig.ServerUrl.IsEmpty then
    raise EConfigurationError.Create('Elastic APM server URL is required');
end;

function TElasticAPMProvider.CreateElasticHeaders: TArray<TNameValuePair>;
begin
  SetLength(Result, 1);
  Result[0] := TNameValuePair.Create('Content-Type', 'application/x-ndjson');
  
  if not FApiKey.IsEmpty then
  begin
    SetLength(Result, 2);
    Result[1] := TNameValuePair.Create('Authorization', 'Bearer ' + FApiKey);
  end;
end;

procedure TElasticAPMProvider.SendToElastic(const JsonData: TJSONObject; const Endpoint: string);
var
  Url: string;
  Response: IHTTPResponse;
  Stream: TStringStream;
begin
  Url := FServerUrl;
  if not Url.EndsWith('/') then
    Url := Url + '/';
  Url := Url + Endpoint;
  
  Stream := TStringStream.Create(JsonData.ToString, TEncoding.UTF8);
  try
    Response := FHttpClient.Post(Url, Stream, nil, CreateElasticHeaders);
    
    if Response.StatusCode <> 202 then
    begin
      System.Writeln(Format('[ELASTIC] Failed to send to %s: %d - %s', 
        [Endpoint, Response.StatusCode, Response.StatusText]));
    end;
  except
    on E: Exception do
      System.Writeln(Format('[ELASTIC] Error sending to %s: %s', [Endpoint, E.Message]));
  end;
  Stream.Free;
end;

procedure TElasticAPMProvider.DoInitialize;
begin
  FHttpClient := THTTPClient.Create;
  FHttpClient.UserAgent := 'ObservabilitySDK4D-Elastic/1.0';
  
  FServerUrl := FConfig.ServerUrl;
  FApiKey := FConfig.ApiKey;
end;

procedure TElasticAPMProvider.DoShutdown;
begin
  FHttpClient.Free;
  FHttpClient := nil;
end;

function TElasticAPMProvider.CreateTracer: IObservabilityTracer;
var
  Context: IObservabilityContext;
begin
  Context := TObservabilityContext.CreateNew;
  Context.ServiceName := FConfig.ServiceName;
  Context.ServiceVersion := FConfig.ServiceVersion;
  Context.Environment := FConfig.Environment;
  
  Result := TElasticTracer.Create(Context, Self);
end;

function TElasticAPMProvider.CreateLogger: IObservabilityLogger;
var
  Context: IObservabilityContext;
begin
  Context := TObservabilityContext.CreateNew;
  Context.ServiceName := FConfig.ServiceName;
  Context.ServiceVersion := FConfig.ServiceVersion;
  Context.Environment := FConfig.Environment;
  
  Result := TElasticLogger.Create(Context, Self);
end;

function TElasticAPMProvider.CreateMetrics: IObservabilityMetrics;
var
  Context: IObservabilityContext;
begin
  Context := TObservabilityContext.CreateNew;
  Context.ServiceName := FConfig.ServiceName;
  Context.ServiceVersion := FConfig.ServiceVersion;
  Context.Environment := FConfig.Environment;
  
  Result := TElasticMetrics.Create(Context, Self);
end;

{ TElasticSpan }

constructor TElasticSpan.Create(const Name: string; const Context: IObservabilityContext; 
  const ElasticProvider: TElasticAPMProvider);
begin
  inherited Create(Name, Context);
  FElasticProvider := ElasticProvider;
end;

function TElasticSpan.ToElasticJSON: TJSONObject;
var
  StartTimeMicros, DurationMicros: Int64;
  Key: string;
begin
  Result := TJSONObject.Create;
  
  // Convert to microseconds since epoch
  StartTimeMicros := Trunc((FStartTime - UnixDateDelta) * MSecsPerDay * 1000);
  DurationMicros := Trunc(GetDuration * 1000);
  
  Result.AddPair('id', FSpanId);
  Result.AddPair('trace_id', FTraceId);
  if not FParentSpanId.IsEmpty then
    Result.AddPair('parent_id', FParentSpanId);
  Result.AddPair('name', FName);
  Result.AddPair('type', 'custom');
  Result.AddPair('timestamp', TJSONNumber.Create(StartTimeMicros));
  Result.AddPair('duration', TJSONNumber.Create(DurationMicros));
  
  // Add outcome
  case FOutcome of
    Success: Result.AddPair('outcome', 'success');
    Failure: Result.AddPair('outcome', 'failure');
    Unknown: Result.AddPair('outcome', 'unknown');
  end;
  
  // Add context with custom fields
  if FAttributes.Count > 0 then
  begin
    var ContextObj := TJSONObject.Create;
    var CustomObj := TJSONObject.Create;
    
    for Key in FAttributes.Keys do
      CustomObj.AddPair(Key, FAttributes[Key]);
    
    ContextObj.AddPair('custom', CustomObj);
    Result.AddPair('context', ContextObj);
  end;
end;

procedure TElasticSpan.DoFinish;
var
  SpanData: TJSONObject;
begin
  SpanData := ToElasticJSON;
  try
    FElasticProvider.SendToElastic(SpanData, 'intake/v2/events');
  finally
    SpanData.Free;
  end;
end;

procedure TElasticSpan.DoRecordException(const Exception: Exception);
var
  ErrorData: TJSONObject;
  ExceptionObj: TJSONObject;
begin
  ErrorData := TJSONObject.Create;
  try
    ErrorData.AddPair('id', FSpanId + '_error');
    ErrorData.AddPair('trace_id', FTraceId);
    ErrorData.AddPair('parent_id', FSpanId);
    ErrorData.AddPair('timestamp', TJSONNumber.Create(Trunc((Now - UnixDateDelta) * MSecsPerDay * 1000)));
    
    ExceptionObj := TJSONObject.Create;
    ExceptionObj.AddPair('type', Exception.ClassName);
    ExceptionObj.AddPair('message', Exception.Message);
    ErrorData.AddPair('exception', ExceptionObj);
    
    FElasticProvider.SendToElastic(ErrorData, 'intake/v2/events');
  finally
    ErrorData.Free;
  end;
end;

procedure TElasticSpan.DoAddEvent(const Name, Description: string);
begin
  // Elastic APM doesn't have direct events, add as span attribute
  AddAttribute('event.' + Name, Description);
end;

{ TElasticTracer }

constructor TElasticTracer.Create(const Context: IObservabilityContext; const ElasticProvider: TElasticAPMProvider);
begin
  inherited Create(Context);
  FElasticProvider := ElasticProvider;
end;

function TElasticTracer.DoCreateSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan;
begin
  Result := TElasticSpan.Create(Name, Context, FElasticProvider);
end;

procedure TElasticTracer.InjectHeaders(const Headers: TStrings);
begin
  if Assigned(FContext) then
  begin
    Headers.Values['elastic-apm-traceparent'] := Format('00-%s-%s-01', [FContext.TraceId, FContext.SpanId]);
  end;
end;

function TElasticTracer.ExtractContext(const Headers: TStrings): IObservabilityContext;
var
  TraceParent: string;
  Parts: TArray<string>;
  Context: IObservabilityContext;
begin
  TraceParent := Headers.Values['elastic-apm-traceparent'];
  Context := TObservabilityContext.CreateNew;
  
  if not TraceParent.IsEmpty then
  begin
    Parts := TraceParent.Split(['-']);
    if Length(Parts) >= 4 then
    begin
      Context.TraceId := Parts[1];
      Context.SpanId := Parts[2];
    end;
  end;
  
  Result := Context;
end;

{ TElasticLogger }

constructor TElasticLogger.Create(const Context: IObservabilityContext; const ElasticProvider: TElasticAPMProvider);
begin
  inherited Create(Context);
  FElasticProvider := ElasticProvider;
end;

function TElasticLogger.LogLevelToElastic(const Level: TLogLevel): string;
begin
  case Level of
    llTrace: Result := 'trace';
    llDebug: Result := 'debug';
    llInfo: Result := 'info';
    llWarning: Result := 'warning';
    llError: Result := 'error';
    llCritical: Result := 'critical';
  else
    Result := 'info';
  end;
end;

procedure TElasticLogger.DoLog(const Level: TLogLevel; const Message: string; 
  const Attributes: TDictionary<string, string>; const Exception: Exception);
var
  LogEntry: TJSONObject;
  Key: string;
begin
  LogEntry := TJSONObject.Create;
  try
    LogEntry.AddPair('@timestamp', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', TTimeZone.Local.ToUniversalTime(Now)));
    LogEntry.AddPair('log.level', LogLevelToElastic(Level));
    LogEntry.AddPair('message', Message);
    LogEntry.AddPair('service.name', FContext.ServiceName);
    LogEntry.AddPair('service.version', FContext.ServiceVersion);
    LogEntry.AddPair('service.environment', FContext.Environment);
    
    // Add trace correlation
    if not FContext.TraceId.IsEmpty then
    begin
      LogEntry.AddPair('trace.id', FContext.TraceId);
      LogEntry.AddPair('span.id', FContext.SpanId);
    end;
    
    // Add custom attributes
    if Assigned(Attributes) then
    begin
      for Key in Attributes.Keys do
        LogEntry.AddPair('labels.' + Key, Attributes[Key]);
    end;
    
    // Add global attributes
    for Key in FAttributes.Keys do
      LogEntry.AddPair('labels.' + Key, FAttributes[Key]);
    
    // Add exception details
    if Assigned(Exception) then
    begin
      LogEntry.AddPair('error.type', Exception.ClassName);
      LogEntry.AddPair('error.message', Exception.Message);
    end;
    
    FElasticProvider.SendToElastic(LogEntry, 'intake/v2/events');
    
  finally
    LogEntry.Free;
  end;
end;

{ TElasticMetrics }

constructor TElasticMetrics.Create(const Context: IObservabilityContext; const ElasticProvider: TElasticAPMProvider);
begin
  inherited Create(Context);
  FElasticProvider := ElasticProvider;
end;

procedure TElasticMetrics.SendMetricSet(const Metrics: TJSONObject);
begin
  FElasticProvider.SendToElastic(Metrics, 'intake/v2/events');
end;

procedure TElasticMetrics.DoCounter(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
var
  MetricData: TJSONObject;
  SamplesObj: TJSONObject;
  Key: string;
begin
  MetricData := TJSONObject.Create;
  try
    MetricData.AddPair('timestamp', TJSONNumber.Create(Trunc((Now - UnixDateDelta) * MSecsPerDay * 1000)));
    
    SamplesObj := TJSONObject.Create;
    SamplesObj.AddPair(Name + '.count', TJSONObject.Create.AddPair('value', TJSONNumber.Create(Value)));
    MetricData.AddPair('samples', SamplesObj);
    
    // Add tags
    if (Assigned(Tags) and (Tags.Count > 0)) or (FGlobalTags.Count > 0) then
    begin
      var TagsObj := TJSONObject.Create;
      
      if Assigned(Tags) then
      begin
        for Key in Tags.Keys do
          TagsObj.AddPair(Key, Tags[Key]);
      end;
      
      for Key in FGlobalTags.Keys do
        TagsObj.AddPair(Key, FGlobalTags[Key]);
        
      MetricData.AddPair('tags', TagsObj);
    end;
    
    SendMetricSet(MetricData);
    
  finally
    MetricData.Free;
  end;
end;

procedure TElasticMetrics.DoGauge(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
var
  MetricData: TJSONObject;
  SamplesObj: TJSONObject;
  Key: string;
begin
  MetricData := TJSONObject.Create;
  try
    MetricData.AddPair('timestamp', TJSONNumber.Create(Trunc((Now - UnixDateDelta) * MSecsPerDay * 1000)));
    
    SamplesObj := TJSONObject.Create;
    SamplesObj.AddPair(Name + '.gauge', TJSONObject.Create.AddPair('value', TJSONNumber.Create(Value)));
    MetricData.AddPair('samples', SamplesObj);
    
    // Add tags
    if (Assigned(Tags) and (Tags.Count > 0)) or (FGlobalTags.Count > 0) then
    begin
      var TagsObj := TJSONObject.Create;
      
      if Assigned(Tags) then
      begin
        for Key in Tags.Keys do
          TagsObj.AddPair(Key, Tags[Key]);
      end;
      
      for Key in FGlobalTags.Keys do
        TagsObj.AddPair(Key, FGlobalTags[Key]);
        
      MetricData.AddPair('tags', TagsObj);
    end;
    
    SendMetricSet(MetricData);
    
  finally
    MetricData.Free;
  end;
end;

procedure TElasticMetrics.DoHistogram(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
var
  MetricData: TJSONObject;
  SamplesObj: TJSONObject;
  Key: string;
begin
  MetricData := TJSONObject.Create;
  try
    MetricData.AddPair('timestamp', TJSONNumber.Create(Trunc((Now - UnixDateDelta) * MSecsPerDay * 1000)));
    
    SamplesObj := TJSONObject.Create;
    SamplesObj.AddPair(Name + '.histogram', TJSONObject.Create.AddPair('value', TJSONNumber.Create(Value)));
    MetricData.AddPair('samples', SamplesObj);
    
    // Add tags
    if (Assigned(Tags) and (Tags.Count > 0)) or (FGlobalTags.Count > 0) then
    begin
      var TagsObj := TJSONObject.Create;
      
      if Assigned(Tags) then
      begin
        for Key in Tags.Keys do
          TagsObj.AddPair(Key, Tags[Key]);
      end;
      
      for Key in FGlobalTags.Keys do
        TagsObj.AddPair(Key, FGlobalTags[Key]);
        
      MetricData.AddPair('tags', TagsObj);
    end;
    
    SendMetricSet(MetricData);
    
  finally
    MetricData.Free;
  end;
end;

procedure TElasticMetrics.DoSummary(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  // Elastic doesn't have summary metrics, use histogram instead
  DoHistogram(Name, Value, Tags);
end;

end.