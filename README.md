# Observability SDK for Delphi (ObservabilitySDK4D)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Delphi](https://img.shields.io/badge/Delphi-XE%2B-red.svg)](https://www.embarcadero.com/products/delphi)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-blue.svg)](https://github.com/Julianoeichelberger/ObservabilitySDK4D)

**Idiomas:** Português (Atual) | [English](./docs/README.en.md) | [Español](./docs/README.es.md) | [Deutsch](./docs/README.de.md)

---

> Um framework completo de **Application Performance Monitoring (APM)** e **Observabilidade** para aplicações Delphi, com suporte para rastreamento distribuído, coleta de métricas e logging estruturado.

---

## 🚀 Início Rápido

```pascal
uses Observability.SDK, Observability.Provider.Console;

begin
  // Inicializar ObservabilitySDK4D
  TObservability.Initialize;
  TObservability.RegisterProvider(TConsoleProvider.Create);
  TObservability.SetActiveProvider(opConsole);
  
  // Começar a rastrear sua aplicação
  var Span := TObservability.StartSpan('operacao-usuario');
  try
    Span.SetAttribute('user.id', '12345');
    // Sua lógica de negócio aqui
    Span.SetOutcome(Success);
  finally
    Span.Finish;
  end;
  
  TObservability.Shutdown;
end;
```

## 🎯 Principais Funcionalidades

- **🔄 Suporte Multi-Provedor**: Elastic APM, Jaeger, Sentry, Datadog, Console
- **📊 Observabilidade Completa**: Tracing, Métricas e Logging em um único SDK
- **🔗 Rastreamento Distribuído**: Rastreie requisições através de microserviços
- **⚡ Configuração Zero**: Funciona imediatamente com configurações padrão inteligentes
- **🧵 Thread-Safe**: Pronto para produção com gerenciamento automático de recursos
- **📈 Métricas Automáticas**: Coleta automática de métricas do sistema (CPU, Memória, GC)

## 📋 Matriz de Suporte dos Provedores

| Provedor | Tracing | Métricas | Logging | Rastreio de Erros | Status |
|----------|---------|---------|---------|-------------------|--------|
| **🔍 Elastic APM** | ✅ | ✅ | ✅ | ✅ | 🟢 Pronto para Produção |
| **🕸️ Jaeger** | ✅ | ❌ | ❌ | ❌ | 🟢 Pronto para Produção |
| **🛡️ Sentry** | ✅ | ❌* | ✅ | ✅ | 🟢 Pronto para Produção |
| **🐕 Datadog** | ✅ | ✅ | ✅ | ✅ | 🟢 Pronto para Produção |
| **📄 Console** | ✅ | ✅ | ✅ | ✅ | 🟢 Desenvolvimento |
| **📁 TextFile** | ✅ | ✅ | ✅ | ✅ | 🟢 Desenvolvimento |

> *Métricas do Sentry não são suportadas nativamente pela plataforma Sentry

## 🏗️ Visão Geral da Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                  TObservability (API Estática)          │
├─────────────────────────────────────────────────────────┤
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │
│ │  Tracing    │ │   Métricas  │ │      Logging        │ │
│ │   (APM)     │ │   Coleta    │ │  (Estruturado)      │ │
│ └─────────────┘ └─────────────┘ └─────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────┐
│            Camada de Abstração de Provedores            │
└─────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────┐
│ 📊 Elastic  🕸️ Jaeger  🛡️ Sentry  🐕 Datadog  📄 Console │
└─────────────────────────────────────────────────────────┘
```

## 🔧 Conceitos Principais

### 🎯 **APM (Application Performance Monitoring)**
Monitoramento de desempenho da aplicação, tempos de resposta, taxa de transferência e taxas de erro em tempo real.

### 🔗 **Rastreamento Distribuído**
Rastreie requisições conforme elas fluem através de múltiplos serviços, criando uma visão completa do comportamento do sistema.

### 📊 **Compatibilidade com OpenTelemetry**
Construído com os princípios do OpenTelemetry para observabilidade independente de fornecedor.

### 📈 **Coleta de Métricas**
- **Contadores (Counters)**: Valores cumulativos (requisições, erros)
- **Medidores (Gauges)**: Valores em um ponto no tempo (memória, conexões)
- **Histogramas**: Distribuição de valores (tempos de resposta)

### 📝 **Logging Estruturado**
Logs ricos e pesquisáveis com contexto e correlação entre sistemas distribuídos.

## 🛠️ Instalação

1. **Download**: Clone ou baixe o repositório
2. **Adicionar Caminho**: Adicione a pasta `source` ao caminho de biblioteca do seu projeto
3. **Incluir Units**: Adicione as units necessárias à sua cláusula uses
4. **Inicializar**: Configure e inicialize na sua aplicação

```pascal
// Units necessárias
uses
  Observability.SDK,
  Observability.Provider.Elastic; // ou seu provedor preferido
```

## 🎮 Exemplos e Amostras

Explore exemplos práticos no diretório [`Samples`](Samples/):

- **🔍 Elastic APM**: Elastic Stack completo com Kibana
- **🕸️ Jaeger**: Rastreamento Jaeger com OTLP
- **🛡️ Sentry**: Rastreamento de erros e desempenho
- **🐕 Datadog**: Observabilidade full-stack
- **💻 Console**: Desenvolvimento e depuração

Cada exemplo inclui ambientes Docker Compose para testes rápidos.

## 📚 Estrutura da Documentação

A documentação completa está disponível nos seguintes idiomas:

- **🇧🇷 [Documentação em Português](README.md)** (Este arquivo)
- **🇺🇸 [English Documentation](./docs/README.en.md)**
- **🇪🇸 [Documentación en Español](./docs/README.es.md)**
- **🇩🇪 [Deutsche Dokumentation](./docs/README.de.md)**

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para:

- Reportar bugs e problemas
- Sugerir novas funcionalidades
- Enviar pull requests
- Melhorar a documentação

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🆘 Suporte

- **📖 Documentação**: Confira a documentação específica por idioma acima
- **🐛 Issues**: [GitHub Issues](https://github.com/Julianoeichelberger/ObservabilitySDK4D/issues)
- **💬 Discussões**: [GitHub Discussions](https://github.com/Julianoeichelberger/ObservabilitySDK4D/discussions)

---

<div align="center">

**ObservabilitySDK4D** - Tornando aplicações Delphi observáveis em ambientes cloud modernos.

[⭐ Star neste projeto](https://github.com/Julianoeichelberger/ObservabilitySDK4D) • [🍴 Fork](https://github.com/Julianoeichelberger/ObservabilitySDK4D/fork) • [📖 Docs](docs/) • [🐛 Issues](https://github.com/Julianoeichelberger/ObservabilitySDK4D/issues)

</div>

---

## 🚀 **Guia de Início Rápido**

### **1. Configuração Básica (30 segundos)**
```pascal
program MeuApp;
uses
  Observability.SDK,
  Observability.Provider.Elastic;

begin
  // Configurar Elastic APM
  var Config := TObservability.CreateElasticConfig;
  Config.ServiceName := 'meu-servico';
  Config.ServerUrl := 'http://localhost:8200';
  
  // Inicializar
  TObservability.RegisterProvider(TElasticAPMProvider.Create.Configure(Config));
  TObservability.SetActiveProvider(opElastic);
  TObservability.Initialize;
  
  // Seu código da aplicação aqui
  TObservability.StartTransaction('Processo Principal');
  try
    FazerAlgo();
  finally
    TObservability.FinishTransaction;
  end;
  
  TObservability.Shutdown;
end.
```

### **2. Uso Avançado com Métricas Customizadas**
```pascal
// Iniciar uma transação
TObservability.StartTransaction('Registro de Usuário', 'request');

try
  // Criar spans aninhados
  TObservability.StartSpan('Validar Entrada');
  ValidarDadosUsuario();
  TObservability.FinishSpan;
  
  TObservability.StartSpan('Inserir no Banco');
  SalvarUsuarioNoBanco();
  TObservability.FinishSpan;
  
  // Métricas customizadas
  TObservability.Metrics.Counter('usuarios.registrados', 1);
  TObservability.Metrics.Gauge('banco.conexoes', GetConexoesAtivas());
  
  TObservability.FinishTransaction;
except
  on E: Exception do
  begin
    TObservability.RecordSpanException(E);
    TObservability.FinishTransactionWithOutcome(Failure);
  end;
end;
```

---

## 📚 **Referência dos Componentes Principais**

### **🎯 TObservability - API Estática Principal**

**Propósito**: Fachada central fornecendo métodos estáticos para todas as operações de observabilidade

#### **Transaction Management**
```pascal
// Start root transactions
class function StartTransaction(const Name: string): IObservabilitySpan;
class function StartTransaction(const Name: string; const TransactionType: string): IObservabilitySpan;

// Finish transactions  
class procedure FinishTransaction;
class procedure FinishTransactionWithOutcome(const Outcome: TOutcome);
```

#### **Span Management** 
```pascal
// Create nested spans
class function StartSpan(const Name: string): IObservabilitySpan;
class function StartSpan(const Name: string; const Kind: TSpanKind): IObservabilitySpan;

// Automatic span management
class procedure FinishSpan;
class procedure AddSpanAttribute(const Key, Value: string);
class procedure SetSpanOutcome(const Outcome: TOutcome);
```

#### **Metrics & Logging**
```pascal
// Access metrics interface
class function Metrics: IObservabilityMetrics;
class function Logger: IObservabilityLogger;

// Quick metrics
TObservability.Metrics.Counter('app.requests', 1);
TObservability.Metrics.Gauge('memory.usage', GetMemoryUsage());
TObservability.Metrics.Histogram('response.time', ElapsedMs);
```

### **🔧 Configuration Management**

```pascal
// Provider-specific configurations
class function CreateElasticConfig: IObservabilityConfig;
class function CreateJaegerConfig: IObservabilityConfig;
class function CreateSentryConfig: IObservabilityConfig;
class function CreateDatadogConfig: IObservabilityConfig;
class function CreateConsoleConfig: IObservabilityConfig;

// Configuration example
var Config := TObservability.CreateElasticConfig;
Config.ServiceName := 'my-service';
Config.ServiceVersion := '1.0.0';
Config.Environment := 'production';
Config.ServerUrl := 'https://apm.mycompany.com:8200';
Config.SecretToken := 'your-secret-token';
```

---

## 🏢 **Provider Implementations**

### **� Elastic APM Provider**

**Features**:
- ✅ Full APM 8.x protocol support
- ✅ Transactions, spans, and metrics
- ✅ NDJSON batch format
- ✅ Automatic parent-child correlation
- ✅ System metrics collection

**Configuration**:
```pascal
var Config := TObservability.CreateElasticConfig;
Config.ServerUrl := 'http://localhost:8200';
Config.SecretToken := 'seu-token';  // Opcional
Config.ServiceName := 'meu-app';
Config.Environment := 'production';

var Provider := TElasticAPMProvider.Create;
Provider.Configure(Config);
TObservability.RegisterProvider(Provider);
TObservability.SetActiveProvider(opElastic);
```

**Estruturas de Dados**:
- **Transações**: `{"transaction": {..., "span_count": {"started": N}}}`
- **Spans**: `{"span": {..., "parent_id": "xxx"}}`
- **Métricas**: `{"metricset": {"timestamp": ..., "samples": {...}}}`

---

## 📊 **Sistema de Métricas**

### **Tipos de Métricas**

```pascal
// Counter - Valores que aumentam monotonicamente
TObservability.Metrics.Counter('http.requisicoes.total', 1);
TObservability.Metrics.Counter('erros.count', 1, Tags);

// Gauge - Valores em um ponto no tempo
TObservability.Metrics.Gauge('memoria.uso.bytes', MemoriaUsada);
TObservability.Metrics.Gauge('cpu.utilizacao.percent', CPUPorcento);

// Histogram - Distribuição de valores
TObservability.Metrics.Histogram('http.requisicao.duracao', TempoDecorridoMs);
TObservability.Metrics.Histogram('banco.consulta.tempo', TempoConsultaMs);
```

### **Métricas do Sistema (Automáticas)**

Quando `TObservability.EnableSystemMetrics` é chamado:

```pascal
// Métricas de memória
- system.memory.application.bytes.gauge
- system.memory.used.mb.gauge  
- system.memory.available.mb.gauge
- system.memory.total.mb.gauge
- system.memory.usage.percent.gauge

// Métricas de CPU  
- system.cpu.application.percent.gauge
- system.cpu.system.percent.gauge

// Métricas de runtime
- system.threads.count.gauge
- system.gc.allocated.bytes.gauge
```

---

## 🔄 **Funcionalidades Avançadas**

### **🎯 Gerenciamento Automático de Spans**

O SDK usa uma **pilha LIFO** para gerenciar automaticamente relacionamentos pai-filho:

```pascal
TObservability.StartTransaction('Requisição HTTP');
  TObservability.StartSpan('Autenticação');
    TObservability.StartSpan('Consulta ao Banco');
    TObservability.FinishSpan; // Finaliza Consulta ao Banco
  TObservability.FinishSpan;   // Finaliza Autenticação  
TObservability.FinishTransaction; // Finaliza Requisição HTTP
```

**Resultado**: Hierarquia perfeita com correlação automática de parent_id

### **🧵 Segurança de Thread**

Todas as operações são thread-safe usando seções críticas:

```pascal
// Múltiplas threads podem criar spans com segurança
TThread.CreateAnonymousThread(procedure
begin
  TObservability.StartSpan('Tarefa em Background');
  try
    FazerTrabalhoBackground();
  finally
    TObservability.FinishSpan;
  end;
end).Start;
```

---

## 📋 **Melhores Práticas**

### **🎯 Padrões de Transação**

```pascal
// ✅ BOM: Limites de transação claros
TObservability.StartTransaction('ProcessarPedido', 'business');
try
  ValidarPedido();
  CalcularTotal();
  SalvarNoBanco();
  TObservability.FinishTransaction;
except
  TObservability.FinishTransactionWithOutcome(Failure);
  raise;
end;

// ❌ EVITAR: Limites não claros
TObservability.StartSpan('FazerTudo');
// Muito amplo, difícil de entender o desempenho
```

### **📊 Nomenclatura de Métricas**

```pascal
// ✅ BOM: Nomes descritivos e hierárquicos
TObservability.Metrics.Counter('http.requisicoes.total');
TObservability.Metrics.Gauge('banco.conexoes.ativas');
TObservability.Metrics.Histogram('api.resposta.duracao');

// ❌ EVITAR: Nomes genéricos
TObservability.Metrics.Counter('count');
TObservability.Metrics.Gauge('valor');
```

---

## 🚀 **Características de Desempenho**

### **📈 Benchmarks**

- **Criação de Span**: ~50-100μs por span
- **Overhead de Memória**: ~2-5MB base + ~1KB por span ativo
- **Batching de Rede**: Tamanho de lote configurável (padrão: 100 eventos)
- **Processamento em Background**: Coleta de métricas não-bloqueante

### **⚙️ Funcionalidades de Otimização**

- **Inicialização Preguiçosa**: Provedores só inicializam quando usados
- **Pooling de Conexões**: Clientes HTTP reutilizam conexões
- **Processamento em Lote**: Múltiplos eventos enviados em uma única requisição
- **Circuit Breaking**: Fallback automático em falhas do provedor

---

## 📦 **Dependências & Requisitos**

### **🔧 Requisitos do Sistema**

- **Delphi**: XE ou superior
- **Plataformas Alvo**: Windows (32/64-bit), Linux (64-bit)
- **Framework**: Compatível com VCL/FMX
- **Runtime**: Sem dependências de DLL externas

### **🌐 Serviços Externos**

| Provedor | Serviço | Porta Padrão | Protocolo |
|----------|---------|--------------|-----------|
| **Elastic APM** | APM Server | 8200 | HTTP/HTTPS |
| **Jaeger** | Jaeger Agent | 14268 | HTTP |
| **Sentry** | Sentry DSN | 443 | HTTPS |
| **Datadog** | DD Agent | 8126 | HTTP |

---

## 📊 **Resumo da Referência da API**

### **Classes Principais**
| Classe | Propósito | Thread-Safe | Métodos Principais |
|--------|-----------|-------------|-------------------|
| `TObservability` | API estática principal | ✅ Sim | `StartTransaction`, `StartSpan`, `Metrics` |
| `TObservabilitySDK` | Instância do SDK | ✅ Sim | `Initialize`, `RegisterProvider`, `Shutdown` |
| `TElasticAPMProvider` | Integração Elastic APM | ✅ Sim | `Configure`, `SendBatch` |
| `TObservabilityContext` | Contexto de requisição | ✅ Sim | `Clone`, `CreateChild` |

### **Contratos de Interface**
| Interface | Propósito | Métodos Principais |
|-----------|-----------|-------------------|
| `IObservabilitySpan` | Operações de span | `Finish`, `AddAttribute`, `SetOutcome` |
| `IObservabilityMetrics` | Coleta de métricas | `Counter`, `Gauge`, `Histogram` |
| `IObservabilityConfig` | Configuração de provedor | Propriedades para URLs, tokens, etc. |
| `IObservabilityProvider` | Abstração de provedor | `Initialize`, `GetTracer`, `GetMetrics` |

---

## 🤝 **Contribuindo & Suporte**

### **📝 Diretrizes de Contribuição**

1. **Fork** o repositório
2. **Crie** branch de feature: `git checkout -b feature/funcionalidade-incrivel`
3. **Commit** as mudanças: `git commit -m 'Adiciona funcionalidade incrível'`
4. **Push** para o branch: `git push origin feature/funcionalidade-incrivel`
5. **Abra** Pull Request

### **🐛 Reportando Issues**

Ao reportar problemas, inclua:
- Versão do Delphi e plataforma
- Tipo e configuração do provedor
- Código mínimo para reprodução
- Saída de debug (se aplicável)

---

## 📄 **Licença & Copyright**

```
Licença MIT

Copyright (c) 2025 Juliano Eichelberger

É concedida permissão, gratuitamente, a qualquer pessoa que obtenha uma cópia
deste software e arquivos de documentação associados (o "Software"), para lidar
com o Software sem restrição, incluindo, sem limitação, os direitos de usar,
copiar, modificar, mesclar, publicar, distribuir, sublicenciar e/ou vender
cópias do Software, e permitir que as pessoas a quem o Software é fornecido
o façam, sujeito às seguintes condições:

O aviso de copyright acima e este aviso de permissão devem ser incluídos em todas
as cópias ou partes substanciais do Software.
```

---

*Esta documentação cobre o ObservabilitySDK4D v1.0.0 - Última atualização: Outubro 2025*
│   ├── Context Management
│   └── Configuration
├── Observability Types
│   ├── Tracing (Spans, Traces)
│   ├── Logging (Structured Logs)
│   └── Metrics (Counters, Gauges, Histograms)
└── Providers
    ├── Elastic APM
    ├── Jaeger
    ├── Sentry
    ├── Datadog
    ├── Console
    └── Text File
```

## 🚀 Quick Start

### 1. Basic Setup

```pascal
uses
  Observability.SDK,
  Observability.Provider.Console;

// Initialize the SDK
TObservability.Initialize;

// Register a provider
TObservability.RegisterProvider(TConsoleProvider.Create);
TObservability.SetActiveProvider(opConsole);
```

### 2. Distributed Tracing

```pascal
// Start a span
var Span := TObservability.StartSpan('user-login');
try
  Span.AddAttribute('user.id', '12345');
  Span.AddAttribute('user.email', 'user@example.com');
  
  // Your business logic here
  
  Span.SetOutcome(Success);
finally
  Span.Finish;
end;
```

### 3. Structured Logging

```pascal
// Simple logging
TObservability.LogInfo('User logged in successfully');

// Logging with formatting
TObservability.LogInfo('User %s logged in from %s', ['john.doe', '192.168.1.1']);

// Error logging with exception
try
  // Some operation
except
  on E: Exception do
    TObservability.LogError('Login failed', E);
end;
```

### 4. Metrics Collection

```pascal
// Counter metric
TObservability.Counter('login.attempts', 1.0);

// Gauge metric
TObservability.Gauge('active.users', 42.0);

// Histogram for response times
TObservability.Histogram('request.duration', ResponseTimeMs);
```

### 5. System Metrics (Auto-Collection)

```pascal
// Enable automatic system metrics collection
TObservability.EnableSystemMetrics;

// Custom system metrics with specific options
TObservability.EnableSystemMetrics(
  [smoMemoryUsage, smoCPUUsage, smoThreadCount], // Metrics to collect
  si30Seconds  // Collection interval
);

// Manual collection
TObservability.CollectSystemMetricsOnce;

// Disable when done
TObservability.DisableSystemMetrics;
```

**Available System Metrics:**
- 📊 **Memory Usage**: Application and system memory consumption
- ⚡ **CPU Usage**: Application and system CPU utilization  
- 🧵 **Thread Count**: Number of active threads
- 📁 **Handle Count**: File handles/descriptors (Windows/Linux)
- 🗑️ **GC Metrics**: Garbage collection statistics
- 💾 **Disk I/O**: Read/write operations (optional)
- 🌐 **Network I/O**: Network traffic statistics (optional)

## 🔧 Advanced Configuration

### Provider-Specific Configuration

#### Elastic APM
```pascal
var
  Config: IObservabilityConfig;
  Provider: IObservabilityProvider;
begin
  Config := TObservability.CreateElasticConfig;
  Config.ServiceName := 'my-delphi-app';
  Config.ServiceVersion := '1.0.0';
  Config.Environment := 'production';
  Config.ServerUrl := 'http://localhost:8200';
  Config.ApiKey := 'your-api-key';
  
  Provider := TElasticAPMProvider.Create;
  Provider.Configure(Config);
  TObservability.RegisterProvider(Provider);
end;
```

#### Jaeger Tracing
```pascal
var
  Config: IObservabilityConfig;
begin
  Config := TObservability.CreateJaegerConfig;
  Config.ServiceName := 'my-service';
  Config.ServerUrl := 'http://localhost:14268/api/traces';
  
  TObservability.RegisterProvider(TJaegerProvider.Create(Config));
end;
```

#### Sentry Integration
```pascal
var
  Config: IObservabilityConfig;
begin
  Config := TObservability.CreateSentryConfig;
  Config.ServerUrl := 'https://your-dsn@sentry.io/project-id';
  Config.Environment := 'production';
  
  TObservability.RegisterProvider(TSentryProvider.Create(Config));
end;
```

### Context Management

```pascal
// Create global context
var Context := TObservability.CreateContext;
Context.ServiceName := 'payment-service';
Context.ServiceVersion := '2.1.0';
Context.Environment := 'production';
Context.AddTag('datacenter', 'us-east-1');

TObservability.SetGlobalContext(Context);

// Create child context for request tracing
var ChildContext := TObservability.CreateChildContext(Context);
ChildContext.AddAttribute('request.id', 'req-12345');
```

## 🎯 Common Use Cases

### Web API Monitoring

```pascal
// In your API endpoint
procedure TMyController.ProcessRequest;
var
  Span: IObservabilitySpan;
begin
  Span := TObservability.StartSpan('api.process-request', skServer);
  try
    Span.AddAttribute('http.method', 'POST');
    Span.AddAttribute('http.url', '/api/users');
    Span.AddAttribute('user.id', GetCurrentUserId);
    
    // Process request
    ProcessUserData;
    
    TObservability.Counter('api.requests.success');
    Span.SetOutcome(Success);
  except
    on E: Exception do
    begin
      Span.RecordException(E);
      Span.SetOutcome(Failure);
      TObservability.Counter('api.requests.error');
      raise;
    end;
  end;
end;
```

### Database Operations

```pascal
procedure TUserRepository.SaveUser(const User: TUser);
var
  Span: IObservabilitySpan;
  StartTime: TDateTime;
begin
  Span := TObservability.StartSpan('db.save-user', skClient);
  StartTime := Now;
  try
    Span.AddAttribute('db.table', 'users');
    Span.AddAttribute('db.operation', 'INSERT');
    Span.AddAttribute('user.id', User.Id);
    
    // Execute database operation
    ExecuteSQL('INSERT INTO users...', User);
    
    TObservability.Histogram('db.query.duration', 
      MilliSecondsBetween(Now, StartTime));
    Span.SetOutcome(Success);
  except
    on E: Exception do
    begin
      Span.RecordException(E);
      TObservability.Counter('db.errors');
      raise;
    end;
  end;
end;
```

### Background Task Monitoring

```pascal
procedure TBackgroundProcessor.ProcessQueue;
var
  Span: IObservabilitySpan;
  ProcessedCount: Integer;
begin
  Span := TObservability.StartSpan('background.process-queue', skInternal);
  ProcessedCount := 0;
  try
    while HasPendingItems do
    begin
      ProcessSingleItem;
      Inc(ProcessedCount);
    end;
    
    Span.AddAttribute('items.processed', ProcessedCount);
    TObservability.Gauge('queue.processed.total', ProcessedCount);
    Span.SetOutcome(Success);
  except
    on E: Exception do
    begin
      Span.RecordException(E);
      TObservability.LogError('Background processing failed', E);
      raise;
    end;
  end;
end;
```

## 📊 Metrics Types

### Counters
Track cumulative values that only increase:
```pascal
TObservability.Counter('http.requests.total');
TObservability.Counter('cache.hits', 1.0);
TObservability.Counter('errors.count', 1.0);
```

### Gauges
Track values that can go up and down:
```pascal
TObservability.Gauge('memory.usage.bytes', GetMemoryUsage);
TObservability.Gauge('active.connections', GetActiveConnections);
TObservability.Gauge('queue.size', GetQueueSize);
```

### Histograms
Track distributions of values:
```pascal
TObservability.Histogram('request.duration.ms', ResponseTime);
TObservability.Histogram('payload.size.bytes', PayloadSize);
TObservability.Histogram('db.query.time', QueryDuration);
```

## 🔍 Span Types and Context

### Span Kinds
- **Client**: Outgoing requests (HTTP calls, database queries)
- **Server**: Incoming requests (API endpoints, message handlers)
- **Producer**: Message producers (queue publishers)
- **Consumer**: Message consumers (queue subscribers)
- **Internal**: Internal operations (business logic, calculations)

### Context Propagation
```pascal
// Extract context from HTTP headers
var Context := TObservability.Tracer.ExtractContext(HttpHeaders);

// Start span with extracted context
var Span := TObservability.StartSpan('handle-request', Context);

// Inject context into outgoing headers
TObservability.Tracer.InjectHeaders(OutgoingHeaders);
```

## 🛠️ Installation

1. Add the source path to your project
2. Include the required units in your uses clause
3. Initialize the SDK in your application startup
4. Register and configure your desired providers

### Required Units
```pascal
uses
  Observability.SDK,              // Main SDK interface
  Observability.Provider.Console, // Console provider
  Observability.Provider.Elastic, // Elastic APM provider
  // Add other providers as needed
```

## 📝 Best Practices

### 1. Naming Conventions
- Use descriptive span names: `'user.authenticate'`, `'db.query.users'`
- Use dot notation for hierarchical naming: `'service.operation.suboperation'`
- Keep metric names consistent: `'http.requests.total'`, `'http.request.duration'`

### 2. Attribute Guidelines
- Add meaningful attributes to spans and logs
- Use consistent attribute names across your application
- Avoid high-cardinality attributes in metrics

### 3. Error Handling
```pascal
var Span := TObservability.StartSpan('risky-operation');
try
  // Your code here
  Span.SetOutcome(Success);
except
  on E: Exception do
  begin
    Span.RecordException(E);
    Span.SetOutcome(Failure);
    TObservability.LogError('Operation failed', E);
    raise; // Re-raise the exception
  end;
end;
```

### 4. Resource Management
- Always call `Span.Finish` in a try-finally block
- Use the SDK's helper methods for common patterns
- Properly shutdown the SDK on application exit

## 🚦 Performance Considerations

- The SDK is designed for minimal overhead
- Spans and metrics are processed asynchronously where possible
- Use sampling rates in high-throughput scenarios
- Consider batch sizes for high-volume logging

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

For support and questions, please open an issue in the GitHub repository.

---

**ObservabilitySDK4D** - Making Delphi applications observable in modern cloud environments.
