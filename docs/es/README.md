# ObservabilitySDK4D - Documentación Completa

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Delphi](https://img.shields.io/badge/Delphi-10.3%2B-red.svg)](https://www.embarcadero.com/products/delphi)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-blue.svg)](https://github.com/Julianoeichelberger/ObservabilitySDK4D)

> Un framework integral de **Monitoreo del Rendimiento de Aplicaciones (APM)** y **Observabilidad** para aplicaciones Delphi con soporte para trazabilidad distribuida, recolección de métricas y logging estructurado.

## ?? Índice

- [?? Descripción General](#-descripción-general)
- [??? Arquitectura](#?-arquitectura)
- [?? Inicio Rápido](#-inicio-rápido)
- [?? Conceptos Fundamentales](#-conceptos-fundamentales)
- [?? Proveedores Soportados](#-proveedores-soportados)
- [?? Sistema de Métricas](#-sistema-de-métricas)
- [?? Trazabilidad Distribuida](#-trazabilidad-distribuida)
- [?? Logging Estructurado](#-logging-estructurado)
- [?? Configuración Avanzada](#?-configuración-avanzada)
- [?? Ejemplos Prácticos](#-ejemplos-prácticos)
- [??? Instalación](#?-instalación)
- [?? Referencia de la API](#-referencia-de-la-api)
- [?? Contribuir](#-contribuir)

## ?? Descripción General

**ObservabilitySDK4D** es un framework moderno de observabilidad para Delphi que permite monitorear, rastrear y analizar el rendimiento de tus aplicaciones en tiempo real. Con soporte multi-proveedor y una API unificada, puedes integrar fácilmente observabilidad completa en tus proyectos Delphi.

### ? Características Principales

- **?? Soporte Multi-Proveedor**: Elastic APM, Jaeger, Sentry, Datadog, Console
- **?? Observabilidad Completa**: Trazabilidad, Métricas y Logging en un SDK
- **?? Trazabilidad Distribuida**: Rastrea solicitudes a través de microservicios
- **? Configuración Cero**: Funciona inmediatamente con configuraciones predeterminadas sensatas
- **?? Thread-Safe**: Listo para producción con gestión automática de recursos
- **?? Auto-Métricas**: Recolección automática de métricas del sistema (CPU, Memoria, GC)

### ?? Beneficios

1. **Visibilidad Completa**: Ve exactamente cómo está funcionando tu aplicación
2. **Detección Rápida de Problemas**: Identifica cuellos de botella y errores en tiempo real
3. **Análisis de Rendimiento**: Comprende patrones de uso y optimiza el rendimiento
4. **Correlación de Datos**: Conecta logs, métricas y trazas para investigación completa
5. **Monitoreo Proactivo**: Recibe alertas antes de que los problemas afecten a los usuarios

## ??? Arquitectura

### ??? Vista General de la Arquitectura

```
???????????????????????????????????????????????????????????
?              TObservability (API Estática)              ?
???????????????????????????????????????????????????????????
? ??????????????? ??????????????? ??????????????????????? ?
? ? Trazabilidad? ?   Métricas  ? ?      Logging        ? ?
? ?    (APM)    ? ? Recolección ? ?   (Estructurado)    ? ?
? ??????????????? ??????????????? ??????????????????????? ?
???????????????????????????????????????????????????????????
                              ?
???????????????????????????????????????????????????????????
?            Capa de Abstracción de Proveedores           ?
???????????????????????????????????????????????????????????
                              ?
???????????????????????????????????????????????????????????
? ?? Elastic  ??? Jaeger  ??? Sentry  ?? Datadog  ?? Console ?
???????????????????????????????????????????????????????????
```

### ?? Flujo de Datos

```
Código de la Aplicación
        ?
    ?????????      ???????????????      ????????????????
    ? Crear ?      ?    Pila     ?      ?   Proveedor  ?
    ? Span  ? ???? ?    de       ? ???? ?  (Elastic/   ? ???? Servidor APM
    ?       ?      ?   Spans     ?      ?   Jaeger)    ?
    ?????????      ???????????????      ????????????????
        ?                  ?                     ?
    ?????????      ???????????????      ????????????????
    ?Finalizar      ? Propagación ?      ? Recolección  ?
    ? Span  ?      ? Contexto    ?      ? Métricas     ? ???? Almacenamiento
    ?????????      ???????????????      ????????????????
```

## ?? Inicio Rápido

### 1. Configuración Básica (30 segundos)

```pascal
program MiApp;
uses
  Observability.SDK,
  Observability.Provider.Console;

begin
  // Inicializar ObservabilitySDK4D
  TObservability.Initialize;
  TObservability.RegisterProvider(TConsoleProvider.Create);
  TObservability.SetActiveProvider(opConsole);
  
  // Comenzar a rastrear tu aplicación
  var Span := TObservability.StartSpan('operacion-usuario');
  try
    Span.SetAttribute('user.id', '12345');
    Span.SetAttribute('operacion', 'login');
    
    // Tu lógica de negocio aquí
    ProcesarLogin();
    
    Span.SetOutcome(Success);
  finally
    Span.Finish;
  end;
  
  TObservability.Shutdown;
end.
```

### 2. Uso Avanzado con Métricas Personalizadas

```pascal
// Iniciar una transacción
TObservability.StartTransaction('Registro de Usuario', 'solicitud');

try
  // Crear spans anidados
  TObservability.StartSpan('Validar Entrada');
  ValidarDatosUsuario();
  TObservability.FinishSpan;
  
  TObservability.StartSpan('Insertar en Base de Datos');
  GuardarUsuarioEnBD();
  TObservability.FinishSpan;
  
  // Métricas personalizadas
  TObservability.Metrics.Counter('usuarios.registrados', 1);
  TObservability.Metrics.Gauge('bd.conexiones_activas', GetConexionesActivas());
  
  TObservability.FinishTransaction;
except
  on E: Exception do
  begin
    TObservability.RecordSpanException(E);
    TObservability.FinishTransactionWithOutcome(Failure);
  end;
end;
```

## ?? Conceptos Fundamentales

### ?? **APM (Application Performance Monitoring)**
Monitoreo del rendimiento de la aplicación, tiempos de respuesta, throughput y tasas de error en tiempo real.

**Beneficios:**
- Detección proactiva de problemas de rendimiento
- Análisis de cuellos de botella en tiempo real
- Métricas de disponibilidad y confiabilidad
- Insights sobre comportamiento del usuario

### ?? **Trazabilidad Distribuida**
Rastrea solicitudes mientras fluyen a través de múltiples servicios, creando una imagen completa del comportamiento del sistema.

**Conceptos Clave:**
- **Trace**: Viaje completo de una solicitud
- **Span**: Unidad individual de trabajo dentro de un trace
- **Context**: Información que conecta spans relacionados

### ?? **Compatibilidad OpenTelemetry**
Construido siguiendo los principios de OpenTelemetry para observabilidad vendor-neutral.

**Ventajas:**
- Estándar de la industria para observabilidad
- Interoperabilidad entre diferentes herramientas
- A prueba de futuro para cambios de proveedor

### ?? **Recolección de Métricas**

#### **Contadores (Counters)**
Valores acumulativos que solo aumentan (solicitudes, errores):
```pascal
TObservability.Metrics.Counter('http.solicitudes.total', 1);
TObservability.Metrics.Counter('cache.hits', 1);
```

#### **Medidores (Gauges)**
Valores puntuales que pueden subir y bajar (memoria, conexiones):
```pascal
TObservability.Metrics.Gauge('memoria.uso.bytes', GetUsoMemoria);
TObservability.Metrics.Gauge('conexiones.activas', GetConexionesActivas);
```

#### **Histogramas**
Distribución de valores (tiempos de respuesta):
```pascal
TObservability.Metrics.Histogram('tiempo.respuesta.ms', TiempoRespuesta);
TObservability.Metrics.Histogram('tamaño.payload.bytes', TamañoPayload);
```

### ?? **Logging Estructurado**
Logs ricos y buscables con contexto y correlación a través de sistemas distribuidos.

**Características:**
- Logs estructurados en JSON
- Correlación automática con traces
- Múltiples niveles de log (DEBUG, INFO, WARN, ERROR)
- Atributos personalizados y contexto

## ?? Proveedores Soportados

### ?? Matriz de Soporte

| Proveedor | Trazabilidad | Métricas | Logging | Seguimiento de Errores | Estado |
|-----------|--------------|----------|---------|------------------------|--------|
| **?? Elastic APM** | ? | ? | ? | ? | ?? Listo para Producción |
| **??? Jaeger** | ? | ? | ? | ? | ?? Listo para Producción |
| **??? Sentry** | ? | ?* | ? | ? | ?? Listo para Producción |
| **?? Datadog** | ? | ? | ? | ? | ?? Listo para Producción |
| **?? Console** | ? | ? | ? | ? | ?? Desarrollo |
| **?? TextFile** | ? | ? | ? | ? | ?? Desarrollo |

> *Las métricas de Sentry no están soportadas nativamente por la plataforma Sentry

### ?? **Proveedor Elastic APM**

**Características Completas:**
- ? Soporte completo del protocolo APM 8.x
- ? Transacciones, spans y métricas
- ? Formato de lote NDJSON
- ? Correlación automática padre-hijo
- ? Recolección de métricas del sistema

**Configuración:**
```pascal
var Config := TObservability.CreateElasticConfig;
Config.ServerUrl := 'http://localhost:8200';
Config.SecretToken := 'tu-token';
Config.ServiceName := 'mi-app';
Config.Environment := 'produccion';

var Provider := TElasticAPMProvider.Create;
Provider.Configure(Config);
TObservability.RegisterProvider(Provider);
TObservability.SetActiveProvider(opElastic);
```

**Ejemplo de Uso:**
```pascal
// Ejemplos y muestras completas disponibles en /Samples/Elastic
docker-compose up -d  // Inicia Elasticsearch + Kibana + APM Server
```

### ??? **Proveedor Jaeger**

**Características:**
- ? Protocolo OpenTelemetry (OTLP)
- ? Trazabilidad distribuida completa
- ? Correlación de contexto B3/W3C
- ? Métricas (no soportado por Jaeger)

**Configuración:**
```pascal
var Config := TObservability.CreateJaegerConfig;
Config.ServiceName := 'mi-servicio';
Config.ServerUrl := 'http://localhost:14268/api/traces';

TObservability.RegisterProvider(TJaegerProvider.Create(Config));
```

### ??? **Proveedor Sentry**

**Características:**
- ? Seguimiento avanzado de errores
- ? Monitoreo de rendimiento
- ? Logging estructurado con breadcrumbs
- ? Seguimiento de releases y deployment

**Configuración:**
```pascal
var Config := TObservability.CreateSentryConfig;
Config.ServerUrl := 'https://tu-dsn@sentry.io/proyecto-id';
Config.Environment := 'produccion';
Config.ServiceVersion := '1.0.0';

TObservability.RegisterProvider(TSentryProvider.Create(Config));
```

### ?? **Proveedor Datadog**

**Características Completas:**
- ? APM completo con correlación de traces
- ? Métricas personalizadas y del sistema
- ? Logging estructurado
- ? Integración con infraestructura

**Configuración:**
```pascal
var Config := TObservability.CreateDatadogConfig;
Config.ApiKey := 'tu-clave-api-datadog';
Config.ServiceName := 'mi-app';
Config.ServerUrl := 'http://localhost:8126'; // Datadog Agent

TObservability.RegisterProvider(TDatadogProvider.Create(Config));
```

## ?? Sistema de Métricas

### ?? Métricas Automáticas del Sistema

Cuando se llama a `TObservability.EnableSystemMetrics`:

```pascal
// Métricas de memoria
- system.memory.application.bytes.gauge     // Uso de memoria de la aplicación
- system.memory.used.mb.gauge              // Memoria total usada del sistema
- system.memory.available.mb.gauge         // Memoria disponible
- system.memory.total.mb.gauge             // Memoria total del sistema
- system.memory.usage.percent.gauge        // Porcentaje de uso de memoria

// Métricas de CPU
- system.cpu.application.percent.gauge     // Uso de CPU de la aplicación
- system.cpu.system.percent.gauge          // Uso de CPU del sistema

// Métricas de runtime
- system.threads.count.gauge               // Número de threads activos
- system.gc.allocated.bytes.gauge          // Bytes asignados por el GC
```

**Habilitación:**
```pascal
// Habilitar recolección automática
TObservability.EnableSystemMetrics;

// O con opciones específicas
TObservability.EnableSystemMetrics(
  [smoMemoryUsage, smoCPUUsage, smoThreadCount], // Métricas a recolectar
  si30Seconds  // Intervalo de recolección
);

// Recolección manual única
TObservability.CollectSystemMetricsOnce;

// Deshabilitar cuando termine
TObservability.DisableSystemMetrics;
```

### ?? Métricas Personalizadas

```pascal
// Contador - Rastrear número de operaciones
TObservability.Metrics.Counter('api.solicitudes.total', 1);
TObservability.Metrics.Counter('cache.hits', 1);

// Medidor - Valores puntuales
TObservability.Metrics.Gauge('memoria.uso.bytes', GetUsoMemoria);
TObservability.Metrics.Gauge('usuarios.activos', GetUsuariosActivos);

// Histograma - Distribución de valores
TObservability.Metrics.Histogram('http.tiempo.respuesta.ms', TiempoRespuesta);
TObservability.Metrics.Histogram('bd.query.duracion', DuracionQuery);
```

## ?? Trazabilidad Distribuida

### ?? Tipos de Span y Contexto

#### **Tipos de Span:**
- **Client**: Solicitudes salientes (llamadas HTTP, consultas de base de datos)
- **Server**: Solicitudes entrantes (endpoints API, manejadores de mensajes)
- **Producer**: Productores de mensajes (publicadores de cola)
- **Consumer**: Consumidores de mensajes (suscriptores de cola)
- **Internal**: Operaciones internas (lógica de negocio, cálculos)

#### **Propagación de Contexto:**
```pascal
// Extraer contexto de headers HTTP
var Context := TObservability.Tracer.ExtractContext(HttpHeaders);

// Iniciar span con contexto extraído
var Span := TObservability.StartSpan('manejar-solicitud', Context);

// Inyectar contexto en headers salientes
TObservability.Tracer.InjectHeaders(HeadersSalientes);
```

### ?? Gestión Automática de Spans

El SDK usa una **pila LIFO** para gestionar automáticamente relaciones padre-hijo:

```pascal
TObservability.StartTransaction('Solicitud HTTP');
  TObservability.StartSpan('Autenticacion');
    TObservability.StartSpan('Consulta Base de Datos');
    TObservability.FinishSpan; // Finaliza Consulta Base de Datos
  TObservability.FinishSpan;   // Finaliza Autenticacion
TObservability.FinishTransaction; // Finaliza Solicitud HTTP
```

**Resultado**: Jerarquía perfecta con correlación automática de parent_id

## ?? Logging Estructurado

### ?? Niveles de Log

```pascal
// Logging simple
TObservability.LogTrace('Operación iniciada');
TObservability.LogDebug('Valor de variable: %d', [valorVariable]);
TObservability.LogInfo('Usuario logueado exitosamente');
TObservability.LogWarning('Cache miss detectado');
TObservability.LogError('Operación falló', excepcion);
TObservability.LogCritical('Sistema no disponible');
```

### ??? Logs con Atributos

```pascal
var
  Logger: IObservabilityLogger;
  Attributes: TDictionary<string, string>;
begin
  Logger := TObservability.GetLogger;
  Attributes := TDictionary<string, string>.Create;
  try
    Attributes.Add('user_id', '12345');
    Attributes.Add('operacion', 'login');
    Attributes.Add('ip_address', '192.168.1.100');
    
    Logger.Info('Login exitoso', Attributes);
  finally
    Attributes.Free;
  end;
end;
```

### ?? Correlación Automática

Los logs se correlacionan automáticamente con traces activos:
```pascal
var Span := TObservability.StartSpan('procesar-pedido');
try
  // Este log será automáticamente asociado con el span activo
  TObservability.LogInfo('Procesando pedido #12345');
  
  // Con atributos adicionales
  var Attrs := TDictionary<string, string>.Create;
  Attrs.Add('pedido_id', '12345');
  Attrs.Add('monto', '299.99');
  TObservability.LogInfo('Pedido validado', Attrs);
  Attrs.Free;
finally
  Span.Finish;
end;
```

## ?? Configuración Avanzada

### ?? Configuración Específica por Proveedor

#### **Configuración Completa de Elastic APM:**
```pascal
var Config := TObservability.CreateElasticConfig;
Config.ServiceName := 'mi-app-delphi';
Config.ServiceVersion := '1.0.0';
Config.Environment := 'produccion';
Config.ServerUrl := 'https://apm.miempresa.com:8200';
Config.SecretToken := 'tu-token-secreto';

// Configuraciones avanzadas vía propiedades personalizadas
var CustomProps := TDictionary<string, string>.Create;
CustomProps.Add('capture_body', 'all');
CustomProps.Add('transaction_sample_rate', '1.0');
Config.CustomProperties := CustomProps;

var Provider := TElasticAPMProvider.Create;
Provider.Configure(Config);
TObservability.RegisterProvider(Provider);
```

#### **Configuración Datadog con Tags Globales:**
```pascal
var Config := TObservability.CreateDatadogConfig;
Config.ApiKey := 'tu-clave-api-datadog';
Config.ServiceName := 'api-pagos';
Config.Environment := 'produccion';

// Tags globales
var CustomProps := TDictionary<string, string>.Create;
CustomProps.Add('equipo', 'backend');
CustomProps.Add('componente', 'api');
CustomProps.Add('datacenter', 'us-east-1');
Config.CustomProperties := CustomProps;

TObservability.RegisterProvider(TDatadogProvider.Create(Config));
```

### ?? Configuración Multi-Proveedor

```pascal
// Registrar múltiples proveedores
var ElasticConfig := TObservability.CreateElasticConfig;
ElasticConfig.ServiceName := 'mi-servicio';
ElasticConfig.ServerUrl := 'http://localhost:8200';

var SentryConfig := TObservability.CreateSentryConfig;
SentryConfig.ServerUrl := 'https://tu-dsn@sentry.io/proyecto';

// Registrar ambos
TObservability.RegisterProvider(TElasticAPMProvider.Create(ElasticConfig));
TObservability.RegisterProvider(TSentryProvider.Create(SentryConfig));

// Usar Elastic APM como principal
TObservability.SetActiveProvider(opElastic);

// Cambiar a Sentry si es necesario
TObservability.SetActiveProvider(opSentry);
```

## ?? Ejemplos Prácticos

### ?? Monitoreo de API Web

```pascal
procedure TMyController.ProcesarSolicitud;
var
  Span: IObservabilitySpan;
begin
  Span := TObservability.StartSpan('api.procesar-solicitud', skServer);
  try
    Span.SetAttribute('http.method', 'POST');
    Span.SetAttribute('http.url', '/api/usuarios');
    Span.SetAttribute('user.id', GetUsuarioActual);
    
    // Procesar solicitud
    ProcesarDatosUsuario;
    
    TObservability.Metrics.Counter('api.solicitudes.exitosas', 1);
    Span.SetOutcome(Success);
  except
    on E: Exception do
    begin
      Span.RecordException(E);
      Span.SetOutcome(Failure);
      TObservability.Metrics.Counter('api.solicitudes.error', 1);
      TObservability.LogError('Procesamiento de solicitud falló', E);
      raise;
    end;
  end;
end;
```

### ??? Operaciones de Base de Datos

```pascal
procedure TUserRepository.GuardarUsuario(const Usuario: TUsuario);
var
  Span: IObservabilitySpan;
  TiempoInicio: TDateTime;
begin
  Span := TObservability.StartSpan('bd.guardar-usuario', skClient);
  TiempoInicio := Now;
  try
    Span.SetAttribute('bd.tabla', 'usuarios');
    Span.SetAttribute('bd.operacion', 'INSERT');
    Span.SetAttribute('user.id', Usuario.Id);
    
    // Ejecutar operación de base de datos
    EjecutarSQL('INSERT INTO usuarios...', Usuario);
    
    TObservability.Metrics.Histogram('bd.query.duracion', 
      MilliSecondsBetween(Now, TiempoInicio));
    
    TObservability.LogInfo('Usuario guardado exitosamente', 
      TDictionary<string, string>.Create.AddOrSetValue('user.id', Usuario.Id));
    
    Span.SetOutcome(Success);
  except
    on E: Exception do
    begin
      Span.RecordException(E);
      TObservability.Metrics.Counter('bd.errores', 1);
      TObservability.LogError('Falló guardar usuario', E);
      raise;
    end;
  end;
end;
```

### ?? Procesamiento en Segundo Plano

```pascal
procedure TBackgroundProcessor.ProcesarCola;
var
  Span: IObservabilitySpan;
  ElementosProcesados: Integer;
begin
  Span := TObservability.StartSpan('background.procesar-cola', skInternal);
  ElementosProcesados := 0;
  try
    while TieneElementosEnCola do
    begin
      ProcesarElementoUnico;
      Inc(ElementosProcesados);
      
      // Actualizar métricas cada 10 elementos
      if ElementosProcesados mod 10 = 0 then
      begin
        TObservability.Metrics.Gauge('cola.elementos.procesados', ElementosProcesados);
        TObservability.LogDebug('Progreso: %d elementos procesados', [ElementosProcesados]);
      end;
    end;
    
    Span.SetAttribute('elementos.procesados', ElementosProcesados);
    TObservability.Metrics.Counter('cola.procesamiento.completo', 1);
    
    TObservability.LogInfo('Procesamiento de cola completado', 
      TDictionary<string, string>.Create.AddOrSetValue('total_elementos', IntToStr(ElementosProcesados)));
    
    Span.SetOutcome(Success);
  except
    on E: Exception do
    begin
      Span.RecordException(E);
      TObservability.LogError('Procesamiento en segundo plano falló', E);
      TObservability.Metrics.Counter('cola.procesamiento.error', 1);
      raise;
    end;
  end;
end;
```

## ??? Instalación

### ?? Requisitos del Sistema

- **Delphi**: 10.3 Rio o superior
- **Plataformas Objetivo**: Windows (32/64-bit), Linux (64-bit)
- **Framework**: Compatible con VCL/FMX
- **Runtime**: Sin dependencias de DLL externas

### ?? Pasos de Instalación

1. **Descargar**: Clona o descarga el repositorio
```bash
git clone https://github.com/Julianoeichelberger/ObservabilitySDK4D.git
```

2. **Agregar Ruta**: Agrega la carpeta `source` al library path de tu proyecto

3. **Incluir Units**: Agrega las units requeridas a tu cláusula uses
```pascal
uses
  Observability.SDK,
  Observability.Provider.Elastic, // o tu proveedor preferido
  Observability.Provider.Console;
```

4. **Inicializar**: Configura e inicializa en tu aplicación
```pascal
initialization
  TObservability.Initialize;
  // Configurar proveedores...

finalization
  TObservability.Shutdown;
```

### ?? Servicios Externos

| Proveedor | Servicio | Puerto Predeterminado | Protocolo |
|-----------|----------|--------------------|-----------|
| **Elastic APM** | APM Server | 8200 | HTTP/HTTPS |
| **Jaeger** | Jaeger Agent | 14268 | HTTP |
| **Sentry** | Sentry DSN | 443 | HTTPS |
| **Datadog** | DD Agent | 8126 | HTTP |

## ?? Referencia de la API

### ??? Clases Principales

| Clase | Propósito | Thread-Safe | Métodos Principales |
|-------|-----------|-------------|-------------------|
| `TObservability` | API estática principal | ? Sí | `StartTransaction`, `StartSpan`, `Metrics` |
| `TObservabilitySDK` | Instancia del SDK | ? Sí | `Initialize`, `RegisterProvider`, `Shutdown` |
| `TElasticAPMProvider` | Integración Elastic APM | ? Sí | `Configure`, `SendBatch` |
| `TObservabilityContext` | Contexto de solicitud | ? Sí | `Clone`, `CreateChild` |

### ?? Contratos de Interface

| Interface | Propósito | Métodos Principales |
|-----------|-----------|-------------------|
| `IObservabilitySpan` | Operaciones de span | `Finish`, `SetAttribute`, `SetOutcome` |
| `IObservabilityMetrics` | Recolección de métricas | `Counter`, `Gauge`, `Histogram` |
| `IObservabilityConfig` | Configuración de proveedor | Propiedades para URLs, tokens, etc. |
| `IObservabilityProvider` | Abstracción de proveedor | `Initialize`, `GetTracer`, `GetMetrics` |

### ? Características de Rendimiento

#### ?? Benchmarks

- **Creación de Span**: ~50-100?s por span
- **Overhead de Memoria**: ~2-5MB baseline + ~1KB por span activo
- **Lote de Red**: Tamaño de lote configurable (predeterminado: 100 eventos)
- **Procesamiento en Segundo Plano**: Recolección de métricas no bloqueante

#### ?? Características de Optimización

- **Inicialización Lazy**: Los proveedores solo se inicializan cuando se usan
- **Pool de Conexiones**: Los clientes HTTP reutilizan conexiones
- **Procesamiento por Lotes**: Múltiples eventos enviados en una sola solicitud
- **Circuit Breaking**: Fallback automático en fallas del proveedor

## ?? Mejores Prácticas

### ?? Patrones de Transacción

```pascal
// ? BUENO: Límites claros de transacción
TObservability.StartTransaction('ProcesarPedido', 'negocio');
try
  ValidarPedido();
  CalcularTotal();
  GuardarEnBD();
  TObservability.FinishTransaction;
except
  TObservability.FinishTransactionWithOutcome(Failure);
  raise;
end;

// ? EVITAR: Límites poco claros
TObservability.StartSpan('HacerTodo');
// Muy amplio, difícil de entender el rendimiento
```

### ?? Nomenclatura de Métricas

```pascal
// ? BUENO: Nombres descriptivos y jerárquicos
TObservability.Metrics.Counter('http.solicitudes.total');
TObservability.Metrics.Gauge('bd.conexiones.activas');
TObservability.Metrics.Histogram('api.tiempo.respuesta');

// ? EVITAR: Nombres genéricos
TObservability.Metrics.Counter('contador');
TObservability.Metrics.Gauge('valor');
```

### ??? Directrices de Atributos

```pascal
// ? BUENO: Atributos significativos
Span.SetAttribute('user.id', '12345');
Span.SetAttribute('http.method', 'POST');
Span.SetAttribute('bd.tabla', 'usuarios');

// ? EVITAR: Atributos de alta cardinalidad en métricas
// Evitar IDs únicos en tags de métricas
```

### ??? Manejo de Errores

```pascal
var Span := TObservability.StartSpan('operacion-riesgosa');
try
  // Tu código aquí
  Span.SetOutcome(Success);
except
  on E: Exception do
  begin
    Span.RecordException(E);
    Span.SetOutcome(Failure);
    TObservability.LogError('Operación falló', E);
    raise; // Re-lanzar la excepción
  end;
end;
```

### ?? Gestión de Recursos

- Siempre llama `Span.Finish` en un bloque try-finally
- Usa los métodos auxiliares del SDK para patrones comunes
- Haz shutdown apropiado del SDK al salir de la aplicación

## ?? Entornos de Ejemplo

Cada proveedor incluye entornos Docker Compose completos para pruebas rápidas:

### ?? **Elastic Stack**
```bash
cd Samples/Elastic
.\elastic.ps1 start
# Acceder: http://localhost:5601 (Kibana)
```

### ??? **Jaeger**
```bash
cd Samples/Jaeger  
.\jaeger.ps1 start
# Acceder: http://localhost:16686 (Jaeger UI)
```

### ??? **Sentry**
```bash
cd Samples/Sentry
.\sentry.ps1 start
# Acceder: http://localhost:9000 (Sentry Web)
```

### ?? **Datadog**
```bash
cd Samples/Datadog
.\datadog.ps1 start
# Configurar tu API key y acceder: https://app.datadoghq.com
```

## ?? Consideraciones de Rendimiento

- El SDK está diseñado para overhead mínimo
- Los spans y métricas se procesan asincrónicamente cuando es posible
- Usa tasas de muestreo en escenarios de alto throughput
- Considera tamaños de lote para logging de alto volumen

## ?? Contribuir

¡Las contribuciones son bienvenidas! Por favor:

1. **Fork** el repositorio
2. **Crea** una rama de característica: `git checkout -b feature/caracteristica-increible`
3. **Commit** tus cambios: `git commit -m 'Agregar característica increíble'`
4. **Push** a la rama: `git push origin feature/caracteristica-increible`
5. **Abre** un Pull Request

### ?? Directrices de Contribución

- Sigue los patrones de código existentes
- Agrega pruebas para nueva funcionalidad
- Actualiza la documentación según sea necesario
- Asegura compatibilidad con Delphi 10.3+

### ?? Reportar Issues

Al reportar problemas, incluye:
- Versión de Delphi y plataforma
- Tipo de proveedor y configuración
- Código de reproducción mínima
- Salida de debug (si es aplicable)

## ?? Licencia

Este proyecto está licenciado bajo la Licencia MIT - ve el archivo [LICENSE](LICENSE) para detalles.

```
MIT License

Copyright (c) 2025 Juliano Eichelberger

Se concede permiso, de forma gratuita, a cualquier persona que obtenga una copia
de este software y archivos de documentación asociados (el "Software"), para tratar
en el Software sin restricción, incluyendo sin limitación los derechos de usar, copiar,
modificar, fusionar, publicar, distribuir, sublicenciar y/o vender copias del
Software, y para permitir a las personas a quienes se proporcione el Software que lo hagan,
sujeto a las siguientes condiciones:

El aviso de copyright anterior y este aviso de permiso deben incluirse en todas
las copias o partes sustanciales del Software.
```

## ?? Soporte

- **?? Documentación**: Revisa los enlaces de documentación específicos por idioma
- **?? Issues**: [GitHub Issues](https://github.com/Julianoeichelberger/ObservabilitySDK4D/issues)
- **?? Discusiones**: [GitHub Discussions](https://github.com/Julianoeichelberger/ObservabilitySDK4D/discussions)
- **?? Email**: Para soporte comercial, contáctanos

---

<div align="center">

**ObservabilitySDK4D** - Haciendo que las aplicaciones Delphi sean observables en entornos cloud modernos.

[? Dar estrella](https://github.com/Julianoeichelberger/ObservabilitySDK4D) • [?? Fork](https://github.com/Julianoeichelberger/ObservabilitySDK4D/fork) • [?? Docs](../README.md) • [?? Issues](https://github.com/Julianoeichelberger/ObservabilitySDK4D/issues)

</div>

---

*Esta documentación cubre ObservabilitySDK4D v1.0.0 - Última actualización: Octubre 2025*