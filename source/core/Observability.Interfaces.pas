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
  TObservabilityProvider = (opElastic, opJaeger, opSentry, opDatadog, opOpenTelemetry, opConsole, opCustom);
  TObservabilityType = (otTracing, otLogging, otMetrics, otAll);
  TObservabilityTypeSet = set of TObservabilityType;
  TLogLevel = (llTrace, llDebug, llInfo, llWarning, llError, llCritical);
  TMetricType = (mtCounter, mtGauge, mtHistogram, mtSummary);
  TSpanKind = (skClient, skServer, skConsumer, skProducer, skInternal);
  TOutcome = (Success, Failure, Unknown);

  // Forward declarations
  IObservabilitySpan = interface;
  IObservabilityTracer = interface;
  IObservabilityLogger = interface;
  IObservabilityMetrics = interface;
  IObservabilityProvider = interface;
  IObservabilityConfig = interface;

  // Contexto compartilhado
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
  IObservabilitySpan = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-234567890ABC}']
    function GetName: string;
    function GetSpanId: string;
    function GetTraceId: string;
    function GetParentSpanId: string;
    function GetKind: TSpanKind;
    function GetStartTime: TDateTime;
    function GetEndTime: TDateTime;
    function GetDuration: Double;
    function GetOutcome: TOutcome;
    function GetAttributes: TDictionary<string, string>;
    function GetContext: IObservabilityContext;
    
    procedure SetName(const Value: string);
    procedure SetKind(const Value: TSpanKind);
    procedure SetOutcome(const Value: TOutcome);
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
    property Duration: Double read GetDuration;
    property Outcome: TOutcome read GetOutcome write SetOutcome;
    property Attributes: TDictionary<string, string> read GetAttributes;
    property Context: IObservabilityContext read GetContext;
  end;

  // Interface para Tracer
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

  // Interface principal do SDK
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
  EObservabilityException = class(Exception);
  EProviderNotFound = class(EObservabilityException);
  EProviderNotInitialized = class(EObservabilityException);
  EConfigurationError = class(EObservabilityException);

implementation

end.