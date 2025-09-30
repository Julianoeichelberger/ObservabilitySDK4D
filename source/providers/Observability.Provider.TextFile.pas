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
unit Observability.Provider.TextFile;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON,
  System.IOUtils, System.SyncObjs, System.DateUtils,
  Observability.Interfaces, Observability.Provider.Base, Observability.Context;

type
  TTextFileProvider = class(TBaseObservabilityProvider)
  private
    FBaseDirectory: string;
    FTraceFileName: string;
    FLogFileName: string;
    FMetricsFileName: string;
    FRotateDaily: Boolean;
    FMaxFileSizeMB: Integer;
    FUseJSON: Boolean;
    FIncludeTimestamp: Boolean;
    FLock: TCriticalSection;
    
    function GetCurrentFileName(const BaseFileName: string): string;
    function FormatTimestamp(const DateTime: TDateTime): string;
    procedure WriteToFile(const FileName, Content: string);
    procedure RotateFileIfNeeded(const FileName: string);
    function GetFileSize(const FileName: string): Int64;
    procedure EnsureDirectoryExists(const Directory: string);
    function GetDefaultLogDirectory: string;
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
    
    // Propriedades de configuração
    property BaseDirectory: string read FBaseDirectory write FBaseDirectory;
    property RotateDaily: Boolean read FRotateDaily write FRotateDaily;
    property MaxFileSizeMB: Integer read FMaxFileSizeMB write FMaxFileSizeMB;
    property UseJSON: Boolean read FUseJSON write FUseJSON;
    property IncludeTimestamp: Boolean read FIncludeTimestamp write FIncludeTimestamp;
  end;

  TTextFileSpan = class(TBaseObservabilitySpan)
  private
    FTextFileProvider: TTextFileProvider;
  protected
    procedure DoFinish; override;
    procedure DoRecordException(const Exception: Exception); override;
    procedure DoAddEvent(const Name, Description: string); override;
  public
    constructor Create(const Name: string; const Context: IObservabilityContext; 
      const TextFileProvider: TTextFileProvider); reintroduce;
    
    function ToTextFormat: string;
    function ToJSONFormat: TJSONObject;
  end;

  TTextFileTracer = class(TBaseObservabilityTracer)
  private
    FTextFileProvider: TTextFileProvider;
  protected
    function DoCreateSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan; override;
  public
    constructor Create(const Context: IObservabilityContext; const TextFileProvider: TTextFileProvider); reintroduce;
    
    procedure InjectHeaders(const Headers: TStrings); override;
    function ExtractContext(const Headers: TStrings): IObservabilityContext; override;
  end;

  TTextFileLogger = class(TBaseObservabilityLogger)
  private
    FTextFileProvider: TTextFileProvider;
    
    function LogLevelToString(const Level: TLogLevel): string;
    function FormatLogEntry(const Level: TLogLevel; const Message: string; 
      const Attributes: TDictionary<string, string>; const Exception: Exception): string;
    function FormatLogEntryJSON(const Level: TLogLevel; const Message: string; 
      const Attributes: TDictionary<string, string>; const Exception: Exception): TJSONObject;
  protected
    procedure DoLog(const Level: TLogLevel; const Message: string; 
      const Attributes: TDictionary<string, string>; const Exception: Exception); override;
  public
    constructor Create(const Context: IObservabilityContext; const TextFileProvider: TTextFileProvider); reintroduce;
  end;

  TTextFileMetrics = class(TBaseObservabilityMetrics)
  private
    FTextFileProvider: TTextFileProvider;
    
    procedure WriteMetric(const MetricType, Name: string; const Value: Double; 
      const Tags: TDictionary<string, string>; const Timestamp: TDateTime);
  protected
    procedure DoCounter(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
    procedure DoGauge(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
    procedure DoHistogram(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
    procedure DoSummary(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
  public
    constructor Create(const Context: IObservabilityContext; const TextFileProvider: TTextFileProvider); reintroduce;
  end;

implementation

{ TTextFileProvider }

constructor TTextFileProvider.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  
  // Valores padrão - será definido em ValidateConfiguration se não for especificado
  FBaseDirectory := ''; // Empty, will be set to default in ValidateConfiguration
  FTraceFileName := 'traces';
  FLogFileName := 'logs';
  FMetricsFileName := 'metrics';
  FRotateDaily := True;
  FMaxFileSizeMB := 100; // 100MB por arquivo
  FUseJSON := True;
  FIncludeTimestamp := True;
end;

destructor TTextFileProvider.Destroy;
begin
  FLock.Free;
  inherited Destroy;
end;

function TTextFileProvider.GetProviderType: TObservabilityProvider;
begin
  Result := opCustom; // Usaremos Custom já que não temos opTextFile definido
end;

function TTextFileProvider.GetSupportedTypes: TObservabilityTypeSet;
begin
  Result := [otTracing, otLogging, otMetrics];
end;

procedure TTextFileProvider.ValidateConfiguration;
begin
  inherited ValidateConfiguration;
  
  if FBaseDirectory.IsEmpty then
    FBaseDirectory := GetDefaultLogDirectory;
    
  EnsureDirectoryExists(FBaseDirectory);
end;

procedure TTextFileProvider.EnsureDirectoryExists(const Directory: string);
begin
  if not TDirectory.Exists(Directory) then
  begin
    try
      TDirectory.CreateDirectory(Directory);
    except
      on E: Exception do
        raise EConfigurationError.CreateFmt('Cannot create directory %s: %s', [Directory, E.Message]);
    end;
  end;
end;

function TTextFileProvider.FormatTimestamp(const DateTime: TDateTime): string;
begin
  if FIncludeTimestamp then
    Result := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', DateTime)
  else
    Result := '';
end;

function TTextFileProvider.GetCurrentFileName(const BaseFileName: string): string;
var
  DateSuffix: string;
  Extension: string;
begin
  Extension := IfThen(FUseJSON, '.jsonl', '.log');
  
  if FRotateDaily then
  begin
    DateSuffix := '_' + FormatDateTime('yyyymmdd', Now);
    Result := TPath.Combine(FBaseDirectory, BaseFileName + DateSuffix + Extension);
  end
  else
    Result := TPath.Combine(FBaseDirectory, BaseFileName + Extension);
end;

function TTextFileProvider.GetFileSize(const FileName: string): Int64;
begin
  try
    if TFile.Exists(FileName) then
      Result := TFile.GetSize(FileName)
    else
      Result := 0;
  except
    Result := 0;
  end;
end;

procedure TTextFileProvider.RotateFileIfNeeded(const FileName: string);
var
  FileSize: Int64;
  NewFileName: string;
  Counter: Integer;
begin
  if FMaxFileSizeMB <= 0 then
    Exit;
    
  FileSize := GetFileSize(FileName);
  if FileSize > (Int64(FMaxFileSizeMB) * 1024 * 1024) then
  begin
    // Rotacionar arquivo
    Counter := 1;
    repeat
      NewFileName := ChangeFileExt(FileName, '') + '_' + Counter.ToString + ExtractFileExt(FileName);
      Inc(Counter);
    until not TFile.Exists(NewFileName);
    
    try
      TFile.Move(FileName, NewFileName);
    except
      // Se falhar a rotação, continua escrevendo no arquivo atual
    end;
  end;
end;

procedure TTextFileProvider.WriteToFile(const FileName, Content: string);
var
  FileStream: TFileStream;
  ContentBytes: TBytes;
begin
  FLock.Enter;
  try
    // Verificar se precisa rotacionar
    RotateFileIfNeeded(FileName);
    
    // Escrever conteúdo
    ContentBytes := TEncoding.UTF8.GetBytes(Content + sLineBreak);
    
    if TFile.Exists(FileName) then
      FileStream := TFileStream.Create(FileName, fmOpenWrite or fmShareDenyWrite)
    else
      FileStream := TFileStream.Create(FileName, fmCreate or fmShareDenyWrite);
      
    try
      FileStream.Seek(0, soFromEnd);
      FileStream.WriteBuffer(ContentBytes[0], Length(ContentBytes));
    finally
      FileStream.Free;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TTextFileProvider.DoInitialize;
begin
  // Configurações do arquivo de configuração customizada
  if FConfig.CustomProperties.ContainsKey('base_directory') then
    FBaseDirectory := FConfig.CustomProperties['base_directory'];
    
  if FConfig.CustomProperties.ContainsKey('rotate_daily') then
    FRotateDaily := FConfig.CustomProperties['rotate_daily'] = 'true';
    
  if FConfig.CustomProperties.ContainsKey('max_file_size_mb') then
    FMaxFileSizeMB := StrToIntDef(FConfig.CustomProperties['max_file_size_mb'], 100);
    
  if FConfig.CustomProperties.ContainsKey('use_json') then
    FUseJSON := FConfig.CustomProperties['use_json'] = 'true';
    
  if FConfig.CustomProperties.ContainsKey('include_timestamp') then
    FIncludeTimestamp := FConfig.CustomProperties['include_timestamp'] = 'true';
    
  EnsureDirectoryExists(FBaseDirectory);
end;

procedure TTextFileProvider.DoShutdown;
begin
  // Nada específico para fazer no shutdown para files
end;

function TTextFileProvider.CreateTracer: IObservabilityTracer;
var
  Context: IObservabilityContext;
begin
  Context := TObservabilityContext.CreateNew;
  Context.ServiceName := FConfig.ServiceName;
  Context.ServiceVersion := FConfig.ServiceVersion;
  Context.Environment := FConfig.Environment;
  
  Result := TTextFileTracer.Create(Context, Self);
end;

function TTextFileProvider.CreateLogger: IObservabilityLogger;
var
  Context: IObservabilityContext;
begin
  Context := TObservabilityContext.CreateNew;
  Context.ServiceName := FConfig.ServiceName;
  Context.ServiceVersion := FConfig.ServiceVersion;
  Context.Environment := FConfig.Environment;
  
  Result := TTextFileLogger.Create(Context, Self);
end;

function TTextFileProvider.CreateMetrics: IObservabilityMetrics;
var
  Context: IObservabilityContext;
begin
  Context := TObservabilityContext.CreateNew;
  Context.ServiceName := FConfig.ServiceName;
  Context.ServiceVersion := FConfig.ServiceVersion;
  Context.Environment := FConfig.Environment;
  
  Result := TTextFileMetrics.Create(Context, Self);
end;

{ TTextFileSpan }

constructor TTextFileSpan.Create(const Name: string; const Context: IObservabilityContext; 
  const TextFileProvider: TTextFileProvider);
begin
  inherited Create(Name, Context);
  FTextFileProvider := TextFileProvider;
end;

function TTextFileSpan.ToTextFormat: string;
var
  AttributesStr: string;
  Key: string;
  OutcomeStr: string;
  TimestampStr: string;
begin
  // Outcome
  case FOutcome of
    Success: OutcomeStr := 'SUCCESS';
    Failure: OutcomeStr := 'FAILURE';
    Unknown: OutcomeStr := 'UNKNOWN';
  end;
  
  // Attributes
  AttributesStr := '';
  for Key in FAttributes.Keys do
  begin
    if not AttributesStr.IsEmpty then
      AttributesStr := AttributesStr + ', ';
    AttributesStr := AttributesStr + Key + '=' + FAttributes[Key];
  end;
  
  if not AttributesStr.IsEmpty then
    AttributesStr := ' [' + AttributesStr + ']';
    
  // Timestamp
  TimestampStr := FTextFileProvider.FormatTimestamp(FStartTime);
  if not TimestampStr.IsEmpty then
    TimestampStr := TimestampStr + ' ';
  
  Result := Format('%s[SPAN] %s | %s | TraceId:%s | SpanId:%s | Duration:%.2fms%s',
    [TimestampStr, FName, OutcomeStr, FTraceId, FSpanId, GetDuration, AttributesStr]);
end;

function TTextFileSpan.ToJSONFormat: TJSONObject;
var
  Key: string;
  AttributesObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  
  Result.AddPair('timestamp', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', TTimeZone.Local.ToUniversalTime(FStartTime)));
  Result.AddPair('type', 'span');
  Result.AddPair('name', FName);
  Result.AddPair('trace_id', FTraceId);
  Result.AddPair('span_id', FSpanId);
  if not FParentSpanId.IsEmpty then
    Result.AddPair('parent_span_id', FParentSpanId);
  
  Result.AddPair('start_time', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', TTimeZone.Local.ToUniversalTime(FStartTime)));
  Result.AddPair('end_time', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', TTimeZone.Local.ToUniversalTime(FEndTime)));
  Result.AddPair('duration_ms', TJSONNumber.Create(GetDuration));
  
  case FOutcome of
    Success: Result.AddPair('outcome', 'success');
    Failure: Result.AddPair('outcome', 'failure');
    Unknown: Result.AddPair('outcome', 'unknown');
  end;
  
  // Service info
  Result.AddPair('service_name', FContext.ServiceName);
  Result.AddPair('service_version', FContext.ServiceVersion);
  Result.AddPair('environment', FContext.Environment);
  
  // Attributes
  if FAttributes.Count > 0 then
  begin
    AttributesObj := TJSONObject.Create;
    for Key in FAttributes.Keys do
      AttributesObj.AddPair(Key, FAttributes[Key]);
    Result.AddPair('attributes', AttributesObj);
  end;
end;

procedure TTextFileSpan.DoFinish;
var
  Content: string;
  JsonObj: TJSONObject;
  FileName: string;
begin
  FileName := FTextFileProvider.GetCurrentFileName(FTextFileProvider.FTraceFileName);
  
  if FTextFileProvider.UseJSON then
  begin
    JsonObj := ToJSONFormat;
    try
      Content := JsonObj.ToString;
    finally
      JsonObj.Free;
    end;
  end
  else
    Content := ToTextFormat;
  
  FTextFileProvider.WriteToFile(FileName, Content);
end;

procedure TTextFileSpan.DoRecordException(const Exception: Exception);
var
  Content: string;
  JsonObj: TJSONObject;
  FileName: string;
  TimestampStr: string;
begin
  FileName := FTextFileProvider.GetCurrentFileName(FTextFileProvider.FTraceFileName);
  TimestampStr := FTextFileProvider.FormatTimestamp(Now);
  if not TimestampStr.IsEmpty then
    TimestampStr := TimestampStr + ' ';
  
  if FTextFileProvider.UseJSON then
  begin
    JsonObj := TJSONObject.Create;
    try
      JsonObj.AddPair('timestamp', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', TTimeZone.Local.ToUniversalTime(Now)));
      JsonObj.AddPair('type', 'span_exception');
      JsonObj.AddPair('span_name', FName);
      JsonObj.AddPair('trace_id', FTraceId);
      JsonObj.AddPair('span_id', FSpanId);
      JsonObj.AddPair('exception_type', Exception.ClassName);
      JsonObj.AddPair('exception_message', Exception.Message);
      JsonObj.AddPair('service_name', FContext.ServiceName);
      
      Content := JsonObj.ToString;
    finally
      JsonObj.Free;
    end;
  end
  else
    Content := Format('%s[SPAN_EXCEPTION] %s | %s: %s | TraceId:%s', 
      [TimestampStr, FName, Exception.ClassName, Exception.Message, FTraceId]);
  
  FTextFileProvider.WriteToFile(FileName, Content);
end;

procedure TTextFileSpan.DoAddEvent(const Name, Description: string);
var
  Content: string;
  JsonObj: TJSONObject;
  FileName: string;
  TimestampStr: string;
begin
  FileName := FTextFileProvider.GetCurrentFileName(FTextFileProvider.FTraceFileName);
  TimestampStr := FTextFileProvider.FormatTimestamp(Now);
  if not TimestampStr.IsEmpty then
    TimestampStr := TimestampStr + ' ';
  
  if FTextFileProvider.UseJSON then
  begin
    JsonObj := TJSONObject.Create;
    try
      JsonObj.AddPair('timestamp', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', TTimeZone.Local.ToUniversalTime(Now)));
      JsonObj.AddPair('type', 'span_event');
      JsonObj.AddPair('span_name', FName);
      JsonObj.AddPair('trace_id', FTraceId);
      JsonObj.AddPair('span_id', FSpanId);
      JsonObj.AddPair('event_name', Name);
      JsonObj.AddPair('event_description', Description);
      JsonObj.AddPair('service_name', FContext.ServiceName);
      
      Content := JsonObj.ToString;
    finally
      JsonObj.Free;
    end;
  end
  else
    Content := Format('%s[SPAN_EVENT] %s | %s: %s | TraceId:%s', 
      [TimestampStr, FName, Name, Description, FTraceId]);
  
  FTextFileProvider.WriteToFile(FileName, Content);
end;

{ TTextFileTracer }

constructor TTextFileTracer.Create(const Context: IObservabilityContext; const TextFileProvider: TTextFileProvider);
begin
  inherited Create(Context);
  FTextFileProvider := TextFileProvider;
end;

function TTextFileTracer.DoCreateSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan;
begin
  Result := TTextFileSpan.Create(Name, Context, FTextFileProvider);
end;

procedure TTextFileTracer.InjectHeaders(const Headers: TStrings);
begin
  if Assigned(FContext) then
  begin
    Headers.Values['X-Trace-Id'] := FContext.TraceId;
    Headers.Values['X-Span-Id'] := FContext.SpanId;
  end;
end;

function TTextFileTracer.ExtractContext(const Headers: TStrings): IObservabilityContext;
var
  TraceId, SpanId: string;
  Context: IObservabilityContext;
begin
  TraceId := Headers.Values['X-Trace-Id'];
  SpanId := Headers.Values['X-Span-Id'];
  
  Context := TObservabilityContext.CreateNew;
  
  if not TraceId.IsEmpty then
  begin
    Context.TraceId := TraceId;
    if not SpanId.IsEmpty then
      Context.SpanId := SpanId;
  end;
  
  Result := Context;
end;

{ TTextFileLogger }

constructor TTextFileLogger.Create(const Context: IObservabilityContext; const TextFileProvider: TTextFileProvider);
begin
  inherited Create(Context);
  FTextFileProvider := TextFileProvider;
end;

function TTextFileLogger.LogLevelToString(const Level: TLogLevel): string;
begin
  case Level of
    llTrace: Result := 'TRACE';
    llDebug: Result := 'DEBUG';
    llInfo: Result := 'INFO ';
    llWarning: Result := 'WARN ';
    llError: Result := 'ERROR';
    llCritical: Result := 'FATAL';
  else
    Result := 'INFO ';
  end;
end;

function TTextFileLogger.FormatLogEntry(const Level: TLogLevel; const Message: string; 
  const Attributes: TDictionary<string, string>; const Exception: Exception): string;
var
  AttributesStr: string;
  Key: string;
  TimestampStr: string;
begin
  // Timestamp
  TimestampStr := FTextFileProvider.FormatTimestamp(Now);
  if not TimestampStr.IsEmpty then
    TimestampStr := TimestampStr + ' ';
  
  // Build attributes string
  AttributesStr := '';
  
  // Add context info
  if not FContext.TraceId.IsEmpty then
  begin
    if not AttributesStr.IsEmpty then AttributesStr := AttributesStr + ', ';
    AttributesStr := AttributesStr + 'TraceId=' + FContext.TraceId;
  end;
  
  if not FContext.ServiceName.IsEmpty then
  begin
    if not AttributesStr.IsEmpty then AttributesStr := AttributesStr + ', ';
    AttributesStr := AttributesStr + 'Service=' + FContext.ServiceName;
  end;
  
  // Add custom attributes
  if Assigned(Attributes) then
  begin
    for Key in Attributes.Keys do
    begin
      if not AttributesStr.IsEmpty then AttributesStr := AttributesStr + ', ';
      AttributesStr := AttributesStr + Key + '=' + Attributes[Key];
    end;
  end;
  
  // Add global attributes
  for Key in FAttributes.Keys do
  begin
    if not AttributesStr.IsEmpty then AttributesStr := AttributesStr + ', ';
    AttributesStr := AttributesStr + Key + '=' + FAttributes[Key];
  end;
  
  if not AttributesStr.IsEmpty then
    AttributesStr := ' [' + AttributesStr + ']';
  
  // Build final log entry
  Result := Format('%s[%s] %s%s', [TimestampStr, LogLevelToString(Level), Message, AttributesStr]);
  
  // Add exception info
  if Assigned(Exception) then
    Result := Result + Format(' | Exception: %s - %s', [Exception.ClassName, Exception.Message]);
end;

function TTextFileLogger.FormatLogEntryJSON(const Level: TLogLevel; const Message: string; 
  const Attributes: TDictionary<string, string>; const Exception: Exception): TJSONObject;
var
  Key: string;
  AttributesObj: TJSONObject;
begin
  Result := TJSONObject.Create;
  
  Result.AddPair('timestamp', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', TTimeZone.Local.ToUniversalTime(Now)));
  Result.AddPair('type', 'log');
  Result.AddPair('level', LogLevelToString(Level).Trim);
  Result.AddPair('message', Message);
  
  // Service info
  Result.AddPair('service_name', FContext.ServiceName);
  Result.AddPair('service_version', FContext.ServiceVersion);
  Result.AddPair('environment', FContext.Environment);
  
  // Trace correlation
  if not FContext.TraceId.IsEmpty then
  begin
    Result.AddPair('trace_id', FContext.TraceId);
    Result.AddPair('span_id', FContext.SpanId);
  end;
  
  // User context
  if not FContext.UserId.IsEmpty then
  begin
    Result.AddPair('user_id', FContext.UserId);
    Result.AddPair('user_name', FContext.UserName);
    Result.AddPair('user_email', FContext.UserEmail);
  end;
  
  // Custom attributes
  if (Assigned(Attributes) and (Attributes.Count > 0)) or (FAttributes.Count > 0) then
  begin
    AttributesObj := TJSONObject.Create;
    
    // Add custom attributes
    if Assigned(Attributes) then
    begin
      for Key in Attributes.Keys do
        AttributesObj.AddPair(Key, Attributes[Key]);
    end;
    
    // Add global attributes
    for Key in FAttributes.Keys do
      AttributesObj.AddPair(Key, FAttributes[Key]);
    
    Result.AddPair('attributes', AttributesObj);
  end;
  
  // Exception info
  if Assigned(Exception) then
  begin
    Result.AddPair('exception_type', Exception.ClassName);
    Result.AddPair('exception_message', Exception.Message);
  end;
end;

procedure TTextFileLogger.DoLog(const Level: TLogLevel; const Message: string; 
  const Attributes: TDictionary<string, string>; const Exception: Exception);
var
  Content: string;
  JsonObj: TJSONObject;
  FileName: string;
begin
  FileName := FTextFileProvider.GetCurrentFileName(FTextFileProvider.FLogFileName);
  
  if FTextFileProvider.UseJSON then
  begin
    JsonObj := FormatLogEntryJSON(Level, Message, Attributes, Exception);
    try
      Content := JsonObj.ToString;
    finally
      JsonObj.Free;
    end;
  end
  else
    Content := FormatLogEntry(Level, Message, Attributes, Exception);
  
  FTextFileProvider.WriteToFile(FileName, Content);
end;

{ TTextFileMetrics }

constructor TTextFileMetrics.Create(const Context: IObservabilityContext; const TextFileProvider: TTextFileProvider);
begin
  inherited Create(Context);
  FTextFileProvider := TextFileProvider;
end;

procedure TTextFileMetrics.WriteMetric(const MetricType, Name: string; const Value: Double; 
  const Tags: TDictionary<string, string>; const Timestamp: TDateTime);
var
  Content: string;
  JsonObj: TJSONObject;
  TagsObj: TJSONObject;
  FileName: string;
  TagsStr: string;
  Key: string;
  TimestampStr: string;
begin
  FileName := FTextFileProvider.GetCurrentFileName(FTextFileProvider.FMetricsFileName);
  
  if FTextFileProvider.UseJSON then
  begin
    JsonObj := TJSONObject.Create;
    try
      JsonObj.AddPair('timestamp', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', TTimeZone.Local.ToUniversalTime(Timestamp)));
      JsonObj.AddPair('type', 'metric');
      JsonObj.AddPair('metric_type', MetricType);
      JsonObj.AddPair('metric_name', Name);
      JsonObj.AddPair('value', TJSONNumber.Create(Value));
      JsonObj.AddPair('service_name', FContext.ServiceName);
      JsonObj.AddPair('service_version', FContext.ServiceVersion);
      JsonObj.AddPair('environment', FContext.Environment);
      
      // Tags
      if (Assigned(Tags) and (Tags.Count > 0)) or (FGlobalTags.Count > 0) then
      begin
        TagsObj := TJSONObject.Create;
        
        // Add custom tags
        if Assigned(Tags) then
        begin
          for Key in Tags.Keys do
            TagsObj.AddPair(Key, Tags[Key]);
        end;
        
        // Add global tags
        for Key in FGlobalTags.Keys do
          TagsObj.AddPair(Key, FGlobalTags[Key]);
        
        JsonObj.AddPair('tags', TagsObj);
      end;
      
      Content := JsonObj.ToString;
    finally
      JsonObj.Free;
    end;
  end
  else
  begin
    // Text format
    TagsStr := '';
    
    // Add custom tags
    if Assigned(Tags) then
    begin
      for Key in Tags.Keys do
      begin
        if not TagsStr.IsEmpty then TagsStr := TagsStr + ', ';
        TagsStr := TagsStr + Key + '=' + Tags[Key];
      end;
    end;
    
    // Add global tags
    for Key in FGlobalTags.Keys do
    begin
      if not TagsStr.IsEmpty then TagsStr := TagsStr + ', ';
      TagsStr := TagsStr + Key + '=' + FGlobalTags[Key];
    end;
    
    if not TagsStr.IsEmpty then
      TagsStr := ' [' + TagsStr + ']';
    
    TimestampStr := FTextFileProvider.FormatTimestamp(Timestamp);
    if not TimestampStr.IsEmpty then
      TimestampStr := TimestampStr + ' ';
    
    Content := Format('%s[%s] %s | %.6f%s', [TimestampStr, MetricType.ToUpper, Name, Value, TagsStr]);
  end;
  
  FTextFileProvider.WriteToFile(FileName, Content);
end;

procedure TTextFileMetrics.DoCounter(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  WriteMetric('counter', Name, Value, Tags, Now);
end;

procedure TTextFileMetrics.DoGauge(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  WriteMetric('gauge', Name, Value, Tags, Now);
end;

procedure TTextFileMetrics.DoHistogram(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  WriteMetric('histogram', Name, Value, Tags, Now);
end;

procedure TTextFileMetrics.DoSummary(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
begin
  WriteMetric('summary', Name, Value, Tags, Now);
end;

function TTextFileProvider.GetDefaultLogDirectory: string;
{$IFDEF MSWINDOWS}
begin
  // Windows: Use Documents folder
  Result := TPath.Combine(TPath.GetDocumentsPath, 'ObservabilityLogs');
end;
{$ELSE}
var
  HomeDir: string;
begin
  // Linux/Unix: Try standard locations
  try
    // First try XDG_DATA_HOME or ~/.local/share
    HomeDir := GetEnvironmentVariable('XDG_DATA_HOME');
    if HomeDir.IsEmpty then
    begin
      HomeDir := GetEnvironmentVariable('HOME');
      if not HomeDir.IsEmpty then
        HomeDir := TPath.Combine(HomeDir, '.local/share')
      else
        HomeDir := '/tmp'; // Last resort
    end;
    
    Result := TPath.Combine(HomeDir, 'observability-logs');
  except
    // Fallback to temp directory
    Result := TPath.Combine(TPath.GetTempPath, 'observability-logs');
  end;
end;
{$ENDIF}

end.