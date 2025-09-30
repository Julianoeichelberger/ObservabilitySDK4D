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
unit Observability.Provider.Jaeger;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON,
  System.Net.HTTPClient, System.Net.HTTPClientComponent, System.SyncObjs,
  Observability.Interfaces, Observability.Provider.Base, Observability.Context;

type
  TJaegerProvider = class(TBaseObservabilityProvider)
  private
    FHttpClient: THTTPClient;
    FBatchSpans: TList<TJSONObject>;
    FBatchLock: TObject;
    
    procedure AddSpanToBatch(const SpanJSON: TJSONObject);
    procedure FlushSpans;
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

  TJaegerSpan = class(TBaseObservabilitySpan)
  private
    FJaegerProvider: TJaegerProvider;
  protected
    procedure DoFinish; override;
    procedure DoRecordException(const Exception: Exception); override;
    procedure DoAddEvent(const Name, Description: string); override;
  public
    constructor Create(const Name: string; const Context: IObservabilityContext; 
      const JaegerProvider: TJaegerProvider); reintroduce;
    
    function ToJaegerJSON: TJSONObject;
  end;

  TJaegerTracer = class(TBaseObservabilityTracer)
  private
    FJaegerProvider: TJaegerProvider;
  protected
    function DoCreateSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan; override;
  public
    constructor Create(const Context: IObservabilityContext; const JaegerProvider: TJaegerProvider); reintroduce;
    
    procedure InjectHeaders(const Headers: TStrings); override;
    function ExtractContext(const Headers: TStrings): IObservabilityContext; override;
  end;

  TJaegerLogger = class(TBaseObservabilityLogger)
  protected
    procedure DoLog(const Level: TLogLevel; const Message: string; 
      const Attributes: TDictionary<string, string>; const Exception: Exception); override;
  end;

  TJaegerMetrics = class(TBaseObservabilityMetrics)
  protected
    procedure DoCounter(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
    procedure DoGauge(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
    procedure DoHistogram(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
    procedure DoSummary(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
  end;

implementation

uses
  System.DateUtils;

{ TJaegerProvider }

constructor TJaegerProvider.Create;
begin
  inherited Create;
  FBatchSpans := TList<TJSONObject>.Create;
  FBatchLock := TObject.Create;
end;

destructor TJaegerProvider.Destroy;
var
  Span: TJSONObject;
begin
  // Clean up any remaining spans
  for Span in FBatchSpans do
    Span.Free;
  FBatchSpans.Free;
  FBatchLock.Free;
  FHttpClient.Free;
  inherited Destroy;
end;

function TJaegerProvider.GetProviderType: TObservabilityProvider;
begin
  Result := opJaeger;
end;

function TJaegerProvider.GetSupportedTypes: TObservabilityTypeSet;
begin
  // Jaeger primarily supports tracing
  Result := [otTracing];
end;

procedure TJaegerProvider.ValidateConfiguration;
begin
  inherited ValidateConfiguration;
  
  if FConfig.ServerUrl.IsEmpty then
    raise EConfigurationError.Create('Jaeger server URL is required');
end;

procedure TJaegerProvider.DoInitialize;
begin
  FHttpClient := THTTPClient.Create;
  FHttpClient.UserAgent := 'ObservabilitySDK4D-Jaeger/2.0';
  
  // Set timeout
  FHttpClient.ConnectionTimeout := 5000;
  FHttpClient.ResponseTimeout := 10000;
  
  // Add API key if provided
  if not FConfig.ApiKey.IsEmpty then
    FHttpClient.CustomHeaders['Authorization'] := 'Bearer ' + FConfig.ApiKey;
end;

procedure TJaegerProvider.DoShutdown;
begin
  // Flush any remaining spans
  FlushSpans;
  
  FHttpClient.Free;
  FHttpClient := nil;
end;

function TJaegerProvider.CreateTracer: IObservabilityTracer;
var
  Context: IObservabilityContext;
begin
  Context := TObservabilityContext.CreateNew;
  Context.ServiceName := FConfig.ServiceName;
  Context.ServiceVersion := FConfig.ServiceVersion;
  Context.Environment := FConfig.Environment;
  
  Result := TJaegerTracer.Create(Context, Self);
end;

function TJaegerProvider.CreateLogger: IObservabilityLogger;
var
  Context: IObservabilityContext;
begin
  Context := TObservabilityContext.CreateNew;
  Context.ServiceName := FConfig.ServiceName;
  Context.ServiceVersion := FConfig.ServiceVersion;
  Context.Environment := FConfig.Environment;
  
  Result := TJaegerLogger.Create(Context);
end;

function TJaegerProvider.CreateMetrics: IObservabilityMetrics;
var
  Context: IObservabilityContext;
begin
  Context := TObservabilityContext.CreateNew;
  Context.ServiceName := FConfig.ServiceName;
  Context.ServiceVersion := FConfig.ServiceVersion;
  Context.Environment := FConfig.Environment;
  
  Result := TJaegerMetrics.Create(Context);
end;

procedure TJaegerProvider.AddSpanToBatch(const SpanJSON: TJSONObject);
begin
  TMonitor.Enter(FBatchLock);
  try
    FBatchSpans.Add(SpanJSON);
    
    // Check if we should flush
    if FBatchSpans.Count >= FConfig.BatchSize then
      FlushSpans;
  finally
    TMonitor.Exit(FBatchLock);
  end;
end;

procedure TJaegerProvider.FlushSpans;
var
  Batch: TJSONObject;
  SpansArray: TJSONArray;
  Span: TJSONObject;
  RequestBody: string;
  Response: IHTTPResponse;
begin
  TMonitor.Enter(FBatchLock);
  try
    if FBatchSpans.Count = 0 then
      Exit;
    
    // Create Jaeger batch format
    Batch := TJSONObject.Create;
    SpansArray := TJSONArray.Create;
    
    try
      // Move all spans to the array
      for Span in FBatchSpans do
        SpansArray.AddElement(Span);
      FBatchSpans.Clear;
      
      // Create batch structure
      Batch.AddPair('spans', SpansArray);
      
      RequestBody := Batch.ToString;
      
      // Send to Jaeger
      try
        Response := FHttpClient.Post(FConfig.ServerUrl, TStringStream.Create(RequestBody), nil, 
          [TNameValuePair.Create('Content-Type', 'application/json')]);
        
        if Response.StatusCode <> 202 then
        begin
          // Log error but don't fail
          System.Writeln(Format('[JAEGER] Failed to send spans. Status: %d, Response: %s', 
            [Response.StatusCode, Response.ContentAsString]));
        end;
      except
        on E: Exception do
          System.Writeln('[JAEGER] Error sending spans: ' + E.Message);
      end;
      
    finally
      Batch.Free; // This will also free SpansArray and remaining spans
    end;
    
  finally
    TMonitor.Exit(FBatchLock);
  end;
end;

{ TJaegerSpan }

constructor TJaegerSpan.Create(const Name: string; const Context: IObservabilityContext; 
  const JaegerProvider: TJaegerProvider);
begin
  inherited Create(Name, Context);
  FJaegerProvider := JaegerProvider;
end;

procedure TJaegerSpan.DoFinish;
begin
  // Send span to Jaeger
  if Assigned(FJaegerProvider) then
    FJaegerProvider.AddSpanToBatch(ToJaegerJSON);
end;

procedure TJaegerSpan.DoRecordException(const Exception: Exception);
begin
  // Add exception as span tags
  AddAttribute('error', 'true');
  AddAttribute('error.kind', Exception.ClassName);
  AddAttribute('error.message', Exception.Message);
end;

procedure TJaegerSpan.DoAddEvent(const Name, Description: string);
begin
  // Jaeger doesn't have direct events support in this simple implementation
  // Could be added as span logs
  AddAttribute('event.' + Name, Description);
end;

function TJaegerSpan.ToJaegerJSON: TJSONObject;
var
  TagsArray: TJSONArray;
  Key: string;
  StartTimeMicros, EndTimeMicros: Int64;
begin
  Result := TJSONObject.Create;
  
  // Convert times to microseconds since epoch
  StartTimeMicros := Trunc((FStartTime - UnixDateDelta) * MSecsPerDay * 1000);
  EndTimeMicros := Trunc((FEndTime - UnixDateDelta) * MSecsPerDay * 1000);
  
  Result.AddPair('traceID', FTraceId.Replace('-', ''));
  Result.AddPair('spanID', FSpanId.Replace('-', ''));
  if not FParentSpanId.IsEmpty then
    Result.AddPair('parentSpanID', FParentSpanId.Replace('-', ''));
  Result.AddPair('operationName', FName);
  Result.AddPair('startTime', TJSONNumber.Create(StartTimeMicros));
  Result.AddPair('duration', TJSONNumber.Create(EndTimeMicros - StartTimeMicros));
  
  // Add tags
  TagsArray := TJSONArray.Create;
  
  // Add span attributes as tags
  for Key in FAttributes.Keys do
  begin
    var Tag := TJSONObject.Create;
    Tag.AddPair('key', Key);
    Tag.AddPair('value', FAttributes[Key]);
    Tag.AddPair('type', 'string');
    TagsArray.AddElement(Tag);
  end;
  
  // Add context information as tags
  if not FContext.ServiceName.IsEmpty then
  begin
    var Tag := TJSONObject.Create;
    Tag.AddPair('key', 'service.name');
    Tag.AddPair('value', FContext.ServiceName);
    Tag.AddPair('type', 'string');
    TagsArray.AddElement(Tag);
  end;
  
  if not FContext.ServiceVersion.IsEmpty then
  begin
    var Tag := TJSONObject.Create;
    Tag.AddPair('key', 'service.version');
    Tag.AddPair('value', FContext.ServiceVersion);
    Tag.AddPair('type', 'string');
    TagsArray.AddElement(Tag);
  end;
  
  Result.AddPair('tags', TagsArray);
  
  // Add process information
  var Process := TJSONObject.Create;
  Process.AddPair('serviceName', FContext.ServiceName);
  var ProcessTags := TJSONArray.Create;
  Process.AddPair('tags', ProcessTags);
  Result.AddPair('process', Process);
end;

{ TJaegerTracer }

constructor TJaegerTracer.Create(const Context: IObservabilityContext; const JaegerProvider: TJaegerProvider);
begin
  inherited Create(Context);
  FJaegerProvider := JaegerProvider;
end;

function TJaegerTracer.DoCreateSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan;
begin
  Result := TJaegerSpan.Create(Name, Context, FJaegerProvider);
end;

procedure TJaegerTracer.InjectHeaders(const Headers: TStrings);
begin
  // Jaeger uses uber-trace-id header format
  if Assigned(FContext) then
  begin
    var TraceId := FContext.TraceId.Replace('-', '');
    var SpanId := FContext.SpanId.Replace('-', '');
    var ParentSpanId := FContext.ParentSpanId.Replace('-', '');
    
    // Format: {trace-id}:{span-id}:{parent-span-id}:{flags}
    var UberTraceId := Format('%s:%s:%s:1', [TraceId, SpanId, ParentSpanId]);
    Headers.Values['uber-trace-id'] := UberTraceId;
  end;
end;

function TJaegerTracer.ExtractContext(const Headers: TStrings): IObservabilityContext;
var
  UberTraceId: string;
  Parts: TArray<string>;
  Context: IObservabilityContext;
begin
  UberTraceId := Headers.Values['uber-trace-id'];
  
  Context := TObservabilityContext.CreateNew;
  
  if not UberTraceId.IsEmpty then
  begin
    Parts := UberTraceId.Split([':']);
    if Length(Parts) >= 3 then
    begin
      Context.TraceId := Parts[0];
      Context.SpanId := Parts[1];
      if Parts[2] <> '0' then
        Context.ParentSpanId := Parts[2];
    end;
  end;
  
  Result := Context;
end;

{ TJaegerLogger }

procedure TJaegerLogger.DoLog(const Level: TLogLevel; const Message: string; 
  const Attributes: TDictionary<string, string>; const Exception: Exception);
begin
  // Jaeger doesn't support logging directly
  // This could be implemented by sending log entries as spans
  // For now, fallback to console
  var LogLine := Format('[JAEGER-LOG %s] %s | %s', [
    GetEnumName(TypeInfo(TLogLevel), Ord(Level)),
    FormatDateTime('hh:nn:ss.zzz', Now),
    Message
  ]);
  
  if Assigned(Exception) then
    LogLine := LogLine + Format(' | Exception: %s', [Exception.Message]);
  
  System.Writeln(LogLine);
end;

{ TJaegerMetrics }

procedure TJaegerMetrics.DoCounter(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  // Jaeger doesn't support metrics directly
  // This could be implemented by sending metric data as spans or to a separate metrics backend
  System.Writeln(Format('[JAEGER-METRICS] Counter %s: %.2f', [Name, Value]));
end;

procedure TJaegerMetrics.DoGauge(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  System.Writeln(Format('[JAEGER-METRICS] Gauge %s: %.2f', [Name, Value]));
end;

procedure TJaegerMetrics.DoHistogram(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  System.Writeln(Format('[JAEGER-METRICS] Histogram %s: %.2f', [Name, Value]));
end;

procedure TJaegerMetrics.DoSummary(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  System.Writeln(Format('[JAEGER-METRICS] Summary %s: %.2f', [Name, Value]));
end;

end.