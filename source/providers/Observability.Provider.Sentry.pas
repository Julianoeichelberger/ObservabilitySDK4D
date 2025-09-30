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
unit Observability.Provider.Sentry;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.JSON, System.Net.HttpClient, System.Net.URLClient,
  System.DateUtils, System.Hash, System.SyncObjs, System.TimeZone,
  Observability.Interfaces, Observability.Provider.Base, Observability.Context;

type
  ESentryError = class(Exception);

  TSentryProvider = class(TBaseObservabilityProvider)
  private
    FDsn: string;
    FProjectId: string;
    FPublicKey: string;
    FSecretKey: string;
    FHost: string;
    FHttpClient: THttpClient;
    FRelease: string;
    FEnvironment: string;    
    procedure ParseDSN(const DSN: string);
    function BuildSentryUrl: string;
    function CreateSentryHeaders: TNetHeaders;
    function GenerateEventId: string;
    procedure SendToSentry(const JsonData: TJSONObject);    
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
    
    property DSN: string read FDsn write FDsn;
    property Release: string read FRelease write FRelease;
    property Environment: string read FEnvironment write FEnvironment;
    
    // Public access to create logger for examples
    function CreateLoggerPublic: IObservabilityLogger;
  end;

  TSentrySpan = class(TBaseObservabilitySpan)
  private
    FSentryProvider: TSentryProvider;    
  protected
    procedure DoFinish; override;
    procedure DoRecordException(const Exception: Exception); override;
    procedure DoAddEvent(const Name, Description: string); override;    
  public
    constructor Create(const Name: string; const Context: IObservabilityContext; 
      Provider: TSentryProvider); reintroduce;
  end;

  TSentryTracer = class(TBaseObservabilityTracer)
  private
    FSentryProvider: TSentryProvider;    
  protected
    function DoCreateSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan; override;    
  public
    constructor Create(const Context: IObservabilityContext; Provider: TSentryProvider); reintroduce;
  end;

  TSentryLogger = class(TBaseObservabilityLogger)
  private
    FSentryProvider: TSentryProvider;
    FBreadcrumbs: TList<TJSONObject>;
    FMaxBreadcrumbs: Integer;
    
    function LogLevelToSentryLevel(Level: TLogLevel): string;
    function CreateBreadcrumb(const Level: TLogLevel; const Message: string; const Category: string = 'default'): TJSONObject;
    function CreateUserContext: TJSONObject;
    function CreateServerContext: TJSONObject;
    function CreateRuntimeContext: TJSONObject;
    procedure AddBreadcrumb(const Breadcrumb: TJSONObject);
    function GetBreadcrumbsArray: TJSONArray;    
  protected
    procedure DoLog(const Level: TLogLevel; const Message: string; 
      const Attributes: TDictionary<string, string>; const Exception: Exception); override;      
  public
    constructor Create(const Context: IObservabilityContext; Provider: TSentryProvider); reintroduce;
    destructor Destroy; override;
    
    // Additional logging methods for better Sentry integration
    procedure LogWithCategory(const Level: TLogLevel; const Message: string; const Category: string);
    procedure LogWithFingerprint(const Level: TLogLevel; const Message: string; const Fingerprint: array of string);
    procedure LogStructured(const Level: TLogLevel; const Message: string; const StructuredData: TJSONObject);
  end;

  TSentryMetrics = class(TBaseObservabilityMetrics)
  private
    FSentryProvider: TSentryProvider;    
  protected
    procedure DoCounter(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
    procedure DoGauge(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
    procedure DoHistogram(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
    procedure DoSummary(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;    
  public
    constructor Create(const Context: IObservabilityContext; Provider: TSentryProvider); reintroduce;
  end;

implementation

uses
  System.StrUtils, System.NetEncoding;

{ TSentryProvider }

constructor TSentryProvider.Create;
begin
  inherited Create;
  FHttpClient := THttpClient.Create;
  FHttpClient.UserAgent := 'ObservabilitySDK4D-Sentry/1.0.0';
end;

destructor TSentryProvider.Destroy;
begin
  FHttpClient.Free;
  inherited Destroy;
end;

function TSentryProvider.GetProviderType: TObservabilityProvider;
begin
  Result := opSentry;
end;

function TSentryProvider.GetSupportedTypes: TObservabilityTypeSet;
begin
  Result := [otTracing, otLogging]; // Sentry foca em tracing e logging
end;

procedure TSentryProvider.ValidateConfiguration;
begin
  inherited ValidateConfiguration;
  
  if FConfig.ServerUrl.IsEmpty then
    raise ESentryError.Create('Sentry DSN is required');
    
  try
    ParseDSN(FConfig.ServerUrl);
  except
    on E: Exception do
      raise ESentryError.CreateFmt('Invalid Sentry DSN format: %s', [E.Message]);
  end;
end;

procedure TSentryProvider.ParseDSN(const DSN: string);
var
  Parts: TArray<string>;
  UrlParts: TArray<string>;
  HostAndPath: string;
begin
  // DSN Format: https://public:secret@host/project_id
  // Example: https://abc123@o123456.ingest.sentry.io/123456
  
  if not DSN.StartsWith('https://') then
    raise ESentryError.Create('DSN must start with https://');
    
  FDsn := DSN;
  
  // Remove https://
  HostAndPath := DSN.Substring(8);
  
  // Split by @
  Parts := HostAndPath.Split(['@']);
  if Length(Parts) <> 2 then
    raise ESentryError.Create('Invalid DSN format: missing @ separator');
    
  // Extract keys (public:secret or just public)
  if Parts[0].Contains(':') then
  begin
    var KeyParts := Parts[0].Split([':']);
    FPublicKey := KeyParts[0];
    if Length(KeyParts) > 1 then
      FSecretKey := KeyParts[1];
  end
  else
    FPublicKey := Parts[0];
    
  // Extract host and project ID
  UrlParts := Parts[1].Split(['/']);
  if Length(UrlParts) < 2 then
    raise ESentryError.Create('Invalid DSN format: missing project ID');
    
  FHost := UrlParts[0];
  FProjectId := UrlParts[1];
end;

function TSentryProvider.BuildSentryUrl: string;
begin
  Result := Format('https://%s/api/%s/store/', [FHost, FProjectId]);
end;

function TSentryProvider.CreateSentryHeaders: TNetHeaders;
var
  AuthHeader: string;
  Timestamp: string;
begin
  Timestamp := IntToStr(DateTimeToUnix(Now));
  
  AuthHeader := Format('Sentry sentry_version=7, sentry_client=ObservabilitySDK4D/1.0.0, ' +
    'sentry_timestamp=%s, sentry_key=%s', [Timestamp, FPublicKey]);
    
  if not FSecretKey.IsEmpty then
    AuthHeader := AuthHeader + ', sentry_secret=' + FSecretKey;
    
  SetLength(Result, 2);
  Result[0] := TNetHeader.Create('X-Sentry-Auth', AuthHeader);
  Result[1] := TNetHeader.Create('Content-Type', 'application/json');
end;

function TSentryProvider.GenerateEventId: string;
var
  Guid: TGUID;
begin
  CreateGUID(Guid);
  Result := GUIDToString(Guid);
  Result := Result.Replace('{', '').Replace('}', '').Replace('-', '').ToLower;
end;

procedure TSentryProvider.SendToSentry(const JsonData: TJSONObject);
var
  Response: IHTTPResponse;
  JsonString: string;
  Stream: TStringStream;
begin
  if not Assigned(JsonData) then
    Exit;
    
  JsonString := JsonData.ToJSON;
  Stream := TStringStream.Create(JsonString, TEncoding.UTF8);
  try
    Response := FHttpClient.Post(BuildSentryUrl, Stream, nil, CreateSentryHeaders);
    
    if (Response.StatusCode < 200) or (Response.StatusCode >= 300) then
    begin
      // Log error but don't throw exception to avoid breaking application
      if True then // Debug mode - could be made configurable
        WriteLn(Format('Sentry error: HTTP %d - %s', [Response.StatusCode, Response.StatusText]));
    end;
    
  except
    on E: Exception do
    begin
      if True then // Debug mode - could be made configurable
        WriteLn(Format('Failed to send to Sentry: %s', [E.Message]));
    end;
  end;
  
  Stream.Free;
end;

procedure TSentryProvider.DoInitialize;
begin
  FDsn := FConfig.ServerUrl;
  FRelease := FConfig.ServiceVersion;
  FEnvironment := FConfig.Environment;
  
  if FEnvironment.IsEmpty then
    FEnvironment := 'production';
    
  ParseDSN(FDsn);
end;

procedure TSentryProvider.DoShutdown;
begin
  // Sentry provider doesn't need special shutdown
end;

function TSentryProvider.CreateTracer: IObservabilityTracer;
var
  Context: IObservabilityContext;
begin
  Context := TObservabilityContext.CreateNew;
  Context.ServiceName := FConfig.ServiceName;
  Context.ServiceVersion := FConfig.ServiceVersion;
  Context.Environment := FConfig.Environment;
  
  Result := TSentryTracer.Create(Context, Self);
end;

function TSentryProvider.CreateLogger: IObservabilityLogger;
var
  Context: IObservabilityContext;
begin
  Context := TObservabilityContext.CreateNew;
  Context.ServiceName := FConfig.ServiceName;
  Context.ServiceVersion := FConfig.ServiceVersion;
  Context.Environment := FConfig.Environment;
  
  Result := TSentryLogger.Create(Context, Self);
end;

function TSentryProvider.CreateLoggerPublic: IObservabilityLogger;
begin
  Result := CreateLogger;
end;

function TSentryProvider.CreateMetrics: IObservabilityMetrics;
var
  Context: IObservabilityContext;
begin
  Context := TObservabilityContext.CreateNew;
  Context.ServiceName := FConfig.ServiceName;
  Context.ServiceVersion := FConfig.ServiceVersion;
  Context.Environment := FConfig.Environment;
  
  Result := TSentryMetrics.Create(Context, Self);
end;

{ TSentrySpan }

constructor TSentrySpan.Create(const Name: string; const Context: IObservabilityContext; 
  Provider: TSentryProvider);
begin
  inherited Create(Name, Context);
  FSentryProvider := Provider;
end;

procedure TSentrySpan.DoFinish;
var
  JsonData: TJSONObject;
  Transaction: TJSONObject;
  SpanData: TJSONObject;
  ContextData: TJSONObject;
  TraceData: TJSONObject;
  TagsData: TJSONObject;
  Attr: TPair<string, string>;
begin
  JsonData := TJSONObject.Create;
  try
    JsonData.AddPair('event_id', FSentryProvider.GenerateEventId);
    JsonData.AddPair('timestamp', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', TTimeZone.Local.ToUniversalTime(FStartTime)));
    JsonData.AddPair('platform', 'delphi');
    JsonData.AddPair('sdk', TJSONObject.Create
      .AddPair('name', 'observability-sdk-4d')
      .AddPair('version', '1.0.0'));
      
    // Release and environment
    if not FSentryProvider.Release.IsEmpty then
      JsonData.AddPair('release', FSentryProvider.Release);
      
    if not FSentryProvider.Environment.IsEmpty then
      JsonData.AddPair('environment', FSentryProvider.Environment);
    
    // Transaction data
    Transaction := TJSONObject.Create;
    Transaction.AddPair('transaction', FName);
    Transaction.AddPair('type', 'transaction');
    JsonData.AddPair('transaction', FName);
    JsonData.AddPair('type', 'transaction');
    
    // Span data
    SpanData := TJSONObject.Create;
    SpanData.AddPair('span_id', FContext.SpanId);
    SpanData.AddPair('trace_id', FContext.TraceId);
    if not FContext.ParentSpanId.IsEmpty then
      SpanData.AddPair('parent_span_id', FContext.ParentSpanId);
    SpanData.AddPair('op', 'custom');
    SpanData.AddPair('description', FName);
    SpanData.AddPair('start_timestamp', FloatToStr(DateTimeToUnix(FStartTime, False)));
    SpanData.AddPair('timestamp', FloatToStr(DateTimeToUnix(Now, False)));
    
    // Context data
    ContextData := TJSONObject.Create;
    
    // Trace context
    TraceData := TJSONObject.Create;
    TraceData.AddPair('trace_id', FContext.TraceId);
    TraceData.AddPair('span_id', FContext.SpanId);
    if not FContext.ParentSpanId.IsEmpty then
      TraceData.AddPair('parent_span_id', FContext.ParentSpanId);
    ContextData.AddPair('trace', TraceData);
    
    JsonData.AddPair('contexts', ContextData);
    
    // Tags/Attributes
    if FAttributes.Count > 0 then
    begin
      TagsData := TJSONObject.Create;
      for Attr in FAttributes do
        TagsData.AddPair(Attr.Key, Attr.Value);
      JsonData.AddPair('tags', TagsData);
    end;
    
    FSentryProvider.SendToSentry(JsonData);
    
  finally
    JsonData.Free;
  end;
end;

procedure TSentrySpan.DoRecordException(const Exception: Exception);
var
  JsonData: TJSONObject;
  ExceptionData: TJSONObject;
  ExceptionArray: TJSONArray;
  ContextData: TJSONObject;
  TraceData: TJSONObject;
begin
  JsonData := TJSONObject.Create;
  try
    JsonData.AddPair('event_id', FSentryProvider.GenerateEventId);
    JsonData.AddPair('timestamp', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', TTimeZone.Local.ToUniversalTime(Now)));
    JsonData.AddPair('platform', 'delphi');
    JsonData.AddPair('level', 'error');
    JsonData.AddPair('sdk', TJSONObject.Create
      .AddPair('name', 'observability-sdk-4d')
      .AddPair('version', '1.0.0'));
      
    // Release and environment
    if not FSentryProvider.Release.IsEmpty then
      JsonData.AddPair('release', FSentryProvider.Release);
      
    if not FSentryProvider.Environment.IsEmpty then
      JsonData.AddPair('environment', FSentryProvider.Environment);
    
    // Exception data
    ExceptionData := TJSONObject.Create;
    ExceptionData.AddPair('type', Exception.ClassName);
    ExceptionData.AddPair('value', Exception.Message);
    
    ExceptionArray := TJSONArray.Create;
    ExceptionArray.AddElement(ExceptionData);
    JsonData.AddPair('exception', TJSONObject.Create.AddPair('values', ExceptionArray));
    
    // Context with trace information
    ContextData := TJSONObject.Create;
    TraceData := TJSONObject.Create;
    TraceData.AddPair('trace_id', FContext.TraceId);
    TraceData.AddPair('span_id', FContext.SpanId);
    ContextData.AddPair('trace', TraceData);
    JsonData.AddPair('contexts', ContextData);
    
    FSentryProvider.SendToSentry(JsonData);
    
  finally
    JsonData.Free;
  end;
end;

procedure TSentrySpan.DoAddEvent(const Name, Description: string);
begin
  // Sentry doesn't have a direct event concept, so we add as breadcrumb
  AddAttribute('event.' + Name, Description);
end;

{ TSentryTracer }

constructor TSentryTracer.Create(const Context: IObservabilityContext; Provider: TSentryProvider);
begin
  inherited Create(Context);
  FSentryProvider := Provider;
end;

function TSentryTracer.DoCreateSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan;
begin
  Result := TSentrySpan.Create(Name, Context, FSentryProvider);
end;

{ TSentryLogger }

constructor TSentryLogger.Create(const Context: IObservabilityContext; Provider: TSentryProvider);
begin
  inherited Create(Context);
  FSentryProvider := Provider;
  FBreadcrumbs := TList<TJSONObject>.Create;
  FMaxBreadcrumbs := 100; // Sentry default
end;

destructor TSentryLogger.Destroy;
var
  Breadcrumb: TJSONObject;
begin
  // Clean up breadcrumbs
  for Breadcrumb in FBreadcrumbs do
    Breadcrumb.Free;
  FBreadcrumbs.Free;
  inherited Destroy;
end;

function TSentryLogger.CreateBreadcrumb(const Level: TLogLevel; const Message: string; const Category: string): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('timestamp', FloatToStr(DateTimeToUnix(Now, False)));
  Result.AddPair('message', Message);
  Result.AddPair('category', Category);
  Result.AddPair('level', LogLevelToSentryLevel(Level));
  Result.AddPair('type', 'default');
end;

function TSentryLogger.CreateUserContext: TJSONObject;
begin
  Result := TJSONObject.Create;
  if not FContext.UserId.IsEmpty then
    Result.AddPair('id', FContext.UserId);
  if not FContext.UserName.IsEmpty then
    Result.AddPair('username', FContext.UserName);
  if not FContext.UserEmail.IsEmpty then
    Result.AddPair('email', FContext.UserEmail);
end;

function TSentryLogger.CreateServerContext: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('name', FContext.ServiceName);
  Result.AddPair('version', FContext.ServiceVersion);
  Result.AddPair('build', FContext.ServiceVersion);
end;

function TSentryLogger.CreateRuntimeContext: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('name', 'Delphi');
  Result.AddPair('version', 'Delphi 12 Athens'); // Could be made dynamic
  Result.AddPair('build', 'ObservabilitySDK4D 1.0.0');
end;

procedure TSentryLogger.AddBreadcrumb(const Breadcrumb: TJSONObject);
begin
  FLock.Enter;
  try
    // Remove oldest breadcrumb if we hit the limit
    while FBreadcrumbs.Count >= FMaxBreadcrumbs do
    begin
      FBreadcrumbs[0].Free;
      FBreadcrumbs.Delete(0);
    end;
    
    FBreadcrumbs.Add(Breadcrumb);
  finally
    FLock.Leave;
  end;
end;

function TSentryLogger.GetBreadcrumbsArray: TJSONArray;
var
  Breadcrumb: TJSONObject;
begin
  Result := TJSONArray.Create;
  FLock.Enter;
  try
    for Breadcrumb in FBreadcrumbs do
      Result.AddElement(Breadcrumb.Clone as TJSONObject);
  finally
    FLock.Leave;
  end;
end;

procedure TSentryLogger.LogWithCategory(const Level: TLogLevel; const Message: string; const Category: string);
var
  Attributes: TDictionary<string, string>;
begin
  Attributes := TDictionary<string, string>.Create;
  try
    Attributes.Add('category', Category);
    DoLog(Level, Message, Attributes, nil);
  finally
    Attributes.Free;
  end;
end;

procedure TSentryLogger.LogWithFingerprint(const Level: TLogLevel; const Message: string; const Fingerprint: array of string);
var
  Attributes: TDictionary<string, string>;
  FingerprintStr: string;
  I: Integer;
begin
  Attributes := TDictionary<string, string>.Create;
  try
    FingerprintStr := '';
    for I := 0 to High(Fingerprint) do
    begin
      if I > 0 then
        FingerprintStr := FingerprintStr + ',';
      FingerprintStr := FingerprintStr + Fingerprint[I];
    end;
    Attributes.Add('fingerprint', FingerprintStr);
    DoLog(Level, Message, Attributes, nil);
  finally
    Attributes.Free;
  end;
end;

procedure TSentryLogger.LogStructured(const Level: TLogLevel; const Message: string; const StructuredData: TJSONObject);
var
  Attributes: TDictionary<string, string>;
begin
  Attributes := TDictionary<string, string>.Create;
  try
    if Assigned(StructuredData) then
      Attributes.Add('structured_data', StructuredData.ToJSON);
    DoLog(Level, Message, Attributes, nil);
  finally
    Attributes.Free;
  end;
end;

function TSentryLogger.LogLevelToSentryLevel(Level: TLogLevel): string;
begin
  case Level of
    llTrace: Result := 'debug';
    llDebug: Result := 'debug';
    llInfo: Result := 'info';
    llWarning: Result := 'warning';
    llError: Result := 'error';
    llCritical: Result := 'fatal';
  else
    Result := 'info';
  end;
end;

procedure TSentryLogger.DoLog(const Level: TLogLevel; const Message: string; 
  const Attributes: TDictionary<string, string>; const Exception: Exception);
var
  JsonData: TJSONObject;
  ExtraData: TJSONObject; 
  ContextData: TJSONObject;
  TraceData: TJSONObject;
  UserData: TJSONObject;
  ServerData: TJSONObject;
  RuntimeData: TJSONObject;
  ExceptionData: TJSONObject;
  ExceptionArray: TJSONArray;
  TagsData: TJSONObject;
  BreadcrumbsArray: TJSONArray;
  FingerprintArray: TJSONArray;
  Attr: TPair<string, string>;
  Category: string;
  FingerprintStr: string;
  FingerprintItems: TArray<string>;
  I: Integer;
begin
  // Add as breadcrumb for context (unless it's an error/critical - those are events)
  Category := 'log';
  if Assigned(Attributes) and Attributes.ContainsKey('category') then
    Category := Attributes['category'];
    
  if Level < llError then
  begin
    var Breadcrumb := CreateBreadcrumb(Level, Message, Category);
    AddBreadcrumb(Breadcrumb);
  end;

  JsonData := TJSONObject.Create;
  try
    JsonData.AddPair('event_id', FSentryProvider.GenerateEventId);
    JsonData.AddPair('timestamp', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', TTimeZone.Local.ToUniversalTime(Now)));
    JsonData.AddPair('platform', 'delphi');
    JsonData.AddPair('level', LogLevelToSentryLevel(Level));
    JsonData.AddPair('logger', 'ObservabilitySDK4D');
    
    // Message structure
    JsonData.AddPair('message', TJSONObject.Create
      .AddPair('formatted', Message)
      .AddPair('message', Message));
    
    // SDK Information
    JsonData.AddPair('sdk', TJSONObject.Create
      .AddPair('name', 'observability-sdk-4d')
      .AddPair('version', '1.0.0')
      .AddPair('packages', TJSONArray.Create(
        TJSONObject.Create
          .AddPair('name', 'delphi:observability-sdk')
          .AddPair('version', '1.0.0'))));
      
    // Release and environment
    if not FSentryProvider.Release.IsEmpty then
      JsonData.AddPair('release', FSentryProvider.Release);
      
    if not FSentryProvider.Environment.IsEmpty then
      JsonData.AddPair('environment', FSentryProvider.Environment);
    
    // Server name (service name)
    if not FContext.ServiceName.IsEmpty then
      JsonData.AddPair('server_name', FContext.ServiceName);
    
    // Contexts - Rich context information
    ContextData := TJSONObject.Create;
    
    // Trace context
    if not FContext.TraceId.IsEmpty then
    begin
      TraceData := TJSONObject.Create;
      TraceData.AddPair('trace_id', FContext.TraceId);
      TraceData.AddPair('span_id', FContext.SpanId);
      if not FContext.ParentSpanId.IsEmpty then
        TraceData.AddPair('parent_span_id', FContext.ParentSpanId);
      ContextData.AddPair('trace', TraceData);
    end;
    
    // User context
    UserData := CreateUserContext;
    if UserData.Count > 0 then
      ContextData.AddPair('user', UserData)
    else
      UserData.Free;
    
    // Server context
    ServerData := CreateServerContext;
    if ServerData.Count > 0 then
      ContextData.AddPair('server', ServerData)
    else
      ServerData.Free;
    
    // Runtime context
    RuntimeData := CreateRuntimeContext;
    ContextData.AddPair('runtime', RuntimeData);
    
    JsonData.AddPair('contexts', ContextData);
    
    // Tags - Convert attributes to tags and extra data
    TagsData := TJSONObject.Create;
    ExtraData := TJSONObject.Create;
    
    // Add service info as tags
    TagsData.AddPair('service.name', FContext.ServiceName);
    TagsData.AddPair('service.version', FContext.ServiceVersion);
    TagsData.AddPair('environment', FContext.Environment);
    
    // Process attributes
    if Assigned(Attributes) then
    begin
      for Attr in Attributes do
      begin
        if Attr.Key = 'category' then
          TagsData.AddPair('category', Attr.Value)
        else if Attr.Key = 'fingerprint' then
        begin
          // Handle fingerprint specially
          FingerprintStr := Attr.Value;
        end
        else if (Attr.Key.StartsWith('tag.')) then
          TagsData.AddPair(Attr.Key.Substring(4), Attr.Value)
        else
          ExtraData.AddPair(Attr.Key, Attr.Value);
      end;
    end;
    
    // Add tags if we have any
    if TagsData.Count > 0 then
      JsonData.AddPair('tags', TagsData)
    else
      TagsData.Free;
    
    // Add extra data if we have any
    if ExtraData.Count > 0 then
      JsonData.AddPair('extra', ExtraData)
    else
      ExtraData.Free;
    
    // Fingerprint for grouping
    if not FingerprintStr.IsEmpty then
    begin
      FingerprintItems := FingerprintStr.Split([',']);
      FingerprintArray := TJSONArray.Create;
      for I := 0 to High(FingerprintItems) do
        FingerprintArray.Add(FingerprintItems[I].Trim);
      JsonData.AddPair('fingerprint', FingerprintArray);
    end;
    
    // Breadcrumbs for context
    BreadcrumbsArray := GetBreadcrumbsArray;
    if BreadcrumbsArray.Count > 0 then
      JsonData.AddPair('breadcrumbs', TJSONObject.Create.AddPair('values', BreadcrumbsArray))
    else
      BreadcrumbsArray.Free;
    
    // Exception data if present
    if Assigned(Exception) then
    begin
      ExceptionData := TJSONObject.Create;
      ExceptionData.AddPair('type', Exception.ClassName);
      ExceptionData.AddPair('value', Exception.Message);
      
      // Add mechanism info
      ExceptionData.AddPair('mechanism', TJSONObject.Create
        .AddPair('type', 'generic')
        .AddPair('handled', TJSONBool.Create(True)));
      
      ExceptionArray := TJSONArray.Create;
      ExceptionArray.AddElement(ExceptionData);
      JsonData.AddPair('exception', TJSONObject.Create.AddPair('values', ExceptionArray));
    end;
    
    FSentryProvider.SendToSentry(JsonData);
    
  finally
    JsonData.Free;
  end;
end;

{ TSentryMetrics }

constructor TSentryMetrics.Create(const Context: IObservabilityContext; Provider: TSentryProvider);
begin
  inherited Create(Context);
  FSentryProvider := Provider;
end;

procedure TSentryMetrics.DoCounter(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  // Sentry doesn't have native metrics support, but we can send as custom events
  // For now, we'll just do nothing or log as debug info
  // In a full implementation, you could send to Sentry as custom events
end;

procedure TSentryMetrics.DoGauge(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  // Sentry doesn't have native metrics support
  // For now, we'll just do nothing
end;

procedure TSentryMetrics.DoHistogram(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  // Sentry doesn't have native metrics support
  // For now, we'll just do nothing
end;

procedure TSentryMetrics.DoSummary(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  // Sentry doesn't have native metrics support
  // For now, we'll just do nothing
end;

end.