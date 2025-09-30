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
  TBaseObservabilityProvider = class abstract(TInterfacedObject, IObservabilityProvider)
  protected
    FConfig: IObservabilityConfig;
    FTracer: IObservabilityTracer;
    FLogger: IObservabilityLogger;
    FMetrics: IObservabilityMetrics;
    FInitialized: Boolean;
    FLock: TCriticalSection;
    
    // Abstract methods that must be implemented by specific providers
    procedure DoInitialize; virtual; abstract;
    procedure DoShutdown; virtual; abstract;
    function CreateTracer: IObservabilityTracer; virtual; abstract;
    function CreateLogger: IObservabilityLogger; virtual; abstract;
    function CreateMetrics: IObservabilityMetrics; virtual; abstract;
    
    // Template methods that can be overridden
    procedure ValidateConfiguration; virtual;
    procedure SetupComponents; virtual;
  protected
    function GetProviderType: TObservabilityProvider; virtual; abstract;
    function GetSupportedTypes: TObservabilityTypeSet; virtual; abstract;
    function GetTracer: IObservabilityTracer; virtual;
    function GetLogger: IObservabilityLogger; virtual;
    function GetMetrics: IObservabilityMetrics; virtual;
    
    procedure Configure(const Config: IObservabilityConfig); virtual;
    procedure Initialize; virtual;
    procedure Shutdown; virtual;
    function IsInitialized: Boolean; virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
  end;

  // Base implementations for common functionality
  TBaseObservabilitySpan = class abstract(TInterfacedObject, IObservabilitySpan)
  protected
    FName: string;
    FSpanId: string;
    FTraceId: string;
    FParentSpanId: string;
    FKind: TSpanKind;
    FStartTime: TDateTime;
    FEndTime: TDateTime;
    FOutcome: TOutcome;
    FAttributes: TDictionary<string, string>;
    FContext: IObservabilityContext;
    FFinished: Boolean;
    FLock: TCriticalSection;
    
    function GenerateId: string;
    
    // Abstract methods
    procedure DoFinish; virtual; abstract;
    procedure DoRecordException(const Exception: Exception); virtual; abstract;
    procedure DoAddEvent(const Name, Description: string); virtual; abstract;
  protected
    function GetName: string; virtual;
    function GetSpanId: string; virtual;
    function GetTraceId: string; virtual;
    function GetParentSpanId: string; virtual;
    function GetKind: TSpanKind; virtual;
    function GetStartTime: TDateTime; virtual;
    function GetEndTime: TDateTime; virtual;
    function GetDuration: Double; virtual;
    function GetOutcome: TOutcome; virtual;
    function GetAttributes: TDictionary<string, string>; virtual;
    function GetContext: IObservabilityContext; virtual;
    
    procedure SetName(const Value: string); virtual;
    procedure SetKind(const Value: TSpanKind); virtual;
    procedure SetOutcome(const Value: TOutcome); virtual;
    procedure AddAttribute(const Key, Value: string); overload; virtual;
    procedure AddAttribute(const Key: string; const Value: Integer); overload; virtual;
    procedure AddAttribute(const Key: string; const Value: Double); overload; virtual;
    procedure AddAttribute(const Key: string; const Value: Boolean); overload; virtual;
    procedure AddEvent(const Name, Description: string); virtual;
    procedure RecordException(const Exception: Exception); virtual;
    procedure Finish; overload; virtual;
    procedure Finish(const Outcome: TOutcome); overload; virtual;
  public
    constructor Create(const Name: string; const Context: IObservabilityContext); virtual;
    destructor Destroy; override;
  end;

  TBaseObservabilityTracer = class abstract(TInterfacedObject, IObservabilityTracer)
  protected
    FContext: IObservabilityContext;
    FActiveSpan: IObservabilitySpan;
    FLock: TCriticalSection;
    
    // Abstract methods
    function DoCreateSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan; virtual; abstract;
  protected
    function StartSpan(const Name: string): IObservabilitySpan; overload; virtual;
    function StartSpan(const Name: string; const Kind: TSpanKind): IObservabilitySpan; overload; virtual;
    function StartSpan(const Name: string; const Kind: TSpanKind; const Parent: IObservabilitySpan): IObservabilitySpan; overload; virtual;
    function StartSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan; overload; virtual;
    function GetActiveSpan: IObservabilitySpan; virtual;
    function GetContext: IObservabilityContext; virtual;
    procedure SetContext(const Context: IObservabilityContext); virtual;
    procedure InjectHeaders(const Headers: TStrings); virtual;
    function ExtractContext(const Headers: TStrings): IObservabilityContext; virtual;
  public
    constructor Create(const Context: IObservabilityContext); virtual;
    destructor Destroy; override;
  end;

  TBaseObservabilityLogger = class abstract(TInterfacedObject, IObservabilityLogger)
  protected
    FLevel: TLogLevel;
    FContext: IObservabilityContext;
    FAttributes: TDictionary<string, string>;
    FLock: TCriticalSection;
    
    // Abstract methods
    procedure DoLog(const Level: TLogLevel; const Message: string; const Attributes: TDictionary<string, string>; const Exception: Exception); virtual; abstract;
  public
    procedure Log(const Level: TLogLevel; const Message: string); overload; virtual;
    procedure Log(const Level: TLogLevel; const Message: string; const Args: array of const); overload; virtual;
    procedure Log(const Level: TLogLevel; const Message: string; const Exception: Exception); overload; virtual;
    procedure Log(const Level: TLogLevel; const Message: string; const Attributes: TDictionary<string, string>); overload; virtual;
    procedure Log(const Level: TLogLevel; const Message: string; const Attributes: TDictionary<string, string>; const Exception: Exception); overload; virtual;
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

  TBaseObservabilityMetrics = class abstract(TInterfacedObject, IObservabilityMetrics)
  protected
    FContext: IObservabilityContext;
    FGlobalTags: TDictionary<string, string>;
    FLock: TCriticalSection;
    
    // Abstract methods
    procedure DoCounter(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); virtual; abstract;
    procedure DoGauge(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); virtual; abstract;
    procedure DoHistogram(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); virtual; abstract;
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
    constructor Create(const Context: IObservabilityContext); virtual;
    destructor Destroy; override;
  end;

implementation

uses
  System.DateUtils;

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
  FParentSpanId := Context.SpanId;
  FStartTime := Now;
  FKind := skInternal;
  FOutcome := Unknown;
  FAttributes := TDictionary<string, string>.Create;
  FFinished := False;
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

function TBaseObservabilitySpan.GetDuration: Double;
begin
  if FEndTime > 0 then
    Result := MilliSecondsBetween(FEndTime, FStartTime)
  else
    Result := MilliSecondsBetween(Now, FStartTime);
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
      
    FEndTime := Now;
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

function TBaseObservabilityTracer.StartSpan(const Name: string; const Kind: TSpanKind; const Parent: IObservabilitySpan): IObservabilitySpan;
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

procedure TBaseObservabilityLogger.Log(const Level: TLogLevel; const Message: string; const Attributes: TDictionary<string, string>);
begin
  Log(Level, Message, Attributes, nil);
end;

procedure TBaseObservabilityLogger.Log(const Level: TLogLevel; const Message: string; const Attributes: TDictionary<string, string>; const Exception: Exception);
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