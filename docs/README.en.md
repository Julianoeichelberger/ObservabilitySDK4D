# Observability SDK for Delphi (ObservabilitySDK4D)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Languages: [Português](../README.md) | English (Current) | [Español](./README.es.md) | [Deutsch](./README.de.md)

---

`ObservabilitySDK4D` is a powerful and extensible framework for Delphi, designed to integrate observability capabilities (Tracing, Logging, and Metrics) into your applications in a unified way. With support for multiple providers like **Jaeger**, **Elastic APM**, **Datadog**, **Sentry**, and others, it allows developers to monitor the health, performance, and behavior of their applications centrally.

## ✨ Key Features

- **Unified API**: A single API to interact with different observability backends.
- **Distributed Tracing**: Track the flow of operations across multiple services with Spans and Transactions.
- **Structured Logging**: Send logs enriched with tracing context, environment information, and custom attributes.
- **Application Metrics**: Collect essential metrics like Counters, Gauges, and Histograms.
- **Provider Management**: Support for multiple providers, allowing you to switch or use several simultaneously.
- **Flexible Configuration**: Configure each provider with specific parameters, such as server endpoints, API keys, and sampling rates.
- **Extensible**: The interface-based architecture makes it easy to create your own observability providers.
- **Automatic Span Management**: An automatic span stack simplifies the creation of nested spans.

## 🚀 Quick Start

Integrating the SDK into your application is simple. Follow the steps below to start sending telemetry data.

### 1. Add the Paths to Your Project

Add the `source/core` and `source/providers` directories to your Delphi project's *Search Path*.

### 2. Initialize the SDK and Register a Provider

In your main project file (e.g., `.dpr`), initialize the SDK and configure the desired provider. This example uses the **Jaeger** provider.

```delphi
uses
  System.SysUtils,
  Observability.SDK,
  Observability.Provider.Jaeger,
  Observability.Interfaces;

begin
  // 1. Create a configuration for the Jaeger provider
  // By default, it connects to http://localhost:14268
  var JaegerConfig := TObservability.CreateJaegerConfig;
  JaegerConfig.ServiceName := 'MyDelphiApp';
  JaegerConfig.ServiceVersion := '1.0.0';
  JaegerConfig.Environment := 'development';

  // 2. Create and register the Jaeger provider
  var JaegerProvider := TJaegerProvider.Create;
  JaegerProvider.Configure(JaegerConfig);
  TObservability.RegisterProvider(JaegerProvider);

  // 3. Set the active provider
  TObservability.SetActiveProvider(opJaeger);

  // 4. Initialize the SDK (this initializes all registered providers)
  TObservability.Initialize;

  // ... your application logic here ...

  // Example usage
  try
    // Start a transaction (root operation)
    var LTransaction := TObservability.StartTransaction('ProcessOrder');
    try
      TObservability.LogInfo('Starting order processing');

      // Start a child span for a specific operation
      var LSpan := TObservability.StartSpan('ValidateStock');
      try
        // Simulate work
        Sleep(100);
        TObservability.AddSpanAttribute('product.id', '12345');
      finally
        // Finish the child span
        LSpan.Finish;
      end;

      // Simulate an error
      try
        raise EMyException.Create('Failed to connect to payment gateway');
      except
        on E: EMyException do
        begin
          TObservability.LogError('An error occurred during payment', E);
          LTransaction.SetOutcome(Failure); // Mark the transaction as failed
        end;
      end;

    finally
      // Finish the main transaction
      LTransaction.Finish;
    end;
  finally
    // 5. Shutdown the SDK when the application exits
    TObservability.Shutdown;
  end;
end.
```

## 📚 Core Concepts

### `TObservability` (Static Class)

The `TObservability` class is the main entry point for all SDK functionalities. It provides static methods to access tracers, loggers, metrics, and manage the SDK's lifecycle.

- `RegisterProvider(Provider)`: Registers a new provider.
- `SetActiveProvider(ProviderType)`: Sets the default provider.
- `Initialize`: Initializes all registered providers.
- `Shutdown`: Releases the resources of all providers.
- `Tracer`: Returns the `IObservabilityTracer` interface to create spans.
- `Logger`: Returns the `IObservabilityLogger` interface to send logs.
- `Metrics`: Returns the `IObservabilityMetrics` interface to collect metrics.

### Tracing

Tracing allows you to visualize the path of a request through different parts of your system.

- **Transaction**: The root span representing a high-level operation (e.g., an HTTP request, a background job). Use `TObservability.StartTransaction('OperationName')`.
- **Span**: Represents an individual operation within a transaction. Use `TObservability.StartSpan('SpanName')` to create a child span of the current span or transaction.
- **Finishing Spans**: It is crucial to finish each span with `.Finish`. The SDK manages the span stack, so you can use `TObservability.FinishSpan` to finish the most recent span.

```delphi
var LTransaction := TObservability.StartTransaction('MyTransaction');
try
  // ... code ...
  var LSpan := TObservability.StartSpan('ChildOperation');
  try
    // ... code ...
  finally
    LSpan.Finish; // or TObservability.FinishSpan;
  end;
finally
  LTransaction.Finish;
end;
```

### Logging

The SDK provides a structured logging interface that automatically correlates logs with the active span.

```delphi
// Informational log
TObservability.LogInfo('User {Username} logged in successfully', ['johndoe']);

// Error log with exception
try
  // ...
except
  on E: Exception do
    TObservability.LogError('Failed to process data', E);
end;
```

### Metrics

Collect metrics to monitor application behavior.

```delphi
// Increment a counter
TObservability.Counter('orders.processed', 1);

// Record the value of a gauge
TObservability.Gauge('memory.available.mb', 512);

// Add a measurement to a histogram
TObservability.Histogram('response.time.ms', 120);
```

## 🛠️ Supported Providers

The SDK is designed to be backend-agnostic. Below are the included providers.

| Provider | Tracing | Logging | Metrics | Notes |
|---|---|---|---|---|
| **Jaeger** | ✅ | ❌ | ❌ | Focused on Distributed Tracing. |
| **Elastic APM** | ✅ | ✅ | ✅ | Complete observability solution. |
| **Datadog** | ✅ | ✅ | ✅ | Complete monitoring solution. |
| **Sentry** | ✅ | ✅ | ❌ | Strong in error and performance tracking. |
| **Console** | ✅ | ✅ | ✅ | Console output, ideal for development. |
| **TextFile** | ✅ | ✅ | ✅ | Saves data to text/JSON files for offline analysis. |

### Configuring Providers

Each provider has a configuration creation function to make it easier:

- `TObservability.CreateJaegerConfig()`
- `TObservability.CreateElasticConfig()`
- `TObservability.CreateDatadogConfig()`
- `TObservability.CreateSentryConfig()`
- `TObservability.CreateConsoleConfig()`
- `TObservability.CreateTextFileConfig()`

**Example with Elastic APM:**

```delphi
var ElasticConfig := TObservability.CreateElasticConfig;
ElasticConfig.ServerUrl := 'http://my-elastic-apm:8200';
ElasticConfig.ApiKey := 'my-secret-token';
ElasticConfig.ServiceName := 'MyService';

var ElasticProvider := TElasticAPMProvider.Create;
ElasticProvider.Configure(ElasticConfig);
TObservability.RegisterProvider(ElasticProvider);
TObservability.SetActiveProvider(opElastic);
```

## 🏛️ Architecture

The SDK is built around a set of core interfaces:

- `IObservabilitySDK`: The core that manages providers.
- `IObservabilityProvider`: The contract for all backend providers.
- `IObservabilityTracer`, `IObservabilityLogger`, `IObservabilityMetrics`: Interfaces for observability functionalities.
- `IObservabilitySpan`: Represents a unit of work in a trace.
- `IObservabilityConfig`: Defines the settings for providers.

This architecture allows you to easily extend the SDK by creating your own provider that implements the `IObservabilityProvider` interface.

## 📄 License

This project is licensed under the **MIT License**. See the [LICENSE](../LICENSE) file for more details.
