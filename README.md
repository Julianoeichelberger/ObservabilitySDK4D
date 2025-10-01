# ObservabilitySDK4D - Comprehensive Documentation

## 📋 **Executive Summary**

**ObservabilitySDK4D** is a comprehensive Delphi framework for Application Performance Monitoring (APM) that provides **distributed tracing**, **metrics collection**, and **observability** for Delphi applications. The SDK offers a **unified API** with support for multiple providers including **Elastic APM**, **Jaeger**, **Sentry**, **Datadog**, and **Console/File** outputs.

### 🎯 **Key Value Propositions**
- **🔄 Multi-Provider Support**: Switch between APM providers without code changes
- **📊 Automatic Instrumentation**: Built-in system metrics and performance tracking  
- **🔗 Distributed Tracing**: Complete request lifecycle tracking across services
- **⚡ Zero-Config**: Works out-of-the-box with sensible defaults
- **🎛️ Thread-Safe**: Production-ready with automatic resource management

---

## 🏗️ **Architecture Overview**

### **Core Components Architecture**
```
┌─────────────────────────────────────────────────────────┐
│                 TObservability (Static API)             │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌──────────────┐  ┌─────────────┐ │
│  │  ITracer        │  │  IMetrics    │  │  ILogger    │ │
│  └─────────────────┘  └──────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────┐
│                Provider Abstraction Layer               │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │IObservability│  │IObservability│  │IObservability│   │
│  │   Provider   │  │   Tracer     │  │   Metrics    │   │
│  └──────────────┘  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────┐
│                    Provider Implementations             │
├─────────────────────────────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────────┐ │
│ │ Elastic │ │ Jaeger  │ │ Sentry  │ │ Console/File    │ │
│ │   APM   │ │ Tracing │ │   APM   │ │    Providers    │ │
│ └─────────┘ └─────────┘ └─────────┘ └─────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### **Data Flow Architecture**
```
Application Code
       │
   ┌───▼───┐      ┌─────────────┐      ┌──────────────┐
   │ Start │      │   Span      │      │   Provider   │
   │ Span  │ ──── │   Stack     │ ──── │  (Elastic/   │ ──── APM Server
   │       │      │ Management  │      │   Jaeger)    │
   └───────┘      └─────────────┘      └──────────────┘
       │                  │                     │
   ┌───▼───┐      ┌─────────────┐      ┌──────────────┐
   │Finish │      │   Context   │      │   Metrics    │
   │ Span  │      │ Propagation │      │  Collection  │ ──── Metrics Storage
   └───────┘      └─────────────┘      └──────────────┘
```

---

## 🚀 **Quick Start Guide**

### **1. Basic Setup (30 seconds)**
```pascal
program MyApp;
uses
  Observability.SDK,
  Observability.Provider.Elastic;

begin
  // Configure Elastic APM
  var Config := TObservability.CreateElasticConfig;
  Config.ServiceName := 'my-service';
  Config.ServerUrl := 'http://localhost:8200';
  
  // Initialize
  TObservability.RegisterProvider(TElasticAPMProvider.Create.Configure(Config));
  TObservability.SetActiveProvider(opElastic);
  TObservability.Initialize;
  
  // Your application code here
  TObservability.StartTransaction('Main Process');
  try
    DoSomething();
  finally
    TObservability.FinishTransaction;
  end;
  
  TObservability.Shutdown;
end.
```

### **2. Advanced Usage with Custom Metrics**
```pascal
// Start a transaction
TObservability.StartTransaction('User Registration', 'request');

try
  // Create nested spans
  TObservability.StartSpan('Validate Input');
  ValidateUserData();
  TObservability.FinishSpan;
  
  TObservability.StartSpan('Database Insert');
  SaveUserToDatabase();
  TObservability.FinishSpan;
  
  // Custom metrics
  TObservability.Metrics.Counter('users.registered', 1);
  TObservability.Metrics.Gauge('database.connections', GetActiveConnections());
  
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

## 📚 **Core Components Reference**

### **🎯 TObservability - Main Static API**

**Purpose**: Central facade providing static methods for all observability operations

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
Config.SecretToken := 'your-token';  // Optional
Config.ServiceName := 'my-app';
Config.Environment := 'production';

var Provider := TElasticAPMProvider.Create;
Provider.Configure(Config);
TObservability.RegisterProvider(Provider);
TObservability.SetActiveProvider(opElastic);
```

**Data Structures**:
- **Transactions**: `{"transaction": {..., "span_count": {"started": N}}}`
- **Spans**: `{"span": {..., "parent_id": "xxx"}}`
- **Metrics**: `{"metricset": {"timestamp": ..., "samples": {...}}}`

---

## 📊 **Metrics System**

### **Metric Types**

```pascal
// Counter - Monotonically increasing values
TObservability.Metrics.Counter('http.requests.total', 1);
TObservability.Metrics.Counter('errors.count', 1, Tags);

// Gauge - Point-in-time values
TObservability.Metrics.Gauge('memory.usage.bytes', MemoryUsed);
TObservability.Metrics.Gauge('cpu.utilization.percent', CPUPercent);

// Histogram - Distribution of values
TObservability.Metrics.Histogram('http.request.duration', ElapsedMs);
TObservability.Metrics.Histogram('database.query.time', QueryTimeMs);
```

### **System Metrics (Automatic)**

When `TObservability.EnableSystemMetrics` is called:

```pascal
// Memory metrics
- system.memory.application.bytes.gauge
- system.memory.used.mb.gauge  
- system.memory.available.mb.gauge
- system.memory.total.mb.gauge
- system.memory.usage.percent.gauge

// CPU metrics  
- system.cpu.application.percent.gauge
- system.cpu.system.percent.gauge

// Runtime metrics
- system.threads.count.gauge
- system.gc.allocated.bytes.gauge
```

---

## 🔄 **Advanced Features**

### **🎯 Automatic Span Management**

The SDK uses a **LIFO stack** to automatically manage parent-child relationships:

```pascal
TObservability.StartTransaction('HTTP Request');
  TObservability.StartSpan('Authentication');
    TObservability.StartSpan('Database Query');
    TObservability.FinishSpan; // Finishes Database Query
  TObservability.FinishSpan;   // Finishes Authentication  
TObservability.FinishTransaction; // Finishes HTTP Request
```

**Result**: Perfect hierarchy with automatic parent_id correlation

### **🧵 Thread Safety**

All operations are thread-safe using critical sections:

```pascal
// Multiple threads can safely create spans
TThread.CreateAnonymousThread(procedure
begin
  TObservability.StartSpan('Background Task');
  try
    DoBackgroundWork();
  finally
    TObservability.FinishSpan;
  end;
end).Start;
```

---

## 📋 **Best Practices**

### **🎯 Transaction Patterns**

```pascal
// ✅ GOOD: Clear transaction boundaries
TObservability.StartTransaction('ProcessOrder', 'business');
try
  ValidateOrder();
  CalculateTotal();
  SaveToDatabase();
  TObservability.FinishTransaction;
except
  TObservability.FinishTransactionWithOutcome(Failure);
  raise;
end;

// ❌ AVOID: Unclear boundaries
TObservability.StartSpan('DoEverything');
// Too broad, hard to understand performance
```

### **📊 Metrics Naming**

```pascal
// ✅ GOOD: Descriptive, hierarchical names
TObservability.Metrics.Counter('http.requests.total');
TObservability.Metrics.Gauge('database.connections.active');
TObservability.Metrics.Histogram('api.response.duration');

// ❌ AVOID: Generic names
TObservability.Metrics.Counter('count');
TObservability.Metrics.Gauge('value');
```

---

## 🚀 **Performance Characteristics**

### **📈 Benchmarks**

- **Span Creation**: ~50-100μs per span
- **Memory Overhead**: ~2-5MB baseline + ~1KB per active span
- **Network Batching**: Configurable batch size (default: 100 events)
- **Background Processing**: Non-blocking metrics collection

### **⚙️ Optimization Features**

- **Lazy Initialization**: Providers only initialize when used
- **Connection Pooling**: HTTP clients reuse connections
- **Batch Processing**: Multiple events sent in single request
- **Circuit Breaking**: Automatic fallback on provider failures

---

## 📦 **Dependencies & Requirements**

### **🔧 System Requirements**

- **Delphi**: 10.3 Rio or newer
- **Target Platforms**: Windows (32/64-bit), Linux (64-bit)
- **Framework**: VCL/FMX compatible
- **Runtime**: No external DLL dependencies

### **🌐 External Services**

| Provider | Service | Default Port | Protocol |
|----------|---------|--------------|----------|
| **Elastic APM** | APM Server | 8200 | HTTP/HTTPS |
| **Jaeger** | Jaeger Agent | 14268 | HTTP |
| **Sentry** | Sentry DSN | 443 | HTTPS |
| **Datadog** | DD Agent | 8126 | HTTP |

---

## 📊 **API Reference Summary**

### **Core Classes**
| Class | Purpose | Thread-Safe | Key Methods |
|-------|---------|-------------|-------------|
| `TObservability` | Main static API | ✅ Yes | `StartTransaction`, `StartSpan`, `Metrics` |
| `TObservabilitySDK` | SDK instance | ✅ Yes | `Initialize`, `RegisterProvider`, `Shutdown` |
| `TElasticAPMProvider` | Elastic APM integration | ✅ Yes | `Configure`, `SendBatch` |
| `TObservabilityContext` | Request context | ✅ Yes | `Clone`, `CreateChild` |

### **Interface Contracts**
| Interface | Purpose | Key Methods |
|-----------|---------|-------------|
| `IObservabilitySpan` | Span operations | `Finish`, `AddAttribute`, `SetOutcome` |
| `IObservabilityMetrics` | Metrics collection | `Counter`, `Gauge`, `Histogram` |
| `IObservabilityConfig` | Provider configuration | Properties for URLs, tokens, etc. |
| `IObservabilityProvider` | Provider abstraction | `Initialize`, `GetTracer`, `GetMetrics` |

---

## 🤝 **Contributing & Support**

### **📝 Contributing Guidelines**

1. **Fork** the repository
2. **Create** feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** changes: `git commit -m 'Add amazing feature'`
4. **Push** to branch: `git push origin feature/amazing-feature`
5. **Open** Pull Request

### **🐛 Issue Reporting**

When reporting issues, include:
- Delphi version and platform
- Provider type and configuration
- Minimal reproduction code
- Debug output (if applicable)

---

## 📄 **License & Copyright**

```
MIT License

Copyright (c) 2025 Juliano Eichelberger

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

*This documentation covers ObservabilitySDK4D v1.0.0 - Last updated: October 2025*
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
