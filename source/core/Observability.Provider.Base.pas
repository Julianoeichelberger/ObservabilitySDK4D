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
unit Observability.Provider.Base;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs,
  Observability.Interfaces, Observability.Context;

type
  /// <summary>
  /// Abstract base class for all observability providers in the SDK.
  /// Implements the Template Method pattern to provide common functionality while allowing
  /// specific providers to customize behavior. Handles provider lifecycle, component management,
  /// configuration validation, and thread-safe initialization/shutdown procedures.
  /// 
  /// Key Features:
  /// - Thread-safe initialization and shutdown
  /// - Automatic component creation (tracer, logger, metrics)
  /// - Configuration validation and management
  /// - Template methods for provider-specific customization
  /// - Error handling for component access
  /// - Lazy initialization of supported components only
  /// </summary>
  TBaseObservabilityProvider = class abstract(TInterfacedObject, IObservabilityProvider)
  protected
    FConfig: IObservabilityConfig;
    FTracer: IObservabilityTracer;
    FLogger: IObservabilityLogger;
    FMetrics: IObservabilityMetrics;
    FInitialized: Boolean;
    FLock: TCriticalSection;

    // Abstract methods that must be implemented by specific providers
    /// <summary>
    /// Called during initialization to perform provider-specific setup.
    /// Override to implement custom initialization logic.
    /// </summary>
    procedure DoInitialize; virtual;
    
    /// <summary>
    /// Called during shutdown to perform provider-specific cleanup.
    /// Override to implement custom shutdown logic.
    /// </summary>
    procedure DoShutdown; virtual;
    
    /// <summary>
    /// Creates a provider-specific tracer instance.
    /// Must be implemented by concrete providers that support tracing.
    /// </summary>
    /// <returns>Provider-specific tracer implementation</returns>
    function CreateTracer: IObservabilityTracer; virtual; abstract;
    
    /// <summary>
    /// Creates a provider-specific logger instance.
    /// Must be implemented by concrete providers that support logging.
    /// </summary>
    /// <returns>Provider-specific logger implementation</returns>
    function CreateLogger: IObservabilityLogger; virtual; abstract;
    
    /// <summary>
    /// Creates a provider-specific metrics collector instance.
    /// Must be implemented by concrete providers that support metrics.
    /// </summary>
    /// <returns>Provider-specific metrics implementation</returns>
    function CreateMetrics: IObservabilityMetrics; virtual; abstract;

    // Template methods that can be overridden
    /// <summary>
    /// Validates the provider configuration.
    /// Override to add provider-specific validation rules.
    /// Default implementation checks for required service name.
    /// </summary>
    procedure ValidateConfiguration; virtual;
    
    /// <summary>
    /// Sets up provider components based on supported types.
    /// Creates tracer, logger, and metrics instances as needed.
    /// Called during initialization after configuration validation.
    /// </summary>
    procedure SetupComponents; virtual;
  protected
    /// <summary>
    /// Returns the provider type identifier.
    /// Must be implemented by concrete providers.
    /// </summary>
    /// <returns>The provider type enum value</returns>
    function GetProviderType: TObservabilityProvider; virtual; abstract;
    
    /// <summary>
    /// Returns the set of observability types supported by this provider.
    /// Must be implemented by concrete providers.
    /// </summary>
    /// <returns>Set of supported observability types</returns>
    function GetSupportedTypes: TObservabilityTypeSet; virtual; abstract;
    
    /// <summary>
    /// Gets the tracer instance for this provider.
    /// Raises exception if tracer is not initialized or not supported.
    /// </summary>
    /// <returns>The tracer instance</returns>
    function GetTracer: IObservabilityTracer; virtual;
    
    /// <summary>
    /// Gets the logger instance for this provider.
    /// Raises exception if logger is not initialized or not supported.
    /// </summary>
    /// <returns>The logger instance</returns>
    function GetLogger: IObservabilityLogger; virtual;
    
    /// <summary>
    /// Gets the metrics instance for this provider.
    /// Raises exception if metrics is not initialized or not supported.
    /// </summary>
    /// <returns>The metrics instance</returns>
    function GetMetrics: IObservabilityMetrics; virtual;

    /// <summary>
    /// Configures the provider with the specified configuration.
    /// Thread-safe operation that validates configuration before storing.
    /// </summary>
    /// <param name="Config">The configuration to apply</param>
    procedure Configure(const Config: IObservabilityConfig); virtual;
    
    /// <summary>
    /// Initializes the provider and all its components.
    /// Thread-safe operation that sets up components and calls DoInitialize.
    /// </summary>
    procedure Initialize; virtual;
    
    /// <summary>
    /// Shuts down the provider and cleans up all components.
    /// Thread-safe operation that calls DoShutdown and releases components.
    /// </summary>
    procedure Shutdown; virtual;
    
    /// <summary>
    /// Checks if the provider has been initialized.
    /// Thread-safe operation for checking provider state.
    /// </summary>
    /// <returns>True if initialized, false otherwise</returns>
    function IsInitialized: Boolean; virtual;
  public
    /// <summary>
    /// Creates a new provider instance and initializes synchronization objects.
    /// Sets initialized state to false and prepares for configuration.
    /// </summary>
    constructor Create; virtual;
    
    /// <summary>
    /// Destroys the provider instance and ensures proper cleanup.
    /// Automatically calls Shutdown if not already called.
    /// </summary>
    destructor Destroy; override;
  end;

  // Base implementations for common functionality
  /// <summary>
  /// Abstract base class for span implementations across all providers.
  /// Provides common span functionality including timing, attributes, context management,
  /// and automatic child span counting. Implements the Template Method pattern for
  /// provider-specific span operations while ensuring consistent behavior.
  /// 
  /// Key Features:
  /// - Automatic timing with UTC timestamps
  /// - Thread-safe attribute and event management
  /// - Child span counting for transaction metrics
  /// - Context correlation and ID generation
  /// - Outcome tracking and exception recording
  /// - Provider-specific customization points
  /// </summary>
  TBaseObservabilitySpan = class abstract(TInterfacedObject, IObservabilitySpan)
  protected
    FName: string;
    FSpanId: string;
    FTraceId: string;
    FParentSpanId: string;
    FKind: TSpanKind;
    Ftimestamp: Int64;
    FDuration: Int64;
    FStartTime: TDateTime;
    FEndTime: TDateTime;
    FOutcome: TOutcome;
    FAttributes: TDictionary<string, string>;
    FContext: IObservabilityContext;
    FFinished: Boolean;
    FChildSpanCount: Integer; // Counter for child spans
    FLock: TCriticalSection;
    
    /// <summary>
    /// Generates a unique identifier for spans.
    /// Creates a GUID-based ID compatible with tracing systems.
    /// </summary>
    /// <returns>Unique span identifier</returns>
    function GenerateId: string;
    
    // Abstract methods
    /// <summary>
    /// Called when the span is finished to perform provider-specific operations.
    /// Must be implemented by concrete span classes.
    /// </summary>
    procedure DoFinish; virtual; abstract;
    
    /// <summary>
    /// Records exception information in provider-specific format.
    /// Must be implemented by concrete span classes.
    /// </summary>
    /// <param name="Exception">The exception to record</param>
    procedure DoRecordException(const Exception: Exception); virtual; abstract;
    
    /// <summary>
    /// Adds an event to the span in provider-specific format.
    /// Must be implemented by concrete span classes.
    /// </summary>
    /// <param name="Name">The event name</param>
    /// <param name="Description">The event description</param>
    procedure DoAddEvent(const Name, Description: string); virtual; abstract;
  protected
    function GetName: string; virtual;
    function GetSpanId: string; virtual;
    function GetTraceId: string; virtual;
    function GetParentSpanId: string; virtual;
    function GetKind: TSpanKind; virtual;
    function GetStartTime: TDateTime; virtual;
    function GetEndTime: TDateTime; virtual; 
    function GetOutcome: TOutcome; virtual;
    function GetAttributes: TDictionary<string, string>; virtual;
    function GetContext: IObservabilityContext; virtual;
    function GetChildSpanCount: Integer; virtual;
    function GetDuration: Double; virtual; // Duration in milliseconds

    procedure SetName(const Value: string); virtual;
    procedure SetKind(const Value: TSpanKind); virtual;
    procedure SetOutcome(const Value: TOutcome); virtual;
    /// <summary>Increments the child span counter for this span. Thread-safe operation.</summary>
    procedure IncrementChildSpanCount; virtual; // Method to increment child span counter
    /// <summary>Adds a string attribute to the span.</summary>
    procedure AddAttribute(const Key, Value: string); overload; virtual;
    /// <summary>Adds an integer attribute to the span.</summary>
    procedure AddAttribute(const Key: string; const Value: Integer); overload; virtual;
    /// <summary>Adds a double attribute to the span.</summary>
    procedure AddAttribute(const Key: string; const Value: Double); overload; virtual;
    /// <summary>Adds a boolean attribute to the span.</summary>
    procedure AddAttribute(const Key: string; const Value: Boolean); overload; virtual;
    /// <summary>Adds an event to the span with optional description.</summary>
    procedure AddEvent(const Name, Description: string); virtual;
    /// <summary>Records an exception in the span and sets outcome to failure.</summary>
    procedure RecordException(const Exception: Exception); virtual;
    /// <summary>Finishes the span with success outcome.</summary>
    procedure Finish; overload; virtual;
    /// <summary>Finishes the span with specified outcome.</summary>
    procedure Finish(const Outcome: TOutcome); overload; virtual;
  public
    /// <summary>
    /// Creates a new span with the specified name and context.
    /// Automatically generates span ID, sets timing, and initializes collections.
    /// Updates the context with the new span ID for proper correlation.
    /// </summary>
    /// <param name="Name">The name of the span</param>
    /// <param name="Context">The observability context for correlation</param>
    constructor Create(const Name: string; const Context: IObservabilityContext); virtual;
    
    /// <summary>
    /// Destroys the span and ensures it's properly finished.
    /// Automatically calls Finish if not already called.
    /// </summary>
    destructor Destroy; override;
  end;

  /// <summary>
  /// Abstract base class for tracer implementations across all providers.
  /// Manages span creation, context propagation, and header injection/extraction
  /// for distributed tracing. Provides common functionality while allowing
  /// provider-specific span creation through the Template Method pattern.
  /// 
  /// Key Features:
  /// - Multiple span creation overloads for different scenarios
  /// - Active span tracking for context management
  /// - Header injection/extraction for distributed tracing
  /// - Thread-safe context and span management
  /// - Provider-specific span creation customization
  /// </summary>
  TBaseObservabilityTracer = class abstract(TInterfacedObject, IObservabilityTracer)
  protected
    FContext: IObservabilityContext;
    FActiveSpan: IObservabilitySpan;
    FLock: TCriticalSection;
    
    // Abstract methods
    /// <summary>
    /// Creates a provider-specific span instance.
    /// Must be implemented by concrete tracer classes.
    /// </summary>
    /// <param name="Name">The name of the span</param>
    /// <param name="Context">The context for the span</param>
    /// <returns>Provider-specific span implementation</returns>
    function DoCreateSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan; virtual; abstract;
  protected
    /// <summary>Creates a span with internal kind using the tracer context.</summary>
    function StartSpan(const Name: string): IObservabilitySpan; overload; virtual;
    /// <summary>Creates a span with specified kind using the tracer context.</summary>
    function StartSpan(const Name: string; const Kind: TSpanKind): IObservabilitySpan; overload; virtual;
    /// <summary>Creates a child span from a parent span with specified kind.</summary>
    function StartSpan(const Name: string; const Kind: TSpanKind; const Parent: IObservabilitySpan): IObservabilitySpan;
      overload; virtual;
    /// <summary>Creates a span with a specific context (most flexible option).</summary>
    function StartSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan; overload; virtual;
    /// <summary>Gets the currently active span.</summary>
    function GetActiveSpan: IObservabilitySpan; virtual;
    /// <summary>Gets the tracer's context.</summary>
    function GetContext: IObservabilityContext; virtual;
    /// <summary>Sets the tracer's context.</summary>
    procedure SetContext(const Context: IObservabilityContext); virtual;
    /// <summary>Injects trace context into HTTP headers for distributed tracing.</summary>
    procedure InjectHeaders(const Headers: TStrings); virtual;
    /// <summary>Extracts trace context from HTTP headers.</summary>
    function ExtractContext(const Headers: TStrings): IObservabilityContext; virtual;
  public
    /// <summary>
    /// Creates a new tracer with the specified context.
    /// Initializes synchronization objects and sets the base context.
    /// </summary>
    /// <param name="Context">The base context for this tracer</param>
    constructor Create(const Context: IObservabilityContext); virtual;
    
    /// <summary>
    /// Destroys the tracer and cleans up synchronization objects.
    /// </summary>
    destructor Destroy; override;
  end;

  /// <summary>
  /// Abstract base class for logger implementations across all providers.
  /// Provides structured logging with multiple severity levels, attribute support,
  /// and context correlation. Implements level filtering and various logging
  /// convenience methods while allowing provider-specific log formatting.
  /// 
  /// Key Features:
  /// - Multiple log levels with filtering support
  /// - Structured logging with attributes and context
  /// - Exception logging with stack traces
  /// - Format string support for parameterized messages
  /// - Thread-safe logging operations
  /// - Provider-specific log output customization
  /// </summary>
  TBaseObservabilityLogger = class abstract(TInterfacedObject, IObservabilityLogger)
  protected
    FLevel: TLogLevel;
    FContext: IObservabilityContext;
    FAttributes: TDictionary<string, string>;
    FLock: TCriticalSection;
    
    // Abstract methods
    /// <summary>
    /// Performs the actual logging operation in provider-specific format.
    /// Must be implemented by concrete logger classes.
    /// </summary>
    /// <param name="Level">The log level</param>
    /// <param name="Message">The log message</param>
    /// <param name="Attributes">Optional attributes dictionary</param>
    /// <param name="Exception">Optional exception to log</param>
    procedure DoLog(const Level: TLogLevel; const Message: string; const Attributes: TDictionary<string, string>;
      const Exception: Exception); virtual; abstract;
  public
    procedure Log(const Level: TLogLevel; const Message: string); overload; virtual;
    procedure Log(const Level: TLogLevel; const Message: string; const Args: array of const); overload; virtual;
    procedure Log(const Level: TLogLevel; const Message: string; const Exception: Exception); overload; virtual;
    procedure Log(const Level: TLogLevel; const Message: string; const Attributes: TDictionary<string, string>);
      overload; virtual;
    procedure Log(const Level: TLogLevel; const Message: string; const Attributes: TDictionary<string, string>;
      const Exception: Exception); overload; virtual;
  protected
    procedure Trace(const Message: string); overload; virtual;
    procedure Trace(const Message: string; const Args: array of const); overload; virtual;
    procedure Debug(const Message: string); overload; virtual;
    procedure Debug(const Message: string; const Args: array of const); overload; virtual;
    procedure Info(const Message: string); overload; virtual;
    procedure Info(const Message: string; const Args: array of const); overload; virtual;
    procedure Warning(const Message: string); overload; virtual;
    procedure Warning(const Message: string; const Args: array of const); overload; virtual;
    procedure Error(const Message: string); overload; virtual;
    procedure Error(const Message: string; const Exception: Exception); overload; virtual;
    procedure Error(const Message: string; const Args: array of const); overload; virtual;
    procedure Critical(const Message: string); overload; virtual;
    procedure Critical(const Message: string; const Exception: Exception); overload; virtual;
    procedure Critical(const Message: string; const Args: array of const); overload; virtual;

    procedure SetLevel(const Level: TLogLevel); virtual;
    function GetLevel: TLogLevel; virtual;
    procedure AddAttribute(const Key, Value: string); virtual;
    procedure SetContext(const Context: IObservabilityContext); virtual;
    function GetContext: IObservabilityContext; virtual;
  public
    constructor Create(const Context: IObservabilityContext); virtual;
    destructor Destroy; override;
  end;

  /// <summary>
  /// Abstract base class for metrics implementations across all providers.
  /// Provides support for all standard metric types (counter, gauge, histogram, summary)
  /// with tagging capabilities and global tag management. Implements thread-safe
  /// metric collection while allowing provider-specific metric formatting and transmission.
  /// 
  /// Key Features:
  /// - Support for all OpenTelemetry metric types
  /// - Per-metric and global tagging system
  /// - Thread-safe metric collection operations
  /// - Context correlation for metric attribution
  /// - Provider-specific metric transmission customization
  /// - Automatic global tag merging
  /// </summary>
  TBaseObservabilityMetrics = class abstract(TInterfacedObject, IObservabilityMetrics)
  protected
    FContext: IObservabilityContext;
    FGlobalTags: TDictionary<string, string>;
    FLock: TCriticalSection;

    // Abstract methods
    /// <summary>Performs counter metric collection in provider-specific format.</summary>
    procedure DoCounter(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); virtual; abstract;
    /// <summary>Performs gauge metric collection in provider-specific format.</summary>
    procedure DoGauge(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); virtual; abstract;
    /// <summary>Performs histogram metric collection in provider-specific format.</summary>
    procedure DoHistogram(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); virtual; abstract;
    /// <summary>Performs summary metric collection in provider-specific format.</summary>
    procedure DoSummary(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); virtual; abstract;
  protected
    procedure Counter(const Name: string; const Value: Double = 1.0); overload; virtual;
    procedure Counter(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); overload; virtual;
    procedure Gauge(const Name: string; const Value: Double); overload; virtual;
    procedure Gauge(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); overload; virtual;
    procedure Histogram(const Name: string; const Value: Double); overload; virtual;
    procedure Histogram(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); overload; virtual;
    procedure Summary(const Name: string; const Value: Double); overload; virtual;
    procedure Summary(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); overload; virtual;

    procedure SetContext(const Context: IObservabilityContext); virtual;
    function GetContext: IObservabilityContext; virtual;
    procedure AddGlobalTag(const Key, Value: string); virtual;
  public
    /// <summary>
    /// Creates a new metrics collector with the specified context.
    /// Initializes global tags collection and synchronization objects.
    /// </summary>
    /// <param name="Context">The context for metric attribution</param>
    constructor Create(const Context: IObservabilityContext); virtual;
    
    /// <summary>
    /// Destroys the metrics collector and cleans up resources.
    /// Properly disposes of global tags collection and synchronization objects.
    /// </summary>
    destructor Destroy; override;
  end;

implementation

uses
  System.DateUtils, Observability.Utils;

{ TBaseObservabilityProvider }

constructor TBaseObservabilityProvider.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FInitialized := False;
end;

destructor TBaseObservabilityProvider.Destroy;
begin
  Shutdown;
  FLock.Free;
  inherited Destroy;
end;

procedure TBaseObservabilityProvider.DoInitialize;
begin
  // virtual
end;

procedure TBaseObservabilityProvider.DoShutdown;
begin
  // virtual
end;

procedure TBaseObservabilityProvider.Configure(const Config: IObservabilityConfig);
begin
  FLock.Enter;
  try
    FConfig := Config;
    ValidateConfiguration;
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilityProvider.Initialize;
begin
  FLock.Enter;
  try
    if FInitialized then
      Exit;

    if not Assigned(FConfig) then
      raise EConfigurationError.Create('Configuration not set');

    SetupComponents;
    DoInitialize;
    FInitialized := True;
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilityProvider.Shutdown;
begin
  FLock.Enter;
  try
    if not FInitialized then
      Exit;

    DoShutdown;
    FTracer := nil;
    FLogger := nil;
    FMetrics := nil;
    FInitialized := False;
  finally
    FLock.Leave;
  end;
end;

function TBaseObservabilityProvider.IsInitialized: Boolean;
begin
  FLock.Enter;
  try
    Result := FInitialized;
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilityProvider.ValidateConfiguration;
begin
  if not Assigned(FConfig) then
    raise EConfigurationError.Create('Configuration is required');

  if FConfig.ServiceName.IsEmpty then
    raise EConfigurationError.Create('Service name is required');
end;

procedure TBaseObservabilityProvider.SetupComponents;
begin
  if otTracing in GetSupportedTypes then
    FTracer := CreateTracer;

  if otLogging in GetSupportedTypes then
    FLogger := CreateLogger;

  if otMetrics in GetSupportedTypes then
    FMetrics := CreateMetrics;
end;

function TBaseObservabilityProvider.GetTracer: IObservabilityTracer;
begin
  if not Assigned(FTracer) then
    raise EProviderNotInitialized.Create('Tracer not initialized or not supported by this provider');
  Result := FTracer;
end;

function TBaseObservabilityProvider.GetLogger: IObservabilityLogger;
begin
  if not Assigned(FLogger) then
    raise EProviderNotInitialized.Create('Logger not initialized or not supported by this provider');
  Result := FLogger;
end;

function TBaseObservabilityProvider.GetMetrics: IObservabilityMetrics;
begin
  if not Assigned(FMetrics) then
    raise EProviderNotInitialized.Create('Metrics not initialized or not supported by this provider');
  Result := FMetrics;
end;

{ TBaseObservabilitySpan }

constructor TBaseObservabilitySpan.Create(const Name: string; const Context: IObservabilityContext);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FName := Name;
  FContext := Context;
  FSpanId := GenerateId;
  FTraceId := Context.TraceId;
  FParentSpanId := Context.ParentSpanId; // Use ParentSpanId from context, not SpanId
  FStartTime := Now;
  Ftimestamp := TTimestampEpoch.Get(FStartTime);
  FKind := skInternal;
  FOutcome := Unknown;
  FAttributes := TDictionary<string, string>.Create;
  FFinished := False;
  FChildSpanCount := 0; // Initialize child span counter
  
  // Update context with this span's ID so future children can reference it correctly
  FContext.SpanId := FSpanId;
end;

destructor TBaseObservabilitySpan.Destroy;
begin
  if not FFinished then
    Finish;
  FAttributes.Free;
  FLock.Free;
  inherited Destroy;
end;

function TBaseObservabilitySpan.GetName: string;
begin
  Result := FName;
end;

function TBaseObservabilitySpan.GetSpanId: string;
begin
  Result := FSpanId;
end;

function TBaseObservabilitySpan.GetTraceId: string;
begin
  Result := FTraceId;
end;

function TBaseObservabilitySpan.GetParentSpanId: string;
begin
  Result := FParentSpanId;
end;

function TBaseObservabilitySpan.GetKind: TSpanKind;
begin
  Result := FKind;
end;

function TBaseObservabilitySpan.GetStartTime: TDateTime;
begin
  Result := FStartTime;
end;

function TBaseObservabilitySpan.GetEndTime: TDateTime;
begin
  Result := FEndTime;
end;

function TBaseObservabilitySpan.GetOutcome: TOutcome;
begin
  Result := FOutcome;
end;

function TBaseObservabilitySpan.GetAttributes: TDictionary<string, string>;
begin
  Result := FAttributes;
end;

function TBaseObservabilitySpan.GetContext: IObservabilityContext;
begin
  Result := FContext;
end;

function TBaseObservabilitySpan.GetChildSpanCount: Integer;
begin
  FLock.Enter;
  try
    Result := FChildSpanCount;
  finally
    FLock.Leave;
  end;
end;

function TBaseObservabilitySpan.GetDuration: Double;
begin
  FLock.Enter;
  try
    if FEndTime > 0 then
      Result := MilliSecondsBetween(FEndTime, FStartTime)
    else
      Result := MilliSecondsBetween(TTimeZone.Local.ToUniversalTime(Now), FStartTime); // Use UTC time
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilitySpan.IncrementChildSpanCount;
begin
  FLock.Enter;
  try
    if not FFinished then
      Inc(FChildSpanCount);
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilitySpan.SetName(const Value: string);
begin
  FLock.Enter;
  try
    if not FFinished then
      FName := Value;
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilitySpan.SetKind(const Value: TSpanKind);
begin
  FLock.Enter;
  try
    if not FFinished then
      FKind := Value;
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilitySpan.SetOutcome(const Value: TOutcome);
begin
  FLock.Enter;
  try
    if not FFinished then
      FOutcome := Value;
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilitySpan.AddAttribute(const Key, Value: string);
begin
  FLock.Enter;
  try
    if not FFinished then
      FAttributes.AddOrSetValue(Key, Value);
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilitySpan.AddAttribute(const Key: string; const Value: Integer);
begin
  AddAttribute(Key, Value.ToString);
end;

procedure TBaseObservabilitySpan.AddAttribute(const Key: string; const Value: Double);
begin
  AddAttribute(Key, Value.ToString);
end;

procedure TBaseObservabilitySpan.AddAttribute(const Key: string; const Value: Boolean);
begin
  AddAttribute(Key, BoolToStr(Value, True));
end;

procedure TBaseObservabilitySpan.AddEvent(const Name, Description: string);
begin
  FLock.Enter;
  try
    if not FFinished then
      DoAddEvent(Name, Description);
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilitySpan.RecordException(const Exception: Exception);
begin
  FLock.Enter;
  try
    if not FFinished then
    begin
      SetOutcome(Failure);
      DoRecordException(Exception);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilitySpan.Finish;
begin
  Finish(Success);
end;

procedure TBaseObservabilitySpan.Finish(const Outcome: TOutcome);
begin
  FLock.Enter;
  try
    if FFinished then
      Exit;

    FEndTime := TTimeZone.Local.ToUniversalTime(Now); // Use UTC time
    FOutcome := Outcome;
    FFinished := True;
    DoFinish;
  finally
    FLock.Leave;
  end;
end;

{ TBaseObservabilityTracer }

constructor TBaseObservabilityTracer.Create(const Context: IObservabilityContext);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FContext := Context;
end;

destructor TBaseObservabilityTracer.Destroy;
begin
  FLock.Free;
  inherited Destroy;
end;

function TBaseObservabilityTracer.StartSpan(const Name: string): IObservabilitySpan;
begin
  Result := StartSpan(Name, skInternal);
end;

function TBaseObservabilityTracer.StartSpan(const Name: string; const Kind: TSpanKind): IObservabilitySpan;
begin
  Result := StartSpan(Name, Kind, nil);
end;

function TBaseObservabilityTracer.StartSpan(const Name: string; const Kind: TSpanKind; const Parent: IObservabilitySpan)
  : IObservabilitySpan;
var
  Context: IObservabilityContext;
begin
  if Assigned(Parent) then
    Context := Parent.Context.Clone
  else
    Context := FContext.Clone;

  Result := StartSpan(Name, Context);
  Result.Kind := Kind;
end;

function TBaseObservabilityTracer.StartSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan;
begin
  FLock.Enter;
  try
    Result := DoCreateSpan(Name, Context);
    FActiveSpan := Result;
  finally
    FLock.Leave;
  end;
end;

function TBaseObservabilityTracer.GetActiveSpan: IObservabilitySpan;
begin
  FLock.Enter;
  try
    Result := FActiveSpan;
  finally
    FLock.Leave;
  end;
end;

function TBaseObservabilityTracer.GetContext: IObservabilityContext;
begin
  FLock.Enter;
  try
    Result := FContext;
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilityTracer.SetContext(const Context: IObservabilityContext);
begin
  FLock.Enter;
  try
    FContext := Context;
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilityTracer.InjectHeaders(const Headers: TStrings);
begin
  FLock.Enter;
  try
    if Assigned(FContext) then
      Headers.Values['X-Trace-Id'] := FContext.TraceId;
  finally
    FLock.Leave;
  end;
end;

function TBaseObservabilityTracer.ExtractContext(const Headers: TStrings): IObservabilityContext;
var
  TraceId: string;
begin
  TraceId := Headers.Values['X-Trace-Id'];
  if not TraceId.IsEmpty then
    Result := TObservabilityContext.CreateWithTraceId(TraceId)
  else
    Result := TObservabilityContext.CreateNew;
end;

{ TBaseObservabilityLogger }

constructor TBaseObservabilityLogger.Create(const Context: IObservabilityContext);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FContext := Context;
  FAttributes := TDictionary<string, string>.Create;
  FLevel := llInfo;
end;

destructor TBaseObservabilityLogger.Destroy;
begin
  FAttributes.Free;
  FLock.Free;
  inherited Destroy;
end;

procedure TBaseObservabilityLogger.Log(const Level: TLogLevel; const Message: string);
begin
  Log(Level, Message, nil, nil);
end;

procedure TBaseObservabilityLogger.Log(const Level: TLogLevel; const Message: string; const Args: array of const);
begin
  Log(Level, Format(Message, Args));
end;

procedure TBaseObservabilityLogger.Log(const Level: TLogLevel; const Message: string; const Exception: Exception);
begin
  Log(Level, Message, nil, Exception);
end;

procedure TBaseObservabilityLogger.Log(const Level: TLogLevel; const Message: string;
  const Attributes: TDictionary<string, string>);
begin
  Log(Level, Message, Attributes, nil);
end;

procedure TBaseObservabilityLogger.Log(const Level: TLogLevel; const Message: string;
  const Attributes: TDictionary<string, string>; const Exception: Exception);
begin
  FLock.Enter;
  try
    if Level >= FLevel then
      DoLog(Level, Message, Attributes, Exception);
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilityLogger.Trace(const Message: string);
begin
  Log(llTrace, Message);
end;

procedure TBaseObservabilityLogger.Trace(const Message: string; const Args: array of const);
begin
  Log(llTrace, Message, Args);
end;

procedure TBaseObservabilityLogger.Debug(const Message: string);
begin
  Log(llDebug, Message);
end;

procedure TBaseObservabilityLogger.Debug(const Message: string; const Args: array of const);
begin
  Log(llDebug, Message, Args);
end;

procedure TBaseObservabilityLogger.Info(const Message: string);
begin
  Log(llInfo, Message);
end;

procedure TBaseObservabilityLogger.Info(const Message: string; const Args: array of const);
begin
  Log(llInfo, Message, Args);
end;

procedure TBaseObservabilityLogger.Warning(const Message: string);
begin
  Log(llWarning, Message);
end;

procedure TBaseObservabilityLogger.Warning(const Message: string; const Args: array of const);
begin
  Log(llWarning, Message, Args);
end;

procedure TBaseObservabilityLogger.Error(const Message: string);
begin
  Log(llError, Message);
end;

procedure TBaseObservabilityLogger.Error(const Message: string; const Exception: Exception);
begin
  Log(llError, Message, Exception);
end;

procedure TBaseObservabilityLogger.Error(const Message: string; const Args: array of const);
begin
  Log(llError, Message, Args);
end;

procedure TBaseObservabilityLogger.Critical(const Message: string);
begin
  Log(llCritical, Message);
end;

procedure TBaseObservabilityLogger.Critical(const Message: string; const Exception: Exception);
begin
  Log(llCritical, Message, Exception);
end;

procedure TBaseObservabilityLogger.Critical(const Message: string; const Args: array of const);
begin
  Log(llCritical, Message, Args);
end;

procedure TBaseObservabilityLogger.SetLevel(const Level: TLogLevel);
begin
  FLock.Enter;
  try
    FLevel := Level;
  finally
    FLock.Leave;
  end;
end;

function TBaseObservabilityLogger.GetLevel: TLogLevel;
begin
  FLock.Enter;
  try
    Result := FLevel;
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilityLogger.AddAttribute(const Key, Value: string);
begin
  FLock.Enter;
  try
    FAttributes.AddOrSetValue(Key, Value);
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilityLogger.SetContext(const Context: IObservabilityContext);
begin
  FLock.Enter;
  try
    FContext := Context;
  finally
    FLock.Leave;
  end;
end;

function TBaseObservabilityLogger.GetContext: IObservabilityContext;
begin
  FLock.Enter;
  try
    Result := FContext;
  finally
    FLock.Leave;
  end;
end;

{ TBaseObservabilityMetrics }

constructor TBaseObservabilityMetrics.Create(const Context: IObservabilityContext);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FContext := Context;
  FGlobalTags := TDictionary<string, string>.Create;
end;

destructor TBaseObservabilityMetrics.Destroy;
begin
  FGlobalTags.Free;
  FLock.Free;
  inherited Destroy;
end;

procedure TBaseObservabilityMetrics.Counter(const Name: string; const Value: Double);
begin
  Counter(Name, Value, nil);
end;

procedure TBaseObservabilityMetrics.Counter(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  FLock.Enter;
  try
    DoCounter(Name, Value, Tags);
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilityMetrics.Gauge(const Name: string; const Value: Double);
begin
  Gauge(Name, Value, nil);
end;

procedure TBaseObservabilityMetrics.Gauge(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  FLock.Enter;
  try
    DoGauge(Name, Value, Tags);
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilityMetrics.Histogram(const Name: string; const Value: Double);
begin
  Histogram(Name, Value, nil);
end;

procedure TBaseObservabilityMetrics.Histogram(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  FLock.Enter;
  try
    DoHistogram(Name, Value, Tags);
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilityMetrics.Summary(const Name: string; const Value: Double);
begin
  Summary(Name, Value, nil);
end;

procedure TBaseObservabilityMetrics.Summary(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  FLock.Enter;
  try
    DoSummary(Name, Value, Tags);
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilityMetrics.SetContext(const Context: IObservabilityContext);
begin
  FLock.Enter;
  try
    FContext := Context;
  finally
    FLock.Leave;
  end;
end;

function TBaseObservabilityMetrics.GetContext: IObservabilityContext;
begin
  FLock.Enter;
  try
    Result := FContext;
  finally
    FLock.Leave;
  end;
end;

procedure TBaseObservabilityMetrics.AddGlobalTag(const Key, Value: string);
begin
  FLock.Enter;
  try
    FGlobalTags.AddOrSetValue(Key, Value);
  finally
    FLock.Leave;
  end;
end;

function TBaseObservabilitySpan.GenerateId: string;
var
  Guid: TGUID;
begin
  CreateGUID(Guid);
  Result := GUIDToString(Guid);
  Result := Result.Replace('{', '').Replace('}', '').Replace('-', '').ToLower;
end;

end.
