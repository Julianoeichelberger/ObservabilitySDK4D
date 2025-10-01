program Elastic;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  System.SysUtils,
  Observability.SDK in '..\..\source\core\Observability.SDK.pas',
  Observability.Config in '..\..\source\core\Observability.Config.pas',
  Observability.Interfaces in '..\..\source\core\Observability.Interfaces.pas',
  Observability.Context in '..\..\source\core\Observability.Context.pas',
  Observability.Provider.Base in '..\..\source\core\Observability.Provider.Base.pas',
  Observability.SystemMetrics in '..\..\source\core\Observability.SystemMetrics.pas',
  Observability.Utils in '..\..\source\core\Observability.Utils.pas',
  Observability.HttpClient in '..\..\source\core\Observability.HttpClient.pas',
  Observability.Provider.Elastic in '..\..\source\providers\Observability.Provider.Elastic.pas';

var
  Config: IObservabilityConfig;
  Provider: IObservabilityProvider;

begin
  try
    Writeln('=== Elastic APM Test - ObservabilitySDK4D ===');
    Writeln('Testing with latest corrections...');
    Writeln;

    // Create and configure Elastic APM
    Config := TObservability.CreateElasticConfig;
    Config.ServiceName := 'elastic-console-test';
    Config.ServiceVersion := '1.0.0';
    Config.Environment := 'development';
    Config.ServerUrl := 'http://localhost:8200';

    Provider := TElasticAPMProvider.Create;
    Provider.Configure(Config);

    TObservability.RegisterProvider(Provider);
    TObservability.SetActiveProvider(opElastic);

    var GlobalContext := TObservabilityContext.CreateNew;
    GlobalContext.ServiceName := 'elastic-console-test';
    GlobalContext.ServiceVersion := '1.0.0';
    GlobalContext.Environment := 'development';
    GlobalContext.UserName := 'PC 1';

    TObservability.SetGlobalContext(GlobalContext);

    // Initialize before creating spans
    TObservability.Initialize;
    TObservability.EnableSystemMetrics;

    // Create transaction using the new API
    TObservability.StartTransaction('HTTP Request', 'request');

    try
      Sleep(100);
      TObservability.StartSpan('Database Query');
      Sleep(500);
      TObservability.FinishSpan; // Finish Database Query span

      Sleep(2000);
      TObservability.StartSpan('External API Call');
      Sleep(150);
      TObservability.StartSpan('Authentication');
      Sleep(800);
      TObservability.FinishSpan; // Finish Authentication span
      TObservability.FinishSpan; // Finish External API Call span 
    except
      on E: Exception do
      begin
        Writeln('Exception in span: ' + E.Message);
        TObservability.FinishTransactionWithOutcome(Failure);
        Exit;
      end;
    end;
    
    // Finish the main transaction
    TObservability.FinishTransaction;
    Sleep(2000);

    TObservability.Shutdown;
    Writeln('Press Enter to exit...');
    Readln;

  except
    on E: Exception do
    begin
      Writeln('Fatal error: ' + E.ClassName + ': ' + E.Message);
      Writeln('Press Enter to exit...');
      Readln;
    end;
  end;

end.
