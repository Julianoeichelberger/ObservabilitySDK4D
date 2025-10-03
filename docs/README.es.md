# Observability SDK for Delphi (ObservabilitySDK4D)

[![Licencia: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Idiomas: [Português](../README.md) | [English](./README.en.md) | Español (Actual) | [Deutsch](./README.de.md)

---

`ObservabilitySDK4D` es un framework potente y extensible para Delphi, diseñado para integrar capacidades de observabilidad (Tracing, Logging y Métricas) en sus aplicaciones de forma unificada. Con soporte para múltiples proveedores como **Jaeger**, **Elastic APM**, **Datadog**, **Sentry** y otros, permite a los desarrolladores monitorear la salud, el rendimiento y el comportamiento de sus aplicaciones de manera centralizada.

## ✨ Características Principales

- **API Unificada**: Una única API para interactuar con diferentes backends de observabilidad.
- **Tracing Distribuido**: Rastree el flujo de operaciones a través de múltiples servicios con Spans y Transacciones.
- **Logging Estructurado**: Envíe logs enriquecidos con contexto de rastreo, información de entorno y atributos personalizados.
- **Métricas de Aplicación**: Recolecte métricas esenciales como contadores (Counters), medidores (Gauges) e histogramas (Histograms).
- **Gestión de Proveedores**: Soporte para múltiples proveedores, permitiendo cambiar o usar varios simultáneamente.
- **Configuración Flexible**: Configure cada proveedor con parámetros específicos, como endpoints de servidor, claves de API y tasas de muestreo.
- **Extensible**: La arquitectura basada en interfaces facilita la creación de sus propios proveedores de observabilidad.
- **Gestión Automática de Spans**: Una pila de spans automática simplifica la creación de spans anidados.

## 🚀 Inicio Rápido

Integrar el SDK en su aplicación es sencillo. Siga los pasos a continuación para comenzar a enviar datos de telemetría.

### 1. Agregue las Rutas a su Proyecto

Agregue los directorios `source/core` y `source/providers` al *Search Path* de su proyecto Delphi.

### 2. Inicialice el SDK y Registre un Proveedor

En el archivo principal de su proyecto (ej: `.dpr`), inicialice el SDK y configure el proveedor deseado. Este ejemplo usa el proveedor **Jaeger**.

```delphi
uses
  System.SysUtils,
  Observability.SDK,
  Observability.Provider.Jaeger,
  Observability.Interfaces;

begin
  // 1. Cree una configuración para el proveedor Jaeger
  // Por defecto, se conecta a http://localhost:14268
  var JaegerConfig := TObservability.CreateJaegerConfig;
  JaegerConfig.ServiceName := 'MiAppDelphi';
  JaegerConfig.ServiceVersion := '1.0.0';
  JaegerConfig.Environment := 'development';

  // 2. Cree y registre el proveedor Jaeger
  var JaegerProvider := TJaegerProvider.Create;
  JaegerProvider.Configure(JaegerConfig);
  TObservability.RegisterProvider(JaegerProvider);

  // 3. Establezca el proveedor activo
  TObservability.SetActiveProvider(opJaeger);

  // 4. Inicialice el SDK (esto inicializa todos los proveedores registrados)
  TObservability.Initialize;

  // ... su lógica de aplicación aquí ...

  // Ejemplo de uso
  try
    // Inicia una transacción (operación raíz)
    var LTransaction := TObservability.StartTransaction('ProcesarPedido');
    try
      TObservability.LogInfo('Iniciando procesamiento del pedido');

      // Inicia un span hijo para una operación específica
      var LSpan := TObservability.StartSpan('ValidarStock');
      try
        // Simula trabajo
        Sleep(100);
        TObservability.AddSpanAttribute('producto.id', '12345');
      finally
        // Finaliza el span hijo
        LSpan.Finish;
      end;

      // Simula un error
      try
        raise EMyException.Create('Fallo al conectar con la pasarela de pago');
      except
        on E: EMyException do
        begin
          TObservability.LogError('Ocurrió un error durante el pago', E);
          LTransaction.SetOutcome(Failure); // Marca la transacción como fallida
        end;
      end;

    finally
      // Finaliza la transacción principal
      LTransaction.Finish;
    end;
  finally
    // 5. Apague el SDK al finalizar la aplicación
    TObservability.Shutdown;
  end;
end.
```

## 📚 Conceptos Principales

### `TObservability` (Clase Estática)

La clase `TObservability` es el principal punto de entrada para todas las funcionalidades del SDK. Proporciona métodos estáticos para acceder a tracers, loggers, métricas y gestionar el ciclo de vida del SDK.

- `RegisterProvider(Provider)`: Registra un nuevo proveedor.
- `SetActiveProvider(ProviderType)`: Establece el proveedor por defecto.
- `Initialize`: Inicializa todos los proveedores registrados.
- `Shutdown`: Libera los recursos de todos los proveedores.
- `Tracer`: Devuelve la interfaz `IObservabilityTracer` para crear spans.
- `Logger`: Devuelve la interfaz `IObservabilityLogger` para enviar logs.
- `Metrics`: Devuelve la interfaz `IObservabilityMetrics` para recolectar métricas.

### Tracing

El Tracing permite visualizar la ruta de una solicitud a través de diferentes partes de su sistema.

- **Transacción**: Es el span raíz que representa una operación de alto nivel (ej: una solicitud HTTP, un trabajo en segundo plano). Use `TObservability.StartTransaction('NombreDeLaOperacion')`.
- **Span**: Representa una operación individual dentro de una transacción. Use `TObservability.StartSpan('NombreDelSpan')` para crear un span hijo del span o transacción actual.
- **Finalizando Spans**: Es crucial finalizar cada span con `.Finish`. El SDK gestiona el apilamiento de spans, por lo que puede usar `TObservability.FinishSpan` para finalizar el span más reciente.

```delphi
var LTransaction := TObservability.StartTransaction('MiTransaccion');
try
  // ... código ...
  var LSpan := TObservability.StartSpan('OperacionHija');
  try
    // ... código ...
  finally
    LSpan.Finish; // o TObservability.FinishSpan;
  end;
finally
  LTransaction.Finish;
end;
```

### Logging

El SDK proporciona una interfaz de logging estructurado que correlaciona automáticamente los logs con el span activo.

```delphi
// Log informativo
TObservability.LogInfo('Usuario {Username} ha iniciado sesión con éxito', ['johndoe']);

// Log de error con excepción
try
  // ...
except
  on E: Exception do
    TObservability.LogError('Fallo al procesar los datos', E);
end;
```

### Métricas

Recolecte métricas para monitorear el comportamiento de la aplicación.

```delphi
// Incrementar un contador
TObservability.Counter('pedidos.procesados', 1);

// Registrar el valor de un medidor (gauge)
TObservability.Gauge('memoria.disponible.mb', 512);

// Añadir una medición a un histograma
TObservability.Histogram('tiempo.respuesta.ms', 120);
```

## 🛠️ Proveedores Soportados

El SDK está diseñado para ser agnóstico al backend. A continuación se muestran los proveedores incluidos.

| Proveedor | Tracing | Logging | Métricas | Notas |
|---|---|---|---|---|
| **Jaeger** | ✅ | ❌ | ❌ | Enfocado en Tracing Distribuido. |
| **Elastic APM** | ✅ | ✅ | ✅ | Solución completa de observabilidad. |
| **Datadog** | ✅ | ✅ | ✅ | Solución completa de monitoreo. |
| **Sentry** | ✅ | ✅ | ❌ | Fuerte en seguimiento de errores y rendimiento. |
| **Console** | ✅ | ✅ | ✅ | Salida en la consola, ideal para desarrollo. |
| **TextFile** | ✅ | ✅ | ✅ | Guarda datos en archivos de texto/JSON para análisis offline. |

### Configurando Proveedores

Cada proveedor tiene una función de creación de configuración para facilitar la tarea:

- `TObservability.CreateJaegerConfig()`
- `TObservability.CreateElasticConfig()`
- `TObservability.CreateDatadogConfig()`
- `TObservability.CreateSentryConfig()`
- `TObservability.CreateConsoleConfig()`
- `TObservability.CreateTextFileConfig()`

**Ejemplo con Elastic APM:**

```delphi
var ElasticConfig := TObservability.CreateElasticConfig;
ElasticConfig.ServerUrl := 'http://my-elastic-apm:8200';
ElasticConfig.ApiKey := 'my-secret-token';
ElasticConfig.ServiceName := 'MiServicio';

var ElasticProvider := TElasticAPMProvider.Create;
ElasticProvider.Configure(ElasticConfig);
TObservability.RegisterProvider(ElasticProvider);
TObservability.SetActiveProvider(opElastic);
```

## 🏛️ Arquitectura

El SDK se construye en torno a un conjunto de interfaces principales:

- `IObservabilitySDK`: El núcleo que gestiona los proveedores.
- `IObservabilityProvider`: El contrato para todos los proveedores de backend.
- `IObservabilityTracer`, `IObservabilityLogger`, `IObservabilityMetrics`: Interfaces para las funcionalidades de observabilidad.
- `IObservabilitySpan`: Representa una unidad de trabajo en un trace.
- `IObservabilityConfig`: Define la configuración para los proveedores.

Esta arquitectura le permite extender fácilmente el SDK creando su propio proveedor que implemente la interfaz `IObservabilityProvider`.

## 📄 Licencia

Este proyecto está licenciado bajo la **Licencia MIT**. Vea el archivo [LICENSE](../LICENSE) para más detalles.
