# ObservabilitySDK4D - Documenta��o Completa

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Delphi](https://img.shields.io/badge/Delphi-10.3%2B-red.svg)](https://www.embarcadero.com/products/delphi)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-blue.svg)](https://github.com/Julianoeichelberger/ObservabilitySDK4D)

> Framework abrangente de **Monitoramento de Performance de Aplica��o (APM)** e **Observabilidade** para aplica��es Delphi com suporte a rastreamento distribu�do, coleta de m�tricas e logging estruturado.

## ?? �ndice

- [?? Vis�o Geral](#-vis�o-geral)
- [??? Arquitetura](#?-arquitetura)
- [?? In�cio R�pido](#-in�cio-r�pido)
- [?? Conceitos Fundamentais](#-conceitos-fundamentais)
- [?? Provedores Suportados](#-provedores-suportados)
- [?? Sistema de M�tricas](#-sistema-de-m�tricas)
- [?? Rastreamento Distribu�do](#-rastreamento-distribu�do)
- [?? Logging Estruturado](#-logging-estruturado)
- [?? Configura��o Avan�ada](#?-configura��o-avan�ada)
- [?? Exemplos Pr�ticos](#-exemplos-pr�ticos)
- [??? Instala��o](#?-instala��o)
- [?? Refer�ncia da API](#-refer�ncia-da-api)
- [?? Contribuindo](#-contribuindo)

## ?? Vis�o Geral

O **ObservabilitySDK4D** � um framework moderno de observabilidade para Delphi que permite monitorar, rastrear e analisar o desempenho de suas aplica��es em tempo real. Com suporte a m�ltiplos provedores e uma API unificada, voc� pode facilmente integrar observabilidade completa em seus projetos Delphi.

### ? Caracter�sticas Principais

- **?? Suporte Multi-Provedor**: Elastic APM, Jaeger, Sentry, Datadog, Console
- **?? Observabilidade Completa**: Rastreamento, M�tricas e Logging em um SDK
- **?? Rastreamento Distribu�do**: Acompanhe requisi��es atrav�s de microsservi�os
- **? Zero Configura��o**: Funciona imediatamente com configura��es padr�o sensatas
- **?? Thread-Safe**: Pronto para produ��o com gerenciamento autom�tico de recursos
- **?? Auto-M�tricas**: Coleta autom�tica de m�tricas do sistema (CPU, Mem�ria, GC)

### ?? Benef�cios

1. **Visibilidade Completa**: Veja exatamente como sua aplica��o est� performando
2. **Detec��o R�pida de Problemas**: Identifique gargalos e erros em tempo real
3. **An�lise de Desempenho**: Entenda padr�es de uso e otimize performance
4. **Correla��o de Dados**: Conecte logs, m�tricas e traces para investiga��o completa
5. **Monitoramento Proativo**: Receba alertas antes que problemas afetem usu�rios

## ??? Arquitetura

### ??? Vis�o Geral da Arquitetura

```
???????????????????????????????????????????????????????????
?              TObservability (API Est�tica)              ?
???????????????????????????????????????????????????????????
? ??????????????? ??????????????? ??????????????????????? ?
? ? Rastreamento? ?   M�tricas  ? ?      Logging        ? ?
? ?    (APM)    ? ?   Coleta    ? ?   (Estruturado)     ? ?
? ??????????????? ??????????????? ??????????????????????? ?
???????????????????????????????????????????????????????????
                              ?
???????????????????????????????????????????????????????????
?             Camada de Abstra��o de Provedores           ?
???????????????????????????????????????????????????????????
                              ?
???????????????????????????????????????????????????????????
? ?? Elastic  ??? Jaeger  ??? Sentry  ?? Datadog  ?? Console ?
???????????????????????????????????????????????????????????
```

### ?? Fluxo de Dados

```
C�digo da Aplica��o
        ?
    ?????????      ???????????????      ????????????????
    ? Criar ?      ?   Pilha     ?      ?   Provedor   ?
    ? Span  ? ???? ?    de       ? ???? ?  (Elastic/   ? ???? Servidor APM
    ?       ?      ?   Spans     ?      ?   Jaeger)    ?
    ?????????      ???????????????      ????????????????
        ?                  ?                     ?
    ?????????      ???????????????      ????????????????
    ?Finalizar      ? Propaga��o  ?      ?   Coleta     ?
    ? Span  ?      ? Contexto    ?      ? M�tricas     ? ???? Armazenamento
    ?????????      ???????????????      ????????????????
```

## ?? In�cio R�pido

### 1. Configura��o B�sica (30 segundos)

```pascal
program MeuApp;
uses
  Observability.SDK,
  Observability.Provider.Console;

begin
  // Inicializar ObservabilitySDK4D
  TObservability.Initialize;
  TObservability.RegisterProvider(TConsoleProvider.Create);
  TObservability.SetActiveProvider(opConsole);
  
  // Come�ar a rastrear sua aplica��o
  var Span := TObservability.StartSpan('operacao-usuario');
  try
    Span.SetAttribute('user.id', '12345');
    Span.SetAttribute('operacao', 'login');
    
    // Sua l�gica de neg�cio aqui
    ProcessarLogin();
    
    Span.SetOutcome(Success);
  finally
    Span.Finish;
  end;
  
  TObservability.Shutdown;
end.
```

### 2. Uso Avan�ado com M�tricas Personalizadas

```pascal
// Iniciar uma transa��o
TObservability.StartTransaction('Cadastro de Usuario', 'requisicao');

try
  // Criar spans aninhados
  TObservability.StartSpan('Validar Entrada');
  ValidarDadosUsuario();
  TObservability.FinishSpan;
  
  TObservability.StartSpan('Inserir no Banco');
  SalvarUsuarioNoBanco();
  TObservability.FinishSpan;
  
  // M�tricas personalizadas
  TObservability.Metrics.Counter('usuarios.cadastrados', 1);
  TObservability.Metrics.Gauge('banco.conexoes_ativas', GetConexoesAtivas());
  
  TObservability.FinishTransaction;
except
  on E: Exception do
  begin
    TObservability.RecordSpanException(E);
    TObservability.FinishTransactionWithOutcome(Failure);
  end;
end;
```

## ?? Conceitos Fundamentais

### ?? **APM (Application Performance Monitoring)**
Monitoramento de performance da aplica��o, tempos de resposta, throughput e taxas de erro em tempo real.

**Benef�cios:**
- Detec��o proativa de problemas de performance
- An�lise de gargalos em tempo real
- M�tricas de disponibilidade e confiabilidade
- Insights sobre comportamento do usu�rio

### ?? **Rastreamento Distribu�do (Distributed Tracing)**
Rastreie requisi��es conforme elas fluem atrav�s de m�ltiplos servi�os, criando uma vis�o completa do comportamento do sistema.

**Conceitos-chave:**
- **Trace**: Jornada completa de uma requisi��o
- **Span**: Unidade individual de trabalho dentro de um trace
- **Context**: Informa��es que conectam spans relacionados

### ?? **Compatibilidade OpenTelemetry**
Constru�do seguindo os princ�pios do OpenTelemetry para observabilidade vendor-neutral.

**Vantagens:**
- Padr�o da ind�stria para observabilidade
- Interoperabilidade entre diferentes ferramentas
- Futuro-prova para mudan�as de provedor

### ?? **Coleta de M�tricas**

#### **Contadores (Counters)**
Valores cumulativos que s� aumentam (requisi��es, erros):
```pascal
TObservability.Metrics.Counter('http.requisicoes.total', 1);
TObservability.Metrics.Counter('cache.hits', 1);
```

#### **Medidores (Gauges)**
Valores instant�neos que podem subir e descer (mem�ria, conex�es):
```pascal
TObservability.Metrics.Gauge('memoria.uso.bytes', GetUsoMemoria);
TObservability.Metrics.Gauge('conexoes.ativas', GetConexoesAtivas);
```

#### **Histogramas**
Distribui��o de valores (tempos de resposta):
```pascal
TObservability.Metrics.Histogram('tempo.resposta.ms', TempoResposta);
TObservability.Metrics.Histogram('tamanho.payload.bytes', TamanhoPayload);
```

### ?? **Logging Estruturado**
Logs ricos e pesquis�veis com contexto e correla��o atrav�s de sistemas distribu�dos.

**Caracter�sticas:**
- Logs estruturados em JSON
- Correla��o autom�tica com traces
- M�ltiplos n�veis de log (DEBUG, INFO, WARN, ERROR)
- Atributos personalizados e contexto

## ?? Provedores Suportados

### ?? Matriz de Suporte

| Provedor | Rastreamento | M�tricas | Logging | Rastreamento de Erros | Status |
|----------|--------------|----------|---------|----------------------|--------|
| **?? Elastic APM** | ? | ? | ? | ? | ?? Pronto para Produ��o |
| **??? Jaeger** | ? | ? | ? | ? | ?? Pronto para Produ��o |
| **??? Sentry** | ? | ?* | ? | ? | ?? Pronto para Produ��o |
| **?? Datadog** | ? | ? | ? | ? | ?? Pronto para Produ��o |
| **?? Console** | ? | ? | ? | ? | ?? Desenvolvimento |
| **?? TextFile** | ? | ? | ? | ? | ?? Desenvolvimento |

> *M�tricas Sentry n�o s�o suportadas nativamente pela plataforma Sentry

### ?? **Elastic APM Provider**

**Caracter�sticas Completas:**
- ? Protocolo APM 8.x completo
- ? Transa��es, spans e m�tricas
- ? Formato de lote NDJSON
- ? Correla��o autom�tica pai-filho
- ? Coleta de m�tricas do sistema

**Configura��o:**
```pascal
var Config := TObservability.CreateElasticConfig;
Config.ServerUrl := 'http://localhost:8200';
Config.SecretToken := 'seu-token';
Config.ServiceName := 'meu-app';
Config.Environment := 'producao';

var Provider := TElasticAPMProvider.Create;
Provider.Configure(Config);
TObservability.RegisterProvider(Provider);
TObservability.SetActiveProvider(opElastic);
```

**Exemplo de Uso:**
```pascal
// Amostras e exemplos completos dispon�veis em /Samples/Elastic
docker-compose up -d  // Inicia Elasticsearch + Kibana + APM Server
```

### ??? **Jaeger Provider**

**Caracter�sticas:**
- ? Protocolo OpenTelemetry (OTLP)
- ? Rastreamento distribu�do completo
- ? Correla��o de contexto B3/W3C
- ? M�tricas (n�o suportado pelo Jaeger)

**Configura��o:**
```pascal
var Config := TObservability.CreateJaegerConfig;
Config.ServiceName := 'meu-servico';
Config.ServerUrl := 'http://localhost:14268/api/traces';

TObservability.RegisterProvider(TJaegerProvider.Create(Config));
```

### ??? **Sentry Provider**

**Caracter�sticas:**
- ? Rastreamento de erros avan�ado
- ? Monitoramento de performance
- ? Logging estruturado com breadcrumbs
- ? Release tracking e deployment

**Configura��o:**
```pascal
var Config := TObservability.CreateSentryConfig;
Config.ServerUrl := 'https://seu-dsn@sentry.io/projeto-id';
Config.Environment := 'producao';
Config.ServiceVersion := '1.0.0';

TObservability.RegisterProvider(TSentryProvider.Create(Config));
```

### ?? **Datadog Provider**

**Caracter�sticas Completas:**
- ? APM completo com correla��o de traces
- ? M�tricas customizadas e do sistema
- ? Logging estruturado
- ? Integra��o com infraestrutura

**Configura��o:**
```pascal
var Config := TObservability.CreateDatadogConfig;
Config.ApiKey := 'sua-chave-api-datadog';
Config.ServiceName := 'meu-app';
Config.ServerUrl := 'http://localhost:8126'; // Datadog Agent

TObservability.RegisterProvider(TDatadogProvider.Create(Config));
```

## ?? Sistema de M�tricas

### ?? M�tricas Autom�ticas do Sistema

Quando `TObservability.EnableSystemMetrics` � chamado:

```pascal
// M�tricas de mem�ria
- system.memory.application.bytes.gauge     // Mem�ria usada pela aplica��o
- system.memory.used.mb.gauge              // Mem�ria total usada no sistema
- system.memory.available.mb.gauge         // Mem�ria dispon�vel
- system.memory.total.mb.gauge             // Mem�ria total do sistema
- system.memory.usage.percent.gauge        // Porcentagem de uso de mem�ria

// M�tricas de CPU
- system.cpu.application.percent.gauge     // CPU usado pela aplica��o
- system.cpu.system.percent.gauge          // CPU usado pelo sistema

// M�tricas de runtime
- system.threads.count.gauge               // N�mero de threads ativas
- system.gc.allocated.bytes.gauge          // Bytes alocados pelo GC
```

**Habilita��o:**
```pascal
// Habilitar coleta autom�tica
TObservability.EnableSystemMetrics;

// Ou com op��es espec�ficas
TObservability.EnableSystemMetrics(
  [smoMemoryUsage, smoCPUUsage, smoThreadCount], // M�tricas para coletar
  si30Seconds  // Intervalo de coleta
);

// Coleta manual �nica
TObservability.CollectSystemMetricsOnce;

// Desabilitar quando finalizar
TObservability.DisableSystemMetrics;
```

### ?? M�tricas Personalizadas

```pascal
// Contador - Rastrear n�mero de opera��es
TObservability.Metrics.Counter('api.requisicoes.total', 1);
TObservability.Metrics.Counter('cache.hits', 1);

// Medidor - Valores instant�neos
TObservability.Metrics.Gauge('memoria.uso.bytes', GetUsoMemoria);
TObservability.Metrics.Gauge('usuarios.ativos', GetUsuariosAtivos);

// Histograma - Distribui��o de valores
TObservability.Metrics.Histogram('http.tempo.resposta.ms', TempoResposta);
TObservability.Metrics.Histogram('db.query.duracao', DuracaoQuery);
```

## ?? Rastreamento Distribu�do

### ?? Tipos de Span e Contexto

#### **Tipos de Span:**
- **Client**: Requisi��es de sa�da (chamadas HTTP, consultas de banco)
- **Server**: Requisi��es de entrada (endpoints API, handlers de mensagem)
- **Producer**: Produtores de mensagem (publishers de fila)
- **Consumer**: Consumidores de mensagem (subscribers de fila)
- **Internal**: Opera��es internas (l�gica de neg�cio, c�lculos)

#### **Propaga��o de Contexto:**
```pascal
// Extrair contexto de headers HTTP
var Context := TObservability.Tracer.ExtractContext(HttpHeaders);

// Iniciar span com contexto extra�do
var Span := TObservability.StartSpan('processar-requisicao', Context);

// Injetar contexto em headers de sa�da
TObservability.Tracer.InjectHeaders(HeadersSaida);
```

### ?? Gerenciamento Autom�tico de Spans

O SDK usa uma **pilha LIFO** para gerenciar automaticamente relacionamentos pai-filho:

```pascal
TObservability.StartTransaction('Requisicao HTTP');
  TObservability.StartSpan('Autenticacao');
    TObservability.StartSpan('Consulta Banco');
    TObservability.FinishSpan; // Finaliza Consulta Banco
  TObservability.FinishSpan;   // Finaliza Autenticacao
TObservability.FinishTransaction; // Finaliza Requisicao HTTP
```

**Resultado**: Hierarquia perfeita com correla��o autom�tica de parent_id

## ?? Logging Estruturado

### ?? N�veis de Log

```pascal
// Logs simples
TObservability.LogTrace('Opera��o iniciada');
TObservability.LogDebug('Valor da vari�vel: %d', [valorVariavel]);
TObservability.LogInfo('Usu�rio logado com sucesso');
TObservability.LogWarning('Cache miss detectado');
TObservability.LogError('Falha na opera��o', excecao);
TObservability.LogCritical('Sistema indispon�vel');
```

### ??? Logs com Atributos

```pascal
var
  Logger: IObservabilityLogger;
  Attributes: TDictionary<string, string>;
begin
  Logger := TObservability.GetLogger;
  Attributes := TDictionary<string, string>.Create;
  try
    Attributes.Add('user_id', '12345');
    Attributes.Add('operacao', 'login');
    Attributes.Add('ip_address', '192.168.1.100');
    
    Logger.Info('Login realizado com sucesso', Attributes);
  finally
    Attributes.Free;
  end;
end;
```

### ?? Correla��o Autom�tica

Logs s�o automaticamente correlacionados com traces ativos:
```pascal
var Span := TObservability.StartSpan('processar-pedido');
try
  // Este log ser� automaticamente associado ao span ativo
  TObservability.LogInfo('Processando pedido #12345');
  
  // Com atributos adicionais
  var Attrs := TDictionary<string, string>.Create;
  Attrs.Add('pedido_id', '12345');
  Attrs.Add('valor', '299.99');
  TObservability.LogInfo('Pedido validado', Attrs);
  Attrs.Free;
finally
  Span.Finish;
end;
```

## ?? Configura��o Avan�ada

### ?? Configura��es por Provedor

#### **Configura��o Elastic APM Completa:**
```pascal
var Config := TObservability.CreateElasticConfig;
Config.ServiceName := 'meu-app-delphi';
Config.ServiceVersion := '1.0.0';
Config.Environment := 'producao';
Config.ServerUrl := 'https://apm.minhaempresa.com:8200';
Config.SecretToken := 'seu-token-secreto';

// Configura��es avan�adas via propriedades customizadas
var CustomProps := TDictionary<string, string>.Create;
CustomProps.Add('capture_body', 'all');
CustomProps.Add('transaction_sample_rate', '1.0');
Config.CustomProperties := CustomProps;

var Provider := TElasticAPMProvider.Create;
Provider.Configure(Config);
TObservability.RegisterProvider(Provider);
```

#### **Configura��o Datadog com Tags Globais:**
```pascal
var Config := TObservability.CreateDatadogConfig;
Config.ApiKey := 'sua-chave-api-datadog';
Config.ServiceName := 'api-pagamentos';
Config.Environment := 'producao';

// Tags globais
var CustomProps := TDictionary<string, string>.Create;
CustomProps.Add('team', 'backend');
CustomProps.Add('component', 'api');
CustomProps.Add('datacenter', 'us-east-1');
Config.CustomProperties := CustomProps;

TObservability.RegisterProvider(TDatadogProvider.Create(Config));
```

### ?? Configura��o Multi-Provedor

```pascal
// Registrar m�ltiplos provedores
var ElasticConfig := TObservability.CreateElasticConfig;
ElasticConfig.ServiceName := 'meu-servico';
ElasticConfig.ServerUrl := 'http://localhost:8200';

var SentryConfig := TObservability.CreateSentryConfig;
SentryConfig.ServerUrl := 'https://seu-dsn@sentry.io/projeto';

// Registrar ambos
TObservability.RegisterProvider(TElasticAPMProvider.Create(ElasticConfig));
TObservability.RegisterProvider(TSentryProvider.Create(SentryConfig));

// Usar Elastic APM como principal
TObservability.SetActiveProvider(opElastic);

// Alternar para Sentry se necess�rio
TObservability.SetActiveProvider(opSentry);
```

## ?? Exemplos Pr�ticos

### ?? Monitoramento de API Web

```pascal
procedure TMyController.ProcessarRequisicao;
var
  Span: IObservabilitySpan;
begin
  Span := TObservability.StartSpan('api.processar-requisicao', skServer);
  try
    Span.SetAttribute('http.method', 'POST');
    Span.SetAttribute('http.url', '/api/usuarios');
    Span.SetAttribute('user.id', GetUsuarioAtual);
    
    // Processar requisi��o
    ProcessarDadosUsuario;
    
    TObservability.Metrics.Counter('api.requisicoes.sucesso', 1);
    Span.SetOutcome(Success);
  except
    on E: Exception do
    begin
      Span.RecordException(E);
      Span.SetOutcome(Failure);
      TObservability.Metrics.Counter('api.requisicoes.erro', 1);
      TObservability.LogError('Falha no processamento da requisi��o', E);
      raise;
    end;
  end;
end;
```

### ??? Opera��es de Banco de Dados

```pascal
procedure TUserRepository.SalvarUsuario(const Usuario: TUsuario);
var
  Span: IObservabilitySpan;
  TempoInicio: TDateTime;
begin
  Span := TObservability.StartSpan('db.salvar-usuario', skClient);
  TempoInicio := Now;
  try
    Span.SetAttribute('db.tabela', 'usuarios');
    Span.SetAttribute('db.operacao', 'INSERT');
    Span.SetAttribute('user.id', Usuario.Id);
    
    // Executar opera��o de banco
    ExecutarSQL('INSERT INTO usuarios...', Usuario);
    
    TObservability.Metrics.Histogram('db.query.duracao', 
      MilliSecondsBetween(Now, TempoInicio));
    
    TObservability.LogInfo('Usu�rio salvo com sucesso', 
      TDictionary<string, string>.Create.AddOrSetValue('user.id', Usuario.Id));
    
    Span.SetOutcome(Success);
  except
    on E: Exception do
    begin
      Span.RecordException(E);
      TObservability.Metrics.Counter('db.erros', 1);
      TObservability.LogError('Falha ao salvar usu�rio', E);
      raise;
    end;
  end;
end;
```

### ?? Processamento em Background

```pascal
procedure TBackgroundProcessor.ProcessarFila;
var
  Span: IObservabilitySpan;
  ItensProcessados: Integer;
begin
  Span := TObservability.StartSpan('background.processar-fila', skInternal);
  ItensProcessados := 0;
  try
    while TemItensNaFila do
    begin
      ProcessarItemUnico;
      Inc(ItensProcessados);
      
      // Atualizar m�tricas a cada 10 itens
      if ItensProcessados mod 10 = 0 then
      begin
        TObservability.Metrics.Gauge('fila.itens.processados', ItensProcessados);
        TObservability.LogDebug('Progresso: %d itens processados', [ItensProcessados]);
      end;
    end;
    
    Span.SetAttribute('itens.processados', ItensProcessados);
    TObservability.Metrics.Counter('fila.processamento.completo', 1);
    
    TObservability.LogInfo('Processamento da fila conclu�do', 
      TDictionary<string, string>.Create.AddOrSetValue('total_itens', IntToStr(ItensProcessados)));
    
    Span.SetOutcome(Success);
  except
    on E: Exception do
    begin
      Span.RecordException(E);
      TObservability.LogError('Falha no processamento em background', E);
      TObservability.Metrics.Counter('fila.processamento.erro', 1);
      raise;
    end;
  end;
end;
```

### ?? Integra��o com Servi�os Externos

```pascal
function TPaymentService.ProcessarPagamento(const Pagamento: TPagamento): TResultadoPagamento;
var
  Span: IObservabilitySpan;
  HttpClient: THttpClient;
  SpanExterno: IObservabilitySpan;
begin
  Span := TObservability.StartSpan('payment.processar', skInternal);
  try
    Span.SetAttribute('payment.id', Pagamento.Id);
    Span.SetAttribute('payment.amount', FloatToStr(Pagamento.Valor));
    
    // Valida��o
    SpanExterno := TObservability.StartSpan('payment.validar', skInternal);
    try
      ValidarPagamento(Pagamento);
      SpanExterno.SetOutcome(Success);
    finally
      SpanExterno.Finish;
    end;
    
    // Chamada para gateway externo
    SpanExterno := TObservability.StartSpan('gateway.processar', skClient);
    try
      SpanExterno.SetAttribute('gateway.provider', 'stripe');
      SpanExterno.SetAttribute('http.method', 'POST');
      SpanExterno.SetAttribute('http.url', 'https://api.stripe.com/charges');
      
      // Injetar contexto nos headers
      HttpClient := THttpClient.Create;
      TObservability.Tracer.InjectHeaders(HttpClient.CustomHeaders);
      
      Result := ChamarGatewayPagamento(HttpClient, Pagamento);
      
      SpanExterno.SetAttribute('gateway.transaction_id', Result.TransactionId);
      SpanExterno.SetOutcome(Success);
      
      TObservability.Metrics.Counter('payment.gateway.sucesso', 1);
    except
      on E: Exception do
      begin
        SpanExterno.RecordException(E);
        SpanExterno.SetOutcome(Failure);
        TObservability.Metrics.Counter('payment.gateway.erro', 1);
        raise;
      end;
    finally
      SpanExterno.Finish;
      HttpClient.Free;
    end;
    
    Span.SetOutcome(Success);
    TObservability.LogInfo('Pagamento processado com sucesso', 
      TDictionary<string, string>.Create
        .AddOrSetValue('payment.id', Pagamento.Id)
        .AddOrSetValue('transaction.id', Result.TransactionId));
        
  except
    on E: Exception do
    begin
      Span.RecordException(E);
      Span.SetOutcome(Failure);
      TObservability.LogError('Falha no processamento do pagamento', E);
      raise;
    end;
  finally
    Span.Finish;
  end;
end;
```

## ??? Instala��o

### ?? Requisitos do Sistema

- **Delphi**: 10.3 Rio ou superior
- **Plataformas de Destino**: Windows (32/64-bit), Linux (64-bit)
- **Framework**: Compat�vel com VCL/FMX
- **Runtime**: Nenhuma depend�ncia de DLL externa

### ?? Passos de Instala��o

1. **Download**: Clone ou fa�a download do reposit�rio
```bash
git clone https://github.com/Julianoeichelberger/ObservabilitySDK4D.git
```

2. **Adicionar Caminho**: Adicione a pasta `source` ao library path do seu projeto

3. **Incluir Units**: Adicione as units necess�rias na sua cl�usula uses
```pascal
uses
  Observability.SDK,
  Observability.Provider.Elastic, // ou seu provedor preferido
  Observability.Provider.Console;
```

4. **Inicializar**: Configure e inicialize em sua aplica��o
```pascal
initialization
  TObservability.Initialize;
  // Configurar provedores...

finalization
  TObservability.Shutdown;
```

### ?? Servi�os Externos

| Provedor | Servi�o | Porta Padr�o | Protocolo |
|----------|---------|--------------|-----------|
| **Elastic APM** | APM Server | 8200 | HTTP/HTTPS |
| **Jaeger** | Jaeger Agent | 14268 | HTTP |
| **Sentry** | Sentry DSN | 443 | HTTPS |
| **Datadog** | DD Agent | 8126 | HTTP |

## ?? Refer�ncia da API

### ??? Classes Principais

| Classe | Prop�sito | Thread-Safe | M�todos Principais |
|--------|-----------|-------------|-------------------|
| `TObservability` | API est�tica principal | ? Sim | `StartTransaction`, `StartSpan`, `Metrics` |
| `TObservabilitySDK` | Inst�ncia do SDK | ? Sim | `Initialize`, `RegisterProvider`, `Shutdown` |
| `TElasticAPMProvider` | Integra��o Elastic APM | ? Sim | `Configure`, `SendBatch` |
| `TObservabilityContext` | Contexto de requisi��o | ? Sim | `Clone`, `CreateChild` |

### ?? Contratos de Interface

| Interface | Prop�sito | M�todos Principais |
|-----------|-----------|-------------------|
| `IObservabilitySpan` | Opera��es de span | `Finish`, `SetAttribute`, `SetOutcome` |
| `IObservabilityMetrics` | Coleta de m�tricas | `Counter`, `Gauge`, `Histogram` |
| `IObservabilityConfig` | Configura��o de provedor | Propriedades para URLs, tokens, etc. |
| `IObservabilityProvider` | Abstra��o de provedor | `Initialize`, `GetTracer`, `GetMetrics` |

### ? Caracter�sticas de Performance

#### ?? Benchmarks

- **Cria��o de Span**: ~50-100?s por span
- **Overhead de Mem�ria**: ~2-5MB baseline + ~1KB por span ativo
- **Lote de Rede**: Tamanho de lote configur�vel (padr�o: 100 eventos)
- **Processamento em Background**: Coleta de m�tricas n�o-bloqueante

#### ?? Recursos de Otimiza��o

- **Inicializa��o Lazy**: Provedores s� inicializam quando usados
- **Pool de Conex�es**: Clientes HTTP reutilizam conex�es
- **Processamento em Lote**: M�ltiplos eventos enviados em uma requisi��o
- **Circuit Breaking**: Fallback autom�tico em falhas de provedor

## ?? Melhores Pr�ticas

### ?? Padr�es de Transa��o

```pascal
// ? BOM: Limites claros de transa��o
TObservability.StartTransaction('ProcessarPedido', 'negocio');
try
  ValidarPedido();
  CalcularTotal();
  SalvarNoBanco();
  TObservability.FinishTransaction;
except
  TObservability.FinishTransactionWithOutcome(Failure);
  raise;
end;

// ? EVITAR: Limites pouco claros
TObservability.StartSpan('FazerTudo');
// Muito amplo, dif�cil de entender performance
```

### ?? Nomenclatura de M�tricas

```pascal
// ? BOM: Nomes descritivos e hier�rquicos
TObservability.Metrics.Counter('http.requisicoes.total');
TObservability.Metrics.Gauge('banco.conexoes.ativas');
TObservability.Metrics.Histogram('api.tempo.resposta');

// ? EVITAR: Nomes gen�ricos
TObservability.Metrics.Counter('contador');
TObservability.Metrics.Gauge('valor');
```

### ??? Diretrizes de Atributos

```pascal
// ? BOM: Atributos significativos
Span.SetAttribute('user.id', '12345');
Span.SetAttribute('http.method', 'POST');
Span.SetAttribute('db.table', 'usuarios');

// ? EVITAR: Atributos de alta cardinalidade em m�tricas
// Evitar IDs �nicos em tags de m�tricas
```

### ??? Tratamento de Erros

```pascal
var Span := TObservability.StartSpan('operacao-arriscada');
try
  // Seu c�digo aqui
  Span.SetOutcome(Success);
except
  on E: Exception do
  begin
    Span.RecordException(E);
    Span.SetOutcome(Failure);
    TObservability.LogError('Opera��o falhou', E);
    raise; // Re-propagar a exce��o
  end;
end;
```

### ?? Gerenciamento de Recursos

- Sempre chame `Span.Finish` em um bloco try-finally
- Use os m�todos auxiliares do SDK para padr�es comuns
- Fa�a shutdown apropriado do SDK na sa�da da aplica��o

## ?? Ambientes de Exemplo

Cada provedor inclui ambientes Docker Compose completos para teste r�pido:

### ?? **Elastic Stack**
```bash
cd Samples/Elastic
.\elastic.ps1 start
# Acesse: http://localhost:5601 (Kibana)
```

### ??? **Jaeger**
```bash
cd Samples/Jaeger  
.\jaeger.ps1 start
# Acesse: http://localhost:16686 (Jaeger UI)
```

### ??? **Sentry**
```bash
cd Samples/Sentry
.\sentry.ps1 start
# Acesse: http://localhost:9000 (Sentry Web)
```

### ?? **Datadog**
```bash
cd Samples/Datadog
.\datadog.ps1 start
# Configure sua API key e acesse: https://app.datadoghq.com
```

## ?? Considera��es de Performance

- O SDK � projetado para overhead m�nimo
- Spans e m�tricas s�o processados assincronamente quando poss�vel
- Use taxas de amostragem em cen�rios de alto throughput
- Considere tamanhos de lote para logging de alto volume

## ?? Contribuindo

Contribui��es s�o bem-vindas! Por favor:

1. **Fork** o reposit�rio
2. **Crie** uma branch para sua feature: `git checkout -b feature/nova-feature`
3. **Commit** suas mudan�as: `git commit -m 'Adiciona nova feature'`
4. **Push** para a branch: `git push origin feature/nova-feature`
5. **Abra** um Pull Request

### ?? Diretrizes de Contribui��o

- Siga os padr�es de c�digo existentes
- Adicione testes para novas funcionalidades
- Atualize a documenta��o conforme necess�rio
- Garanta compatibilidade com Delphi 10.3+

### ?? Reportando Issues

Ao reportar problemas, inclua:
- Vers�o do Delphi e plataforma
- Tipo de provedor e configura��o
- C�digo de reprodu��o m�nima
- Sa�da de debug (se aplic�vel)

## ?? Licen�a

Este projeto est� licenciado sob a Licen�a MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

```
MIT License

Copyright (c) 2025 Juliano Eichelberger

� concedida permiss�o, gratuitamente, a qualquer pessoa que obtenha uma c�pia
deste software e arquivos de documenta��o associados (o "Software"), para lidar
no Software sem restri��o, incluindo, sem limita��o, os direitos de usar, copiar,
modificar, mesclar, publicar, distribuir, sublicenciar e/ou vender c�pias do
Software, e para permitir que as pessoas a quem o Software � fornecido o fa�am,
sujeito �s seguintes condi��es:

O aviso de copyright acima e este aviso de permiss�o devem ser inclu�dos em todas
as c�pias ou partes substanciais do Software.
```

## ?? Suporte

- **?? Documenta��o**: Confira os links de documenta��o espec�fica por idioma
- **?? Issues**: [GitHub Issues](https://github.com/Julianoeichelberger/ObservabilitySDK4D/issues)
- **?? Discuss�es**: [GitHub Discussions](https://github.com/Julianoeichelberger/ObservabilitySDK4D/discussions)
- **?? Email**: Para suporte comercial, entre em contato

---

<div align="center">

**ObservabilitySDK4D** - Tornando aplica��es Delphi observ�veis em ambientes cloud modernos.

[? Dar uma estrela](https://github.com/Julianoeichelberger/ObservabilitySDK4D) � [?? Fork](https://github.com/Julianoeichelberger/ObservabilitySDK4D/fork) � [?? Docs](../README.md) � [?? Issues](https://github.com/Julianoeichelberger/ObservabilitySDK4D/issues)

</div>

---

*Esta documenta��o cobre ObservabilitySDK4D v1.0.0 - �ltima atualiza��o: Outubro 2025*