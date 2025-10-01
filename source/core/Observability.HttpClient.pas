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
unit Observability.HttpClient;

interface

uses
  System.TypInfo, System.SysUtils, System.Classes, Data.DB, System.Generics.Collections, 
  REST.Client, REST.Types, System.JSON, REST.JSON, REST.Authenticator.Basic;

type
  TListenerEvent = (leBeforeExecute, leAfterExecute, leHttpError);
  TSetListenerEvent = Set of TListenerEvent;
  TRESTContentType = Rest.Types.TRESTContentType;

  TRESTListener = class
  public
    function Events: TSetListenerEvent; virtual;
    procedure Execute(Sender: TRESTRequest; const AEvent: TListenerEvent); virtual;
  End;

  TRESTListenerClass = class of TRESTListener;

  TRESTListeners = class
  private
    class var FList: TObjectList<TRESTListener>;
    class procedure ExecuteAll(Sender: TRESTRequest; const AEvent: TListenerEvent);
  public
    class procedure Register(Clas: TRESTListenerClass);
  end;

  IResponse = interface
    ['{633621C6-8035-40FD-839F-853C02F190C0}']
    function ContentLength: Cardinal;
    function ContentType: string;
    function ContentEncoding: string;
    function AsString: string;
    function AsStream: TStream;
    function StatusCode: Integer;
    function AsBytes: TBytes;
    function AsJSON: TJSONValue;
    function AsJSONArray: TJSONArray;
    function Header(const AName: string): string;
    function Headers: TStrings;
  end;

  TResponse = class(TInterfacedObject, IResponse)
  private
    FJsonValue: TJSONValue;
    FJsonArray: TJSONArray;
    FRESTResponse: TRESTResponse;
    FStreamValue: TMemoryStream;
    function AsString: string;
    function ContentLength: Cardinal;
    function ContentType: string;
    function ContentEncoding: string;
    function AsStream: TStream;
    function StatusCode: Integer;
    function AsBytes: TBytes;
    function AsJSON: TJSONValue;
    function AsJSONArray: TJSONArray;
    function Headers: TStrings;
    function Header(const AName: string): string;

    procedure FillResults;
  public
    constructor Create(const ARESTResponse: TRESTResponse);
    destructor Destroy; override;
  end;

  TParamsOptions = Rest.Types.TRESTRequestParameterOptions;
  TOnExecRequest = reference to procedure(AResponse: IResponse);

  TRESTExecThread = class(TThread)
  private
    FCompleteHandler: TOnExecRequest;
    FErrorHandler: TOnExecRequest;
    FSynchronized: Boolean;
    FRequest: TCustomRESTRequest;
    FResponse: IResponse;
  protected
    procedure HandleCompletion;
    procedure HandleCompletionWithError;
    procedure Execute; override;
  public
    constructor Create(ARequest: TCustomRESTRequest; AOnComplete: TOnExecRequest;
      ASynchronized: Boolean = True; AFreeThread: Boolean = True; AOnError: TOnExecRequest = nil);
  end;

  IRequest = interface
    ['{518B831C-12B1-35AB-E922-A191AB030991}']
    function AcceptEncoding(const AAcceptEncoding: string): IRequest;
    function AcceptCharset(const AAcceptCharset: string): IRequest;
    function UserAgent(const AName: string): IRequest;
    function ContentType(const AContentType: string): IRequest;
    function Accept(const AAccept: string): IRequest;
    function Timeout(const ATimeout: Integer): IRequest;
    function DataSetAdapter(const ADataSet: TDataSet): IRequest;
    function BaseURL(const ABaseURL: string): IRequest;
    function RaiseExceptionOn500(const ARaiseException: Boolean): IRequest;
    function Token(const AToken: string): IRequest;
    function AddHeader(const AName, AValue: string; const AOptions: TParamsOptions = []): IRequest;
    function AddQuery(const AName, AValue: string): IRequest;
    function AddParameter(const AName, AValue: string; AKind: TRESTRequestParameterKind = pkGETorPOST;
      AOptions: TRESTRequestParameterOptions = []): IRequest;
    function AddBody(const AContent: TJSONObject; const AOwns: Boolean): IRequest; overload;
    function AddBody(const AContent: string; const AContentType: TRESTContentType = ctAPPLICATION_JSON): IRequest; overload;
    function AddBody(const AContent: TObject; const AOwns: Boolean = True): IRequest; overload;
    function AddBody(const AContent: TStream; const AOwns: Boolean): IRequest; overload;
    function AddBodyJson(const AContent: TObject; const AOwns: Boolean = True): IRequest;
    function AddProxy(const AServer: string; const APort: Integer;
      const APassword: string = ''; const AUsername: string = ''): IRequest;
    function Resource(const AResource: string): IRequest; overload;
    function ResourceSuffix(const AResourceSuffix: string): IRequest;
    function AddAuthParameter(const AUsername: String; Const APassword: String): IRequest;

    function Get: IResponse; overload;

    function Post: IResponse; overload;
    function Post(const AContent: TObject; const AOwns: Boolean = True): IResponse; overload;

    function Put: IResponse; overload;
    function Put(const AContent: TObject; const AOwns: Boolean = True): IResponse; overload;

    function Delete: IResponse; overload;
    function Delete(const AId: string): IResponse; overload;
    function Delete(const AContent: TObject; const AOwns: Boolean = True): IResponse; overload;

    function Patch: IResponse; overload;

    procedure Async(const AMethod: TRESTRequestMethod = TRESTRequestMethod.rmPOST;
      AOnComplete: TOnExecRequest = nil; AOnError: TOnExecRequest = nil); overload;
    function Async(const AFreeThread: Boolean; const AMethod: TRESTRequestMethod = TRESTRequestMethod.rmPOST;
      AOnComplete: TOnExecRequest = nil; AOnError: TOnExecRequest = nil): TRESTExecThread; overload;

    procedure GetAsync(AOnComplete: TOnExecRequest = nil); overload;
    procedure PostAsync(AOnComplete: TOnExecRequest = nil); overload;
    procedure PutAsync(AOnComplete: TOnExecRequest = nil); overload;
    procedure DeleteAsync(AOnComplete: TOnExecRequest = nil); overload;
  end;

  TRestClient = class(TObject, IRequest)
  strict private
    FRefCount: Integer;
    FIsAsync: Boolean;
    FResponse: IResponse;
    FDataSetAdapter: TDataSet;
    procedure InternalDestroy(Sender: TObject);
    function QueryInterface(const IID: TGUID; out Obj): HResult; virtual; stdcall;
    function _AddRef: Integer; virtual; stdcall;
    function _Release: Integer; virtual; stdcall;
  private
    function AcceptEncoding(const AAcceptEncoding: string): IRequest;
    function AcceptCharset(const AAcceptCharset: string): IRequest;
    function UserAgent(const AName: string): IRequest;
    function ContentType(const AContentType: string): IRequest;
    function Accept(const AAccept: string): IRequest;
    function Timeout(const ATimeout: Integer): IRequest;
    function DataSetAdapter(const ADataSet: TDataSet): IRequest;
    function BaseURL(const ABaseURL: string): IRequest;
    function Resource(const AResource: string): IRequest; overload;
    function ResourceSuffix(const AResourceSuffix: string): IRequest;
    function RaiseExceptionOn500(const ARaiseException: Boolean): IRequest;
    function Token(const AToken: string): IRequest;
    function AddHeader(const AName, AValue: string; const AOptions: TParamsOptions = []): IRequest;
    function AddQuery(const AName, AValue: string): IRequest;
    function AddParameter(const AName, AValue: string; AKind: TRESTRequestParameterKind; AOptions: TRESTRequestParameterOptions)
      : IRequest;

    function AddBody(const AContent: TJSONObject; const AOwns: Boolean): IRequest; overload;
    function AddBody(const AContent: string; const AContentType: TRESTContentType = ctAPPLICATION_JSON): IRequest; overload;
    function AddBody(const AContent: TObject; const AOwns: Boolean = True): IRequest; overload;
    function AddBody(const AContent: TStream; const AOwns: Boolean): IRequest; overload;
    function AddBodyJson(const AContent: TObject; const AOwns: Boolean = True): IRequest;
    function AddProxy(const AServer: string; const APort: Integer;
      const APassword: string = ''; const AUsername: string = ''): IRequest;
    function AddAuthParameter(const AUsername: String; Const APassword: String): IRequest;

    procedure Async(const AMethod: TRESTRequestMethod = TRESTRequestMethod.rmPOST;
      AOnComplete: TOnExecRequest = nil; AOnError: TOnExecRequest = nil); overload;
    function Async(const AFreeThread: Boolean; const AMethod: TRESTRequestMethod = TRESTRequestMethod.rmPOST;
      AOnComplete: TOnExecRequest = nil; AOnError: TOnExecRequest = nil): TRESTExecThread; overload;

    function Get: IResponse; overload;
    procedure GetAsync(AOnComplete: TOnExecRequest = nil); overload;

    function Post: IResponse; overload;
    function Post(const AContent: TObject; const AOwns: Boolean = True): IResponse; overload;
    procedure PostAsync(AOnComplete: TOnExecRequest = nil); overload;

    function Put: IResponse; overload;
    function Put(const AContent: TObject; const AOwns: Boolean = True): IResponse; overload;
    procedure PutAsync(AOnComplete: TOnExecRequest = nil); overload;

    function Delete: IResponse; overload;
    function Delete(const AId: string): IResponse; overload;
    function Delete(const AContent: TObject; const AOwns: Boolean = True): IResponse; overload;
    procedure DeleteAsync(AOnComplete: TOnExecRequest = nil); overload;

    function Patch: IResponse; overload;
  protected
    FRESTRequest: TRESTRequest;
    FRESTResponse: TRESTResponse;
    FRESTClient: Rest.Client.TRestClient;
    FHTTPBasicAuthenticator: THTTPBasicAuthenticator;
  protected
    procedure DoAfterExecute(Sender: TCustomRESTRequest); virtual;
    procedure DoBeforeExecute(Sender: TCustomRESTRequest); virtual;
    procedure DoHTTPProtocolError(Sender: TCustomRESTRequest); virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    class function New: IRequest; virtual;
  end; 

implementation

uses
  System.StrUtils, Winapi.Windows, System.Net.HttpClient;

{ TRESTListener }

function TRESTListener.Events: TSetListenerEvent;
begin
  Result := [leBeforeExecute, leAfterExecute, leHttpError];
end;

procedure TRESTListener.Execute(Sender: TRESTRequest; const AEvent: TListenerEvent);
begin
  // virtual;
end;

{ TResponse }

constructor TResponse.Create(const ARESTResponse: TRESTResponse);
begin
  FRESTResponse := ARESTResponse;
end;

destructor TResponse.Destroy;
begin
  if Assigned(FStreamValue) then
    FreeAndNil(FStreamValue);

  if Assigned(FJsonValue) then
    FreeAndNil(FJsonValue);

  if Assigned(FJsonArray) then
    FreeAndNil(FJsonArray);

  inherited;
end;

procedure TResponse.FillResults;
begin
  AsJSON;
  AsJSONArray;
end;

function TResponse.AsString: string;
begin
  Result := FRESTResponse.Content;
end;

function TResponse.Header(const AName: string): string;
var
  Idx: Integer;
begin
  Idx := FRESTResponse.Headers.IndexOfName(AName);
  if Idx = -1 then
    Exit('');

  Result := FRESTResponse.Headers.Strings[Idx].Split(['='])[1];
end;

function TResponse.Headers: TStrings;
begin
  Result := FRESTResponse.Headers;
end;

function TResponse.ContentEncoding: string;
begin
  Result := FRESTResponse.ContentEncoding;
end;

function TResponse.ContentLength: Cardinal;
begin
  Result := FRESTResponse.ContentLength;
end;

function TResponse.AsStream: TStream;
begin
  if Assigned(FStreamValue) then
    FreeAndNil(FStreamValue);
  FStreamValue := TMemoryStream.Create;
  if (Length(FRESTResponse.RawBytes) > 0) then
    FStreamValue.WriteBuffer(FRESTResponse.RawBytes[0], Length(FRESTResponse.RawBytes));
  Result := FStreamValue;
  Result.Position := 0;
end;

function TResponse.ContentType: string;
begin
  Result := FRESTResponse.ContentType;
end;

function TResponse.AsJSON: TJSONValue;
begin
  if Assigned(FJsonValue) then
    Exit(FJsonValue);

  if Assigned(FRESTResponse.JSONValue) then
    FJsonValue := TJSONObject.ParseJSONValue(FRESTResponse.JSONValue.ToJSON)
  Else
    FJsonValue := TJSONNull.Create;

  Result := FJsonValue;
end;

function TResponse.AsJSONArray: TJSONArray;
begin
  if Assigned(FJsonArray) then
    Exit(FJsonArray);

  if FRESTResponse.Content.StartsWith('[{') then
    FJsonArray := TJSONObject.ParseJSONValue(FRESTResponse.Content) as TJSONArray
  else
    FJsonArray := TJSONObject.ParseJSONValue(format('{[%s]}', [FRESTResponse.Content])) as TJSONArray;

  Result := FJsonArray;
end;

function TResponse.AsBytes: TBytes;
begin
  Result := FRESTResponse.RawBytes;
end;

function TResponse.StatusCode: Integer;
begin
  Result := FRESTResponse.StatusCode;
end;

{ TRESTListeners }

class procedure TRESTListeners.ExecuteAll(Sender: TRESTRequest; const AEvent: TListenerEvent);
var
  Current: TRESTListener;
begin
  if Assigned(FList) then
    for Current in FList.ToArray do
    begin
      if AEvent in Current.Events then
        Current.Execute(Sender, AEvent);
    end;
end;

class procedure TRESTListeners.Register(Clas: TRESTListenerClass);
begin
  if not Assigned(FList) then
    FList := TObjectList<TRESTListener>.Create;

  FList.Add(Clas.Create);
end;

{ TRESTExecThread }

constructor TRESTExecThread.Create(ARequest: TCustomRESTRequest;
  AOnComplete: TOnExecRequest; ASynchronized, AFreeThread: Boolean; AOnError: TOnExecRequest);
begin
  inherited Create(False);
  FreeOnTerminate := AFreeThread;
  FCompleteHandler := AOnComplete;
  FSynchronized := ASynchronized;
  FRequest := ARequest;
  FErrorHandler := AOnError;
end;

procedure TRESTExecThread.Execute;
begin
  try
    FResponse := TResponse.Create(TRESTResponse(FRequest.Response));
    FRequest.Execute;
    if FSynchronized then
      Synchronize(HandleCompletion)
    else
      HandleCompletion;
  except
    if Assigned(FErrorHandler) then
      try
        if FSynchronized then
          Synchronize(HandleCompletionWithError)
        else
          HandleCompletionWithError;
      except
      end;
  end;
end;

procedure TRESTExecThread.HandleCompletion;
begin
  if Assigned(FCompleteHandler) then
    FCompleteHandler(FResponse);
end;

procedure TRESTExecThread.HandleCompletionWithError;
begin
  if Assigned(FErrorHandler) then
    FErrorHandler(FResponse);
end;

{ TRestClient }

function IfThenOwn(const AOwn: Boolean): TRESTObjectOwnership;
begin
  if AOwn then
    Result := ooREST
  else
    Result := ooApp;
end;

function TRestClient.Accept(const AAccept: string): IRequest;
begin
  Result := Self;
  FRESTRequest.Accept := AAccept;
end;

function TRestClient.AcceptCharset(const AAcceptCharset: string): IRequest;
begin
  Result := Self;
  FRESTRequest.AcceptCharset := AAcceptCharset;
end;

function TRestClient.AcceptEncoding(const AAcceptEncoding: string): IRequest;
begin
  Result := Self;
  FRESTRequest.AcceptEncoding := AAcceptEncoding;
end;

function TRestClient.AddBody(const AContent: TObject; const AOwns: Boolean): IRequest;
begin
  Result := Self;
  FRESTRequest.Body.Add(AContent, IfThenOwn(AOwns));
end;

function TRestClient.AddBody(const AContent: TJSONObject; const AOwns: Boolean): IRequest;
begin
  Result := Self;
  FRESTRequest.Body.Add(AContent, IfThenOwn(AOwns));
end;

function TRestClient.AddBodyJson(const AContent: TObject; const AOwns: Boolean): IRequest;
const
  JSON_OPTIONS = [joIgnoreEmptyStrings, joDateIsUTC, joDateFormatISO8601];
begin
  Result := Self;
  FRESTRequest.Body.Add(TJson.ObjectToJsonString(AContent, JSON_OPTIONS), ctAPPLICATION_JSON);
  if AOwns then
    AContent.Free;
end;

function TRestClient.AddBody(const AContent: string; const AContentType: TRESTContentType): IRequest;
begin
  Result := Self;
  FRESTRequest.Body.Add(AContent, AContentType);
end;

function TRestClient.AddAuthParameter(const AUsername, APassword: String): IRequest;
begin
  if not Assigned(FHTTPBasicAuthenticator) then
    FHTTPBasicAuthenticator := THTTPBasicAuthenticator.Create(nil);

  FRESTClient.Authenticator := FHTTPBasicAuthenticator;
  FHTTPBasicAuthenticator.Username := AUsername;
  FHTTPBasicAuthenticator.Password := APassword;

  Result := Self;
end;

function TRestClient.AddBody(const AContent: TStream; const AOwns: Boolean): IRequest;
begin
  Result := Self;
  FRESTRequest.Body.Add(AContent);
  if AOwns then
    AContent.Free;
end;

function TRestClient.AddHeader(const AName, AValue: string; const AOptions: TParamsOptions): IRequest;
begin
  Result := Self;
  if AName.Trim.IsEmpty or AValue.Trim.IsEmpty then
    Exit;
  FRESTRequest.Params.AddHeader(AName, AValue);
  FRESTRequest.Params.ParameterByName(AName).Options := AOptions;
end;

function TRestClient.AddParameter(const AName, AValue: string; AKind: TRESTRequestParameterKind;
  AOptions: TRESTRequestParameterOptions): IRequest;
begin
  Result := Self;
  FRESTRequest.AddParameter(AName, AValue, AKind, AOptions);
end;

function TRestClient.AddProxy(const AServer: string; const APort: Integer; const APassword, AUsername: string): IRequest;
begin
  Result := Self;
  FRESTClient.ProxyPassword := APassword;
  FRESTClient.ProxyServer := AServer;
  FRESTClient.ProxyUsername := AUsername;
  FRESTClient.ProxyPort := APort;
end;

function TRestClient.AddQuery(const AName, AValue: string): IRequest;
begin
  Result := Self;
  FRESTRequest.AddParameter(AName, AValue, pkQUERY);
end;

function TRestClient.BaseURL(const ABaseURL: string): IRequest;
begin
  Result := Self;
  FRESTClient.BaseURL := ABaseURL;
end;

function TRestClient.ContentType(const AContentType: string): IRequest;
begin
  Result := Self;
  FRESTClient.ContentType := AContentType;
end;

constructor TRestClient.Create;
begin
  FRESTResponse := TRESTResponse.Create(nil);
  FRESTClient := Rest.Client.TRestClient.Create(nil);
  FRESTClient.Authenticator := nil;
  FRESTRequest := TRESTRequest.Create(nil);

  FResponse := TResponse.Create(FRESTResponse);

  FRESTRequest.OnAfterExecute := DoAfterExecute;
  FRESTRequest.OnHTTPProtocolError := DoHTTPProtocolError;
  FRESTRequest.Client := FRESTClient;
  FRESTRequest.Response := FRESTResponse;

  FRESTClient.RaiseExceptionOn500 := False;
  FRESTClient.Accept := '*/*';
  FRESTClient.ContentType := 'application/json';
  FRESTClient.SecureProtocols := [THTTPSecureProtocol.TLS12, THTTPSecureProtocol.TLS13];
end;

function TRestClient.DataSetAdapter(const ADataSet: TDataSet): IRequest;
begin
  Result := Self;
  FDataSetAdapter := ADataSet;
end;

destructor TRestClient.Destroy;
begin
  if Assigned(FHTTPBasicAuthenticator) then
    FreeAndNil(FHTTPBasicAuthenticator);

  FreeAndNil(FRESTRequest);
  FreeAndNil(FRESTClient);
  FreeAndNil(FRESTResponse);
  inherited;
end;

procedure TRestClient.InternalDestroy(Sender: TObject);
begin
  Destroy;
end;

class function TRestClient.New: IRequest;
begin
  Result := TRestClient.Create;
end;

procedure TRestClient.DoAfterExecute(Sender: TCustomRESTRequest);
begin
  TRESTListeners.ExecuteAll(FRESTRequest, leAfterExecute);
  TResponse(FResponse).FillResults;
end;

procedure TRestClient.DoBeforeExecute(Sender: TCustomRESTRequest);
begin
  TRESTListeners.ExecuteAll(FRESTRequest, leBeforeExecute);
end;

procedure TRestClient.DoHTTPProtocolError(Sender: TCustomRESTRequest);
begin
  TRESTListeners.ExecuteAll(FRESTRequest, leHttpError);
end;

function TRestClient.Async(const AFreeThread: Boolean; const AMethod: TRESTRequestMethod; AOnComplete,
  AOnError: TOnExecRequest): TRESTExecThread;
begin
  FIsAsync := True;
  FRESTRequest.Method := AMethod;
  DoBeforeExecute(FRESTRequest);
  Result := TRESTExecThread.Create(FRESTRequest, AOnComplete, True, AFreeThread, AOnError);
  Result.OnTerminate := InternalDestroy;
end;

procedure TRestClient.Async(const AMethod: TRESTRequestMethod; AOnComplete: TOnExecRequest; AOnError: TOnExecRequest);
var
  Thread: TRESTExecThread;
begin
  FIsAsync := True;
  FRESTRequest.Method := AMethod;
  DoBeforeExecute(FRESTRequest);
  Thread := TRESTExecThread.Create(FRESTRequest, AOnComplete, True, True, AOnError);
  Thread.OnTerminate := InternalDestroy;
end;

function TRestClient.Get: IResponse;
begin
  Result := FResponse;
  FRESTRequest.Method := TRESTRequestMethod.rmGET;
  DoBeforeExecute(FRESTRequest);
  FRESTRequest.Execute;
end;

procedure TRestClient.GetAsync(AOnComplete: TOnExecRequest);
begin
  Async(TRESTRequestMethod.rmGET, AOnComplete);
end;

function TRestClient.Delete: IResponse;
begin
  Result := FResponse;
  FRESTRequest.Method := TRESTRequestMethod.rmDELETE;
  DoBeforeExecute(FRESTRequest);
  FRESTRequest.Execute;
end;

function TRestClient.Delete(const AId: string): IResponse;
begin
  FRESTRequest.ResourceSuffix := AId;
  Result := Delete;
end;

function TRestClient.Delete(const AContent: TObject; const AOwns: Boolean = True): IResponse;
begin
  Result := AddBodyJson(AContent, AOwns).Delete;
end;

procedure TRestClient.DeleteAsync(AOnComplete: TOnExecRequest);
begin
  Async(TRESTRequestMethod.rmDELETE, AOnComplete);
end;

function TRestClient.Patch: IResponse;
begin
  Result := FResponse;
  FRESTRequest.Method := TRESTRequestMethod.rmPATCH;
  DoBeforeExecute(FRESTRequest);
  FRESTRequest.Execute;
end;

function TRestClient.Post(const AContent: TObject; const AOwns: Boolean): IResponse;
begin
  Result := AddBodyJson(AContent, AOwns).Post;
end;

procedure TRestClient.PostAsync(AOnComplete: TOnExecRequest);
begin
  Async(TRESTRequestMethod.rmPOST, AOnComplete);
end;

function TRestClient.Post: IResponse;
begin
  Result := FResponse;
  FRESTRequest.Method := TRESTRequestMethod.rmPOST;
  DoBeforeExecute(FRESTRequest);
  FRESTRequest.Execute;
end;

function TRestClient.Put: IResponse;
begin
  Result := FResponse;
  FRESTRequest.Method := TRESTRequestMethod.rmPUT;
  DoBeforeExecute(FRESTRequest);
  FRESTRequest.Execute;
end;

function TRestClient.Put(const AContent: TObject; const AOwns: Boolean): IResponse;
begin
  Result := AddBodyJson(AContent, AOwns).Put;
end;

procedure TRestClient.PutAsync(AOnComplete: TOnExecRequest);
begin
  Async(TRESTRequestMethod.rmPUT, AOnComplete);
end;

function TRestClient.RaiseExceptionOn500(const ARaiseException: Boolean): IRequest;
begin
  FRESTClient.RaiseExceptionOn500 := ARaiseException;
end;

function TRestClient.Resource(const AResource: string): IRequest;
begin
  Result := Self;
  FRESTRequest.Resource := FRESTRequest.Resource +
    IfThen(FRESTRequest.Resource.IsEmpty or FRESTRequest.Resource.EndsWith('/'), AResource, '/' + AResource);
end;

function TRestClient.ResourceSuffix(const AResourceSuffix: string): IRequest;
begin
  Result := Self;
  FRESTRequest.ResourceSuffix := AResourceSuffix;
end;

function TRestClient.Timeout(const ATimeout: Integer): IRequest;
begin
  Result := Self;
  FRESTRequest.Timeout := ATimeout;
end;

function TRestClient.Token(const AToken: string): IRequest;
const
  AUTHORIZATION = 'Authorization';
begin
  Result := Self;
  FRESTRequest.Params.AddHeader(AUTHORIZATION, 'Bearer ' + AToken);
  FRESTRequest.Params.ParameterByName(AUTHORIZATION).Options := [poDoNotEncode];
end;

function TRestClient.UserAgent(const AName: string): IRequest;
begin
  Result := Self;
  FRESTRequest.Client.UserAgent := AName;
end;

function TRestClient.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TRestClient._AddRef: Integer;
begin
  Result := InterlockedIncrement(FRefCount);
end;

function TRestClient._Release: Integer;
begin
  Result := InterlockedDecrement(FRefCount);
  if (Result = 0) and not FIsAsync then
    Destroy;
end;

end.
