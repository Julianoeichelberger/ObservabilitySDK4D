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
unit Observability.Config;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs,
  Observability.Interfaces;

type
  TObservabilityConfig = class(TInterfacedObject, IObservabilityConfig)
  private
    FServiceName: string;
    FServiceVersion: string;
    FEnvironment: string;
    FServerUrl: string;
    FApiKey: string;
    FSampleRate: Double;
    FBatchSize: Integer;
    FFlushInterval: Integer;
    FEnabled: Boolean;
    FProviderType: TObservabilityProvider;
    FSupportedTypes: TObservabilityTypeSet;
    FCustomProperties: TDictionary<string, string>;
    FLock: TCriticalSection;
  protected
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
  public
    constructor Create;
    destructor Destroy; override;
    
    // Factory methods for different providers
    class function CreateElasticConfig: IObservabilityConfig; static;
    class function CreateJaegerConfig: IObservabilityConfig; static;
    class function CreateSentryConfig: IObservabilityConfig; static;
    class function CreateDatadogConfig: IObservabilityConfig; static;
    class function CreateConsoleConfig: IObservabilityConfig; static;
    class function CreateTextFileConfig: IObservabilityConfig; static;
  end;

implementation

{ TObservabilityConfig }

constructor TObservabilityConfig.Create;
begin
  inherited Create;
  FCustomProperties := TDictionary<string, string>.Create;
  FLock := TCriticalSection.Create;
  
  // Default values
  FSampleRate := 1.0;
  FBatchSize := 50;
  FFlushInterval := 30000; // 30 seconds
  FEnabled := True;
  FProviderType := opElastic;
  FSupportedTypes := [otAll];
  FEnvironment := 'development';
end;

destructor TObservabilityConfig.Destroy;
begin
  FCustomProperties.Free;
  FLock.Free;
  inherited Destroy;
end;

class function TObservabilityConfig.CreateElasticConfig: IObservabilityConfig;
var
  Config: TObservabilityConfig;
begin
  Config := TObservabilityConfig.Create;
  Config.FProviderType := opElastic;
  Config.FServerUrl := 'http://localhost:8200';
  Config.FSupportedTypes := [otTracing, otLogging, otMetrics];
  Result := Config;
end;

class function TObservabilityConfig.CreateJaegerConfig: IObservabilityConfig;
var
  Config: TObservabilityConfig;
begin
  Config := TObservabilityConfig.Create;
  Config.FProviderType := opJaeger;
  Config.FServerUrl := 'http://localhost:14268/api/traces';
  Config.FSupportedTypes := [otTracing];
  Result := Config;
end;

class function TObservabilityConfig.CreateSentryConfig: IObservabilityConfig;
var
  Config: TObservabilityConfig;
begin
  Config := TObservabilityConfig.Create;
  Config.FProviderType := opSentry;
  Config.FServerUrl := ''; // DSN deve ser fornecido pelo usuário
  Config.FSupportedTypes := [otTracing, otLogging];
  Result := Config;
end;

class function TObservabilityConfig.CreateDatadogConfig: IObservabilityConfig;
var
  Config: TObservabilityConfig;
begin
  Config := TObservabilityConfig.Create;
  Config.FProviderType := opDatadog;
  Config.FServerUrl := 'https://api.datadoghq.com';
  Config.FSupportedTypes := [otTracing, otLogging, otMetrics];
  Result := Config;
end;

class function TObservabilityConfig.CreateConsoleConfig: IObservabilityConfig;
var
  Config: TObservabilityConfig;
begin
  Config := TObservabilityConfig.Create;
  Config.FProviderType := opConsole;
  Config.FServerUrl := '';
  Config.FSupportedTypes := [otTracing, otLogging, otMetrics];
  Result := Config;
end;

class function TObservabilityConfig.CreateTextFileConfig: IObservabilityConfig;
var
  Config: TObservabilityConfig;
begin
  Config := TObservabilityConfig.Create;
  Config.FProviderType := opCustom; // Usaremos Custom já que não temos opTextFile
  Config.FServerUrl := '';
  Config.FSupportedTypes := [otTracing, otLogging, otMetrics];
  
  // Configurações padrão para TextFile
  Config.AddCustomProperty('base_directory', ''); // Será definido pelo provider
  Config.AddCustomProperty('rotate_daily', 'true');
  Config.AddCustomProperty('max_file_size_mb', '100');
  Config.AddCustomProperty('use_json', 'true');
  Config.AddCustomProperty('include_timestamp', 'true');
  
  Result := Config;
end;

function TObservabilityConfig.GetServiceName: string;
begin
  FLock.Enter;
  try
    Result := FServiceName;
  finally
    FLock.Leave;
  end;
end;

function TObservabilityConfig.GetServiceVersion: string;
begin
  FLock.Enter;
  try
    Result := FServiceVersion;
  finally
    FLock.Leave;
  end;
end;

function TObservabilityConfig.GetEnvironment: string;
begin
  FLock.Enter;
  try
    Result := FEnvironment;
  finally
    FLock.Leave;
  end;
end;

function TObservabilityConfig.GetServerUrl: string;
begin
  FLock.Enter;
  try
    Result := FServerUrl;
  finally
    FLock.Leave;
  end;
end;

function TObservabilityConfig.GetApiKey: string;
begin
  FLock.Enter;
  try
    Result := FApiKey;
  finally
    FLock.Leave;
  end;
end;

function TObservabilityConfig.GetSampleRate: Double;
begin
  FLock.Enter;
  try
    Result := FSampleRate;
  finally
    FLock.Leave;
  end;
end;

function TObservabilityConfig.GetBatchSize: Integer;
begin
  FLock.Enter;
  try
    Result := FBatchSize;
  finally
    FLock.Leave;
  end;
end;

function TObservabilityConfig.GetFlushInterval: Integer;
begin
  FLock.Enter;
  try
    Result := FFlushInterval;
  finally
    FLock.Leave;
  end;
end;

function TObservabilityConfig.GetEnabled: Boolean;
begin
  FLock.Enter;
  try
    Result := FEnabled;
  finally
    FLock.Leave;
  end;
end;

function TObservabilityConfig.GetProviderType: TObservabilityProvider;
begin
  FLock.Enter;
  try
    Result := FProviderType;
  finally
    FLock.Leave;
  end;
end;

function TObservabilityConfig.GetSupportedTypes: TObservabilityTypeSet;
begin
  FLock.Enter;
  try
    Result := FSupportedTypes;
  finally
    FLock.Leave;
  end;
end;

function TObservabilityConfig.GetCustomProperties: TDictionary<string, string>;
begin
  FLock.Enter;
  try
    Result := FCustomProperties;
  finally
    FLock.Leave;
  end;
end;

procedure TObservabilityConfig.SetServiceName(const Value: string);
begin
  FLock.Enter;
  try
    FServiceName := Value;
  finally
    FLock.Leave;
  end;
end;

procedure TObservabilityConfig.SetServiceVersion(const Value: string);
begin
  FLock.Enter;
  try
    FServiceVersion := Value;
  finally
    FLock.Leave;
  end;
end;

procedure TObservabilityConfig.SetEnvironment(const Value: string);
begin
  FLock.Enter;
  try
    FEnvironment := Value;
  finally
    FLock.Leave;
  end;
end;

procedure TObservabilityConfig.SetServerUrl(const Value: string);
begin
  FLock.Enter;
  try
    FServerUrl := Value;
  finally
    FLock.Leave;
  end;
end;

procedure TObservabilityConfig.SetApiKey(const Value: string);
begin
  FLock.Enter;
  try
    FApiKey := Value;
  finally
    FLock.Leave;
  end;
end;

procedure TObservabilityConfig.SetSampleRate(const Value: Double);
begin
  FLock.Enter;
  try
    if (Value >= 0.0) and (Value <= 1.0) then
      FSampleRate := Value;
  finally
    FLock.Leave;
  end;
end;

procedure TObservabilityConfig.SetBatchSize(const Value: Integer);
begin
  FLock.Enter;
  try
    if Value > 0 then
      FBatchSize := Value;
  finally
    FLock.Leave;
  end;
end;

procedure TObservabilityConfig.SetFlushInterval(const Value: Integer);
begin
  FLock.Enter;
  try
    if Value > 0 then
      FFlushInterval := Value;
  finally
    FLock.Leave;
  end;
end;

procedure TObservabilityConfig.SetEnabled(const Value: Boolean);
begin
  FLock.Enter;
  try
    FEnabled := Value;
  finally
    FLock.Leave;
  end;
end;

procedure TObservabilityConfig.SetProviderType(const Value: TObservabilityProvider);
begin
  FLock.Enter;
  try
    FProviderType := Value;
  finally
    FLock.Leave;
  end;
end;

procedure TObservabilityConfig.SetSupportedTypes(const Value: TObservabilityTypeSet);
begin
  FLock.Enter;
  try
    FSupportedTypes := Value;
  finally
    FLock.Leave;
  end;
end;

procedure TObservabilityConfig.AddCustomProperty(const Key, Value: string);
begin
  FLock.Enter;
  try
    FCustomProperties.AddOrSetValue(Key, Value);
  finally
    FLock.Leave;
  end;
end;

end.