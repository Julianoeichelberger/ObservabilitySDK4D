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
  Observability.Interfaces, Observability.Context, Observability.Config;

type
  TObservabilitySDK = class(TInterfacedObject, IObservabilitySDK)
  private
    FProviders: TDictionary<TObservabilityProvider, IObservabilityProvider>;
    FActiveProvider: TObservabilityProvider;
    FGlobalContext: IObservabilityContext;
    FInitialized: Boolean;
    FLock: TCriticalSection;
    
    class var FInstance: IObservabilitySDK;
    class var FInstanceLock: TCriticalSection;
  protected
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
  public
    constructor Create;
    destructor Destroy; override;
    
    class function Instance: IObservabilitySDK; static;
    class procedure ReleaseInstance; static;
  end;

  // Helper class for easier access
  TObservability = class
  private
    class function GetSDK: IObservabilitySDK; static;
  public
    // Provider management
    class procedure RegisterProvider(const Provider: IObservabilityProvider); static;
    class procedure SetActiveProvider(const ProviderType: TObservabilityProvider); static;
    class function GetProvider(const ProviderType: TObservabilityProvider): IObservabilityProvider; static;
    
    // Quick access methods
    class function Tracer: IObservabilityTracer; overload; static;
    class function Tracer(const ProviderType: TObservabilityProvider): IObservabilityTracer; overload; static;
    class function Logger: IObservabilityLogger; overload; static;
    class function Logger(const ProviderType: TObservabilityProvider): IObservabilityLogger; overload; static;
    class function Metrics: IObservabilityMetrics; overload; static;
    class function Metrics(const ProviderType: TObservabilityProvider): IObservabilityMetrics; overload; static;
    
    // Context management
    class procedure SetGlobalContext(const Context: IObservabilityContext); static;
    class function GetGlobalContext: IObservabilityContext; static;
    class function CreateContext: IObservabilityContext; static;
    class function CreateContextWithTraceId(const TraceId: string): IObservabilityContext; static;
    class function CreateChildContext(const Parent: IObservabilityContext): IObservabilityContext; static;
    
    // Lifecycle
    class procedure Initialize; static;
    class procedure Shutdown; static;
    class function IsInitialized: Boolean; static;
    
    // Configuration helpers
    class function CreateElasticConfig: IObservabilityConfig; static;
    class function CreateJaegerConfig: IObservabilityConfig; static;
    class function CreateSentryConfig: IObservabilityConfig; static;
    class function CreateDatadogConfig: IObservabilityConfig; static;
    class function CreateConsoleConfig: IObservabilityConfig; static;
    class function CreateTextFileConfig: IObservabilityConfig; static;
    
    // Quick tracing helpers
    class function StartSpan(const Name: string): IObservabilitySpan; overload; static;
    class function StartSpan(const Name: string; const Kind: TSpanKind): IObservabilitySpan; overload; static;
    class function StartSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan; overload; static;
    
    // Quick logging helpers
    class procedure LogInfo(const Message: string); overload; static;
    class procedure LogInfo(const Message: string; const Args: array of const); overload; static;
    class procedure LogWarning(const Message: string); overload; static;
    class procedure LogWarning(const Message: string; const Args: array of const); overload; static;
    class procedure LogError(const Message: string); overload; static;
    class procedure LogError(const Message: string; const Exception: Exception); overload; static;
    class procedure LogError(const Message: string; const Args: array of const); overload; static;
    
    // Quick metrics helpers
    class procedure Counter(const Name: string; const Value: Double = 1.0); static;
    class procedure Gauge(const Name: string; const Value: Double); static;
    class procedure Histogram(const Name: string; const Value: Double); static;
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
begin
  Result := Tracer.StartSpan(Name);
end;

class function TObservability.StartSpan(const Name: string; const Kind: TSpanKind): IObservabilitySpan;
begin
  Result := Tracer.StartSpan(Name, Kind);
end;

class function TObservability.StartSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan;
begin
  Result := Tracer.StartSpan(Name, Context);
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

initialization
  TObservabilitySDK.FInstanceLock := TCriticalSection.Create;

finalization
  TObservabilitySDK.ReleaseInstance;
  TObservabilitySDK.FInstanceLock.Free;

end.