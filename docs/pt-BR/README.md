# ObservabilitySDK4D - Documentação Completa

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Delphi](https://img.shields.io/badge/Delphi-10.3%2B-red.svg)](https://www.embarcadero.com/products/delphi)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-blue.svg)](https://github.com/Julianoeichelberger/ObservabilitySDK4D)

> Framework abrangente de **Monitoramento de Performance de Aplicação (APM)** e **Observabilidade** para aplicações Delphi com suporte a rastreamento distribuído, coleta de métricas e logging estruturado.

## ?? Índice

- [?? Visão Geral](#-visão-geral)
- [??? Arquitetura](#?-arquitetura)
- [?? Início Rápido](#-início-rápido)
- [?? Conceitos Fundamentais](#-conceitos-fundamentais)
- [?? Provedores Suportados](#-provedores-suportados)
- [?? Sistema de Métricas](#-sistema-de-métricas)
- [?? Rastreamento Distribuído](#-rastreamento-distribuído)
- [?? Logging Estruturado](#-logging-estruturado)
- [?? Configuração Avançada](#?-configuração-avançada)
- [?? Exemplos Práticos](#-exemplos-práticos)
- [??? Instalação](#?-instalação)
- [?? Referência da API](#-referência-da-api)
- [?? Contribuindo](#-contribuindo)

## ?? Visão Geral

O **ObservabilitySDK4D** é um framework moderno de observabilidade para Delphi que permite monitorar, rastrear e analisar o desempenho de suas aplicações em tempo real. Com suporte a múltiplos provedores e uma API unificada, você pode facilmente integrar observabilidade completa em seus projetos Delphi.

### ? Características Principais

- **?? Suporte Multi-Provedor**: Elastic APM, Jaeger, Sentry, Datadog, Console
- **?? Observabilidade Completa**: Rastreamento, Métricas e Logging em um SDK
- **?? Rastreamento Distribuído**: Acompanhe requisições através de microsserviços
- **? Zero Configuração**: Funciona imediatamente com configurações padrão sensatas
- **?? Thread-Safe**: Pronto para produção com gerenciamento automático de recursos
- **?? Auto-Métricas**: Coleta automática de métricas do sistema (CPU, Memória, GC)

### ?? Benefícios

1. **Visibilidade Completa**: Veja exatamente como sua aplicação está performando
2. **Detecção Rápida de Problemas**: Identifique gargalos e erros em tempo real
3. **Análise de Desempenho**: Entenda padrões de uso e otimize performance
4. **Correlação de Dados**: Conecte logs, métricas e traces para investigação completa
5. **Monitoramento Proativo**: Receba alertas antes que problemas afetem usuários

## ??? Arquitetura

### ??? Visão Geral da Arquitetura

```
???????????????????????????????????????????????????????????
?              TObservability (API Estática)              ?
???????????????????????????????????????????????????????????
? ??????????????? ??????????????? ??????????????????????? ?
? ? Rastreamento? ?   Métricas  ? ?      Logging        ? ?
? ?    (APM)    ? ?   Coleta    ? ?   (Estruturado)     ? ?
? ??????????????? ??????????????? ??????????????????????? ?
???????????????????????????????????????????????????????????
                              ?
???????????????????????????????????????????????????????????
?             Camada de Abstração de Provedores           ?
???????????????????????????????????????????????????????????
                              ?
???????????????????????????????????????????????????????????
? ?? Elastic  ??? Jaeger  ??? Sentry  ?? Datadog  ?? Console ?
???????????????????????????????????????????????????????????
```

### ?? Fluxo de Dados

```
Código da Aplicação
        ?
    ?????????      ???????????????      ????????????????
    ? Criar ?      ?   Pilha     ?      ?   Provedor   ?
    ? Span  ? ???? ?    de       ? ???? ?  (Elastic/   ? ???? Servidor APM
    ?       ?      ?   Spans     ?      ?   Jaeger)    ?
    ?????????      ???????????????      ????????????????
        ?                  ?                     ?
    ?????????      ???????????????      ????????????????
    ?Finalizar      ? Propagação  ?      ?   Coleta     ?
    ? Span  ?      ? Contexto    ?      ? Métricas     ? ???? Armazenamento
    ?????????      ???????????????      ????????????????
```

## ?? Início Rápido

### 1. Configuração Básica (30 segundos)

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
  
  // Começar a rastrear sua aplicação
  var Span := TObservability.StartSpan('operacao-usuario');
  try
    Span.SetAttribute('user.id', '12345');
    Span.SetAttribute('operacao', 'login');
    
    // Sua lógica de negócio aqui
    ProcessarLogin();
    
    Span.SetOutcome(Success);
  finally
    Span.Finish;
  end;
  
  TObservability.Shutdown;
end.
```

### 2. Uso Avançado com Métricas Personalizadas

```pascal
// Iniciar uma transação
TObservability.StartTransaction('Cadastro de Usuario', 'requisicao');

try
  // Criar spans aninhados
  TObservability.StartSpan('Validar Entrada');
  ValidarDadosUsuario();
  TObservability.FinishSpan;
  
  TObservability.StartSpan('Inserir no Banco');
  SalvarUsuarioNoBanco();
  TObservability.FinishSpan;
  
  // Métricas personalizadas
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
Monitoramento de performance da aplicação, tempos de resposta, throughput e taxas de erro em tempo real.

**Benefícios:**
- Detecção proativa de problemas de performance
- Análise de gargalos em tempo real
- Métricas de disponibilidade e confiabilidade
- Insights sobre comportamento do usuário

### ?? **Rastreamento Distribuído (Distributed Tracing)**
Rastreie requisições conforme elas fluem através de múltiplos serviços, criando uma visão completa do comportamento do sistema.

**Conceitos-chave:**
- **Trace**: Jornada completa de uma requisição
- **Span**: Unidade individual de trabalho dentro de um trace
- **Context**: Informações que conectam spans relacionados

### ?? **Compatibilidade OpenTelemetry**
Construído seguindo os princípios do OpenTelemetry para observabilidade vendor-neutral.

**Vantagens:**
- Padrão da indústria para observabilidade
- Interoperabilidade entre diferentes ferramentas
- Futuro-prova para mudanças de provedor

### ?? **Coleta de Métricas**

#### **Contadores (Counters)**
Valores cumulativos que só aumentam (requisições, erros):
```pascal
TObservability.Metrics.Counter('http.requisicoes.total', 1);
TObservability.Metrics.Counter('cache.hits', 1);
```

#### **Medidores (Gauges)**
Valores instantâneos que podem subir e descer (memória, conexões):
```pascal
TObservability.Metrics.Gauge('memoria.uso.bytes', GetUsoMemoria);
TObservability.Metrics.Gauge('conexoes.ativas', GetConexoesAtivas);
```

#### **Histogramas**
Distribuição de valores (tempos de resposta):
```pascal
TObservability.Metrics.Histogram('tempo.resposta.ms', TempoResposta);
TObservability.Metrics.Histogram('tamanho.payload.bytes', TamanhoPayload);
```

### ?? **Logging Estruturado**
Logs ricos e pesquisáveis com contexto e correlação através de sistemas distribuídos.

**Características:**
- Logs estruturados em JSON
- Correlação automática com traces
- Múltiplos níveis de log (DEBUG, INFO, WARN, ERROR)
- Atributos personalizados e contexto

## ?? Provedores Suportados

### ?? Matriz de Suporte

| Provedor | Rastreamento | Métricas | Logging | Rastreamento de Erros | Status |
|----------|--------------|----------|---------|----------------------|--------|
| **?? Elastic APM** | ? | ? | ? | ? | ?? Pronto para Produção |
| **??? Jaeger** | ? | ? | ? | ? | ?? Pronto para Produção |
| **??? Sentry** | ? | ?* | ? | ? | ?? Pronto para Produção |
| **?? Datadog** | ? | ? | ? | ? | ?? Pronto para Produção |
| **?? Console** | ? | ? | ? | ? | ?? Desenvolvimento |
| **?? TextFile** | ? | ? | ? | ? | ?? Desenvolvimento |

> *Métricas Sentry não são suportadas nativamente pela plataforma Sentry

### ?? **Elastic APM Provider**

**Características Completas:**
- ? Protocolo APM 8.x completo
- ? Transações, spans e métricas
- ? Formato de lote NDJSON
- ? Correlação automática pai-filho
- ? Coleta de métricas do sistema

**Configuração:**
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
// Amostras e exemplos completos disponíveis em /Samples/Elastic
docker-compose up -d  // Inicia Elasticsearch + Kibana + APM Server
```

### ??? **Jaeger Provider**

**Características:**
- ? Protocolo OpenTelemetry (OTLP)
- ? Rastreamento distribuído completo
- ? Correlação de contexto B3/W3C
- ? Métricas (não suportado pelo Jaeger)

**Configuração:**
```pascal
var Config := TObservability.CreateJaegerConfig;
Config.ServiceName := 'meu-servico';
Config.ServerUrl := 'http://localhost:14268/api/traces';

TObservability.RegisterProvider(TJaegerProvider.Create(Config));
```

### ??? **Sentry Provider**

**Características:**
- ? Rastreamento de erros avançado
- ? Monitoramento de performance
- ? Logging estruturado com breadcrumbs
- ? Release tracking e deployment

**Configuração:**
```pascal
var Config := TObservability.CreateSentryConfig;
Config.ServerUrl := 'https://seu-dsn@sentry.io/projeto-id';
Config.Environment := 'producao';
Config.ServiceVersion := '1.0.0';

TObservability.RegisterProvider(TSentryProvider.Create(Config));
```

### ?? **Datadog Provider**

**Características Completas:**
- ? APM completo com correlação de traces
- ? Métricas customizadas e do sistema
- ? Logging estruturado
- ? Integração com infraestrutura

**Configuração:**
```pascal
var Config := TObservability.CreateDatadogConfig;
Config.ApiKey := 'sua-chave-api-datadog';
Config.ServiceName := 'meu-app';
Config.ServerUrl := 'http://localhost:8126'; // Datadog Agent

TObservability.RegisterProvider(TDatadogProvider.Create(Config));
```

## ?? Sistema de Métricas

### ?? Métricas Automáticas do Sistema

Quando `TObservability.EnableSystemMetrics` é chamado:

```pascal
// Métricas de memória
- system.memory.application.bytes.gauge     // Memória usada pela aplicação
- system.memory.used.mb.gauge              // Memória total usada no sistema
- system.memory.available.mb.gauge         // Memória disponível
- system.memory.total.mb.gauge             // Memória total do sistema
- system.memory.usage.percent.gauge        // Porcentagem de uso de memória

// Métricas de CPU
- system.cpu.application.percent.gauge     // CPU usado pela aplicação
- system.cpu.system.percent.gauge          // CPU usado pelo sistema

// Métricas de runtime
- system.threads.count.gauge               // Número de threads ativas
- system.gc.allocated.bytes.gauge          // Bytes alocados pelo GC
```

**Habilitação:**
```pascal
// Habilitar coleta automática
TObservability.EnableSystemMetrics;

// Ou com opções específicas
TObservability.EnableSystemMetrics(
  [smoMemoryUsage, smoCPUUsage, smoThreadCount], // Métricas para coletar
  si30Seconds  // Intervalo de coleta
);

// Coleta manual única
TObservability.CollectSystemMetricsOnce;

// Desabilitar quando finalizar
TObservability.DisableSystemMetrics;
```

### ?? Métricas Personalizadas

```pascal
// Contador - Rastrear número de operações
TObservability.Metrics.Counter('api.requisicoes.total', 1);
TObservability.Metrics.Counter('cache.hits', 1);

// Medidor - Valores instantâneos
TObservability.Metrics.Gauge('memoria.uso.bytes', GetUsoMemoria);
TObservability.Metrics.Gauge('usuarios.ativos', GetUsuariosAtivos);

// Histograma - Distribuição de valores
TObservability.Metrics.Histogram('http.tempo.resposta.ms', TempoResposta);
TObservability.Metrics.Histogram('db.query.duracao', DuracaoQuery);
```

## ?? Rastreamento Distribuído

### ?? Tipos de Span e Contexto

#### **Tipos de Span:**
- **Client**: Requisições de saída (chamadas HTTP, consultas de banco)
- **Server**: Requisições de entrada (endpoints API, handlers de mensagem)
- **Producer**: Produtores de mensagem (publishers de fila)
- **Consumer**: Consumidores de mensagem (subscribers de fila)
- **Internal**: Operações internas (lógica de negócio, cálculos)

#### **Propagação de Contexto:**
```pascal
// Extrair contexto de headers HTTP
var Context := TObservability.Tracer.ExtractContext(HttpHeaders);

// Iniciar span com contexto extraído
var Span := TObservability.StartSpan('processar-requisicao', Context);

// Injetar contexto em headers de saída
TObservability.Tracer.InjectHeaders(HeadersSaida);
```

### ?? Gerenciamento Automático de Spans

O SDK usa uma **pilha LIFO** para gerenciar automaticamente relacionamentos pai-filho:

```pascal
TObservability.StartTransaction('Requisicao HTTP');
  TObservability.StartSpan('Autenticacao');
    TObservability.StartSpan('Consulta Banco');
    TObservability.FinishSpan; // Finaliza Consulta Banco
  TObservability.FinishSpan;   // Finaliza Autenticacao
TObservability.FinishTransaction; // Finaliza Requisicao HTTP
```

**Resultado**: Hierarquia perfeita com correlação automática de parent_id

## ?? Logging Estruturado

### ?? Níveis de Log

```pascal
// Logs simples
TObservability.LogTrace('Operação iniciada');
TObservability.LogDebug('Valor da variável: %d', [valorVariavel]);
TObservability.LogInfo('Usuário logado com sucesso');
TObservability.LogWarning('Cache miss detectado');
TObservability.LogError('Falha na operação', excecao);
TObservability.LogCritical('Sistema indisponível');
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

### ?? Correlação Automática

Logs são automaticamente correlacionados com traces ativos:
```pascal
var Span := TObservability.StartSpan('processar-pedido');
try
  // Este log será automaticamente associado ao span ativo
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

## ?? Configuração Avançada

### ?? Configurações por Provedor

#### **Configuração Elastic APM Completa:**
```pascal
var Config := TObservability.CreateElasticConfig;
Config.ServiceName := 'meu-app-delphi';
Config.ServiceVersion := '1.0.0';
Config.Environment := 'producao';
Config.ServerUrl := 'https://apm.minhaempresa.com:8200';
Config.SecretToken := 'seu-token-secreto';

// Configurações avançadas via propriedades customizadas
var CustomProps := TDictionary<string, string>.Create;
CustomProps.Add('capture_body', 'all');
CustomProps.Add('transaction_sample_rate', '1.0');
Config.CustomProperties := CustomProps;

var Provider := TElasticAPMProvider.Create;
Provider.Configure(Config);
TObservability.RegisterProvider(Provider);
```

#### **Configuração Datadog com Tags Globais:**
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

### ?? Configuração Multi-Provedor

```pascal
// Registrar múltiplos provedores
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

// Alternar para Sentry se necessário
TObservability.SetActiveProvider(opSentry);
```

## ?? Exemplos Práticos

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
    
    // Processar requisição
    ProcessarDadosUsuario;
    
    TObservability.Metrics.Counter('api.requisicoes.sucesso', 1);
    Span.SetOutcome(Success);
  except
    on E: Exception do
    begin
      Span.RecordException(E);
      Span.SetOutcome(Failure);
      TObservability.Metrics.Counter('api.requisicoes.erro', 1);
      TObservability.LogError('Falha no processamento da requisição', E);
      raise;
    end;
  end;
end;
```

### ??? Operações de Banco de Dados

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
    
    // Executar operação de banco
    ExecutarSQL('INSERT INTO usuarios...', Usuario);
    
    TObservability.Metrics.Histogram('db.query.duracao', 
      MilliSecondsBetween(Now, TempoInicio));
    
    TObservability.LogInfo('Usuário salvo com sucesso', 
      TDictionary<string, string>.Create.AddOrSetValue('user.id', Usuario.Id));
    
    Span.SetOutcome(Success);
  except
    on E: Exception do
    begin
      Span.RecordException(E);
      TObservability.Metrics.Counter('db.erros', 1);
      TObservability.LogError('Falha ao salvar usuário', E);
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
      
      // Atualizar métricas a cada 10 itens
      if ItensProcessados mod 10 = 0 then
      begin
        TObservability.Metrics.Gauge('fila.itens.processados', ItensProcessados);
        TObservability.LogDebug('Progresso: %d itens processados', [ItensProcessados]);
      end;
    end;
    
    Span.SetAttribute('itens.processados', ItensProcessados);
    TObservability.Metrics.Counter('fila.processamento.completo', 1);
    
    TObservability.LogInfo('Processamento da fila concluído', 
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

### ?? Integração com Serviços Externos

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
    
    // Validação
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

## ??? Instalação

### ?? Requisitos do Sistema

- **Delphi**: 10.3 Rio ou superior
- **Plataformas de Destino**: Windows (32/64-bit), Linux (64-bit)
- **Framework**: Compatível com VCL/FMX
- **Runtime**: Nenhuma dependência de DLL externa

### ?? Passos de Instalação

1. **Download**: Clone ou faça download do repositório
```bash
git clone https://github.com/Julianoeichelberger/ObservabilitySDK4D.git
```

2. **Adicionar Caminho**: Adicione a pasta `source` ao library path do seu projeto

3. **Incluir Units**: Adicione as units necessárias na sua cláusula uses
```pascal
uses
  Observability.SDK,
  Observability.Provider.Elastic, // ou seu provedor preferido
  Observability.Provider.Console;
```

4. **Inicializar**: Configure e inicialize em sua aplicação
```pascal
initialization
  TObservability.Initialize;
  // Configurar provedores...

finalization
  TObservability.Shutdown;
```

### ?? Serviços Externos

| Provedor | Serviço | Porta Padrão | Protocolo |
|----------|---------|--------------|-----------|
| **Elastic APM** | APM Server | 8200 | HTTP/HTTPS |
| **Jaeger** | Jaeger Agent | 14268 | HTTP |
| **Sentry** | Sentry DSN | 443 | HTTPS |
| **Datadog** | DD Agent | 8126 | HTTP |

## ?? Referência da API

### ??? Classes Principais

| Classe | Propósito | Thread-Safe | Métodos Principais |
|--------|-----------|-------------|-------------------|
| `TObservability` | API estática principal | ? Sim | `StartTransaction`, `StartSpan`, `Metrics` |
| `TObservabilitySDK` | Instância do SDK | ? Sim | `Initialize`, `RegisterProvider`, `Shutdown` |
| `TElasticAPMProvider` | Integração Elastic APM | ? Sim | `Configure`, `SendBatch` |
| `TObservabilityContext` | Contexto de requisição | ? Sim | `Clone`, `CreateChild` |

### ?? Contratos de Interface

| Interface | Propósito | Métodos Principais |
|-----------|-----------|-------------------|
| `IObservabilitySpan` | Operações de span | `Finish`, `SetAttribute`, `SetOutcome` |
| `IObservabilityMetrics` | Coleta de métricas | `Counter`, `Gauge`, `Histogram` |
| `IObservabilityConfig` | Configuração de provedor | Propriedades para URLs, tokens, etc. |
| `IObservabilityProvider` | Abstração de provedor | `Initialize`, `GetTracer`, `GetMetrics` |

### ? Características de Performance

#### ?? Benchmarks

- **Criação de Span**: ~50-100?s por span
- **Overhead de Memória**: ~2-5MB baseline + ~1KB por span ativo
- **Lote de Rede**: Tamanho de lote configurável (padrão: 100 eventos)
- **Processamento em Background**: Coleta de métricas não-bloqueante

#### ?? Recursos de Otimização

- **Inicialização Lazy**: Provedores só inicializam quando usados
- **Pool de Conexões**: Clientes HTTP reutilizam conexões
- **Processamento em Lote**: Múltiplos eventos enviados em uma requisição
- **Circuit Breaking**: Fallback automático em falhas de provedor

## ?? Melhores Práticas

### ?? Padrões de Transação

```pascal
// ? BOM: Limites claros de transação
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
// Muito amplo, difícil de entender performance
```

### ?? Nomenclatura de Métricas

```pascal
// ? BOM: Nomes descritivos e hierárquicos
TObservability.Metrics.Counter('http.requisicoes.total');
TObservability.Metrics.Gauge('banco.conexoes.ativas');
TObservability.Metrics.Histogram('api.tempo.resposta');

// ? EVITAR: Nomes genéricos
TObservability.Metrics.Counter('contador');
TObservability.Metrics.Gauge('valor');
```

### ??? Diretrizes de Atributos

```pascal
// ? BOM: Atributos significativos
Span.SetAttribute('user.id', '12345');
Span.SetAttribute('http.method', 'POST');
Span.SetAttribute('db.table', 'usuarios');

// ? EVITAR: Atributos de alta cardinalidade em métricas
// Evitar IDs únicos em tags de métricas
```

### ??? Tratamento de Erros

```pascal
var Span := TObservability.StartSpan('operacao-arriscada');
try
  // Seu código aqui
  Span.SetOutcome(Success);
except
  on E: Exception do
  begin
    Span.RecordException(E);
    Span.SetOutcome(Failure);
    TObservability.LogError('Operação falhou', E);
    raise; // Re-propagar a exceção
  end;
end;
```

### ?? Gerenciamento de Recursos

- Sempre chame `Span.Finish` em um bloco try-finally
- Use os métodos auxiliares do SDK para padrões comuns
- Faça shutdown apropriado do SDK na saída da aplicação

## ?? Ambientes de Exemplo

Cada provedor inclui ambientes Docker Compose completos para teste rápido:

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

## ?? Considerações de Performance

- O SDK é projetado para overhead mínimo
- Spans e métricas são processados assincronamente quando possível
- Use taxas de amostragem em cenários de alto throughput
- Considere tamanhos de lote para logging de alto volume

## ?? Contribuindo

Contribuições são bem-vindas! Por favor:

1. **Fork** o repositório
2. **Crie** uma branch para sua feature: `git checkout -b feature/nova-feature`
3. **Commit** suas mudanças: `git commit -m 'Adiciona nova feature'`
4. **Push** para a branch: `git push origin feature/nova-feature`
5. **Abra** um Pull Request

### ?? Diretrizes de Contribuição

- Siga os padrões de código existentes
- Adicione testes para novas funcionalidades
- Atualize a documentação conforme necessário
- Garanta compatibilidade com Delphi 10.3+

### ?? Reportando Issues

Ao reportar problemas, inclua:
- Versão do Delphi e plataforma
- Tipo de provedor e configuração
- Código de reprodução mínima
- Saída de debug (se aplicável)

## ?? Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

```
MIT License

Copyright (c) 2025 Juliano Eichelberger

É concedida permissão, gratuitamente, a qualquer pessoa que obtenha uma cópia
deste software e arquivos de documentação associados (o "Software"), para lidar
no Software sem restrição, incluindo, sem limitação, os direitos de usar, copiar,
modificar, mesclar, publicar, distribuir, sublicenciar e/ou vender cópias do
Software, e para permitir que as pessoas a quem o Software é fornecido o façam,
sujeito às seguintes condições:

O aviso de copyright acima e este aviso de permissão devem ser incluídos em todas
as cópias ou partes substanciais do Software.
```

## ?? Suporte

- **?? Documentação**: Confira os links de documentação específica por idioma
- **?? Issues**: [GitHub Issues](https://github.com/Julianoeichelberger/ObservabilitySDK4D/issues)
- **?? Discussões**: [GitHub Discussions](https://github.com/Julianoeichelberger/ObservabilitySDK4D/discussions)
- **?? Email**: Para suporte comercial, entre em contato

---

<div align="center">

**ObservabilitySDK4D** - Tornando aplicações Delphi observáveis em ambientes cloud modernos.

[? Dar uma estrela](https://github.com/Julianoeichelberger/ObservabilitySDK4D) • [?? Fork](https://github.com/Julianoeichelberger/ObservabilitySDK4D/fork) • [?? Docs](../README.md) • [?? Issues](https://github.com/Julianoeichelberger/ObservabilitySDK4D/issues)

</div>

---

*Esta documentação cobre ObservabilitySDK4D v1.0.0 - Última atualização: Outubro 2025*