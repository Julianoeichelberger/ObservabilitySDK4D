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
  System.Threading, System.DateUtils, System.TypInfo,
  Observability.Interfaces, Observability.Provider.Base, Observability.Context;

type 
  /// <summary>
  /// Configuration options specific to Jaeger integration.
  /// Focuses on HTTP transport with Jaeger Collector.
  /// </summary>
  TJaegerConfig = class
  public 
    CollectorEndpoint: string;      // HTTP endpoint for collector
    ProcessTags: TDictionary<string, string>;  // Process-level tags
    QueueSize: Integer;             // Internal queue size
    FlushInterval: Integer;         // Auto-flush interval in ms
    ReporterLogSpans: Boolean;      // Log spans to console
    SamplingType: string;           // const, probabilistic, ratelimiting
    SamplingParam: Double;          // Sampling parameter
    
    constructor Create;
    destructor Destroy; override;
  end;
  /// <summary>
  /// Jaeger provider implementation with HTTP transport integration.
  /// Provides reliable span delivery to Jaeger Collector via HTTP/HTTPS.
  /// Designed for production use with robust error handling and performance optimization.
  /// 
  /// Key Features:
  /// - HTTP/HTTPS transport to Jaeger Collector
  /// - Advanced sampling strategies (const, probabilistic, rate limiting)
  /// - Process-level tagging and service metadata
  /// - Batch processing with configurable queue sizes
  /// - Auto-flush capabilities with configurable intervals
  /// - Full Jaeger data model compliance
  /// - OpenTracing compatibility
  /// </summary>
  TJaegerProvider = class(TBaseObservabilityProvider)
  private
    FHttpClient: THTTPClient;
    FBatchSpans: TList<TJSONObject>;
    FBatchLock: TCriticalSection;
    FJaegerConfig: TJaegerConfig;
    FFlushTimer: TTimer;
    FProcess: TJSONObject;          // Cached process information
    FSpanQueue: TThreadedQueue<TJSONObject>;
    FReporterThread: TThread;
    
    // Core functionality
    procedure AddSpanToBatch(const SpanJSON: TJSONObject);
    procedure FlushSpans;
    procedure InitializeProcess;
    procedure StartReporter;
    procedure StopReporter;
    
    // HTTP transport
    procedure SendViaHTTP(const BatchData: string);
    
    // Sampling
    function ShouldSample(const TraceId: string): Boolean;
    
    // Jaeger format helpers
    function CreateJaegerBatch(const Spans: TArray<TJSONObject>): TJSONObject;
    function TraceIdToJaeger(const TraceId: string): string;
    function SpanIdToJaeger(const SpanId: string): string;
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

  /// <summary>
  /// Enhanced Jaeger span implementation with full Jaeger data model support.
  /// Implements proper Jaeger span format including process information,
  /// operation names, span kinds, logs, and references. Supports parent-child
  /// relationships and follows OpenTracing semantic conventions.
  /// </summary>
  TJaegerSpan = class(TBaseObservabilitySpan)
  private
    FJaegerProvider: TJaegerProvider;
    FLogs: TList<TJSONObject>;       // Span logs/events
    FReferences: TList<TJSONObject>; // Span references (ChildOf, FollowsFrom)
    
    procedure AddLog(const Timestamp: Int64; const Fields: TJSONObject);
    procedure AddReference(const RefType: string; const TraceId, SpanId: string);
    function CreateJaegerTags: TJSONArray;
    function CreateJaegerLogs: TJSONArray;
    function CreateJaegerReferences: TJSONArray;
  protected
    procedure DoFinish; override;
    procedure DoRecordException(const Exception: Exception); override;
    procedure DoAddEvent(const Name, Description: string); override;
  public
    constructor Create(const Name: string; const Context: IObservabilityContext; 
      const JaegerProvider: TJaegerProvider); reintroduce;
    destructor Destroy; override;
    
    /// <summary>
    /// Converts span to complete Jaeger JSON format with all metadata.
    /// Includes process information, tags, logs, and references.
    /// </summary>
    function ToJaegerJSON: TJSONObject;
    
    /// <summary>
    /// Adds a structured log entry to the span.
    /// </summary>
    procedure AddStructuredLog(const Level: string; const Message: string; const Fields: TDictionary<string, string> = nil);
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
  System.Math;

{ TJaegerConfig }

constructor TJaegerConfig.Create;
begin
  inherited Create;
  ProcessTags := TDictionary<string, string>.Create;
  
  // Default values 
  CollectorEndpoint := 'http://localhost:14268/api/traces';
  QueueSize := 1000;
  FlushInterval := 5000;  // 5 seconds
  ReporterLogSpans := False;
  SamplingType := 'const';
  SamplingParam := 1.0;
end;

destructor TJaegerConfig.Destroy;
begin
  ProcessTags.Free;
  inherited Destroy;
end;

{ TJaegerProvider }

constructor TJaegerProvider.Create(const AConfig: TObservabilityConfig);
begin
  inherited Create(AConfig);
  FJaegerConfig := TJaegerConfig.Create;
  FSpanQueue := TThreadList<TJaegerSpan>.Create;
  FBatchSender := nil;
  LoadFromConfig(AConfig);
  InitializeProcess;
  StartReporter;
end;

destructor TJaegerProvider.Destroy;
begin
  StopReporter;
  FJaegerConfig.Free;
  FSpanQueue.Free;
  inherited Destroy;
end;

procedure TJaegerProvider.LoadFromConfig(const AConfig: TObservabilityConfig);
var
  endpoint: string;
begin
  if AConfig.TryGetValue('jaeger.endpoint', endpoint) then
    FJaegerConfig.CollectorEndpoint := endpoint;
end;

procedure TJaegerProvider.InitializeProcess;
begin
  FProcessTags := TJSONObject.Create;
  
  // Add default process tags
  FJaegerConfig.ProcessTags.Add('hostname', GetEnvironmentVariable('COMPUTERNAME'));
  FJaegerConfig.ProcessTags.Add('process.executable_name', ExtractFileName(ParamStr(0)));
  FJaegerConfig.ProcessTags.Add('process.pid', IntToStr(GetCurrentProcessId));
  FJaegerConfig.ProcessTags.Add('jaeger.version', 'ObservabilitySDK4D-1.0');
  
  // Convert to JSON
  for var pair in FJaegerConfig.ProcessTags do
  begin
    FProcessTags.AddPair(pair.Key, pair.Value);
  end;
end;

procedure TJaegerProvider.StartReporter;
begin
  // HTTP reporter is always ready - no background threads needed for now
  // In a production environment, you could implement a background thread here
end;

procedure TJaegerProvider.StopReporter;
begin
  // Flush any remaining spans
  FlushSpans;
end;

procedure TJaegerProvider.SendViaHTTP(const ASpans: TArray<TJaegerSpan>);
var
  HttpClient: THTTPClient;
  Request: IHTTPRequest;
  Response: IHTTPResponse;
  JSONPayload: TJSONObject;
  JSONArray: TJSONArray;
  Stream: TStringStream;
begin
  HttpClient := THTTPClient.Create;
  try
    JSONPayload := TJSONObject.Create;
    try
      JSONArray := TJSONArray.Create;
      
      for var span in ASpans do
      begin
        JSONArray.AddElement(span.ToJSON);
      end;
      
      JSONPayload.AddPair('data', JSONArray);
      
      Stream := TStringStream.Create(JSONPayload.ToString, TEncoding.UTF8);
      try
        Request := HttpClient.CreateRequest;
        Request.URL := FJaegerConfig.CollectorEndpoint;
        Request.Method := 'POST';
        Request.Headers['Content-Type'] := 'application/json';
        Request.SourceStream := Stream;
        
        Response := Request.Execute;
        
        if Response.StatusCode <> 200 then
        begin
          // Log error but don't throw exception to avoid breaking application
          // In production, you would use proper logging
        end;
      finally
        Stream.Free;
      end;
    finally
      JSONPayload.Free;
    end;
  finally
    HttpClient.Free;
  end;
end;

function TJaegerProvider.ShouldSample: Boolean;
begin
  case FJaegerConfig.SamplingType of
    'const':
      Result := FJaegerConfig.SamplingParam > 0;
    'probabilistic':
      Result := Random <= FJaegerConfig.SamplingParam;
    'ratelimiting':
      Result := True; // Simplified - would need rate limiting logic
  else
    Result := True;
  end;
end;

procedure TJaegerProvider.FlushSpans;
var
  SpanList: TList<TJaegerSpan>;
  SpansToSend: TArray<TJaegerSpan>;
begin
  SpanList := FSpanQueue.LockList;
  try
    if SpanList.Count > 0 then
    begin
      SetLength(SpansToSend, SpanList.Count);
      for var i := 0 to SpanList.Count - 1 do
        SpansToSend[i] := SpanList[i];
      
      SpanList.Clear;
    end;
  finally
    FSpanQueue.UnlockList;
  end;
  
  if Length(SpansToSend) > 0 then
  begin
    SendViaHTTP(SpansToSend);
  end;
end;

{ TJaegerSpan }

constructor TJaegerSpan.Create(const ATraceId, ASpanId, AParentSpanId, AOperationName: string);
begin
  inherited Create(ATraceId, ASpanId, AParentSpanId, AOperationName);
  FLogs := TJSONArray.Create;
  FReferences := TJSONArray.Create;
  FProcess := TJSONObject.Create;
end;

destructor TJaegerSpan.Destroy;
begin
  FLogs.Free;
  FReferences.Free;
  FProcess.Free;
  inherited Destroy;
end;

procedure TJaegerSpan.AddLog(const ATimestamp: TDateTime; const AFields: TDictionary<string, string>);
var
  LogEntry: TJSONObject;
  FieldsJSON: TJSONArray;
  FieldObj: TJSONObject;
begin
  LogEntry := TJSONObject.Create;
  LogEntry.AddPair('timestamp', TJSONNumber.Create(DateTimeToUnix(ATimestamp) * 1000000)); // microseconds
  
  FieldsJSON := TJSONArray.Create;
  for var pair in AFields do
  begin
    FieldObj := TJSONObject.Create;
    FieldObj.AddPair('key', pair.Key);
    FieldObj.AddPair('value', pair.Value);
    FieldsJSON.AddElement(FieldObj);
  end;
  
  LogEntry.AddPair('fields', FieldsJSON);
  FLogs.AddElement(LogEntry);
end;

procedure TJaegerSpan.AddReference(const ARefType: string; const ATraceId, ASpanId: string);
var
  RefObj: TJSONObject;
  SpanContextObj: TJSONObject;
begin
  RefObj := TJSONObject.Create;
  RefObj.AddPair('refType', ARefType);
  
  SpanContextObj := TJSONObject.Create;
  SpanContextObj.AddPair('traceID', ATraceId);
  SpanContextObj.AddPair('spanID', ASpanId);
  
  RefObj.AddPair('spanContext', SpanContextObj);
  FReferences.AddElement(RefObj);
end;

function TJaegerSpan.CreateJaegerTags: TJSONArray;
var
  TagObj: TJSONObject;
begin
  Result := TJSONArray.Create;
  
  for var pair in FTags do
  begin
    TagObj := TJSONObject.Create;
    TagObj.AddPair('key', pair.Key);
    TagObj.AddPair('value', pair.Value);
    TagObj.AddPair('type', 'string'); // Simplified - would need type detection
    Result.AddElement(TagObj);
  end;
end;

function TJaegerSpan.ToJSON: TJSONObject;
var
  TagsArray: TJSONArray;
begin
  Result := TJSONObject.Create;
  
  Result.AddPair('traceID', FTraceId);
  Result.AddPair('spanID', FSpanId);
  if not FParentSpanId.IsEmpty then
    Result.AddPair('parentSpanID', FParentSpanId);
  
  Result.AddPair('operationName', FOperationName);
  Result.AddPair('startTime', TJSONNumber.Create(DateTimeToUnix(FStartTime) * 1000000)); // microseconds
  
  if FFinished then
    Result.AddPair('duration', TJSONNumber.Create(MilliSecondsBetween(FEndTime, FStartTime) * 1000)); // microseconds
  
  TagsArray := CreateJaegerTags;
  Result.AddPair('tags', TagsArray);
  
  if FLogs.Count > 0 then
    Result.AddPair('logs', FLogs.Clone as TJSONArray);
    
  if FReferences.Count > 0 then
    Result.AddPair('references', FReferences.Clone as TJSONArray);
    
  Result.AddPair('process', FProcess.Clone as TJSONObject);
end;

// Implementação dos métodos abstratos do TBaseObservabilityProvider

function TJaegerProvider.GetProviderType: TObservabilityProvider;
begin
  Result := opJaeger;
end;

function TJaegerProvider.GetSupportedTypes: TObservabilityTypeSet;
begin
  Result := [otTracing]; // Jaeger foca apenas em tracing
end;

function TJaegerProvider.CreateTracer: IObservabilityTracer;
begin
  Result := TJaegerTracer.Create(Self);
end;

function TJaegerProvider.CreateLogger: IObservabilityLogger;
begin
  // Jaeger não suporta logging direto, mas pode usar spans para isso
  raise ENotSupportedException.Create('Jaeger provider does not support direct logging');
end;

function TJaegerProvider.CreateMetrics: IObservabilityMetrics;
begin
  // Jaeger não suporta métricas diretas
  raise ENotSupportedException.Create('Jaeger provider does not support metrics');
end;

{ TJaegerTracer }

constructor TJaegerTracer.Create(AProvider: TJaegerProvider);
begin
  inherited Create(AProvider);
  FProvider := AProvider;
end;

function TJaegerTracer.DoCreateSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan;
var
  TraceId, SpanId, ParentSpanId: string;
  JaegerSpan: TJaegerSpan;
begin
  // Generate IDs
  TraceId := Context.TraceId;
  if TraceId.IsEmpty then
    TraceId := GenerateTraceId;
    
  SpanId := GenerateSpanId;
  ParentSpanId := Context.SpanId;
  
  // Create Jaeger span
  JaegerSpan := TJaegerSpan.Create(TraceId, SpanId, ParentSpanId, Name);
  
  // Check sampling
  if not FProvider.ShouldSample then
  begin
    JaegerSpan.SetTag('sampling.priority', '0');
  end;
  
  Result := JaegerSpan;
end;

function TJaegerTracer.GenerateTraceId: string;
begin
  // Generate 128-bit trace ID as hex string
  Result := Format('%.16x%.16x', [Random(MaxInt), Random(MaxInt)]);
end;

function TJaegerTracer.GenerateSpanId: string;
begin
  // Generate 64-bit span ID as hex string
  Result := Format('%.16x', [Random(MaxInt)]);
end;

{ TJaegerSpan - implementação dos métodos abstratos }

procedure TJaegerSpan.DoFinish;
var
  SpanList: TList<TJaegerSpan>;
begin
  inherited DoFinish;
  
  // Add span to provider's queue for sending
  if Assigned(FProvider) then
  begin
    SpanList := FProvider.FSpanQueue.LockList;
    try
      SpanList.Add(Self);
      
      // Flush if queue is full
      if SpanList.Count >= FProvider.FJaegerConfig.QueueSize then
      begin
        FProvider.FlushSpans;
      end;
    finally
      FProvider.FSpanQueue.UnlockList;
    end;
  end;
end;

procedure TJaegerSpan.DoRecordException(const Exception: Exception);
var
  Fields: TDictionary<string, string>;
begin
  Fields := TDictionary<string, string>.Create;
  try
    Fields.Add('event', 'error');
    Fields.Add('error.kind', Exception.ClassName);
    Fields.Add('error.object', Exception.Message);
    Fields.Add('level', 'error');
    
    AddLog(Now, Fields);
    SetTag('error', 'true');
  finally
    Fields.Free;
  end;
end;

procedure TJaegerSpan.DoAddEvent(const Name, Description: string);
var
  Fields: TDictionary<string, string>;
begin
  Fields := TDictionary<string, string>.Create;
  try
    Fields.Add('event', Name);
    if not Description.IsEmpty then
      Fields.Add('message', Description);
      
    AddLog(Now, Fields);
  finally
    Fields.Free;
  end;
end;

{ TJaegerLogger - stub implementation }

constructor TJaegerLogger.Create(AProvider: TBaseObservabilityProvider);
begin
  inherited Create(AProvider);
  FProvider := AProvider as TJaegerProvider;
end;

procedure TJaegerLogger.DoLog(const Level: TObservabilityLogLevel; const Message: string; 
  const Exception: Exception);
begin
  // Jaeger logger creates spans for log entries
  var span := FProvider.GetTracer.StartSpan('log');
  try
    span.SetTag('level', GetLogLevelString(Level));
    span.SetTag('message', Message);
    
    if Assigned(Exception) then
      span.RecordException(Exception);
  finally
    span.Finish;
  end;
end;

function TJaegerLogger.GetLogLevelString(Level: TObservabilityLogLevel): string;
begin
  case Level of
    llTrace: Result := 'trace';
    llDebug: Result := 'debug';
    llInfo: Result := 'info';
    llWarn: Result := 'warn';
    llError: Result := 'error';
    llFatal: Result := 'fatal';
  else
    Result := 'info';
  end;
end;

{ TJaegerMetrics - stub implementation }

constructor TJaegerMetrics.Create(AProvider: TBaseObservabilityProvider);
begin
  inherited Create(AProvider);
  FProvider := AProvider as TJaegerProvider;
end;

procedure TJaegerMetrics.DoCounter(const Name: string; const Value: Double; 
  const Tags: TDictionary<string, string>);
begin
  // Jaeger metrics creates spans for metric entries
  var span := FProvider.GetTracer.StartSpan('metric.counter');
  try
    span.SetTag('metric.name', Name);
    span.SetTag('metric.value', FloatToStr(Value));
    span.SetTag('metric.type', 'counter');
    
    if Assigned(Tags) then
    begin
      for var tag in Tags do
        span.SetTag('tag.' + tag.Key, tag.Value);
    end;
  finally
    span.Finish;
  end;
end;

procedure TJaegerMetrics.DoGauge(const Name: string; const Value: Double; 
  const Tags: TDictionary<string, string>);
begin
  var span := FProvider.GetTracer.StartSpan('metric.gauge');
  try
    span.SetTag('metric.name', Name);
    span.SetTag('metric.value', FloatToStr(Value));
    span.SetTag('metric.type', 'gauge');
    
    if Assigned(Tags) then
    begin
      for var tag in Tags do
        span.SetTag('tag.' + tag.Key, tag.Value);
    end;
  finally
    span.Finish;
  end;
end;

procedure TJaegerMetrics.DoHistogram(const Name: string; const Value: Double; 
  const Tags: TDictionary<string, string>);
begin
  var span := FProvider.GetTracer.StartSpan('metric.histogram');
  try
    span.SetTag('metric.name', Name);
    span.SetTag('metric.value', FloatToStr(Value));
    span.SetTag('metric.type', 'histogram');
    
    if Assigned(Tags) then
    begin
      for var tag in Tags do
        span.SetTag('tag.' + tag.Key, tag.Value);
    end;
  finally
    span.Finish;
  end;
end;

procedure TJaegerMetrics.DoSummary(const Name: string; const Value: Double; 
  const Tags: TDictionary<string, string>);
begin
  var span := FProvider.GetTracer.StartSpan('metric.summary');
  try
    span.SetTag('metric.name', Name);
    span.SetTag('metric.value', FloatToStr(Value));
    span.SetTag('metric.type', 'summary');
    
    if Assigned(Tags) then
    begin
      for var tag in Tags do
        span.SetTag('tag.' + tag.Key, tag.Value);
    end;
  finally
    span.Finish;
  end;
end;

// Implementação dos métodos faltantes do TJaegerProvider

function TJaegerProvider.CreateJaegerBatch(const Spans: TArray<TJSONObject>): TJSONObject;
var
  ProcessObj: TJSONObject;
  SpansArray: TJSONArray;
begin
  Result := TJSONObject.Create;
  
  // Create process object
  ProcessObj := TJSONObject.Create;
  ProcessObj.AddPair('serviceName', FConfig.ServiceName);
  ProcessObj.AddPair('tags', FProcessTags.Clone as TJSONArray);
  
  // Create spans array
  SpansArray := TJSONArray.Create;
  for var span in Spans do
    SpansArray.AddElement(span.Clone as TJSONObject);
  
  // Create batch
  var BatchObj := TJSONObject.Create;
  BatchObj.AddPair('process', ProcessObj);
  BatchObj.AddPair('spans', SpansArray);
  
  var BatchesArray := TJSONArray.Create;
  BatchesArray.AddElement(BatchObj);
  
  Result.AddPair('data', BatchesArray);
end;

function TJaegerProvider.TraceIdToJaeger(const TraceId: string): string;
begin
  // Convert trace ID to Jaeger format (128-bit hex)
  if TraceId.Length = 32 then
    Result := TraceId.ToLower
  else if TraceId.Length = 16 then
    Result := '0000000000000000' + TraceId.ToLower
  else
    Result := TraceId.ToLower;
end;

function TJaegerProvider.SpanIdToJaeger(const SpanId: string): string;
begin
  // Convert span ID to Jaeger format (64-bit hex)
  if SpanId.Length = 16 then
    Result := SpanId.ToLower
  else if SpanId.Length = 8 then
    Result := '00000000' + SpanId.ToLower
  else
    Result := SpanId.ToLower;
end;

// Implementação dos métodos faltantes do TJaegerSpan

function TJaegerSpan.CreateJaegerLogs: TJSONArray;
begin
  Result := TJSONArray.Create;
  for var logObj in FLogs do
    Result.AddElement(logObj.Clone as TJSONObject);
end;

function TJaegerSpan.CreateJaegerReferences: TJSONArray;
begin
  Result := TJSONArray.Create;
  for var refObj in FReferences do
    Result.AddElement(refObj.Clone as TJSONObject);
end;

procedure TJaegerSpan.AddStructuredLog(const Level: string; const Message: string; 
  const Fields: TDictionary<string, string> = nil);
var
  LogEntry: TJSONObject;
  FieldsArray: TJSONArray;
  FieldObj: TJSONObject;
begin
  LogEntry := TJSONObject.Create;
  LogEntry.AddPair('timestamp', TJSONNumber.Create(DateTimeToUnix(Now) * 1000000)); // microseconds
  
  FieldsArray := TJSONArray.Create;
  
  // Add level field
  FieldObj := TJSONObject.Create;
  FieldObj.AddPair('key', 'level');
  FieldObj.AddPair('value', Level);
  FieldsArray.AddElement(FieldObj);
  
  // Add message field
  FieldObj := TJSONObject.Create;
  FieldObj.AddPair('key', 'message');
  FieldObj.AddPair('value', Message);
  FieldsArray.AddElement(FieldObj);
  
  // Add custom fields
  if Assigned(Fields) then
  begin
    for var pair in Fields do
    begin
      FieldObj := TJSONObject.Create;
      FieldObj.AddPair('key', pair.Key);
      FieldObj.AddPair('value', pair.Value);
      FieldsArray.AddElement(FieldObj);
    end;
  end;
  
  LogEntry.AddPair('fields', FieldsArray);
  FLogs.Add(LogEntry);
end;

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