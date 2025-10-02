# ObservabilitySDK4D - Complete Documentation

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Delphi](https://img.shields.io/badge/Delphi-10.3%2B-red.svg)](https://www.embarcadero.com/products/delphi)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-blue.svg)](https://github.com/Julianoeichelberger/ObservabilitySDK4D)

> A comprehensive **Application Performance Monitoring (APM)** and **Observability** framework for Delphi applications with support for distributed tracing, metrics collection, and structured logging.

## ?? Table of Contents

- [?? Overview](#-overview)
- [??? Architecture](#?-architecture)
- [?? Quick Start](#-quick-start)
- [?? Core Concepts](#-core-concepts)
- [?? Supported Providers](#-supported-providers)
- [?? Metrics System](#-metrics-system)
- [?? Distributed Tracing](#-distributed-tracing)
- [?? Structured Logging](#-structured-logging)
- [?? Advanced Configuration](#?-advanced-configuration)
- [?? Practical Examples](#-practical-examples)
- [??? Installation](#?-installation)
- [?? API Reference](#-api-reference)
- [?? Contributing](#-contributing)

## ?? Overview

**ObservabilitySDK4D** is a modern observability framework for Delphi that enables monitoring, tracing, and analyzing your application performance in real-time. With multi-provider support and a unified API, you can easily integrate complete observability into your Delphi projects.

### ? Key Features

- **?? Multi-Provider Support**: Elastic APM, Jaeger, Sentry, Datadog, Console
- **?? Complete Observability**: Tracing, Metrics, and Logging in one SDK
- **?? Distributed Tracing**: Track requests across microservices
- **? Zero Configuration**: Works out-of-the-box with sensible defaults
- **?? Thread-Safe**: Production-ready with automatic resource management
- **?? Auto-Metrics**: Automatic system metrics collection (CPU, Memory, GC)

### ?? Benefits

1. **Complete Visibility**: See exactly how your application is performing
2. **Fast Problem Detection**: Identify bottlenecks and errors in real-time
3. **Performance Analysis**: Understand usage patterns and optimize performance
4. **Data Correlation**: Connect logs, metrics, and traces for complete investigation
5. **Proactive Monitoring**: Receive alerts before problems affect users

## ??? Architecture

### ??? Architecture Overview

```
???????????????????????????????????????????????????????????
?                TObservability (Static API)              ?
???????????????????????????????????????????????????????????
? ??????????????? ??????????????? ??????????????????????? ?
? ?   Tracing   ? ?   Metrics   ? ?      Logging        ? ?
? ?    (APM)    ? ? Collection  ? ?   (Structured)      ? ?
? ??????????????? ??????????????? ??????????????????????? ?
???????????????????????????????????????????????????????????
                              ?
???????????????????????????????????????????????????????????
?              Provider Abstraction Layer                 ?
???????????????????????????????????????????????????????????
                              ?
???????????????????????????????????????????????????????????
? ?? Elastic  ??? Jaeger  ??? Sentry  ?? Datadog  ?? Console ?
???????????????????????????????????????????????????????????
```

### ?? Data Flow

```
Application Code
        ?
    ?????????      ???????????????      ????????????????
    ? Create?      ?    Span     ?      ?   Provider   ?
    ? Span  ? ???? ?   Stack     ? ???? ?  (Elastic/   ? ???? APM Server
    ?       ?      ? Management  ?      ?   Jaeger)    ?
    ?????????      ???????????????      ????????????????
        ?                  ?                     ?
    ?????????      ???????????????      ????????????????
    ?Finish ?      ?  Context    ?      ?   Metrics    ?
    ? Span  ?      ? Propagation ?      ?  Collection  ? ???? Storage
    ?????????      ???????????????      ????????????????
```

## ?? Quick Start

### 1. Basic Setup (30 seconds)

```pascal
program MyApp;
uses
  Observability.SDK,
  Observability.Provider.Console;

begin
  // Initialize ObservabilitySDK4D
  TObservability.Initialize;
  TObservability.RegisterProvider(TConsoleProvider.Create);
  TObservability.SetActiveProvider(opConsole);
  
  // Start tracing your application
  var Span := TObservability.StartSpan('user-operation');
  try
    Span.SetAttribute('user.id', '12345');
    Span.SetAttribute('operation', 'login');
    
    // Your business logic here
    ProcessLogin();
    
    Span.SetOutcome(Success);
  finally
    Span.Finish;
  end;
  
  TObservability.Shutdown;
end.
```

### 2. Advanced Usage with Custom Metrics

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
  TObservability.Metrics.Gauge('database.active_connections', GetActiveConnections());
  
  TObservability.FinishTransaction;
except
  on E: Exception do
  begin
    TObservability.RecordSpanException(E);
    TObservability.FinishTransactionWithOutcome(Failure);
  end;
end;
```

## ?? Core Concepts

### ?? **APM (Application Performance Monitoring)**
Monitoring application performance, response times, throughput, and error rates in real-time.

**Benefits:**
- Proactive detection of performance issues
- Real-time bottleneck analysis
- Availability and reliability metrics
- User behavior insights

### ?? **Distributed Tracing**
Track requests as they flow through multiple services, creating a complete picture of system behavior.

**Key Concepts:**
- **Trace**: Complete journey of a request
- **Span**: Individual unit of work within a trace
- **Context**: Information connecting related spans

### ?? **OpenTelemetry Compatibility**
Built following OpenTelemetry principles for vendor-neutral observability.

**Advantages:**
- Industry standard for observability
- Interoperability between different tools
- Future-proof for provider changes

### ?? **Metrics Collection**

#### **Counters**
Cumulative values that only increase (requests, errors):
```pascal
TObservability.Metrics.Counter('http.requests.total', 1);
TObservability.Metrics.Counter('cache.hits', 1);
```

#### **Gauges**
Point-in-time values that can go up and down (memory, connections):
```pascal
TObservability.Metrics.Gauge('memory.usage.bytes', GetMemoryUsage);
TObservability.Metrics.Gauge('active.connections', GetActiveConnections);
```

#### **Histograms**
Distribution of values (response times):
```pascal
TObservability.Metrics.Histogram('response.time.ms', ResponseTime);
TObservability.Metrics.Histogram('payload.size.bytes', PayloadSize);
```

### ?? **Structured Logging**
Rich, searchable logs with context and correlation across distributed systems.

**Features:**
- Structured JSON logs
- Automatic correlation with traces
- Multiple log levels (DEBUG, INFO, WARN, ERROR)
- Custom attributes and context

## ?? Supported Providers

### ?? Support Matrix

| Provider | Tracing | Metrics | Logging | Error Tracking | Status |
|----------|---------|---------|---------|----------------|--------|
| **?? Elastic APM** | ? | ? | ? | ? | ?? Production Ready |
| **??? Jaeger** | ? | ? | ? | ? | ?? Production Ready |
| **??? Sentry** | ? | ?* | ? | ? | ?? Production Ready |
| **?? Datadog** | ? | ? | ? | ? | ?? Production Ready |
| **?? Console** | ? | ? | ? | ? | ?? Development |
| **?? TextFile** | ? | ? | ? | ? | ?? Development |

> *Sentry metrics are not natively supported by Sentry platform

### ?? **Elastic APM Provider**

**Complete Features:**
- ? Full APM 8.x protocol support
- ? Transactions, spans, and metrics
- ? NDJSON batch format
- ? Automatic parent-child correlation
- ? System metrics collection

**Configuration:**
```pascal
var Config := TObservability.CreateElasticConfig;
Config.ServerUrl := 'http://localhost:8200';
Config.SecretToken := 'your-token';
Config.ServiceName := 'my-app';
Config.Environment := 'production';

var Provider := TElasticAPMProvider.Create;
Provider.Configure(Config);
TObservability.RegisterProvider(Provider);
TObservability.SetActiveProvider(opElastic);
```

**Usage Example:**
```pascal
// Complete samples and examples available in /Samples/Elastic
docker-compose up -d  // Starts Elasticsearch + Kibana + APM Server
```

### ??? **Jaeger Provider**

**Features:**
- ? OpenTelemetry Protocol (OTLP)
- ? Complete distributed tracing
- ? B3/W3C context correlation
- ? Metrics (not supported by Jaeger)

**Configuration:**
```pascal
var Config := TObservability.CreateJaegerConfig;
Config.ServiceName := 'my-service';
Config.ServerUrl := 'http://localhost:14268/api/traces';

TObservability.RegisterProvider(TJaegerProvider.Create(Config));
```

### ??? **Sentry Provider**

**Features:**
- ? Advanced error tracking
- ? Performance monitoring
- ? Structured logging with breadcrumbs
- ? Release tracking and deployment

**Configuration:**
```pascal
var Config := TObservability.CreateSentryConfig;
Config.ServerUrl := 'https://your-dsn@sentry.io/project-id';
Config.Environment := 'production';
Config.ServiceVersion := '1.0.0';

TObservability.RegisterProvider(TSentryProvider.Create(Config));
```

### ?? **Datadog Provider**

**Complete Features:**
- ? Full APM with trace correlation
- ? Custom and system metrics
- ? Structured logging
- ? Infrastructure integration

**Configuration:**
```pascal
var Config := TObservability.CreateDatadogConfig;
Config.ApiKey := 'your-datadog-api-key';
Config.ServiceName := 'my-app';
Config.ServerUrl := 'http://localhost:8126'; // Datadog Agent

TObservability.RegisterProvider(TDatadogProvider.Create(Config));
```

## ?? Metrics System

### ?? Automatic System Metrics

When `TObservability.EnableSystemMetrics` is called:

```pascal
// Memory metrics
- system.memory.application.bytes.gauge     // Application memory usage
- system.memory.used.mb.gauge              // Total system memory used
- system.memory.available.mb.gauge         // Available memory
- system.memory.total.mb.gauge             // Total system memory
- system.memory.usage.percent.gauge        // Memory usage percentage

// CPU metrics
- system.cpu.application.percent.gauge     // Application CPU usage
- system.cpu.system.percent.gauge          // System CPU usage

// Runtime metrics
- system.threads.count.gauge               // Active thread count
- system.gc.allocated.bytes.gauge          // Bytes allocated by GC
```

**Enabling:**
```pascal
// Enable automatic collection
TObservability.EnableSystemMetrics;

// Or with specific options
TObservability.EnableSystemMetrics(
  [smoMemoryUsage, smoCPUUsage, smoThreadCount], // Metrics to collect
  si30Seconds  // Collection interval
);

// Manual one-time collection
TObservability.CollectSystemMetricsOnce;

// Disable when done
TObservability.DisableSystemMetrics;
```

### ?? Custom Metrics

```pascal
// Counter - Track number of operations
TObservability.Metrics.Counter('api.requests.total', 1);
TObservability.Metrics.Counter('cache.hits', 1);

// Gauge - Point-in-time values
TObservability.Metrics.Gauge('memory.usage.bytes', GetMemoryUsage);
TObservability.Metrics.Gauge('active.users', GetActiveUsers);

// Histogram - Distribution of values
TObservability.Metrics.Histogram('http.response.time.ms', ResponseTime);
TObservability.Metrics.Histogram('db.query.duration', QueryDuration);
```

## ?? Distributed Tracing

### ?? Span Types and Context

#### **Span Kinds:**
- **Client**: Outgoing requests (HTTP calls, database queries)
- **Server**: Incoming requests (API endpoints, message handlers)
- **Producer**: Message producers (queue publishers)
- **Consumer**: Message consumers (queue subscribers)
- **Internal**: Internal operations (business logic, calculations)

#### **Context Propagation:**
```pascal
// Extract context from HTTP headers
var Context := TObservability.Tracer.ExtractContext(HttpHeaders);

// Start span with extracted context
var Span := TObservability.StartSpan('handle-request', Context);

// Inject context into outgoing headers
TObservability.Tracer.InjectHeaders(OutgoingHeaders);
```

### ?? Automatic Span Management

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

## ?? Structured Logging

### ?? Log Levels

```pascal
// Simple logging
TObservability.LogTrace('Operation started');
TObservability.LogDebug('Variable value: %d', [variableValue]);
TObservability.LogInfo('User logged in successfully');
TObservability.LogWarning('Cache miss detected');
TObservability.LogError('Operation failed', exception);
TObservability.LogCritical('System unavailable');
```

### ??? Logs with Attributes

```pascal
var
  Logger: IObservabilityLogger;
  Attributes: TDictionary<string, string>;
begin
  Logger := TObservability.GetLogger;
  Attributes := TDictionary<string, string>.Create;
  try
    Attributes.Add('user_id', '12345');
    Attributes.Add('operation', 'login');
    Attributes.Add('ip_address', '192.168.1.100');
    
    Logger.Info('Login successful', Attributes);
  finally
    Attributes.Free;
  end;
end;
```

### ?? Automatic Correlation

Logs are automatically correlated with active traces:
```pascal
var Span := TObservability.StartSpan('process-order');
try
  // This log will be automatically associated with the active span
  TObservability.LogInfo('Processing order #12345');
  
  // With additional attributes
  var Attrs := TDictionary<string, string>.Create;
  Attrs.Add('order_id', '12345');
  Attrs.Add('amount', '299.99');
  TObservability.LogInfo('Order validated', Attrs);
  Attrs.Free;
finally
  Span.Finish;
end;
```

## ?? Advanced Configuration

### ?? Provider-Specific Configuration

#### **Complete Elastic APM Configuration:**
```pascal
var Config := TObservability.CreateElasticConfig;
Config.ServiceName := 'my-delphi-app';
Config.ServiceVersion := '1.0.0';
Config.Environment := 'production';
Config.ServerUrl := 'https://apm.mycompany.com:8200';
Config.SecretToken := 'your-secret-token';

// Advanced settings via custom properties
var CustomProps := TDictionary<string, string>.Create;
CustomProps.Add('capture_body', 'all');
CustomProps.Add('transaction_sample_rate', '1.0');
Config.CustomProperties := CustomProps;

var Provider := TElasticAPMProvider.Create;
Provider.Configure(Config);
TObservability.RegisterProvider(Provider);
```

#### **Datadog Configuration with Global Tags:**
```pascal
var Config := TObservability.CreateDatadogConfig;
Config.ApiKey := 'your-datadog-api-key';
Config.ServiceName := 'payment-api';
Config.Environment := 'production';

// Global tags
var CustomProps := TDictionary<string, string>.Create;
CustomProps.Add('team', 'backend');
CustomProps.Add('component', 'api');
CustomProps.Add('datacenter', 'us-east-1');
Config.CustomProperties := CustomProps;

TObservability.RegisterProvider(TDatadogProvider.Create(Config));
```

### ?? Multi-Provider Configuration

```pascal
// Register multiple providers
var ElasticConfig := TObservability.CreateElasticConfig;
ElasticConfig.ServiceName := 'my-service';
ElasticConfig.ServerUrl := 'http://localhost:8200';

var SentryConfig := TObservability.CreateSentryConfig;
SentryConfig.ServerUrl := 'https://your-dsn@sentry.io/project';

// Register both
TObservability.RegisterProvider(TElasticAPMProvider.Create(ElasticConfig));
TObservability.RegisterProvider(TSentryProvider.Create(SentryConfig));

// Use Elastic APM as primary
TObservability.SetActiveProvider(opElastic);

// Switch to Sentry if needed
TObservability.SetActiveProvider(opSentry);
```

## ?? Practical Examples

### ?? Web API Monitoring

```pascal
procedure TMyController.ProcessRequest;
var
  Span: IObservabilitySpan;
begin
  Span := TObservability.StartSpan('api.process-request', skServer);
  try
    Span.SetAttribute('http.method', 'POST');
    Span.SetAttribute('http.url', '/api/users');
    Span.SetAttribute('user.id', GetCurrentUser);
    
    // Process request
    ProcessUserData;
    
    TObservability.Metrics.Counter('api.requests.success', 1);
    Span.SetOutcome(Success);
  except
    on E: Exception do
    begin
      Span.RecordException(E);
      Span.SetOutcome(Failure);
      TObservability.Metrics.Counter('api.requests.error', 1);
      TObservability.LogError('Request processing failed', E);
      raise;
    end;
  end;
end;
```

### ??? Database Operations

```pascal
procedure TUserRepository.SaveUser(const User: TUser);
var
  Span: IObservabilitySpan;
  StartTime: TDateTime;
begin
  Span := TObservability.StartSpan('db.save-user', skClient);
  StartTime := Now;
  try
    Span.SetAttribute('db.table', 'users');
    Span.SetAttribute('db.operation', 'INSERT');
    Span.SetAttribute('user.id', User.Id);
    
    // Execute database operation
    ExecuteSQL('INSERT INTO users...', User);
    
    TObservability.Metrics.Histogram('db.query.duration', 
      MilliSecondsBetween(Now, StartTime));
    
    TObservability.LogInfo('User saved successfully', 
      TDictionary<string, string>.Create.AddOrSetValue('user.id', User.Id));
    
    Span.SetOutcome(Success);
  except
    on E: Exception do
    begin
      Span.RecordException(E);
      TObservability.Metrics.Counter('db.errors', 1);
      TObservability.LogError('Failed to save user', E);
      raise;
    end;
  end;
end;
```

### ?? Background Processing

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
      
      // Update metrics every 10 items
      if ProcessedCount mod 10 = 0 then
      begin
        TObservability.Metrics.Gauge('queue.items.processed', ProcessedCount);
        TObservability.LogDebug('Progress: %d items processed', [ProcessedCount]);
      end;
    end;
    
    Span.SetAttribute('items.processed', ProcessedCount);
    TObservability.Metrics.Counter('queue.processing.complete', 1);
    
    TObservability.LogInfo('Queue processing completed', 
      TDictionary<string, string>.Create.AddOrSetValue('total_items', IntToStr(ProcessedCount)));
    
    Span.SetOutcome(Success);
  except
    on E: Exception do
    begin
      Span.RecordException(E);
      TObservability.LogError('Background processing failed', E);
      TObservability.Metrics.Counter('queue.processing.error', 1);
      raise;
    end;
  end;
end;
```

### ?? External Service Integration

```pascal
function TPaymentService.ProcessPayment(const Payment: TPayment): TPaymentResult;
var
  Span: IObservabilitySpan;
  HttpClient: THttpClient;
  ExternalSpan: IObservabilitySpan;
begin
  Span := TObservability.StartSpan('payment.process', skInternal);
  try
    Span.SetAttribute('payment.id', Payment.Id);
    Span.SetAttribute('payment.amount', FloatToStr(Payment.Amount));
    
    // Validation
    ExternalSpan := TObservability.StartSpan('payment.validate', skInternal);
    try
      ValidatePayment(Payment);
      ExternalSpan.SetOutcome(Success);
    finally
      ExternalSpan.Finish;
    end;
    
    // External gateway call
    ExternalSpan := TObservability.StartSpan('gateway.process', skClient);
    try
      ExternalSpan.SetAttribute('gateway.provider', 'stripe');
      ExternalSpan.SetAttribute('http.method', 'POST');
      ExternalSpan.SetAttribute('http.url', 'https://api.stripe.com/charges');
      
      // Inject context into headers
      HttpClient := THttpClient.Create;
      TObservability.Tracer.InjectHeaders(HttpClient.CustomHeaders);
      
      Result := CallPaymentGateway(HttpClient, Payment);
      
      ExternalSpan.SetAttribute('gateway.transaction_id', Result.TransactionId);
      ExternalSpan.SetOutcome(Success);
      
      TObservability.Metrics.Counter('payment.gateway.success', 1);
    except
      on E: Exception do
      begin
        ExternalSpan.RecordException(E);
        ExternalSpan.SetOutcome(Failure);
        TObservability.Metrics.Counter('payment.gateway.error', 1);
        raise;
      end;
    finally
      ExternalSpan.Finish;
      HttpClient.Free;
    end;
    
    Span.SetOutcome(Success);
    TObservability.LogInfo('Payment processed successfully', 
      TDictionary<string, string>.Create
        .AddOrSetValue('payment.id', Payment.Id)
        .AddOrSetValue('transaction.id', Result.TransactionId));
        
  except
    on E: Exception do
    begin
      Span.RecordException(E);
      Span.SetOutcome(Failure);
      TObservability.LogError('Payment processing failed', E);
      raise;
    end;
  finally
    Span.Finish;
  end;
end;
```

## ??? Installation

### ?? System Requirements

- **Delphi**: 10.3 Rio or newer
- **Target Platforms**: Windows (32/64-bit), Linux (64-bit)
- **Framework**: VCL/FMX compatible
- **Runtime**: No external DLL dependencies

### ?? Installation Steps

1. **Download**: Clone or download the repository
```bash
git clone https://github.com/Julianoeichelberger/ObservabilitySDK4D.git
```

2. **Add Path**: Add `source` folder to your project library path

3. **Include Units**: Add required units to your uses clause
```pascal
uses
  Observability.SDK,
  Observability.Provider.Elastic, // or your preferred provider
  Observability.Provider.Console;
```

4. **Initialize**: Configure and initialize in your application
```pascal
initialization
  TObservability.Initialize;
  // Configure providers...

finalization
  TObservability.Shutdown;
```

### ?? External Services

| Provider | Service | Default Port | Protocol |
|----------|---------|--------------|----------|
| **Elastic APM** | APM Server | 8200 | HTTP/HTTPS |
| **Jaeger** | Jaeger Agent | 14268 | HTTP |
| **Sentry** | Sentry DSN | 443 | HTTPS |
| **Datadog** | DD Agent | 8126 | HTTP |

## ?? API Reference

### ??? Core Classes

| Class | Purpose | Thread-Safe | Key Methods |
|-------|---------|-------------|-------------|
| `TObservability` | Main static API | ? Yes | `StartTransaction`, `StartSpan`, `Metrics` |
| `TObservabilitySDK` | SDK instance | ? Yes | `Initialize`, `RegisterProvider`, `Shutdown` |
| `TElasticAPMProvider` | Elastic APM integration | ? Yes | `Configure`, `SendBatch` |
| `TObservabilityContext` | Request context | ? Yes | `Clone`, `CreateChild` |

### ?? Interface Contracts

| Interface | Purpose | Key Methods |
|-----------|---------|-------------|
| `IObservabilitySpan` | Span operations | `Finish`, `SetAttribute`, `SetOutcome` |
| `IObservabilityMetrics` | Metrics collection | `Counter`, `Gauge`, `Histogram` |
| `IObservabilityConfig` | Provider configuration | Properties for URLs, tokens, etc. |
| `IObservabilityProvider` | Provider abstraction | `Initialize`, `GetTracer`, `GetMetrics` |

### ? Performance Characteristics

#### ?? Benchmarks

- **Span Creation**: ~50-100?s per span
- **Memory Overhead**: ~2-5MB baseline + ~1KB per active span
- **Network Batching**: Configurable batch size (default: 100 events)
- **Background Processing**: Non-blocking metrics collection

#### ?? Optimization Features

- **Lazy Initialization**: Providers only initialize when used
- **Connection Pooling**: HTTP clients reuse connections
- **Batch Processing**: Multiple events sent in single request
- **Circuit Breaking**: Automatic fallback on provider failures

## ?? Best Practices

### ?? Transaction Patterns

```pascal
// ? GOOD: Clear transaction boundaries
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

// ? AVOID: Unclear boundaries
TObservability.StartSpan('DoEverything');
// Too broad, hard to understand performance
```

### ?? Metrics Naming

```pascal
// ? GOOD: Descriptive, hierarchical names
TObservability.Metrics.Counter('http.requests.total');
TObservability.Metrics.Gauge('database.connections.active');
TObservability.Metrics.Histogram('api.response.duration');

// ? AVOID: Generic names
TObservability.Metrics.Counter('count');
TObservability.Metrics.Gauge('value');
```

### ??? Attribute Guidelines

```pascal
// ? GOOD: Meaningful attributes
Span.SetAttribute('user.id', '12345');
Span.SetAttribute('http.method', 'POST');
Span.SetAttribute('db.table', 'users');

// ? AVOID: High-cardinality attributes in metrics
// Avoid unique IDs in metric tags
```

### ??? Error Handling

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

### ?? Resource Management

- Always call `Span.Finish` in a try-finally block
- Use the SDK's helper methods for common patterns
- Properly shutdown the SDK on application exit

## ?? Sample Environments

Each provider includes complete Docker Compose environments for quick testing:

### ?? **Elastic Stack**
```bash
cd Samples/Elastic
.\elastic.ps1 start
# Access: http://localhost:5601 (Kibana)
```

### ??? **Jaeger**
```bash
cd Samples/Jaeger  
.\jaeger.ps1 start
# Access: http://localhost:16686 (Jaeger UI)
```

### ??? **Sentry**
```bash
cd Samples/Sentry
.\sentry.ps1 start
# Access: http://localhost:9000 (Sentry Web)
```

### ?? **Datadog**
```bash
cd Samples/Datadog
.\datadog.ps1 start
# Configure your API key and access: https://app.datadoghq.com
```

## ?? Performance Considerations

- The SDK is designed for minimal overhead
- Spans and metrics are processed asynchronously where possible
- Use sampling rates in high-throughput scenarios
- Consider batch sizes for high-volume logging

## ?? Contributing

Contributions are welcome! Please:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** your changes: `git commit -m 'Add amazing feature'`
4. **Push** to the branch: `git push origin feature/amazing-feature`
5. **Open** a Pull Request

### ?? Contributing Guidelines

- Follow existing code patterns
- Add tests for new functionality
- Update documentation as needed
- Ensure compatibility with Delphi 10.3+

### ?? Issue Reporting

When reporting issues, include:
- Delphi version and platform
- Provider type and configuration
- Minimal reproduction code
- Debug output (if applicable)

## ?? License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

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

## ?? Support

- **?? Documentation**: Check the language-specific documentation links
- **?? Issues**: [GitHub Issues](https://github.com/Julianoeichelberger/ObservabilitySDK4D/issues)
- **?? Discussions**: [GitHub Discussions](https://github.com/Julianoeichelberger/ObservabilitySDK4D/discussions)
- **?? Email**: For commercial support, contact us

---

<div align="center">

**ObservabilitySDK4D** - Making Delphi applications observable in modern cloud environments.

[? Star this project](https://github.com/Julianoeichelberger/ObservabilitySDK4D) • [?? Fork](https://github.com/Julianoeichelberger/ObservabilitySDK4D/fork) • [?? Docs](../README.md) • [?? Issues](https://github.com/Julianoeichelberger/ObservabilitySDK4D/issues)

</div>

---

*This documentation covers ObservabilitySDK4D v1.0.0 - Last updated: October 2025*