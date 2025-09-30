# ObservabilitySDK4D

A modern, comprehensive Observability SDK for Delphi applications that provides Application Performance Monitoring (APM), Distributed Tracing, Structured Logging, and Metrics collection capabilities.

## 🚀 Overview

ObservabilitySDK4D is a unified observability solution designed specifically for Delphi applications. It implements industry-standard observability patterns including OpenTelemetry-compatible APIs, providing developers with powerful tools to monitor, debug, and optimize their applications in production environments.

### Key Features

- **🔍 Distributed Tracing**: Track requests across services with automatic span generation and context propagation
- **📝 Structured Logging**: Advanced logging with multiple levels, attributes, and exception tracking
- **📊 Metrics Collection**: Counter, Gauge, Histogram, and Summary metrics with custom tags
- **🔌 Multiple Providers**: Support for popular observability platforms
- **🎯 Thread-Safe**: Built with concurrent applications in mind
- **⚡ High Performance**: Minimal overhead with asynchronous operations
- **🛠️ Easy Integration**: Simple API with helper classes for quick adoption

## 📋 Supported Providers

The SDK supports multiple observability platforms out of the box:

| Provider | Tracing | Logging | Metrics | Description |
|----------|---------|---------|---------|-------------|
| **Elastic APM** | ✅ | ✅ | ✅ | Full Elastic Stack integration |
| **Jaeger** | ✅ | ❌ | ❌ | Distributed tracing focused |
| **Sentry** | ✅ | ✅ | ❌ | Error tracking and performance monitoring |
| **Datadog** | ✅ | ✅ | ✅ | Complete APM solution |
| **Console** | ✅ | ✅ | ✅ | Debug output for development |
| **Text File** | ✅ | ✅ | ✅ | File-based logging and metrics |

## 🏗️ Architecture

The SDK follows a provider-based architecture with three main observability pillars:

```
ObservabilitySDK4D
├── Core Components
│   ├── SDK Manager (Singleton)
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
  
  Provider := TElasticProvider.Create;
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
