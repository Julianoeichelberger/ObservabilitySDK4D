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
    
    // System metrics support
    function GetSystemMetricsCollector: ISystemMetricsCollector;
    procedure EnableSystemMetrics(const Options: TSystemMetricsOptions; const Interval: TSystemMetricsCollectionInterval);
    procedure DisableSystemMetrics;
    function IsSystemMetricsEnabled: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    
    class function Instance: IObservabilitySDK; static;
    class procedure ReleaseInstance; static;
  end;

  // Helper class for easier access
  TObservability = class
  private
    class var FSpanStack: TList<IObservabilitySpan>;
    class var FSpanStackLock: TCriticalSection;
    
    class function GetSDK: IObservabilitySDK; static;
  public
    // Provider management
    class procedure RegisterProvider(const Provider: IObservabilityProvider); static;
    class procedure SetActiveProvider(const ProviderType: TObservabilityProvider); static;
    class function GetProvider(const ProviderType: TObservabilityProvider): IObservabilityProvider; static;
    
    // Span stack management
    class procedure SetCurrentSpan(const Span: IObservabilitySpan); static;
    
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
    
    // Transaction management helpers
    class function StartTransaction(const Name: string): IObservabilitySpan; overload; static;
    class function StartTransaction(const Name: string; const TransactionType: string): IObservabilitySpan; overload; static;
    class procedure FinishTransaction; static;
    class procedure FinishTransactionWithOutcome(const Outcome: TOutcome); static;
    
    // Span finalization helpers (automatic span management)
    class procedure FinishSpan; static;
    class procedure FinishSpanWithOutcome(const Outcome: TOutcome); static;
    class procedure FinishSpanWithError(const Exception: Exception); static;
    class function GetCurrentSpan: IObservabilitySpan; static;
    
    // Current span manipulation helpers
    class procedure AddSpanAttribute(const Key, Value: string); static;
    class procedure AddSpanEvent(const Name: string; const Description: string = ''); static;
    class procedure SetSpanOutcome(const Outcome: TOutcome); static;
    class procedure RecordSpanException(const Exception: Exception); static;
    
    // Span stack inspection helpers
    class function GetSpanStackDepth: Integer; static;
    class function HasActiveSpans: Boolean; static;
    class procedure ClearSpanStack; static;
    
    // Auto-finalizing span execution helpers
    class procedure ExecuteInSpan(const Name: string; const Proc: TProc); overload; static;
    class procedure ExecuteInSpan(const Name: string; const Kind: TSpanKind; const Proc: TProc); overload; static;
    class function ExecuteInSpan<T>(const Name: string; const Func: TFunc<T>): T; overload; static;
    class function ExecuteInSpan<T>(const Name: string; const Kind: TSpanKind; const Func: TFunc<T>): T; overload; static;
    
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
    
    // System metrics helpers
    class function CreateSystemMetricsCollector: ISystemMetricsCollector; static;
    class procedure EnableSystemMetrics; overload; static;
    class procedure EnableSystemMetrics(const Options: TSystemMetricsOptions); overload; static;
    class procedure EnableSystemMetrics(const Options: TSystemMetricsOptions; const Interval: TSystemMetricsCollectionInterval); overload; static;
    class procedure DisableSystemMetrics; static;
    class function IsSystemMetricsEnabled: Boolean; static;
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