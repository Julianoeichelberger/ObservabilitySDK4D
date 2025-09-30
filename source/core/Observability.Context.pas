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
unit Observability.Context;

interface

uses
  System.SysUtils, System.Generics.Collections,
  Observability.Interfaces;

type
  TObservabilityContext = class(TInterfacedObject, IObservabilityContext)
  private
    FTraceId, FSpanId, FParentSpanId: string;
    FServiceName, FServiceVersion, FEnvironment: string;
    FUserId, FUserName, FUserEmail: string;
    FTags: TDictionary<string,string>;
    FAttributes: TDictionary<string,string>;
    function GenerateId: string;
  protected
    function GetTraceId: string;
    function GetSpanId: string;
    function GetParentSpanId: string;
    function GetServiceName: string;
    function GetServiceVersion: string;
    function GetEnvironment: string;
    function GetUserId: string;
    function GetUserName: string;
    function GetUserEmail: string;
    function GetTags: TDictionary<string,string>;
    function GetAttributes: TDictionary<string,string>;
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
  public
    constructor Create;
    destructor Destroy; override;
    class function New: IObservabilityContext; static;
    class function CreateNew: IObservabilityContext; static; inline;
    class function CreateWithTraceId(const TraceId: string): IObservabilityContext; static;
    class function CreateChild(const Parent: IObservabilityContext): IObservabilityContext; static;
  end;

implementation

{ TObservabilityContext }

constructor TObservabilityContext.Create;
begin
  inherited Create;
  FTags := TDictionary<string,string>.Create;
  FAttributes := TDictionary<string,string>.Create;
  FTraceId := GenerateId;
  FSpanId := GenerateId;
end;

destructor TObservabilityContext.Destroy;
begin
  FTags.Free;
  FAttributes.Free;
  inherited Destroy;
end;

class function TObservabilityContext.New: IObservabilityContext;
begin
  Result := TObservabilityContext.Create;
end;

class function TObservabilityContext.CreateNew: IObservabilityContext;
begin
  Result := New;
end;

class function TObservabilityContext.CreateWithTraceId(const TraceId: string): IObservabilityContext;
var
  Context: TObservabilityContext;
begin
  Context := TObservabilityContext.Create;
  Context.FTraceId := TraceId;
  Result := Context;
end;

class function TObservabilityContext.CreateChild(const Parent: IObservabilityContext): IObservabilityContext;
var
  Context: TObservabilityContext;
  Key: string;
begin
  Context := TObservabilityContext.Create;
  Context.FTraceId := Parent.TraceId;
  Context.FParentSpanId := Parent.SpanId;
  Context.FServiceName := Parent.ServiceName;
  Context.FServiceVersion := Parent.ServiceVersion;
  Context.FEnvironment := Parent.Environment;
  Context.FUserId := Parent.UserId;
  Context.FUserName := Parent.UserName;
  Context.FUserEmail := Parent.UserEmail;
  
  // Copy tags and attributes
  for Key in Parent.Tags.Keys do
    Context.FTags.Add(Key, Parent.Tags[Key]);
  for Key in Parent.Attributes.Keys do
    Context.FAttributes.Add(Key, Parent.Attributes[Key]);
  
  Result := Context;
end;

function TObservabilityContext.Clone: IObservabilityContext;
var
  C: TObservabilityContext;
  K: string;
begin
  C := TObservabilityContext.Create;
  C.FTraceId := FTraceId;
  C.FSpanId := C.GenerateId;
  C.FParentSpanId := FSpanId;
  C.FServiceName := FServiceName;
  C.FServiceVersion := FServiceVersion;
  C.FEnvironment := FEnvironment;
  C.FUserId := FUserId;
  C.FUserName := FUserName;
  C.FUserEmail := FUserEmail;
  for K in FTags.Keys do
    C.FTags.Add(K, FTags[K]);
  for K in FAttributes.Keys do
    C.FAttributes.Add(K, FAttributes[K]);
  Result := C;
end;

function TObservabilityContext.GenerateId: string;
var
  G: TGUID;
begin
  CreateGUID(G);
  Result := GUIDToString(G).Replace('{','').Replace('}','').Replace('-','').ToLower;
end;

procedure TObservabilityContext.AddAttribute(const Key, Value: string);
begin
  FAttributes.AddOrSetValue(Key, Value);
end;

procedure TObservabilityContext.AddTag(const Key, Value: string);
begin
  FTags.AddOrSetValue(Key, Value);
end;

function TObservabilityContext.GetAttributes: TDictionary<string,string>;
begin
  Result := FAttributes;
end;

function TObservabilityContext.GetEnvironment: string;
begin
  Result := FEnvironment;
end;

function TObservabilityContext.GetParentSpanId: string;
begin
  Result := FParentSpanId;
end;

function TObservabilityContext.GetServiceName: string;
begin
  Result := FServiceName;
end;

function TObservabilityContext.GetServiceVersion: string;
begin
  Result := FServiceVersion;
end;

function TObservabilityContext.GetSpanId: string;
begin
  Result := FSpanId;
end;

function TObservabilityContext.GetTags: TDictionary<string,string>;
begin
  Result := FTags;
end;

function TObservabilityContext.GetTraceId: string;
begin
  Result := FTraceId;
end;

function TObservabilityContext.GetUserEmail: string;
begin
  Result := FUserEmail;
end;

function TObservabilityContext.GetUserId: string;
begin
  Result := FUserId;
end;

function TObservabilityContext.GetUserName: string;
begin
  Result := FUserName;
end;

procedure TObservabilityContext.SetEnvironment(const Value: string);
begin
  FEnvironment := Value;
end;

procedure TObservabilityContext.SetParentSpanId(const Value: string);
begin
  FParentSpanId := Value;
end;

procedure TObservabilityContext.SetServiceName(const Value: string);
begin
  FServiceName := Value;
end;

procedure TObservabilityContext.SetServiceVersion(const Value: string);
begin
  FServiceVersion := Value;
end;

procedure TObservabilityContext.SetSpanId(const Value: string);
begin
  FSpanId := Value;
end;

procedure TObservabilityContext.SetTraceId(const Value: string);
begin
  FTraceId := Value;
end;

procedure TObservabilityContext.SetUserEmail(const Value: string);
begin
  FUserEmail := Value;
end;

procedure TObservabilityContext.SetUserId(const Value: string);
begin
  FUserId := Value;
end;

procedure TObservabilityContext.SetUserName(const Value: string);
begin
  FUserName := Value;
end;

end.