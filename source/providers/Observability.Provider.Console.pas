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
unit Observability.Provider.Console;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Observability.Interfaces, Observability.Provider.Base, Observability.Context;

type
  TConsoleProvider = class(TBaseObservabilityProvider)
  protected
    function GetProviderType: TObservabilityProvider; override;
    function GetSupportedTypes: TObservabilityTypeSet; override;
    
    procedure DoInitialize; override;
    procedure DoShutdown; override;
    function CreateTracer: IObservabilityTracer; override;
    function CreateLogger: IObservabilityLogger; override;
    function CreateMetrics: IObservabilityMetrics; override;
  end;

  TConsoleSpan = class(TBaseObservabilitySpan)
  protected
    procedure DoFinish; override;
    procedure DoRecordException(const Exception: Exception); override;
    procedure DoAddEvent(const Name, Description: string); override;
  end;

  TConsoleTracer = class(TBaseObservabilityTracer)
  protected
    function DoCreateSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan; override;
  end;

  TConsoleLogger = class(TBaseObservabilityLogger)
  protected
    procedure DoLog(const Level: TLogLevel; const Message: string; 
      const Attributes: TDictionary<string, string>; const Exception: Exception); override;
  private
    function LogLevelToString(const Level: TLogLevel): string;
  end;

  TConsoleMetrics = class(TBaseObservabilityMetrics)
  protected
    procedure DoCounter(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
    procedure DoGauge(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
    procedure DoHistogram(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
    procedure DoSummary(const Name: string; const Value: Double; const Tags: TDictionary<string, string>); override;
  end;

implementation

{ TConsoleProvider }

function TConsoleProvider.GetProviderType: TObservabilityProvider;
begin
  Result := opConsole;
end;

function TConsoleProvider.GetSupportedTypes: TObservabilityTypeSet;
begin
  Result := [otTracing, otLogging, otMetrics];
end;

procedure TConsoleProvider.DoInitialize;
begin
  System.Writeln('[CONSOLE PROVIDER] Initialized');
end;

procedure TConsoleProvider.DoShutdown;
begin
  System.Writeln('[CONSOLE PROVIDER] Shutdown');
end;

function TConsoleProvider.CreateTracer: IObservabilityTracer;
var
  Context: IObservabilityContext;
begin
  Context := TObservabilityContext.CreateNew;
  Context.ServiceName := FConfig.ServiceName;
  Context.ServiceVersion := FConfig.ServiceVersion;
  Context.Environment := FConfig.Environment;
  
  Result := TConsoleTracer.Create(Context);
end;

function TConsoleProvider.CreateLogger: IObservabilityLogger;
var
  Context: IObservabilityContext;
begin
  Context := TObservabilityContext.CreateNew;
  Context.ServiceName := FConfig.ServiceName;
  Context.ServiceVersion := FConfig.ServiceVersion;
  Context.Environment := FConfig.Environment;
  
  Result := TConsoleLogger.Create(Context);
end;

function TConsoleProvider.CreateMetrics: IObservabilityMetrics;
var
  Context: IObservabilityContext;
begin
  Context := TObservabilityContext.CreateNew;
  Context.ServiceName := FConfig.ServiceName;
  Context.ServiceVersion := FConfig.ServiceVersion;
  Context.Environment := FConfig.Environment;
  
  Result := TConsoleMetrics.Create(Context);
end;

{ TConsoleSpan }

procedure TConsoleSpan.DoFinish;
var
  OutcomeStr: string;
  AttributesStr: string;
  Key: string;
begin
  case FOutcome of
    Success: OutcomeStr := 'SUCCESS';
    Failure: OutcomeStr := 'FAILURE';
    Unknown: OutcomeStr := 'UNKNOWN';
  end;
  
  AttributesStr := '';
  for Key in FAttributes.Keys do
  begin
    if not AttributesStr.IsEmpty then
      AttributesStr := AttributesStr + ', ';
    AttributesStr := AttributesStr + Key + '=' + FAttributes[Key];
  end;
  
  if not AttributesStr.IsEmpty then
    AttributesStr := ' [' + AttributesStr + ']';
  
  System.Writeln(Format('[SPAN] %s | %s | %s->%s | %.2fms | %s%s', [
    FName,
    OutcomeStr,
    FormatDateTime('hh:nn:ss.zzz', FStartTime),
    FormatDateTime('hh:nn:ss.zzz', FEndTime),
    GetDuration,
    FSpanId,
    AttributesStr
  ]));
end;

procedure TConsoleSpan.DoRecordException(const Exception: Exception);
begin
  System.Writeln(Format('[SPAN EXCEPTION] %s | %s: %s', [FName, Exception.ClassName, Exception.Message]));
end;

procedure TConsoleSpan.DoAddEvent(const Name, Description: string);
begin
  System.Writeln(Format('[SPAN EVENT] %s | %s: %s', [FName, Name, Description]));
end;

{ TConsoleTracer }

function TConsoleTracer.DoCreateSpan(const Name: string; const Context: IObservabilityContext): IObservabilitySpan;
begin
  Result := TConsoleSpan.Create(Name, Context);
  System.Writeln(Format('[TRACE] Started span: %s | TraceId: %s | SpanId: %s | ParentSpanId: %s', [
    Name, 
    Context.TraceId, 
    Result.SpanId, 
    Context.SpanId
  ]));
end;

{ TConsoleLogger }

procedure TConsoleLogger.DoLog(const Level: TLogLevel; const Message: string; 
  const Attributes: TDictionary<string, string>; const Exception: Exception);
var
  LogLine: string;
  AttributesStr: string;
  Key: string;
begin
  LogLine := Format('[%s] %s | %s', [
    LogLevelToString(Level),
    FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now),
    Message
  ]);
  
  // Add context information
  if not FContext.TraceId.IsEmpty then
    LogLine := LogLine + Format(' | TraceId: %s', [FContext.TraceId]);
    
  if not FContext.ServiceName.IsEmpty then
    LogLine := LogLine + Format(' | Service: %s', [FContext.ServiceName]);
  
  // Add attributes
  AttributesStr := '';
  if Assigned(Attributes) then
  begin
    for Key in Attributes.Keys do
    begin
      if not AttributesStr.IsEmpty then
        AttributesStr := AttributesStr + ', ';
      AttributesStr := AttributesStr + Key + '=' + Attributes[Key];
    end;
  end;
  
  // Add global attributes
  for Key in FAttributes.Keys do
  begin
    if not AttributesStr.IsEmpty then
      AttributesStr := AttributesStr + ', ';
    AttributesStr := AttributesStr + Key + '=' + FAttributes[Key];
  end;
  
  if not AttributesStr.IsEmpty then
    LogLine := LogLine + ' [' + AttributesStr + ']';
  
  // Add exception information
  if Assigned(Exception) then
    LogLine := LogLine + Format(' | Exception: %s - %s', [Exception.ClassName, Exception.Message]);
  
  System.Writeln(LogLine);
end;

function TConsoleLogger.LogLevelToString(const Level: TLogLevel): string;
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

{ TConsoleMetrics }

procedure TConsoleMetrics.DoCounter(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
var
  TagsStr: string;
  Key: string;
begin
  TagsStr := '';
  
  // Add tags
  if Assigned(Tags) then
  begin
    for Key in Tags.Keys do
    begin
      if not TagsStr.IsEmpty then
        TagsStr := TagsStr + ', ';
      TagsStr := TagsStr + Key + '=' + Tags[Key];
    end;
  end;
  
  // Add global tags
  for Key in FGlobalTags.Keys do
  begin
    if not TagsStr.IsEmpty then
      TagsStr := TagsStr + ', ';
    TagsStr := TagsStr + Key + '=' + FGlobalTags[Key];
  end;
  
  if not TagsStr.IsEmpty then
    TagsStr := ' [' + TagsStr + ']';
  
  System.Writeln(Format('[COUNTER] %s | %.2f%s | %s', [
    Name, 
    Value, 
    TagsStr,
    FormatDateTime('hh:nn:ss.zzz', Now)
  ]));
end;

procedure TConsoleMetrics.DoGauge(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
var
  TagsStr: string;
  Key: string;
begin
  TagsStr := '';
  
  // Add tags
  if Assigned(Tags) then
  begin
    for Key in Tags.Keys do
    begin
      if not TagsStr.IsEmpty then
        TagsStr := TagsStr + ', ';
      TagsStr := TagsStr + Key + '=' + Tags[Key];
    end;
  end;
  
  // Add global tags
  for Key in FGlobalTags.Keys do
  begin
    if not TagsStr.IsEmpty then
      TagsStr := TagsStr + ', ';
    TagsStr := TagsStr + Key + '=' + FGlobalTags[Key];
  end;
  
  if not TagsStr.IsEmpty then
    TagsStr := ' [' + TagsStr + ']';
  
  System.Writeln(Format('[GAUGE] %s | %.2f%s | %s', [
    Name, 
    Value, 
    TagsStr,
    FormatDateTime('hh:nn:ss.zzz', Now)
  ]));
end;

procedure TConsoleMetrics.DoHistogram(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
var
  TagsStr: string;
  Key: string;
begin
  TagsStr := '';
  
  // Add tags
  if Assigned(Tags) then
  begin
    for Key in Tags.Keys do
    begin
      if not TagsStr.IsEmpty then
        TagsStr := TagsStr + ', ';
      TagsStr := TagsStr + Key + '=' + Tags[Key];
    end;
  end;
  
  // Add global tags
  for Key in FGlobalTags.Keys do
  begin
    if not TagsStr.IsEmpty then
      TagsStr := TagsStr + ', ';
    TagsStr := TagsStr + Key + '=' + FGlobalTags[Key];
  end;
  
  if not TagsStr.IsEmpty then
    TagsStr := ' [' + TagsStr + ']';
  
  System.Writeln(Format('[HISTOGRAM] %s | %.2f%s | %s', [
    Name, 
    Value, 
    TagsStr,
    FormatDateTime('hh:nn:ss.zzz', Now)
  ]));
end;

procedure TConsoleMetrics.DoSummary(const Name: string; const Value: Double; const Tags: TDictionary<string, string>);
var
  TagsStr: string;
  Key: string;
begin
  TagsStr := '';
  
  // Add tags
  if Assigned(Tags) then
  begin
    for Key in Tags.Keys do
    begin
      if not TagsStr.IsEmpty then
        TagsStr := TagsStr + ', ';
      TagsStr := TagsStr + Key + '=' + Tags[Key];
    end;
  end;
  
  // Add global tags
  for Key in FGlobalTags.Keys do
  begin
    if not TagsStr.IsEmpty then
      TagsStr := TagsStr + ', ';
    TagsStr := TagsStr + Key + '=' + FGlobalTags[Key];
  end;
  
  if not TagsStr.IsEmpty then
    TagsStr := ' [' + TagsStr + ']';
  
  System.Writeln(Format('[SUMMARY] %s | %.2f%s | %s', [
    Name, 
    Value, 
    TagsStr,
    FormatDateTime('hh:nn:ss.zzz', Now)
  ]));
end;

end.
