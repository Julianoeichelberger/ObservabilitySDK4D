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
unit Observability.SDK;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs, System.TypInfo,
  Observability.Interfaces, Observability.Context, Observability.Config, Observability.SystemMetrics;

type
  /// <summary>
  /// Core SDK implementation that manages observability providers and coordinates tracing, logging, and metrics collection.
  /// This class implements the Singleton pattern and provides thread-safe access to all observability operations.
  /// It serves as the central coordinator for multiple observability providers (Elastic APM, Jaeger, Sentry, etc.)
  /// and maintains global context and system metrics collection capabilities.
  /// </summary>
  TObservabilitySDK = class(TInterfacedObject, IObservabilitySDK)
  private
    FProviders: TDictionary<TObservabilityProvider, IObservabilityProvider>;
    FActiveProvider: TObservabilityProvider;
    FGlobalContext: IObservabilityContext;
    FInitialized: Boolean;
    FLock: TCriticalSection;
    FSystemMetrics: ISystemMetricsCollector;
    
    class var FInstance: IObservabilitySDK;
    class var FInstanceLock: TCriticalSection;
  protected
    /// <summary>
    /// Registers a new observability provider with the SDK.
    /// Providers are identified by their type and can be retrieved later.
    /// Thread-safe operation that stores the provider in an internal dictionary.
    /// </summary>
    /// <param name="Provider">The provider instance to register</param>
    procedure RegisterProvider(const Provider: IObservabilityProvider);
    
    /// <summary>
    /// Sets the active provider for the SDK operations.
    /// All subsequent calls to GetTracer, GetLogger, GetMetrics will use this provider.
    /// Raises EProviderNotFound if the provider type is not registered.
    /// </summary>
    /// <param name="ProviderType">The type of provider to activate</param>
    procedure SetActiveProvider(const ProviderType: TObservabilityProvider);
    
    /// <summary>
    /// Retrieves the currently active observability provider.
    /// Thread-safe operation that returns the provider set by SetActiveProvider.
    /// Raises EProviderNotFound if no active provider is available.
    /// </summary>
    /// <returns>The active provider instance</returns>
    function GetActiveProvider: IObservabilityProvider;
    
    /// <summary>
    /// Retrieves a specific observability provider by type.
    /// Allows access to providers other than the currently active one.
    /// Raises EProviderNotFound if the provider type is not registered.
    /// </summary>
    /// <param name="ProviderType">The type of provider to retrieve</param>
    /// <returns>The requested provider instance</returns>
    function GetProvider(const ProviderType: TObservabilityProvider): IObservabilityProvider;
    
    /// <summary>
    /// Gets the tracer from the currently active provider.
    /// Tracers are used to create and manage spans for distributed tracing.
    /// </summary>
    /// <returns>The tracer interface from the active provider</returns>
    function GetTracer: IObservabilityTracer; overload;
    
    /// <summary>
    /// Gets the tracer from a specific provider type.
    /// Allows access to tracers from providers other than the active one.
    /// </summary>
    /// <param name="ProviderType">The provider type to get the tracer from</param>
    /// <returns>The tracer interface from the specified provider</returns>
    function GetTracer(const ProviderType: TObservabilityProvider): IObservabilityTracer; overload;
    
    /// <summary>
    /// Gets the logger from the currently active provider.
    /// Loggers are used for structured logging with different severity levels.
    /// </summary>
    /// <returns>The logger interface from the active provider</returns>
    function GetLogger: IObservabilityLogger; overload;
    
    /// <summary>
    /// Gets the logger from a specific provider type.
    /// Allows access to loggers from providers other than the active one.
    /// </summary>
    /// <param name="ProviderType">The provider type to get the logger from</param>
    /// <returns>The logger interface from the specified provider</returns>
    function GetLogger(const ProviderType: TObservabilityProvider): IObservabilityLogger; overload;
    
    /// <summary>
    /// Gets the metrics interface from the currently active provider.
    /// Metrics are used for collecting counters, gauges, histograms, and system metrics.
    /// </summary>
    /// <returns>The metrics interface from the active provider</returns>
    function GetMetrics: IObservabilityMetrics; overload;
    
    /// <summary>
    /// Gets the metrics interface from a specific provider type.
    /// Allows access to metrics from providers other than the active one.
    /// </summary>
    /// <param name="ProviderType">The provider type to get the metrics from</param>
    /// <returns>The metrics interface from the specified provider</returns>
    function GetMetrics(const ProviderType: TObservabilityProvider): IObservabilityMetrics; overload;
    
    /// <summary>
    /// Sets the global context that will be inherited by all new spans and operations.
    /// Global context typically contains service-level information like service name, version, environment.
    /// Thread-safe operation that affects all subsequent observability operations.
    /// </summary>
    /// <param name="Context">The context to set as global</param>
    procedure SetGlobalContext(const Context: IObservabilityContext);
    
    /// <summary>
    /// Gets the current global context.
    /// Returns the context set by SetGlobalContext or the default context created during initialization.
    /// Thread-safe operation that provides access to global service information.
    /// </summary>
    /// <returns>The current global context</returns>
    function GetGlobalContext: IObservabilityContext;
    
    /// <summary>
    /// Initializes all registered providers.
    /// Must be called before using any observability operations.
    /// Thread-safe operation that ensures all providers are ready for use.
    /// </summary>
    procedure Initialize;
    
    /// <summary>
    /// Shuts down all registered providers.
    /// Should be called during application cleanup to ensure proper resource disposal.
    /// Thread-safe operation that gracefully terminates all provider connections.
    /// </summary>
    procedure Shutdown;
    
    /// <summary>
    /// Checks if the SDK has been initialized.
    /// Returns true after Initialize has been called and before Shutdown.
    /// Thread-safe operation for checking SDK readiness.
    /// </summary>
    /// <returns>True if the SDK is initialized, false otherwise</returns>
    function IsInitialized: Boolean;
     
    /// <summary>
    /// Gets the system metrics collector instance.
    /// Creates a new collector if one doesn't exist.
    /// System metrics include memory, CPU, threads, and garbage collection information.
    /// </summary>
    /// <returns>The system metrics collector interface</returns>
    function GetSystemMetricsCollector: ISystemMetricsCollector;
    
    /// <summary>
    /// Enables automatic system metrics collection with specified options and interval.
    /// System metrics are collected periodically and sent to the active metrics provider.
    /// Requires the SDK to be initialized before enabling.
    /// </summary>
    /// <param name="Options">The types of system metrics to collect</param>
    /// <param name="Interval">The collection interval frequency</param>
    procedure EnableSystemMetrics(const Options: TSystemMetricsOptions; const Interval: TSystemMetricsCollectionInterval);
    
    /// <summary>
    /// Disables automatic system metrics collection.
    /// Stops the background collection timer and frees associated resources.
    /// Thread-safe operation that can be called at any time.
    /// </summary>
    procedure DisableSystemMetrics;
    
    /// <summary>
    /// Checks if system metrics collection is currently enabled and running.
    /// Returns true if metrics are being collected automatically in the background.
    /// </summary>
    /// <returns>True if system metrics collection is active, false otherwise</returns>
    function IsSystemMetricsEnabled: Boolean;
  public
    /// <summary>
    /// Creates a new instance of the ObservabilitySDK.
    /// Initializes internal data structures, creates the default global context,
    /// and sets up thread synchronization primitives.
    /// </summary>
    constructor Create;
    
    /// <summary>
    /// Destroys the ObservabilitySDK instance.
    /// Automatically calls Shutdown to ensure proper cleanup of all providers
    /// and releases all allocated resources including thread synchronization objects.
    /// </summary>
    destructor Destroy; override;
    
    /// <summary>
    /// Gets the singleton instance of the ObservabilitySDK.
    /// Thread-safe implementation using double-checked locking pattern.
    /// Creates a new instance if one doesn't exist.
    /// </summary>
    /// <returns>The singleton SDK instance</returns>
    class function Instance: IObservabilitySDK; static;
    
    /// <summary>
    /// Releases the singleton instance.
    /// Used for cleanup during application shutdown.
    /// Thread-safe operation that sets the instance to nil.
    /// </summary>
    class procedure ReleaseInstance; static;
  end;
 
  /// <summary>
  /// Static helper class that provides convenient access to all observability operations.
  /// This class serves as the main API facade for the ObservabilitySDK4D framework.
  /// It manages automatic span stack operations, provides quick access to tracers/loggers/metrics,
  /// and includes helper methods for common observability patterns like transactions and system metrics.
  /// All methods are thread-safe and work with the singleton SDK instance.
  /// </summary>
  TObservability = class
  private
    class var FSpanStack: TList<IObservabilitySpan>;
    class var FSpanStackLock: TCriticalSection;
    
    /// <summary>
    /// Gets the singleton SDK instance for internal operations.
    /// Private helper method used by all static methods.
    /// </summary>
    /// <returns>The SDK singleton instance</returns>
    class function GetSDK: IObservabilitySDK; static;
  public 
    /// <summary>
    /// Registers an observability provider with the SDK.
    /// Providers implement specific backends like Elastic APM, Jaeger, Sentry, etc.
    /// </summary>
    /// <param name="Provider">The provider instance to register</param>
    class procedure RegisterProvider(const Provider: IObservabilityProvider); static;
    
    /// <summary>
    /// Sets the active provider for all subsequent operations.
    /// The active provider is used by default for all tracer, logger, and metrics operations.
    /// </summary>
    /// <param name="ProviderType">The type of provider to activate</param>
    class procedure SetActiveProvider(const ProviderType: TObservabilityProvider); static;
    
    /// <summary>
    /// Gets a specific provider by type.
    /// Allows access to providers other than the currently active one.
    /// </summary>
    /// <param name="ProviderType">The type of provider to retrieve</param>
    /// <returns>The requested provider instance</returns>
    class function GetProvider(const ProviderType: TObservabilityProvider): IObservabilityProvider; static;
     
    /// <summary>
    /// Sets the current span in the automatic span stack.
    /// The span stack maintains parent-child relationships automatically using LIFO (Last In, First Out) ordering.
    /// When setting a current span, it automatically increments the parent span's child count if one exists.
    /// </summary>
    /// <param name="Span">The span to set as current</param>
    class procedure SetCurrentSpan(const Span: IObservabilitySpan); static;
     
    /// <summary>
    /// Gets the tracer from the currently active provider.
    /// Tracers are used to create and manage distributed tracing spans.
    /// </summary>
    /// <returns>The tracer interface from the active provider</returns>
    class function Tracer: IObservabilityTracer; overload; static;
    
    /// <summary>
    /// Gets the tracer from a specific provider type.
    /// Allows using tracers from multiple providers simultaneously.
    /// </summary>
    /// <param name="ProviderType">The provider type to get the tracer from</param>
    /// <returns>The tracer interface from the specified provider</returns>
    class function Tracer(const ProviderType: TObservabilityProvider): IObservabilityTracer; overload; static;
    
    /// <summary>
    /// Gets the logger from the currently active provider.
    /// Loggers provide structured logging with different severity levels and span correlation.
    /// </summary>
    /// <returns>The logger interface from the active provider</returns>
    class function Logger: IObservabilityLogger; overload; static;
    
    /// <summary>
    /// Gets the logger from a specific provider type.
    /// Allows using loggers from multiple providers simultaneously.
    /// </summary>
    /// <param name="ProviderType">The provider type to get the logger from</param>
    /// <returns>The logger interface from the specified provider</returns>
    class function Logger(const ProviderType: TObservabilityProvider): IObservabilityLogger; overload; static;
    
    /// <summary>
    /// Gets the metrics interface from the currently active provider.
    /// Metrics are used for collecting counters, gauges, histograms, and custom measurements.
    /// </summary>
    /// <returns>The metrics interface from the active provider</returns>
    class function Metrics: IObservabilityMetrics; overload; static;
    
    /// <summary>
    /// Gets the metrics interface from a specific provider type.
    /// Allows sending metrics to multiple providers simultaneously.
    /// </summary>
    /// <param name="ProviderType">The provider type to get the metrics from</param>
    /// <returns>The metrics interface from the specified provider</returns>
    class function Metrics(const ProviderType: TObservabilityProvider): IObservabilityMetrics; overload; static;
     
    /// <summary>
    /// Sets the global context that will be inherited by all new operations.
    /// Global context typically contains service-level information.
    /// </summary>
    /// <param name="Context">The context to set as global</param>
    class procedure SetGlobalContext(const Context: IObservabilityContext); static;
    
    /// <summary>
    /// Gets the current global context.
    /// </summary>
    /// <returns>The current global context</returns>
    class function GetGlobalContext: IObservabilityContext; static;
    
    /// <summary>
    /// Creates a new observability context with a new trace ID.
    /// Used for starting new trace chains or operations.
    /// </summary>
    /// <returns>A new context instance</returns>
    class function CreateContext: IObservabilityContext; static;
    
    /// <summary>
    /// Creates a new context with a specific trace ID.
    /// Useful for continuing existing traces or implementing custom correlation.
    /// </summary>
    /// <param name="TraceId">The trace ID to use for the new context</param>
    /// <returns>A new context with the specified trace ID</returns>
    class function CreateContextWithTraceId(const TraceId: string): IObservabilityContext; static;
    
    /// <summary>
    /// Creates a child context from a parent context.
    /// Child contexts inherit the trace ID and other properties from the parent.
    /// </summary>
    /// <param name="Parent">The parent context to create a child from</param>
    /// <returns>A new child context</returns>
    class function CreateChildContext(const Parent: IObservabilityContext): IObservabilityContext; static;
     
    /// <summary>
    /// Initializes the SDK and all registered providers.
    /// Must be called before using any observability operations.
    /// </summary>
    class procedure Initialize; static;
    
    /// <summary>
    /// Shuts down the SDK and all registered providers.
    /// Should be called during application cleanup.
    /// </summary>
    class procedure Shutdown; static;
    
    /// <summary>
    /// Checks if the SDK has been initialized.
    /// </summary>
    /// <returns>True if initialized, false otherwise</returns>
    class function IsInitialized: Boolean; static;
     
    /// <summary>
    /// Creates a configuration object for Elastic APM provider.
    /// Includes settings for APM server URL, authentication, service information, etc.
    /// </summary>
    /// <returns>Configuration object for Elastic APM</returns>
    class function CreateElasticConfig: IObservabilityConfig; static;
    
    /// <summary>
    /// Creates a configuration object for Jaeger provider.
    /// Includes settings for Jaeger agent/collector endpoints and sampling configuration.
    /// </summary>
    /// <returns>Configuration object for Jaeger</returns>
    class function CreateJaegerConfig: IObservabilityConfig; static;
    
    /// <summary>
    /// Creates a configuration object for Sentry provider.
    /// Includes settings for Sentry DSN and error tracking options.
    /// </summary>
    /// <returns>Configuration object for Sentry</returns>
    class function CreateSentryConfig: IObservabilityConfig; static;
    
    /// <summary>
    /// Creates a configuration object for Datadog provider.
    /// Includes settings for Datadog APM agent and service information.
    /// </summary>
    /// <returns>Configuration object for Datadog</returns>
    class function CreateDatadogConfig: IObservabilityConfig; static;
    
    /// <summary>
    /// Creates a configuration object for Console provider.
    /// Used for debugging and development, outputs to console/debug log.
    /// </summary>
    /// <returns>Configuration object for Console output</returns>
    class function CreateConsoleConfig: IObservabilityConfig; static;
    
    /// <summary>
    /// Creates a configuration object for Text File provider.
    /// Outputs observability data to text files for offline analysis.
    /// </summary>
    /// <returns>Configuration object for text file output</returns>
    class function CreateTextFileConfig: IObservabilityConfig; static;
     
    /// <summary>
    /// Starts a new span with the specified name.
    /// If there's a current span, creates a child span automatically.
    /// Uses automatic span stack management for parent-child relationships.
    /// </summary>
    /// <param name="Name">The name of the span (operation being traced)</param>
    /// <returns>The created span instance</returns>
    class function StartSpan(const Name: string): IObservabilitySpan; overload; static;
    
    /// <summary>
    /// Starts a new span with the specified name and kind.
    /// Span kind indicates the type of operation (server, client, internal, etc.).
    /// </summary>
    /// <param name="Name">The name of the span</param>
    /// <param name="Kind">The kind of span (server, client, internal, etc.)</param>
    /// <returns>The created span instance</returns>
    class function StartSpan(const Name: string; const Kind: TSpanKind): IObservabilitySpan; overload; static;
    
    /// <summary>
    /// Starts a new span with the specified name and context.
    /// Allows manual control over the span's context and parent relationships.
    /// </summary>
    /// <param name="Name">The name of the span</param>
    /// <param name="Context">The context to use for the span</param>
    /// <returns>The created span instance</returns>
    class function StartSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan; overload; static;
     
    /// <summary>
    /// Starts a new transaction (root-level operation) with the specified name.
    /// Transactions represent the highest level operations in your application (HTTP requests, background jobs, etc.).
    /// Creates a clean context and sets the span as the current span for child operations.
    /// </summary>
    /// <param name="Name">The name of the transaction</param>
    /// <returns>The transaction span instance</returns>
    class function StartTransaction(const Name: string): IObservabilitySpan; overload; static;
    
    /// <summary>
    /// Starts a new transaction with the specified name and type.
    /// Transaction type categorizes the operation (e.g., "request", "job", "task").
    /// </summary>
    /// <param name="Name">The name of the transaction</param>
    /// <param name="TransactionType">The type/category of the transaction</param>
    /// <returns>The transaction span instance</returns>
    class function StartTransaction(const Name: string; const TransactionType: string): IObservabilitySpan; overload; static;
    
    /// <summary>
    /// Finishes the current transaction with a success outcome.
    /// Automatically removes the transaction from the span stack.
    /// Should be called when the main operation completes successfully.
    /// </summary>
    class procedure FinishTransaction; static;
    
    /// <summary>
    /// Finishes the current transaction with a specific outcome.
    /// Allows specifying success, failure, or unknown outcome for the transaction.
    /// </summary>
    /// <param name="Outcome">The outcome of the transaction (Success, Failure, Unknown)</param>
    class procedure FinishTransactionWithOutcome(const Outcome: TOutcome); static;
     
    /// <summary>
    /// Finishes the current span from the automatic span stack.
    /// Uses LIFO (Last In, First Out) ordering to automatically finish the most recent span.
    /// This is the recommended way to finish spans when using automatic span management.
    /// </summary>
    class procedure FinishSpan; static;
    
    /// <summary>
    /// Finishes the current span with a specific outcome.
    /// Automatically removes the span from the stack after setting the outcome.
    /// </summary>
    /// <param name="Outcome">The outcome of the span (Success, Failure, Unknown)</param>
    class procedure FinishSpanWithOutcome(const Outcome: TOutcome); static;
    
    /// <summary>
    /// Finishes the current span with an error outcome and records the exception.
    /// Automatically sets the outcome to Failure and captures exception details.
    /// </summary>
    /// <param name="Exception">The exception that caused the span to fail</param>
    class procedure FinishSpanWithError(const Exception: Exception); static;
    
    /// <summary>
    /// Gets the current span from the automatic span stack.
    /// Returns the most recently started span that hasn't been finished yet.
    /// </summary>
    /// <returns>The current span, or nil if no active spans</returns>
    class function GetCurrentSpan: IObservabilitySpan; static;
     
    /// <summary>
    /// Adds an attribute (key-value pair) to the current span.
    /// Attributes provide additional context about the operation being traced.
    /// If no current span exists, the operation is ignored.
    /// </summary>
    /// <param name="Key">The attribute key/name</param>
    /// <param name="Value">The attribute value</param>
    class procedure AddSpanAttribute(const Key, Value: string); static;
    
    /// <summary>
    /// Adds an event to the current span.
    /// Events represent significant moments during the span's execution.
    /// </summary>
    /// <param name="Name">The name of the event</param>
    /// <param name="Description">Optional description of the event</param>
    class procedure AddSpanEvent(const Name: string; const Description: string = ''); static;
    
    /// <summary>
    /// Sets the outcome of the current span.
    /// Outcome indicates whether the operation succeeded, failed, or is unknown.
    /// </summary>
    /// <param name="Outcome">The outcome to set (Success, Failure, Unknown)</param>
    class procedure SetSpanOutcome(const Outcome: TOutcome); static;
    
    /// <summary>
    /// Records an exception in the current span.
    /// Captures exception details and marks the span with error information.
    /// Does not automatically set the outcome - use SetSpanOutcome or FinishSpanWithError for that.
    /// </summary>
    /// <param name="Exception">The exception to record</param>
    class procedure RecordSpanException(const Exception: Exception); static;
    
    // Span stack inspection helpers
    /// <summary>
    /// Gets the current depth of the automatic span stack.
    /// Indicates how many nested spans are currently active.
    /// </summary>
    /// <returns>The number of active spans in the stack</returns>
    class function GetSpanStackDepth: Integer; static;
    
    /// <summary>
    /// Checks if there are any active spans in the stack.
    /// Convenient method to check if any tracing operations are in progress.
    /// </summary>
    /// <returns>True if there are active spans, false otherwise</returns>
    class function HasActiveSpans: Boolean; static;
    
    /// <summary>
    /// Clears all spans from the automatic span stack.
    /// WARNING: This does not finish the spans, it just removes them from the stack.
    /// Use only for cleanup in error scenarios or testing.
    /// </summary>
    class procedure ClearSpanStack; static;
     
    /// <summary>
    /// Executes a procedure within a span that is automatically managed.
    /// Creates a span, executes the procedure, and automatically finishes the span.
    /// Sets outcome to Success if no exception occurs, Failure if an exception is raised.
    /// </summary>
    /// <param name="Name">The name of the span</param>
    /// <param name="Proc">The procedure to execute within the span</param>
    class procedure ExecuteInSpan(const Name: string; const Proc: TProc); overload; static;
    
    /// <summary>
    /// Executes a procedure within a span of specific kind that is automatically managed.
    /// Creates a span with the specified kind, executes the procedure, and automatically finishes the span.
    /// </summary>
    /// <param name="Name">The name of the span</param>
    /// <param name="Kind">The kind of span to create</param>
    /// <param name="Proc">The procedure to execute within the span</param>
    class procedure ExecuteInSpan(const Name: string; const Kind: TSpanKind; const Proc: TProc); overload; static;
    
    /// <summary>
    /// Executes a function within a span that is automatically managed.
    /// Creates a span, executes the function, and automatically finishes the span.
    /// Returns the function's result and propagates any exceptions.
    /// </summary>
    /// <param name="Name">The name of the span</param>
    /// <param name="Func">The function to execute within the span</param>
    /// <returns>The result of the function execution</returns>
    class function ExecuteInSpan<T>(const Name: string; const Func: TFunc<T>): T; overload; static;
    
    /// <summary>
    /// Executes a function within a span of specific kind that is automatically managed.
    /// Creates a span with the specified kind, executes the function, and automatically finishes the span.
    /// </summary>
    /// <param name="Name">The name of the span</param>
    /// <param name="Kind">The kind of span to create</param>
    /// <param name="Func">The function to execute within the span</param>
    /// <returns>The result of the function execution</returns>
    class function ExecuteInSpan<T>(const Name: string; const Kind: TSpanKind; const Func: TFunc<T>): T; overload; static;
     
    /// <summary>
    /// Logs an informational message using the active provider's logger.
    /// Info level is used for general application flow information.
    /// </summary>
    /// <param name="Message">The message to log</param>
    class procedure LogInfo(const Message: string); overload; static;
    
    /// <summary>
    /// Logs an informational message with format arguments using the active provider's logger.
    /// Supports string formatting with Format() function syntax.
    /// </summary>
    /// <param name="Message">The message format string</param>
    /// <param name="Args">The format arguments</param>
    class procedure LogInfo(const Message: string; const Args: array of const); overload; static;
    
    /// <summary>
    /// Logs a warning message using the active provider's logger.
    /// Warning level is used for potentially harmful situations that don't stop execution.
    /// </summary>
    /// <param name="Message">The warning message to log</param>
    class procedure LogWarning(const Message: string); overload; static;
    
    /// <summary>
    /// Logs a warning message with format arguments using the active provider's logger.
    /// </summary>
    /// <param name="Message">The warning message format string</param>
    /// <param name="Args">The format arguments</param>
    class procedure LogWarning(const Message: string; const Args: array of const); overload; static;
    
    /// <summary>
    /// Logs an error message using the active provider's logger.
    /// Error level is used for error events that don't stop the application.
    /// </summary>
    /// <param name="Message">The error message to log</param>
    class procedure LogError(const Message: string); overload; static;
    
    /// <summary>
    /// Logs an error message with exception details using the active provider's logger.
    /// Captures exception information along with the custom message.
    /// </summary>
    /// <param name="Message">The error message to log</param>
    /// <param name="Exception">The exception to include in the log</param>
    class procedure LogError(const Message: string; const Exception: Exception); overload; static;
    
    /// <summary>
    /// Logs an error message with format arguments using the active provider's logger.
    /// </summary>
    /// <param name="Message">The error message format string</param>
    /// <param name="Args">The format arguments</param>
    class procedure LogError(const Message: string; const Args: array of const); overload; static;
     
    /// <summary>
    /// Records a counter metric with the specified name and value.
    /// Counters represent cumulative values that only increase (e.g., request count, error count).
    /// </summary>
    /// <param name="Name">The name of the counter metric</param>
    /// <param name="Value">The value to add to the counter (default: 1.0)</param>
    class procedure Counter(const Name: string; const Value: Double = 1.0); static;
    
    /// <summary>
    /// Records a gauge metric with the specified name and value.
    /// Gauges represent point-in-time values that can go up or down (e.g., memory usage, CPU usage).
    /// </summary>
    /// <param name="Name">The name of the gauge metric</param>
    /// <param name="Value">The current value of the gauge</param>
    class procedure Gauge(const Name: string; const Value: Double); static;
    
    /// <summary>
    /// Records a histogram metric with the specified name and value.
    /// Histograms track the distribution of values over time (e.g., response times, request sizes).
    /// </summary>
    /// <param name="Name">The name of the histogram metric</param>
    /// <param name="Value">The value to add to the histogram</param>
    class procedure Histogram(const Name: string; const Value: Double); static;
     
    /// <summary>
    /// Creates a new system metrics collector instance.
    /// System metrics collectors gather information about memory, CPU, threads, and garbage collection.
    /// </summary>
    /// <returns>A new system metrics collector instance</returns>
    class function CreateSystemMetricsCollector: ISystemMetricsCollector; static;
    
    /// <summary>
    /// Enables automatic system metrics collection with default options.
    /// Collects memory usage, CPU usage, thread count, and GC metrics every 30 seconds.
    /// </summary>
    class procedure EnableSystemMetrics; overload; static;
    
    /// <summary>
    /// Enables automatic system metrics collection with specific options.
    /// Uses default collection interval of 30 seconds.
    /// </summary>
    /// <param name="Options">The types of system metrics to collect</param>
    class procedure EnableSystemMetrics(const Options: TSystemMetricsOptions); overload; static;
    
    /// <summary>
    /// Enables automatic system metrics collection with specific options and interval.
    /// Allows full control over what metrics are collected and how frequently.
    /// </summary>
    /// <param name="Options">The types of system metrics to collect</param>
    /// <param name="Interval">The collection interval frequency</param>
    class procedure EnableSystemMetrics(const Options: TSystemMetricsOptions; const Interval: TSystemMetricsCollectionInterval); overload; static;
    
    /// <summary>
    /// Disables automatic system metrics collection.
    /// Stops the background collection timer and frees associated resources.
    /// </summary>
    class procedure DisableSystemMetrics; static;
    
    /// <summary>
    /// Checks if automatic system metrics collection is currently enabled.
    /// </summary>
    /// <returns>True if system metrics collection is active, false otherwise</returns>
    class function IsSystemMetricsEnabled: Boolean; static;
    
    /// <summary>
    /// Collects system metrics once immediately.
    /// Useful for manual collection or testing without enabling automatic collection.
    /// </summary>
    class procedure CollectSystemMetricsOnce; static;
  end;

implementation

{ TObservabilitySDK }

constructor TObservabilitySDK.Create;
begin
  inherited Create;
  FProviders := TDictionary<TObservabilityProvider, IObservabilityProvider>.Create;
  FLock := TCriticalSection.Create;
  FActiveProvider := opElastic; // Default
  FGlobalContext := TObservabilityContext.CreateNew;
  FInitialized := False;
  FSystemMetrics := nil; // Will be created when needed
end;

destructor TObservabilitySDK.Destroy;
begin
  Shutdown;
  FProviders.Free;
  FLock.Free;
  inherited Destroy;
end;

class function TObservabilitySDK.Instance: IObservabilitySDK;
begin
  if not Assigned(FInstance) then
  begin
    FInstanceLock.Enter;
    try
      if not Assigned(FInstance) then
        FInstance := TObservabilitySDK.Create;
    finally
      FInstanceLock.Leave;
    end;
  end;
  Result := FInstance;
end;

class procedure TObservabilitySDK.ReleaseInstance;
begin
  FInstanceLock.Enter;
  try
    FInstance := nil;
  finally
    FInstanceLock.Leave;
  end;
end;

procedure TObservabilitySDK.RegisterProvider(const Provider: IObservabilityProvider);
begin
  FLock.Enter;
  try
    FProviders.AddOrSetValue(Provider.ProviderType, Provider);
  finally
    FLock.Leave;
  end;
end;

procedure TObservabilitySDK.SetActiveProvider(const ProviderType: TObservabilityProvider);
begin
  FLock.Enter;
  try
    if FProviders.ContainsKey(ProviderType) then
      FActiveProvider := ProviderType
    else
      raise EProviderNotFound.CreateFmt('Provider %s not registered', [GetEnumName(TypeInfo(TObservabilityProvider), Ord(ProviderType))]);
  finally
    FLock.Leave;
  end;
end;

function TObservabilitySDK.GetActiveProvider: IObservabilityProvider;
begin
  FLock.Enter;
  try
    if FProviders.ContainsKey(FActiveProvider) then
      Result := FProviders[FActiveProvider]
    else
      raise EProviderNotFound.CreateFmt('Active provider %s not found', [GetEnumName(TypeInfo(TObservabilityProvider), Ord(FActiveProvider))]);
  finally
    FLock.Leave;
  end;
end;

function TObservabilitySDK.GetProvider(const ProviderType: TObservabilityProvider): IObservabilityProvider;
begin
  FLock.Enter;
  try
    if FProviders.ContainsKey(ProviderType) then
      Result := FProviders[ProviderType]
    else
      raise EProviderNotFound.CreateFmt('Provider %s not found', [GetEnumName(TypeInfo(TObservabilityProvider), Ord(ProviderType))]);
  finally
    FLock.Leave;
  end;
end;

function TObservabilitySDK.GetTracer: IObservabilityTracer;
begin
  Result := GetActiveProvider.Tracer;
end;

function TObservabilitySDK.GetTracer(const ProviderType: TObservabilityProvider): IObservabilityTracer;
begin
  Result := GetProvider(ProviderType).Tracer;
end;

function TObservabilitySDK.GetLogger: IObservabilityLogger;
begin
  Result := GetActiveProvider.Logger;
end;

function TObservabilitySDK.GetLogger(const ProviderType: TObservabilityProvider): IObservabilityLogger;
begin
  Result := GetProvider(ProviderType).Logger;
end;

function TObservabilitySDK.GetMetrics: IObservabilityMetrics;
begin
  Result := GetActiveProvider.Metrics;
end;

function TObservabilitySDK.GetMetrics(const ProviderType: TObservabilityProvider): IObservabilityMetrics;
begin
  Result := GetProvider(ProviderType).Metrics;
end;

procedure TObservabilitySDK.SetGlobalContext(const Context: IObservabilityContext);
begin
  FLock.Enter;
  try
    FGlobalContext := Context;
  finally
    FLock.Leave;
  end;
end;

function TObservabilitySDK.GetGlobalContext: IObservabilityContext;
begin
  FLock.Enter;
  try
    Result := FGlobalContext;
  finally
    FLock.Leave;
  end;
end;

procedure TObservabilitySDK.Initialize;
var
  Provider: IObservabilityProvider;
begin
  FLock.Enter;
  try
    if FInitialized then
      Exit;
      
    for Provider in FProviders.Values do
    begin
      if not Provider.IsInitialized then
        Provider.Initialize;
    end;
    
    FInitialized := True;
  finally
    FLock.Leave;
  end;
end;

procedure TObservabilitySDK.Shutdown;
var
  Provider: IObservabilityProvider;
begin
  FLock.Enter;
  try
    if not FInitialized then
      Exit;
      
    for Provider in FProviders.Values do
    begin
      if Provider.IsInitialized then
        Provider.Shutdown;
    end;
    
    FInitialized := False;
  finally
    FLock.Leave;
  end;
end;

function TObservabilitySDK.IsInitialized: Boolean;
begin
  FLock.Enter;
  try
    Result := FInitialized;
  finally
    FLock.Leave;
  end;
end;

function TObservabilitySDK.GetSystemMetricsCollector: ISystemMetricsCollector;
begin
  FLock.Enter;
  try
    if not Assigned(FSystemMetrics) then
    begin
      FSystemMetrics := TSystemMetricsCollector.CreateDefaultCollector;
      if FInitialized and FProviders.ContainsKey(FActiveProvider) then
        FSystemMetrics.SetMetricsProvider(FProviders[FActiveProvider].Metrics);
    end;
    Result := FSystemMetrics;
  finally
    FLock.Leave;
  end;
end;

procedure TObservabilitySDK.EnableSystemMetrics(const Options: TSystemMetricsOptions; const Interval: TSystemMetricsCollectionInterval);
var
  Collector: ISystemMetricsCollector;
begin
  Collector := GetSystemMetricsCollector;
  Collector.SetOptions(Options);
  Collector.SetInterval(Interval);
  if FInitialized and FProviders.ContainsKey(FActiveProvider) then
  begin
    Collector.SetMetricsProvider(FProviders[FActiveProvider].Metrics);
    Collector.Start;
  end;
end;

procedure TObservabilitySDK.DisableSystemMetrics;
begin
  FLock.Enter;
  try
    if Assigned(FSystemMetrics) then
      FSystemMetrics.Stop;
  finally
    FLock.Leave;
  end;
end;

function TObservabilitySDK.IsSystemMetricsEnabled: Boolean;
begin
  FLock.Enter;
  try
    Result := Assigned(FSystemMetrics) and FSystemMetrics.IsRunning;
  finally
    FLock.Leave;
  end;
end;

{ TObservability }

class function TObservability.GetSDK: IObservabilitySDK;
begin
  Result := TObservabilitySDK.Instance;
end;

class procedure TObservability.RegisterProvider(const Provider: IObservabilityProvider);
begin
  GetSDK.RegisterProvider(Provider);
end;

class procedure TObservability.SetActiveProvider(const ProviderType: TObservabilityProvider);
begin
  GetSDK.SetActiveProvider(ProviderType);
end;

class function TObservability.GetProvider(const ProviderType: TObservabilityProvider): IObservabilityProvider;
begin
  Result := GetSDK.GetProvider(ProviderType);
end;

class function TObservability.Tracer: IObservabilityTracer;
begin
  Result := GetSDK.GetTracer;
end;

class function TObservability.Tracer(const ProviderType: TObservabilityProvider): IObservabilityTracer;
begin
  Result := GetSDK.GetTracer(ProviderType);
end;

class function TObservability.Logger: IObservabilityLogger;
begin
  Result := GetSDK.GetLogger;
end;

class function TObservability.Logger(const ProviderType: TObservabilityProvider): IObservabilityLogger;
begin
  Result := GetSDK.GetLogger(ProviderType);
end;

class function TObservability.Metrics: IObservabilityMetrics;
begin
  Result := GetSDK.GetMetrics;
end;

class function TObservability.Metrics(const ProviderType: TObservabilityProvider): IObservabilityMetrics;
begin
  Result := GetSDK.GetMetrics(ProviderType);
end;

class procedure TObservability.SetGlobalContext(const Context: IObservabilityContext);
begin
  GetSDK.SetGlobalContext(Context);
end;

class function TObservability.GetGlobalContext: IObservabilityContext;
begin
  Result := GetSDK.GetGlobalContext;
end;

class function TObservability.CreateContext: IObservabilityContext;
begin
  Result := TObservabilityContext.CreateNew;
end;

class function TObservability.CreateContextWithTraceId(const TraceId: string): IObservabilityContext;
begin
  Result := TObservabilityContext.CreateWithTraceId(TraceId);
end;

class function TObservability.CreateChildContext(const Parent: IObservabilityContext): IObservabilityContext;
begin
  Result := TObservabilityContext.CreateChild(Parent);
end;

class procedure TObservability.Initialize;
begin
  GetSDK.Initialize;
end;

class procedure TObservability.Shutdown;
begin
  GetSDK.Shutdown;
end;

class function TObservability.IsInitialized: Boolean;
begin
  Result := GetSDK.IsInitialized;
end;

class function TObservability.CreateElasticConfig: IObservabilityConfig;
begin
  Result := TObservabilityConfig.CreateElasticConfig;
end;

class function TObservability.CreateJaegerConfig: IObservabilityConfig;
begin
  Result := TObservabilityConfig.CreateJaegerConfig;
end;

class function TObservability.CreateSentryConfig: IObservabilityConfig;
begin
  Result := TObservabilityConfig.CreateSentryConfig;
end;

class function TObservability.CreateDatadogConfig: IObservabilityConfig;
begin
  Result := TObservabilityConfig.CreateDatadogConfig;
end;

class function TObservability.CreateConsoleConfig: IObservabilityConfig;
begin
  Result := TObservabilityConfig.CreateConsoleConfig;
end;

class function TObservability.CreateTextFileConfig: IObservabilityConfig;
begin
  Result := TObservabilityConfig.CreateTextFileConfig;
end;

class function TObservability.StartSpan(const Name: string): IObservabilitySpan;
var
  CurrentSpan: IObservabilitySpan;
  ChildContext: IObservabilityContext;
begin
  // Check if there's a current span to create a child
  CurrentSpan := GetCurrentSpan;
  if Assigned(CurrentSpan) then
  begin
    // Create child context from current span
    ChildContext := CreateChildContext(CurrentSpan.Context);
    Result := Tracer.StartSpan(Name, ChildContext);
  end
  else
  begin
    // No current span, create a root span
    Result := Tracer.StartSpan(Name);
  end;
  
  SetCurrentSpan(Result);
end;

class function TObservability.StartSpan(const Name: string; const Kind: TSpanKind): IObservabilitySpan;
var
  CurrentSpan: IObservabilitySpan;
  ChildContext: IObservabilityContext;
begin
  // Check if there's a current span to create a child
  CurrentSpan := GetCurrentSpan;
  if Assigned(CurrentSpan) then
  begin
    // Create child context from current span
    ChildContext := CreateChildContext(CurrentSpan.Context);
    Result := Tracer.StartSpan(Name, Kind, nil);
    Result.Context.TraceId := ChildContext.TraceId;
    Result.Context.SpanId := ChildContext.SpanId;
  end
  else
  begin
    // No current span, create a root span
    Result := Tracer.StartSpan(Name, Kind);
  end;
  
  SetCurrentSpan(Result);
end;

class function TObservability.StartSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan;
var
  CurrentSpan: IObservabilitySpan;
  ChildContext: IObservabilityContext;
  IsRootSpan: Boolean;
begin
  // Check if there's a current span to create a child
  CurrentSpan := GetCurrentSpan;
  IsRootSpan := not Assigned(CurrentSpan);
  
  if IsRootSpan then
  begin
    // No current span - this is a root span, use provided context or create new
    if Assigned(Context) then
      Result := Tracer.StartSpan(Name, Context)
    else
      Result := Tracer.StartSpan(Name);
  end
  else
  begin
    // There's a current span - create child with proper context hierarchy
    if Assigned(Context) then
      Result := Tracer.StartSpan(Name, Context)
    else
    begin
      ChildContext := CreateChildContext(CurrentSpan.Context);
      Result := Tracer.StartSpan(Name, ChildContext);
    end;
  end;
  
  // Always add to stack (automatic management)
  SetCurrentSpan(Result);
end;

class function TObservability.StartTransaction(const Name: string): IObservabilitySpan;
var
  TransactionContext: IObservabilityContext;
  GlobalContext: IObservabilityContext;
begin
  // Create a clean context for the transaction
  TransactionContext := CreateContext;
  
  // Copy global context properties if available
  GlobalContext := GetGlobalContext;
  if Assigned(GlobalContext) then
  begin
    TransactionContext.ServiceName := GlobalContext.ServiceName;
    TransactionContext.ServiceVersion := GlobalContext.ServiceVersion;
    TransactionContext.Environment := GlobalContext.Environment;
    TransactionContext.UserName := GlobalContext.UserName;
    TransactionContext.UserId := GlobalContext.UserId;
    TransactionContext.UserEmail := GlobalContext.UserEmail;
  end;
  
  // Start transaction as root span with clean context
  Result := Tracer.StartSpan(Name, TransactionContext);
  Result.SetKind(skServer); // Transactions are typically server spans
  
  // Set as current span for child spans
  SetCurrentSpan(Result);
end;

class function TObservability.StartTransaction(const Name: string; const TransactionType: string): IObservabilitySpan;
begin
  Result := StartTransaction(Name);
  // Add transaction type as attribute
  Result.AddAttribute('transaction.type', TransactionType);
end;

class procedure TObservability.FinishTransaction;
var
  CurrentSpan: IObservabilitySpan;
begin
  CurrentSpan := GetCurrentSpan;
  if Assigned(CurrentSpan) then
  begin
    CurrentSpan.SetOutcome(Success);
    CurrentSpan.Finish;
    
    // Remove from stack
    FSpanStackLock.Enter;
    try
      if (FSpanStack.Count > 0) and (FSpanStack.Last = CurrentSpan) then
        FSpanStack.Delete(FSpanStack.Count - 1);
    finally
      FSpanStackLock.Leave;
    end;
  end;
end;

class procedure TObservability.FinishTransactionWithOutcome(const Outcome: TOutcome);
var
  CurrentSpan: IObservabilitySpan;
begin
  CurrentSpan := GetCurrentSpan;
  if Assigned(CurrentSpan) then
  begin
    CurrentSpan.SetOutcome(Outcome);
    CurrentSpan.Finish;
    
    // Remove from stack
    FSpanStackLock.Enter;
    try
      if (FSpanStack.Count > 0) and (FSpanStack.Last = CurrentSpan) then
        FSpanStack.Delete(FSpanStack.Count - 1);
    finally
      FSpanStackLock.Leave;
    end;
  end;
end;

class procedure TObservability.FinishSpan;
var
  CurrentSpan: IObservabilitySpan;
begin
  FSpanStackLock.Enter;
  try
    if (FSpanStack.Count > 0) then
    begin
      CurrentSpan := FSpanStack.Last;
      FSpanStack.Delete(FSpanStack.Count - 1); // Remove from stack
    end
    else
      CurrentSpan := nil;
  finally
    FSpanStackLock.Leave;
  end;
  
  if Assigned(CurrentSpan) then
    CurrentSpan.Finish;
end;

class procedure TObservability.FinishSpanWithOutcome(const Outcome: TOutcome);
var
  CurrentSpan: IObservabilitySpan;
begin
  FSpanStackLock.Enter;
  try
    if (FSpanStack.Count > 0) then
    begin
      CurrentSpan := FSpanStack.Last;
      FSpanStack.Delete(FSpanStack.Count - 1); // Remove from stack
    end
    else
      CurrentSpan := nil;
  finally
    FSpanStackLock.Leave;
  end;
  
  if Assigned(CurrentSpan) then
  begin
    CurrentSpan.SetOutcome(Outcome);
    CurrentSpan.Finish;
  end;
end;

class procedure TObservability.FinishSpanWithError(const Exception: Exception);
var
  CurrentSpan: IObservabilitySpan;
begin
  FSpanStackLock.Enter;
  try
    if (FSpanStack.Count > 0) then
    begin
      CurrentSpan := FSpanStack.Last;
      FSpanStack.Delete(FSpanStack.Count - 1); // Remove from stack
    end
    else
      CurrentSpan := nil;
  finally
    FSpanStackLock.Leave;
  end;
  
  if Assigned(CurrentSpan) then
  begin
    CurrentSpan.RecordException(Exception);
    CurrentSpan.SetOutcome(Failure);
    CurrentSpan.Finish;
  end;
end;

class function TObservability.GetCurrentSpan: IObservabilitySpan;
begin
  FSpanStackLock.Enter;
  try
    if (FSpanStack.Count > 0) then
      Result := FSpanStack.Last
    else
      Result := nil;
  finally
    FSpanStackLock.Leave;
  end;
end;

class procedure TObservability.SetCurrentSpan(const Span: IObservabilitySpan);
var
  ParentSpan: IObservabilitySpan;
begin
  FSpanStackLock.Enter;
  try
    if Assigned(Span) then
    begin
      // If there's a current span, increment its child counter
      if FSpanStack.Count > 0 then
      begin
        ParentSpan := FSpanStack.Last;
        if Assigned(ParentSpan) then
          ParentSpan.IncrementChildSpanCount;
      end;
      
      FSpanStack.Add(Span);
    end;
  finally
    FSpanStackLock.Leave;
  end;
end;

class procedure TObservability.AddSpanAttribute(const Key, Value: string);
var
  CurrentSpan: IObservabilitySpan;
begin
  CurrentSpan := GetCurrentSpan;
  if Assigned(CurrentSpan) then
    CurrentSpan.AddAttribute(Key, Value);
end;

class procedure TObservability.AddSpanEvent(const Name: string; const Description: string);
var
  CurrentSpan: IObservabilitySpan;
begin
  CurrentSpan := GetCurrentSpan;
  if Assigned(CurrentSpan) then
    CurrentSpan.AddEvent(Name, Description);
end;

class procedure TObservability.SetSpanOutcome(const Outcome: TOutcome);
var
  CurrentSpan: IObservabilitySpan;
begin
  CurrentSpan := GetCurrentSpan;
  if Assigned(CurrentSpan) then
    CurrentSpan.SetOutcome(Outcome);
end;

class procedure TObservability.RecordSpanException(const Exception: Exception);
var
  CurrentSpan: IObservabilitySpan;
begin
  CurrentSpan := GetCurrentSpan;
  if Assigned(CurrentSpan) then
    CurrentSpan.RecordException(Exception);
end;

class function TObservability.GetSpanStackDepth: Integer;
begin
  FSpanStackLock.Enter;
  try
    Result := FSpanStack.Count;
  finally
    FSpanStackLock.Leave;
  end;
end;

class function TObservability.HasActiveSpans: Boolean;
begin
  Result := GetSpanStackDepth > 0;
end;

class procedure TObservability.ClearSpanStack;
begin
  FSpanStackLock.Enter;
  try
    FSpanStack.Clear;
  finally
    FSpanStackLock.Leave;
  end;
end;

class procedure TObservability.ExecuteInSpan(const Name: string; const Proc: TProc);
begin
  ExecuteInSpan(Name, skInternal, Proc);
end;

class procedure TObservability.ExecuteInSpan(const Name: string; const Kind: TSpanKind; const Proc: TProc);
var
  Span: IObservabilitySpan;
begin
  Span := StartSpan(Name, Kind);
  try
    Proc();
    Span.SetOutcome(Success);
  except
    on E: Exception do
    begin
      Span.RecordException(E);
      Span.SetOutcome(Failure);
      raise;
    end;
  end;
  Span.Finish;
end;

class function TObservability.ExecuteInSpan<T>(const Name: string; const Func: TFunc<T>): T;
begin
  Result := ExecuteInSpan<T>(Name, skInternal, Func);
end;

class function TObservability.ExecuteInSpan<T>(const Name: string; const Kind: TSpanKind; const Func: TFunc<T>): T;
var
  Span: IObservabilitySpan;
begin
  Span := StartSpan(Name, Kind);
  try
    Result := Func();
    Span.SetOutcome(Success);
  except
    on E: Exception do
    begin
      Span.RecordException(E);
      Span.SetOutcome(Failure);
      raise;
    end;
  end;
  Span.Finish;
end;

class procedure TObservability.LogInfo(const Message: string);
begin
  Logger.Info(Message);
end;

class procedure TObservability.LogInfo(const Message: string; const Args: array of const);
begin
  Logger.Info(Message, Args);
end;

class procedure TObservability.LogWarning(const Message: string);
begin
  Logger.Warning(Message);
end;

class procedure TObservability.LogWarning(const Message: string; const Args: array of const);
begin
  Logger.Warning(Message, Args);
end;

class procedure TObservability.LogError(const Message: string);
begin
  Logger.Error(Message);
end;

class procedure TObservability.LogError(const Message: string; const Exception: Exception);
begin
  Logger.Error(Message, Exception);
end;

class procedure TObservability.LogError(const Message: string; const Args: array of const);
begin
  Logger.Error(Message, Args);
end;

class procedure TObservability.Counter(const Name: string; const Value: Double);
begin
  Metrics.Counter(Name, Value);
end;

class procedure TObservability.Gauge(const Name: string; const Value: Double);
begin
  Metrics.Gauge(Name, Value);
end;

class procedure TObservability.Histogram(const Name: string; const Value: Double);
begin
  Metrics.Histogram(Name, Value);
end;

class function TObservability.CreateSystemMetricsCollector: ISystemMetricsCollector;
begin
  Result := TSystemMetricsCollector.CreateDefaultCollector;
end;

class procedure TObservability.EnableSystemMetrics;
begin
  EnableSystemMetrics([smoMemoryUsage, smoCPUUsage, smoThreadCount, smoGCMetrics], si30Seconds);
end;

class procedure TObservability.EnableSystemMetrics(const Options: TSystemMetricsOptions);
begin
  EnableSystemMetrics(Options, si30Seconds);
end;

class procedure TObservability.EnableSystemMetrics(const Options: TSystemMetricsOptions; const Interval: TSystemMetricsCollectionInterval);
begin
  (GetSDK as TObservabilitySDK).EnableSystemMetrics(Options, Interval);
end;

class procedure TObservability.DisableSystemMetrics;
begin
  (GetSDK as TObservabilitySDK).DisableSystemMetrics;
end;

class function TObservability.IsSystemMetricsEnabled: Boolean;
begin
  Result := (GetSDK as TObservabilitySDK).IsSystemMetricsEnabled;
end;

class procedure TObservability.CollectSystemMetricsOnce;
var
  Collector: ISystemMetricsCollector;
begin
  Collector := (GetSDK as TObservabilitySDK).GetSystemMetricsCollector;
  if Assigned(Collector) then
    Collector.CollectOnce;
end;

initialization
  TObservabilitySDK.FInstanceLock := TCriticalSection.Create;
  TObservability.FSpanStackLock := TCriticalSection.Create;
  TObservability.FSpanStack := TList<IObservabilitySpan>.Create;

finalization
  TObservabilitySDK.ReleaseInstance;
  TObservabilitySDK.FInstanceLock.Free;
  TObservability.FSpanStack.Free;
  TObservability.FSpanStackLock.Free;

end.