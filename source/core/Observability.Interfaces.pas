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
unit Observability.Interfaces;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  // Enums básicos
  /// <summary>
  /// Enumeration of supported observability providers.
  /// Each provider represents a different backend for collecting observability data.
  /// </summary>
  TObservabilityProvider = (
    opElastic,        // Elastic APM for full observability stack
    opJaeger,         // Jaeger for distributed tracing
    opSentry,         // Sentry for error tracking and performance monitoring
    opDatadog,        // Datadog APM for complete monitoring solution
    opOpenTelemetry,  // OpenTelemetry standard (reserved for future use)
    opConsole,        // Console output for development and debugging
    opCustom          // Custom provider implementation
  );
  
  /// <summary>
  /// Types of observability data that can be collected.
  /// Used to specify which capabilities a provider supports.
  /// </summary>
  TObservabilityType = (
    otTracing,  // Distributed tracing with spans
    otLogging,  // Structured logging
    otMetrics,  // Application and system metrics
    otAll       // All observability types
  );
  
  /// <summary>
  /// Set of observability types for specifying multiple capabilities.
  /// </summary>
  TObservabilityTypeSet = set of TObservabilityType;
  
  /// <summary>
  /// Log severity levels from least to most severe.
  /// Used to categorize log messages by importance and filter logs.
  /// </summary>
  TLogLevel = (
    llTrace,    // Finest-grained informational events
    llDebug,    // Fine-grained informational events for debugging
    llInfo,     // Informational messages highlighting application progress
    llWarning,  // Potentially harmful situations
    llError,    // Error events that don't stop the application
    llCritical  // Critical error events that might cause application termination
  );
  
  /// <summary>
  /// Types of metrics that can be collected.
  /// Each type has different semantic meaning and aggregation behavior.
  /// </summary>
  TMetricType = (
    mtCounter,   // Cumulative metric that only increases (e.g., request count)
    mtGauge,     // Point-in-time metric that can go up or down (e.g., memory usage)
    mtHistogram, // Distribution of values with configurable buckets (e.g., response times)
    mtSummary    // Distribution with percentile calculations (e.g., percentiles)
  );
  
  /// <summary>
  /// Span kinds that indicate the type of operation being traced.
  /// Used for proper visualization and understanding of distributed traces.
  /// </summary>
  TSpanKind = (
    skClient,    // Span represents a request to a remote service
    skServer,    // Span represents a server handling a request
    skConsumer,  // Span represents a consumer receiving a message
    skProducer,  // Span represents a producer sending a message
    skInternal   // Span represents an internal operation within an application
  );
  
  /// <summary>
  /// Outcome of an operation indicating success, failure, or unknown status.
  /// Used to categorize the result of spans and transactions for monitoring.
  /// </summary>
  TOutcome = (
    Success,  // Operation completed successfully
    Failure,  // Operation failed or encountered an error
    Unknown   // Outcome is not known or not applicable
  );

  // Forward declarations
  IObservabilitySpan = interface;
  IObservabilityTracer = interface;
  IObservabilityLogger = interface;
  IObservabilityMetrics = interface;
  IObservabilityProvider = interface;
  IObservabilityConfig = interface;

  // Contexto compartilhado
  /// <summary>
  /// Interface that represents the observability context shared across all operations.
  /// Context contains trace correlation information, service metadata, and user details.
  /// It's used to maintain relationships between spans and provide consistent metadata
  /// across all observability operations (tracing, logging, metrics).
  /// </summary>
  IObservabilityContext = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-1234567890AB}']
    function GetTraceId: string;
    function GetSpanId: string;
    function GetParentSpanId: string;
    function GetServiceName: string;
    function GetServiceVersion: string;
    function GetEnvironment: string;
    function GetUserId: string;
    function GetUserName: string;
    function GetUserEmail: string;
    function GetTags: TDictionary<string, string>;
    function GetAttributes: TDictionary<string, string>;
    
    procedure SetTraceId(const Value: string);
    procedure SetSpanId(const Value: string);
    procedure SetParentSpanId(const Value: string);
    procedure SetServiceName(const Value: string);
    procedure SetServiceVersion(const Value: string);
    procedure SetEnvironment(const Value: string);
    procedure SetUserId(const Value: string);
    procedure SetUserName(const Value: string);
    procedure SetUserEmail(const Value: string);
    procedure AddTag(const Key, Value: string);
    procedure AddAttribute(const Key, Value: string);
    
    function Clone: IObservabilityContext;
    
    property TraceId: string read GetTraceId write SetTraceId;
    property SpanId: string read GetSpanId write SetSpanId;
    property ParentSpanId: string read GetParentSpanId write SetParentSpanId;
    property ServiceName: string read GetServiceName write SetServiceName;
    property ServiceVersion: string read GetServiceVersion write SetServiceVersion;
    property Environment: string read GetEnvironment write SetEnvironment;
    property UserId: string read GetUserId write SetUserId;
    property UserName: string read GetUserName write SetUserName;
    property UserEmail: string read GetUserEmail write SetUserEmail;
    property Tags: TDictionary<string, string> read GetTags;
    property Attributes: TDictionary<string, string> read GetAttributes;
  end;

  // Interface para Span (Tracing)
  /// <summary>
  /// Interface that represents a span in distributed tracing.
  /// Spans represent individual operations within a trace and contain timing information,
  /// attributes, events, and outcome data. They form a tree structure through parent-child
  /// relationships to represent the complete flow of a distributed operation.
  /// </summary>
  IObservabilitySpan = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-234567890ABC}']
    function GetName: string;
    function GetSpanId: string;
    function GetTraceId: string;
    function GetParentSpanId: string;
    function GetKind: TSpanKind;
    function GetStartTime: TDateTime;
    function GetEndTime: TDateTime;
    function GetOutcome: TOutcome;
    function GetAttributes: TDictionary<string, string>;
    function GetContext: IObservabilityContext;
    function GetChildSpanCount: Integer;
    function GetDuration: Double; // Duration in milliseconds
    
    procedure SetName(const Value: string);
    procedure SetKind(const Value: TSpanKind);
    procedure SetOutcome(const Value: TOutcome);
    procedure IncrementChildSpanCount;
    procedure AddAttribute(const Key, Value: string); overload;
    procedure AddAttribute(const Key: string; const Value: Integer); overload;
    procedure AddAttribute(const Key: string; const Value: Double); overload;
    procedure AddAttribute(const Key: string; const Value: Boolean); overload;
    procedure AddEvent(const Name, Description: string);
    procedure RecordException(const Exception: Exception);
    procedure Finish; overload;
    procedure Finish(const Outcome: TOutcome); overload;
    
    property Name: string read GetName write SetName;
    property SpanId: string read GetSpanId;
    property TraceId: string read GetTraceId;
    property ParentSpanId: string read GetParentSpanId;
    property Kind: TSpanKind read GetKind write SetKind;
    property StartTime: TDateTime read GetStartTime;
    property EndTime: TDateTime read GetEndTime;
    property Outcome: TOutcome read GetOutcome write SetOutcome;
    property Attributes: TDictionary<string, string> read GetAttributes;
    property Context: IObservabilityContext read GetContext;
    property ChildSpanCount: Integer read GetChildSpanCount;
    property Duration: Double read GetDuration; // Duration in milliseconds
  end;

  // Interface para Tracer
  /// <summary>
  /// Interface for creating and managing spans in distributed tracing.
  /// Tracers are responsible for starting new spans, managing active span context,
  /// and handling trace propagation between services through header injection/extraction.
  /// Each provider implements this interface to provide tracing capabilities.
  /// </summary>
  IObservabilityTracer = interface
    ['{C3D4E5F6-A7B8-9012-CDEF-34567890ABCD}']
    function StartSpan(const Name: string): IObservabilitySpan; overload;
    function StartSpan(const Name: string; const Kind: TSpanKind): IObservabilitySpan; overload;
    function StartSpan(const Name: string; const Kind: TSpanKind; const Parent: IObservabilitySpan): IObservabilitySpan; overload;
    function StartSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan; overload;
    function GetActiveSpan: IObservabilitySpan;
    function GetContext: IObservabilityContext;
    procedure SetContext(const Context: IObservabilityContext);
    procedure InjectHeaders(const Headers: TStrings);
    function ExtractContext(const Headers: TStrings): IObservabilityContext;
  end;

  // Interface para Logger
  /// <summary>
  /// Interface for structured logging with multiple severity levels.
  /// Loggers provide methods for different log levels (trace, debug, info, warning, error, critical)
  /// and support structured logging with attributes and exception details.
  /// Logs are automatically correlated with active spans when available.
  /// </summary>
  IObservabilityLogger = interface
    ['{D4E5F6A7-B8C9-0123-DEF0-4567890ABCDE}']
    procedure Log(const Level: TLogLevel; const Message: string); overload;
    procedure Log(const Level: TLogLevel; const Message: string; const Args: array of const); overload;
    procedure Log(const Level: TLogLevel; const Message: string; const Exception: Exception); overload;
    procedure Log(const Level: TLogLevel; const Message: string; const Attributes: TDictionary<string, string>); overload;
    procedure Log(const Level: TLogLevel; const Message: string; const Attributes: TDictionary<string, string>; const Exception: Exception); overload;
    
    procedure Trace(const Message: string); overload;
    procedure Trace(const Message: string; const Args: array of const); overload;
    procedure Debug(const Message: string); overload;
    procedure Debug(const Message: string; const Args: array of const); overload;
    procedure Info(const Message: string); overload;
    procedure Info(const Message: string; const Args: array of const); overload;
    procedure Warning(const Message: string); overload;
    procedure Warning(const Message: string; const Args: array of const); overload;
    procedure Error(const Message: string); overload;
    procedure Error(const Message: string; const Exception: Exception); overload;
    procedure Error(const Message: string; const Args: array of const); overload;
    procedure Critical(const Message: string); overload;
    procedure Critical(const Message: string; const Exception: Exception); overload;
    procedure Critical(const Message: string; const Args: array of const); overload;
    
    procedure SetLevel(const Level: TLogLevel);
    function GetLevel: TLogLevel;
    procedure AddAttribute(const Key, Value: string);
    procedure SetContext(const Context: IObservabilityContext);
    function GetContext: IObservabilityContext;
  end;

  // Interface para Metrics
  /// <summary>
  /// Interface for collecting and reporting application metrics.
  /// Supports different metric types: counters (cumulative), gauges (point-in-time),
  /// histograms (distributions), and summaries (percentile calculations).
  /// Metrics can be tagged for additional dimensionality and filtering.
  /// </summary>
  IObservabilityMetrics = interface
    ['{E5F6A7B8-C9D0-1234-EFAB-567890ABCDEF}']
    procedure Counter(const Name: string; const Value: Double = 1.0); overload;
    procedure Counter(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); overload;
    procedure Gauge(const Name: string; const Value: Double); overload;
    procedure Gauge(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); overload;
    procedure Histogram(const Name: string; const Value: Double); overload;
    procedure Histogram(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); overload;
    procedure Summary(const Name: string; const Value: Double); overload;
    procedure Summary(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); overload;
    
    procedure SetContext(const Context: IObservabilityContext);
    function GetContext: IObservabilityContext;
    procedure AddGlobalTag(const Key, Value: string);
  end;

  // Interface para Provider específico
  /// <summary>
  /// Interface implemented by all observability providers (Elastic APM, Jaeger, Sentry, etc.).
  /// Providers encapsulate the specific implementation details for different observability backends
  /// and offer unified access to tracing, logging, and metrics capabilities.
  /// Each provider can support different combinations of observability types.
  /// </summary>
  IObservabilityProvider = interface
    ['{F6A7B8C9-D0E1-2345-FABC-67890ABCDEF0}']
    function GetProviderType: TObservabilityProvider;
    function GetSupportedTypes: TObservabilityTypeSet;
    function GetTracer: IObservabilityTracer;
    function GetLogger: IObservabilityLogger;
    function GetMetrics: IObservabilityMetrics;
    
    procedure Configure(const Config: IObservabilityConfig);
    procedure Initialize;
    procedure Shutdown;
    function IsInitialized: Boolean;
    
    property ProviderType: TObservabilityProvider read GetProviderType;
    property SupportedTypes: TObservabilityTypeSet read GetSupportedTypes;
    property Tracer: IObservabilityTracer read GetTracer;
    property Logger: IObservabilityLogger read GetLogger;
    property Metrics: IObservabilityMetrics read GetMetrics;
  end;

  // Interface para configuração
  /// <summary>
  /// Interface for provider configuration settings.
  /// Contains all necessary parameters to configure observability providers including
  /// service information, server endpoints, authentication, performance settings,
  /// and custom properties. Each provider type may use different subsets of these properties.
  /// </summary>
  IObservabilityConfig = interface
    ['{A7B8C9D0-E1F2-3456-ABCD-7890ABCDEF01}']
    function GetServiceName: string;
    function GetServiceVersion: string;
    function GetEnvironment: string;
    function GetServerUrl: string;
    function GetApiKey: string;
    function GetSampleRate: Double;
    function GetBatchSize: Integer;
    function GetFlushInterval: Integer;
    function GetEnabled: Boolean;
    function GetProviderType: TObservabilityProvider;
    function GetSupportedTypes: TObservabilityTypeSet;
    function GetCustomProperties: TDictionary<string, string>;
    
    procedure SetServiceName(const Value: string);
    procedure SetServiceVersion(const Value: string);
    procedure SetEnvironment(const Value: string);
    procedure SetServerUrl(const Value: string);
    procedure SetApiKey(const Value: string);
    procedure SetSampleRate(const Value: Double);
    procedure SetBatchSize(const Value: Integer);
    procedure SetFlushInterval(const Value: Integer);
    procedure SetEnabled(const Value: Boolean);
    procedure SetProviderType(const Value: TObservabilityProvider);
    procedure SetSupportedTypes(const Value: TObservabilityTypeSet);
    procedure AddCustomProperty(const Key, Value: string);
    
    property ServiceName: string read GetServiceName write SetServiceName;
    property ServiceVersion: string read GetServiceVersion write SetServiceVersion;
    property Environment: string read GetEnvironment write SetEnvironment;
    property ServerUrl: string read GetServerUrl write SetServerUrl;
    property ApiKey: string read GetApiKey write SetApiKey;
    property SampleRate: Double read GetSampleRate write SetSampleRate;
    property BatchSize: Integer read GetBatchSize write SetBatchSize;
    property FlushInterval: Integer read GetFlushInterval write SetFlushInterval;
    property Enabled: Boolean read GetEnabled write SetEnabled;
    property ProviderType: TObservabilityProvider read GetProviderType write SetProviderType;
    property SupportedTypes: TObservabilityTypeSet read GetSupportedTypes write SetSupportedTypes;
    property CustomProperties: TDictionary<string, string> read GetCustomProperties;
  end;
 
  /// <summary>
  /// Main interface for the ObservabilitySDK that provides unified access to all observability operations.
  /// This interface defines the contract for the SDK singleton and manages multiple providers,
  /// global context, and lifecycle operations. It serves as the foundation for the TObservability
  /// static helper class and provides thread-safe access to all observability capabilities.
  /// </summary>
  IObservabilitySDK = interface
    ['{A8B9C0D1-E2F3-4567-ABCD-890ABCDEF012}']
    procedure RegisterProvider(const Provider: IObservabilityProvider);
    procedure SetActiveProvider(const ProviderType: TObservabilityProvider);
    function GetActiveProvider: IObservabilityProvider;
    function GetProvider(const ProviderType: TObservabilityProvider): IObservabilityProvider;
    
    function GetTracer: IObservabilityTracer; overload;
    function GetTracer(const ProviderType: TObservabilityProvider): IObservabilityTracer; overload;
    function GetLogger: IObservabilityLogger; overload;
    function GetLogger(const ProviderType: TObservabilityProvider): IObservabilityLogger; overload;
    function GetMetrics: IObservabilityMetrics; overload;
    function GetMetrics(const ProviderType: TObservabilityProvider): IObservabilityMetrics; overload;
    
    procedure SetGlobalContext(const Context: IObservabilityContext);
    function GetGlobalContext: IObservabilityContext;
    
    procedure Initialize;
    procedure Shutdown;
    function IsInitialized: Boolean;
    
    property ActiveProvider: IObservabilityProvider read GetActiveProvider;
    property GlobalContext: IObservabilityContext read GetGlobalContext write SetGlobalContext;
  end;

  // Exceções customizadas
  /// <summary>
  /// Base exception class for all observability-related errors.
  /// Serves as the parent class for specific observability exceptions.
  /// </summary>
  EObservabilityException = class(Exception);
  
  /// <summary>
  /// Exception raised when attempting to access a provider that hasn't been registered.
  /// This typically occurs when trying to set an active provider or get a specific provider
  /// that was never registered with the SDK.
  /// </summary>
  EProviderNotFound = class(EObservabilityException);
  EProviderNotInitialized = class(EObservabilityException);
  EConfigurationError = class(EObservabilityException);

implementation

end.