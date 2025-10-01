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
  System.Net.URLClient, System.DateUtils, REST.Types,
{$IFDEF MSWINDOWS}
  Winapi.Windows,
{$ENDIF}
{$IFDEF LINUX}
  Posix.Unistd,
{$ENDIF}
  Observability.Interfaces, Observability.Provider.Base, Observability.Context,
  Observability.HttpClient;

type
  /// <summary>
  /// Elastic APM provider implementation for the ObservabilitySDK4D framework.
  /// This provider integrates with Elastic APM Server to send tracing, logging, and metrics data
  /// using the APM v2 API with NDJSON format. Supports transactions, spans, errors, and metrics
  /// with proper correlation and real-time data transmission.
  /// 
  /// Features:
  /// - Full APM v2 protocol compliance
  /// - NDJSON batch format for efficient data transmission
  /// - Automatic parent-child span correlation
  /// - System and application metrics collection
  /// - Error and exception tracking
  /// - Configurable server endpoints and authentication
  /// </summary>
  TElasticAPMProvider = class(TBaseObservabilityProvider)
  private
    FServerUrl: string;
    FApiKey: string;
    /// <summary>
    /// Sends a batch of observability data to Elastic APM Server using NDJSON format.
    /// Handles HTTP communication, authentication, and error handling.
    /// </summary>
    /// <param name="BatchData">The NDJSON formatted batch data to send</param>
    procedure SendBatchToElastic(const BatchData: string);
    
    /// <summary>
    /// Creates the metadata object required by Elastic APM protocol.
    /// Metadata contains service information, runtime details, and environment data.
    /// </summary>
    /// <returns>JSON object containing APM metadata</returns>
    function CreateMetadataObject: TJSONObject;
  protected
    /// <summary>
    /// Returns the provider type identifier.
    /// </summary>
    /// <returns>TObservabilityProvider.opElastic</returns>
    function GetProviderType: TObservabilityProvider; override;
    
    /// <summary>
    /// Returns the set of observability types supported by this provider.
    /// Elastic APM supports all types: tracing, logging, and metrics.
    /// </summary>
    /// <returns>Set containing all observability types</returns>
    function GetSupportedTypes: TObservabilityTypeSet; override;

    /// <summary>
    /// Creates a new Elastic-specific tracer instance.
    /// </summary>
    /// <returns>Tracer implementation for Elastic APM</returns>
    function CreateTracer: IObservabilityTracer; override;
    
    /// <summary>
    /// Creates a new Elastic-specific logger instance.
    /// </summary>
    /// <returns>Logger implementation for Elastic APM</returns>
    function CreateLogger: IObservabilityLogger; override;
    
    /// <summary>
    /// Creates a new Elastic-specific metrics collector instance.
    /// </summary>
    /// <returns>Metrics implementation for Elastic APM</returns>
    function CreateMetrics: IObservabilityMetrics; override;

    /// <summary>
    /// Validates the provider configuration for required Elastic APM settings.
    /// Checks server URL format and other required configuration parameters.
    /// </summary>
    procedure ValidateConfiguration; override;
  public
    /// <summary>
    /// Creates a new instance of the Elastic APM provider.
    /// Initializes the provider with default settings for Elastic APM integration.
    /// </summary>
    constructor Create; override;
  end;

  /// <summary>
  /// Elastic APM specific implementation of spans for distributed tracing.
  /// Handles conversion of span data to Elastic APM JSON format and manages
  /// the distinction between transactions (root spans) and regular spans.
  /// Integrates with Elastic APM's correlation model and timing requirements.
  /// </summary>
  TElasticSpan = class(TBaseObservabilitySpan)
  private
    FElasticProvider: TElasticAPMProvider;
  protected
    /// <summary>
    /// Called when the span is finished to send data to Elastic APM.
    /// Converts span data to Elastic JSON format and sends to APM server.
    /// </summary>
    procedure DoFinish; override;
    
    /// <summary>
    /// Records exception information in Elastic APM format.
    /// Captures exception details and associates them with the span.
    /// </summary>
    /// <param name="Exception">The exception to record</param>
    procedure DoRecordException(const Exception: Exception); override;
    
    /// <summary>
    /// Adds span events in Elastic APM format.
    /// Events represent significant moments during span execution.
    /// </summary>
    /// <param name="Name">The name of the event</param>
    /// <param name="Description">Description of the event</param>
    procedure DoAddEvent(const Name, Description: string); override;
  public
    /// <summary>
    /// Creates a new Elastic span instance.
    /// </summary>
    /// <param name="Name">The name of the span</param>
    /// <param name="Context">The observability context for the span</param>
    /// <param name="ElasticProvider">The Elastic provider instance</param>
    constructor Create(const Name: string; const Context: IObservabilityContext;
      const ElasticProvider: TElasticAPMProvider); reintroduce;

    /// <summary>
    /// Converts the span to Elastic APM JSON format.
    /// Supports both transaction and span formats based on the IsTransaction parameter.
    /// </summary>
    /// <param name="IsTransaction">True to format as transaction, false as span</param>
    /// <returns>JSON object in Elastic APM format</returns>
    function ToElasticJSON(const IsTransaction: Boolean = True): TJSONObject;
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

function TElasticAPMProvider.CreateMetadataObject: TJSONObject;
var
  ServiceObj, AgentObj, SystemObj, ProcessObj: TJSONObject;
  HostName: string;
begin
  Result := TJSONObject.Create;

  // Service metadata with embedded agent
  ServiceObj := TJSONObject.Create;
  ServiceObj.AddPair('name', FConfig.ServiceName);
  if not FConfig.ServiceVersion.IsEmpty then
    ServiceObj.AddPair('version', FConfig.ServiceVersion);
  if not FConfig.Environment.IsEmpty then
    ServiceObj.AddPair('environment', FConfig.Environment);

  // Agent metadata - INSIDE service object
  AgentObj := TJSONObject.Create;
  AgentObj.AddPair('name', 'apm-agent-delphi');
  AgentObj.AddPair('version', '1.0.0');
  ServiceObj.AddPair('agent', AgentObj);

  // Process metadata is optional
  ProcessObj := TJSONObject.Create;
  ProcessObj.AddPair('pid', TJSONNumber.Create(
{$IFDEF MSWINDOWS} GetCurrentProcessId {$ELSE} getpid {$ENDIF} )
    );

  // Get hostname
  HostName := GetEnvironmentVariable({$IFDEF MSWINDOWS} 'COMPUTERNAME' {$ELSE} 'HOSTNAME' {$ENDIF});
  if HostName.IsEmpty then
    HostName := 'localhost';

  // System metadata is optional
  SystemObj := TJSONObject.Create;
  SystemObj.AddPair('platform', {$IFDEF MSWINDOWS} 'windows' {$ELSE} 'linux' {$ENDIF});
  SystemObj.AddPair('architecture', {$IFDEF CPUX64} 'x86_64' {$ELSE} 'x86' {$ENDIF});
  SystemObj.AddPair('hostname', HostName);

  // Add service (with agent inside) and optional fields
  Result.AddPair('service', ServiceObj);
  Result.AddPair('process', ProcessObj);
  Result.AddPair('system', SystemObj);
end;

procedure TElasticAPMProvider.SendBatchToElastic(const BatchData: string);
var
  Response: IResponse;
  Request: IRequest;
begin
  // Try to recreate the client if it was somehow lost
  try
    Request := TRestClient.New
      .BaseURL(FServerUrl)
      .UserAgent('ObservabilitySDK4D-Elastic/1.0')
      .Accept('application/json')
      .Timeout(30000);

    if not FApiKey.IsEmpty then
      Request := Request.AddHeader('Authorization', 'Bearer ' + FApiKey);
  except
    on E: Exception do
    begin
      System.Writeln('[ELASTIC] ? Failed to recreate HttpClient: ' + E.Message);
      Exit;
    end;
  end;

  if BatchData.Trim.IsEmpty then
  begin
    System.Writeln('[ELASTIC] ? BatchData is empty');
    Exit;
  end;

  try
    System.Writeln('[ELASTIC-DEBUG] Sending to intake/v2/events endpoint');
    System.Writeln('[ELASTIC-DEBUG] Data: ' + BatchData);

    Response := Request
      .Resource('intake/v2/events')
      .AddHeader('Content-Type', 'application/x-ndjson', [poDoNotEncode])
      .AddBody(BatchData)
      .Post;

    if Response.StatusCode = 202 then
    begin
      System.Writeln('[ELASTIC] ? Batch sent successfully')
    end
    else
    begin
      System.Writeln(Format('[ELASTIC] ? Failed to send batch: %d', [Response.StatusCode]));
      System.Writeln('[ELASTIC] Response: ' + Response.AsString);
    end;
  except
    on E: Exception do
    begin
      System.Writeln(Format('[ELASTIC] ? Error sending batch: %s', [E.Message]));
      System.Writeln('[ELASTIC] Exception type: ' + E.ClassName);
    end;
  end;
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

function TElasticSpan.ToElasticJSON(const IsTransaction: Boolean = True): TJSONObject;
var
  Key: string;
  ContextObj, CustomObj, SpanCountObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  SpanCountObj := nil;
  ContextObj := nil;
  CustomObj := nil;

  try
    FDuration := MilliSecondsBetween(now, FStartTime);

    Result.AddPair('id', FSpanId);
    Result.AddPair('trace_id', FTraceId);
    if not FParentSpanId.IsEmpty then
      Result.AddPair('parent_id', FParentSpanId);
    Result.AddPair('name', FName);

    if IsTransaction then
    begin
      Result.AddPair('type', 'request'); // Standard transaction type
      // Required field for transactions: span_count (number of child spans)
      SpanCountObj := TJSONObject.Create;
      SpanCountObj.AddPair('started', TJSONNumber.Create(FChildSpanCount)); // Use real child span count
      Result.AddPair('span_count', SpanCountObj);
      SpanCountObj := nil; // Ownership transferred to Result
    end
    else
    begin
      Result.AddPair('type', 'custom'); // Standard span type
      // Spans don't need span_count
    end;

    Result.AddPair('timestamp', TJSONNumber.Create(Ftimestamp));
    Result.AddPair('duration', TJSONNumber.Create(FDuration));

    // Add outcome
    case FOutcome of
      Success:
        Result.AddPair('outcome', 'success');
      Failure:
        Result.AddPair('outcome', 'failure');
      Unknown:
        Result.AddPair('outcome', 'unknown');
    end;

    // Add context with custom fields
    if FAttributes.Count > 0 then
    begin
      ContextObj := TJSONObject.Create;
      CustomObj := TJSONObject.Create;

      for Key in FAttributes.Keys do
        CustomObj.AddPair(Key, FAttributes[Key]);

      ContextObj.AddPair('custom', CustomObj);
      CustomObj := nil; // Ownership transferred to ContextObj

      Result.AddPair('context', ContextObj);
      ContextObj := nil; // Ownership transferred to Result
    end;

  except
    SpanCountObj.Free;
    CustomObj.Free;
    ContextObj.Free;
    raise;
  end;
end;

procedure TElasticSpan.DoFinish;
var
  MetadataWrapper, DataObj: TJSONObject;
  BatchData: string;
  IsRootTransaction: Boolean;
begin
  // Determine if this is a root transaction (no parent) or a child span
  IsRootTransaction := FParentSpanId.IsEmpty;

  // Create metadata wrapper object (required for Elastic APM)
  MetadataWrapper := TJSONObject.Create;
  try
    MetadataWrapper.AddPair('metadata', FElasticProvider.CreateMetadataObject);

    // Create transaction or span wrapper based on hierarchy
    DataObj := TJSONObject.Create;
    try
      if IsRootTransaction then
        DataObj.AddPair('transaction', ToElasticJSON(True))
      else
        DataObj.AddPair('span', ToElasticJSON(False));

      // Create NDJSON batch format
      BatchData := MetadataWrapper.ToString + #10 + DataObj.ToString + #10;

      FElasticProvider.SendBatchToElastic(BatchData);
    finally
      DataObj.Free;
    end;
  finally
    MetadataWrapper.Free;
  end;
end;

procedure TElasticSpan.DoRecordException(const Exception: Exception);
var
  MetadataObj, ErrorObj, ExceptionObj: TJSONObject;
  BatchData: string;
begin
  // Create metadata
  MetadataObj := TJSONObject.Create;
  try
    MetadataObj.AddPair('metadata', FElasticProvider.CreateMetadataObject);

    // Create error object
    ErrorObj := TJSONObject.Create;
    try
      var
      ErrorData := TJSONObject.Create;
      ErrorData.AddPair('id', TGuid.NewGuid.ToString);
      ErrorData.AddPair('trace_id', FTraceId);
      ErrorData.AddPair('parent_id', FSpanId);
      ErrorData.AddPair('timestamp',
        TJSONNumber.Create(Trunc((TTimeZone.Local.ToUniversalTime(Now) - UnixDateDelta) * MSecsPerDay * 1000)));

      ExceptionObj := TJSONObject.Create;
      ExceptionObj.AddPair('type', Exception.ClassName);
      ExceptionObj.AddPair('message', Exception.Message);
      ErrorData.AddPair('exception', ExceptionObj);

      ErrorObj.AddPair('error', ErrorData);

      // Create NDJSON batch
      BatchData := MetadataObj.ToString + #10 + ErrorObj.ToString + #10;
      FElasticProvider.SendBatchToElastic(BatchData);

    finally
      ErrorObj.Free;
    end;
  finally
    MetadataObj.Free;
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
    llTrace:
      Result := 'trace';
    llDebug:
      Result := 'debug';
    llInfo:
      Result := 'info';
    llWarning:
      Result := 'warning';
    llError:
      Result := 'error';
    llCritical:
      Result := 'critical';
  else
    Result := 'info';
  end;
end;

procedure TElasticLogger.DoLog(const Level: TLogLevel; const Message: string;
  const Attributes: TDictionary<string, string>; const Exception: Exception);
var
  MetadataObj, LogObj: TJSONObject;
  LogEntry: TJSONObject;
  BatchData: string;
  Key: string;
begin
  // Create metadata
  MetadataObj := TJSONObject.Create;
  try
    MetadataObj.AddPair('metadata', FElasticProvider.CreateMetadataObject);

    // Create log object
    LogObj := TJSONObject.Create;
    try
      LogEntry := TJSONObject.Create;
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

      LogObj.AddPair('log', LogEntry);

      // Create NDJSON batch
      BatchData := MetadataObj.ToString + #10 + LogObj.ToString + #10;
      FElasticProvider.SendBatchToElastic(BatchData);

    finally
      LogObj.Free;
    end;
  finally
    MetadataObj.Free;
  end;
end;

{ TElasticMetrics }

constructor TElasticMetrics.Create(const Context: IObservabilityContext; const ElasticProvider: TElasticAPMProvider);
begin
  inherited Create(Context);
  FElasticProvider := ElasticProvider;
end;

procedure TElasticMetrics.SendMetricSet(const Metrics: TJSONObject);
var
  MetadataObj, MetricObj: TJSONObject;
  BatchData: string;
begin
  // Create metadata
  MetadataObj := TJSONObject.Create;
  try
    MetadataObj.AddPair('metadata', FElasticProvider.CreateMetadataObject);

    // Create metric object
    MetricObj := TJSONObject.Create;
    try
      MetricObj.AddPair('metricset', Metrics);

      // Create NDJSON batch
      BatchData := MetadataObj.ToString + #10 + MetricObj.ToString + #10;
      FElasticProvider.SendBatchToElastic(BatchData);
    finally
      MetricObj.Free;
    end;
  finally
    MetadataObj.Free;
  end;
end;

procedure TElasticMetrics.DoCounter(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
var
  MetricData: TJSONObject;
  SamplesObj: TJSONObject;
  Key: string;
begin
  MetricData := TJSONObject.Create;
  
  // Add required timestamp in microseconds since Unix epoch
  MetricData.AddPair('timestamp', TJSONNumber.Create(Trunc((TTimeZone.Local.ToUniversalTime(Now) - UnixDateDelta) * MSecsPerDay * 1000)));

  SamplesObj := TJSONObject.Create;
  SamplesObj.AddPair(Name + '.count', TJSONObject.Create.AddPair('value', TJSONNumber.Create(Value)));
  MetricData.AddPair('samples', SamplesObj);

  // Add tags
  if (Assigned(Tags) and (Tags.Count > 0)) or (FGlobalTags.Count > 0) then
  begin
    var
    TagsObj := TJSONObject.Create;

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
end;

procedure TElasticMetrics.DoGauge(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
var
  MetricData: TJSONObject;
  SamplesObj: TJSONObject;
  Key: string;
begin
  MetricData := TJSONObject.Create;
  
  // Add required timestamp in microseconds since Unix epoch
  MetricData.AddPair('timestamp', TJSONNumber.Create(Trunc((TTimeZone.Local.ToUniversalTime(Now) - UnixDateDelta) * MSecsPerDay * 1000)));

  SamplesObj := TJSONObject.Create;
  SamplesObj.AddPair(Name + '.gauge', TJSONObject.Create.AddPair('value', TJSONNumber.Create(Value)));
  MetricData.AddPair('samples', SamplesObj);

  // Add tags
  if (Assigned(Tags) and (Tags.Count > 0)) or (FGlobalTags.Count > 0) then
  begin
    var
    TagsObj := TJSONObject.Create;

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
end;

procedure TElasticMetrics.DoHistogram(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
var
  MetricData: TJSONObject;
  SamplesObj: TJSONObject;
  Key: string;
begin
  MetricData := TJSONObject.Create;
  
  // Add required timestamp in microseconds since Unix epoch
  MetricData.AddPair('timestamp', TJSONNumber.Create(Trunc((TTimeZone.Local.ToUniversalTime(Now) - UnixDateDelta) * MSecsPerDay * 1000)));

  SamplesObj := TJSONObject.Create;
  SamplesObj.AddPair(Name + '.histogram', TJSONObject.Create.AddPair('value', TJSONNumber.Create(Value)));
  MetricData.AddPair('samples', SamplesObj);

  // Add tags
  if (Assigned(Tags) and (Tags.Count > 0)) or (FGlobalTags.Count > 0) then
  begin
    var
    TagsObj := TJSONObject.Create;

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
end;

procedure TElasticMetrics.DoSummary(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  // Elastic doesn't have summary metrics, use histogram instead
  DoHistogram(Name, Value, Tags);
end;

end.
