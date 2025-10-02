# ObservabilitySDK4D - Documentaci�n Completa

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Delphi](https://img.shields.io/badge/Delphi-10.3%2B-red.svg)](https://www.embarcadero.com/products/delphi)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-blue.svg)](https://github.com/Julianoeichelberger/ObservabilitySDK4D)

> Un framework integral de **Monitoreo del Rendimiento de Aplicaciones (APM)** y **Observabilidad** para aplicaciones Delphi con soporte para trazabilidad distribuida, recolecci�n de m�tricas y logging estructurado.

## ?? �ndice

- [?? Descripci�n General](#-descripci�n-general)
- [??? Arquitectura](#?-arquitectura)
- [?? Inicio R�pido](#-inicio-r�pido)
- [?? Conceptos Fundamentales](#-conceptos-fundamentales)
- [?? Proveedores Soportados](#-proveedores-soportados)
- [?? Sistema de M�tricas](#-sistema-de-m�tricas)
- [?? Trazabilidad Distribuida](#-trazabilidad-distribuida)
- [?? Logging Estructurado](#-logging-estructurado)
- [?? Configuraci�n Avanzada](#?-configuraci�n-avanzada)
- [?? Ejemplos Pr�cticos](#-ejemplos-pr�cticos)
- [??? Instalaci�n](#?-instalaci�n)
- [?? Referencia de la API](#-referencia-de-la-api)
- [?? Contribuir](#-contribuir)

## ?? Descripci�n General

**ObservabilitySDK4D** es un framework moderno de observabilidad para Delphi que permite monitorear, rastrear y analizar el rendimiento de tus aplicaciones en tiempo real. Con soporte multi-proveedor y una API unificada, puedes integrar f�cilmente observabilidad completa en tus proyectos Delphi.

### ? Caracter�sticas Principales

- **?? Soporte Multi-Proveedor**: Elastic APM, Jaeger, Sentry, Datadog, Console
- **?? Observabilidad Completa**: Trazabilidad, M�tricas y Logging en un SDK
- **?? Trazabilidad Distribuida**: Rastrea solicitudes a trav�s de microservicios
- **? Configuraci�n Cero**: Funciona inmediatamente con configuraciones predeterminadas sensatas
- **?? Thread-Safe**: Listo para producci�n con gesti�n autom�tica de recursos
- **?? Auto-M�tricas**: Recolecci�n autom�tica de m�tricas del sistema (CPU, Memoria, GC)

### ?? Beneficios

1. **Visibilidad Completa**: Ve exactamente c�mo est� funcionando tu aplicaci�n
2. **Detecci�n R�pida de Problemas**: Identifica cuellos de botella y errores en tiempo real
3. **An�lisis de Rendimiento**: Comprende patrones de uso y optimiza el rendimiento
4. **Correlaci�n de Datos**: Conecta logs, m�tricas y trazas para investigaci�n completa
5. **Monitoreo Proactivo**: Recibe alertas antes de que los problemas afecten a los usuarios

## ??? Arquitectura

### ??? Vista General de la Arquitectura

```
???????????????????????????????????????????????????????????
?              TObservability (API Est�tica)              ?
???????????????????????????????????????????????????????????
? ??????????????? ??????????????? ??????????????????????? ?
? ? Trazabilidad? ?   M�tricas  ? ?      Logging        ? ?
? ?    (APM)    ? ? Recolecci�n ? ?   (Estructurado)    ? ?
? ??????????????? ??????????????? ??????????????????????? ?
???????????????????????????????????????????????????????????
                              ?
???????????????????????????????????????????????????????????
?            Capa de Abstracci�n de Proveedores           ?
???????????????????????????????????????????????????????????
                              ?
???????????????????????????????????????????????????????????
? ?? Elastic  ??? Jaeger  ??? Sentry  ?? Datadog  ?? Console ?
???????????????????????????????????????????????????????????
```

### ?? Flujo de Datos

```
C�digo de la Aplicaci�n
        ?
    ?????????      ???????????????      ????????????????
    ? Crear ?      ?    Pila     ?      ?   Proveedor  ?
    ? Span  ? ???? ?    de       ? ???? ?  (Elastic/   ? ???? Servidor APM
    ?       ?      ?   Spans     ?      ?   Jaeger)    ?
    ?????????      ???????????????      ????????????????
        ?                  ?                     ?
    ?????????      ???????????????      ????????????????
    ?Finalizar      ? Propagaci�n ?      ? Recolecci�n  ?
    ? Span  ?      ? Contexto    ?      ? M�tricas     ? ???? Almacenamiento
    ?????????      ???????????????      ????????????????
```

## ?? Inicio R�pido

### 1. Configuraci�n B�sica (30 segundos)

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
  
  // Comenzar a rastrear tu aplicaci�n
  var Span := TObservability.StartSpan('operacion-usuario');
  try
    Span.SetAttribute('user.id', '12345');
    Span.SetAttribute('operacion', 'login');
    
    // Tu l�gica de negocio aqu�
    ProcesarLogin();
    
    Span.SetOutcome(Success);
  finally
    Span.Finish;
  end;
  
  TObservability.Shutdown;
end.
```

### 2. Uso Avanzado con M�tricas Personalizadas

```pascal
// Iniciar una transacci�n
TObservability.StartTransaction('Registro de Usuario', 'solicitud');

try
  // Crear spans anidados
  TObservability.StartSpan('Validar Entrada');
  ValidarDatosUsuario();
  TObservability.FinishSpan;
  
  TObservability.StartSpan('Insertar en Base de Datos');
  GuardarUsuarioEnBD();
  TObservability.FinishSpan;
  
  // M�tricas personalizadas
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
Monitoreo del rendimiento de la aplicaci�n, tiempos de respuesta, throughput y tasas de error en tiempo real.

**Beneficios:**
- Detecci�n proactiva de problemas de rendimiento
- An�lisis de cuellos de botella en tiempo real
- M�tricas de disponibilidad y confiabilidad
- Insights sobre comportamiento del usuario

### ?? **Trazabilidad Distribuida**
Rastrea solicitudes mientras fluyen a trav�s de m�ltiples servicios, creando una imagen completa del comportamiento del sistema.

**Conceptos Clave:**
- **Trace**: Viaje completo de una solicitud
- **Span**: Unidad individual de trabajo dentro de un trace
- **Context**: Informaci�n que conecta spans relacionados

### ?? **Compatibilidad OpenTelemetry**
Construido siguiendo los principios de OpenTelemetry para observabilidad vendor-neutral.

**Ventajas:**
- Est�ndar de la industria para observabilidad
- Interoperabilidad entre diferentes herramientas
- A prueba de futuro para cambios de proveedor

### ?? **Recolecci�n de M�tricas**

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
Distribuci�n de valores (tiempos de respuesta):
```pascal
TObservability.Metrics.Histogram('tiempo.respuesta.ms', TiempoRespuesta);
TObservability.Metrics.Histogram('tama�o.payload.bytes', Tama�oPayload);
```

### ?? **Logging Estructurado**
Logs ricos y buscables con contexto y correlaci�n a trav�s de sistemas distribuidos.

**Caracter�sticas:**
- Logs estructurados en JSON
- Correlaci�n autom�tica con traces
- M�ltiples niveles de log (DEBUG, INFO, WARN, ERROR)
- Atributos personalizados y contexto

## ?? Proveedores Soportados

### ?? Matriz de Soporte

| Proveedor | Trazabilidad | M�tricas | Logging | Seguimiento de Errores | Estado |
|-----------|--------------|----------|---------|------------------------|--------|
| **?? Elastic APM** | ? | ? | ? | ? | ?? Listo para Producci�n |
| **??? Jaeger** | ? | ? | ? | ? | ?? Listo para Producci�n |
| **??? Sentry** | ? | ?* | ? | ? | ?? Listo para Producci�n |
| **?? Datadog** | ? | ? | ? | ? | ?? Listo para Producci�n |
| **?? Console** | ? | ? | ? | ? | ?? Desarrollo |
| **?? TextFile** | ? | ? | ? | ? | ?? Desarrollo |

> *Las m�tricas de Sentry no est�n soportadas nativamente por la plataforma Sentry

### ?? **Proveedor Elastic APM**

**Caracter�sticas Completas:**
- ? Soporte completo del protocolo APM 8.x
- ? Transacciones, spans y m�tricas
- ? Formato de lote NDJSON
- ? Correlaci�n autom�tica padre-hijo
- ? Recolecci�n de m�tricas del sistema

**Configuraci�n:**
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

**Caracter�sticas:**
- ? Protocolo OpenTelemetry (OTLP)
- ? Trazabilidad distribuida completa
- ? Correlaci�n de contexto B3/W3C
- ? M�tricas (no soportado por Jaeger)

**Configuraci�n:**
```pascal
var Config := TObservability.CreateJaegerConfig;
Config.ServiceName := 'mi-servicio';
Config.ServerUrl := 'http://localhost:14268/api/traces';

TObservability.RegisterProvider(TJaegerProvider.Create(Config));
```

### ??? **Proveedor Sentry**

**Caracter�sticas:**
- ? Seguimiento avanzado de errores
- ? Monitoreo de rendimiento
- ? Logging estructurado con breadcrumbs
- ? Seguimiento de releases y deployment

**Configuraci�n:**
```pascal
var Config := TObservability.CreateSentryConfig;
Config.ServerUrl := 'https://tu-dsn@sentry.io/proyecto-id';
Config.Environment := 'produccion';
Config.ServiceVersion := '1.0.0';

TObservability.RegisterProvider(TSentryProvider.Create(Config));
```

### ?? **Proveedor Datadog**

**Caracter�sticas Completas:**
- ? APM completo con correlaci�n de traces
- ? M�tricas personalizadas y del sistema
- ? Logging estructurado
- ? Integraci�n con infraestructura

**Configuraci�n:**
```pascal
var Config := TObservability.CreateDatadogConfig;
Config.ApiKey := 'tu-clave-api-datadog';
Config.ServiceName := 'mi-app';
Config.ServerUrl := 'http://localhost:8126'; // Datadog Agent

TObservability.RegisterProvider(TDatadogProvider.Create(Config));
```

## ?? Sistema de M�tricas

### ?? M�tricas Autom�ticas del Sistema

Cuando se llama a `TObservability.EnableSystemMetrics`:

```pascal
// M�tricas de memoria
- system.memory.application.bytes.gauge     // Uso de memoria de la aplicaci�n
- system.memory.used.mb.gauge              // Memoria total usada del sistema
- system.memory.available.mb.gauge         // Memoria disponible
- system.memory.total.mb.gauge             // Memoria total del sistema
- system.memory.usage.percent.gauge        // Porcentaje de uso de memoria

// M�tricas de CPU
- system.cpu.application.percent.gauge     // Uso de CPU de la aplicaci�n
- system.cpu.system.percent.gauge          // Uso de CPU del sistema

// M�tricas de runtime
- system.threads.count.gauge               // N�mero de threads activos
- system.gc.allocated.bytes.gauge          // Bytes asignados por el GC
```

**Habilitaci�n:**
```pascal
// Habilitar recolecci�n autom�tica
TObservability.EnableSystemMetrics;

// O con opciones espec�ficas
TObservability.EnableSystemMetrics(
  [smoMemoryUsage, smoCPUUsage, smoThreadCount], // M�tricas a recolectar
  si30Seconds  // Intervalo de recolecci�n
);

// Recolecci�n manual �nica
TObservability.CollectSystemMetricsOnce;

// Deshabilitar cuando termine
TObservability.DisableSystemMetrics;
```

### ?? M�tricas Personalizadas

```pascal
// Contador - Rastrear n�mero de operaciones
TObservability.Metrics.Counter('api.solicitudes.total', 1);
TObservability.Metrics.Counter('cache.hits', 1);

// Medidor - Valores puntuales
TObservability.Metrics.Gauge('memoria.uso.bytes', GetUsoMemoria);
TObservability.Metrics.Gauge('usuarios.activos', GetUsuariosActivos);

// Histograma - Distribuci�n de valores
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
- **Internal**: Operaciones internas (l�gica de negocio, c�lculos)

#### **Propagaci�n de Contexto:**
```pascal
// Extraer contexto de headers HTTP
var Context := TObservability.Tracer.ExtractContext(HttpHeaders);

// Iniciar span con contexto extra�do
var Span := TObservability.StartSpan('manejar-solicitud', Context);

// Inyectar contexto en headers salientes
TObservability.Tracer.InjectHeaders(HeadersSalientes);
```

### ?? Gesti�n Autom�tica de Spans

El SDK usa una **pila LIFO** para gestionar autom�ticamente relaciones padre-hijo:

```pascal
TObservability.StartTransaction('Solicitud HTTP');
  TObservability.StartSpan('Autenticacion');
    TObservability.StartSpan('Consulta Base de Datos');
    TObservability.FinishSpan; // Finaliza Consulta Base de Datos
  TObservability.FinishSpan;   // Finaliza Autenticacion
TObservability.FinishTransaction; // Finaliza Solicitud HTTP
```

**Resultado**: Jerarqu�a perfecta con correlaci�n autom�tica de parent_id

## ?? Logging Estructurado

### ?? Niveles de Log

```pascal
// Logging simple
TObservability.LogTrace('Operaci�n iniciada');
TObservability.LogDebug('Valor de variable: %d', [valorVariable]);
TObservability.LogInfo('Usuario logueado exitosamente');
TObservability.LogWarning('Cache miss detectado');
TObservability.LogError('Operaci�n fall�', excepcion);
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

### ?? Correlaci�n Autom�tica

Los logs se correlacionan autom�ticamente con traces activos:
```pascal
var Span := TObservability.StartSpan('procesar-pedido');
try
  // Este log ser� autom�ticamente asociado con el span activo
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

## ?? Configuraci�n Avanzada

### ?? Configuraci�n Espec�fica por Proveedor

#### **Configuraci�n Completa de Elastic APM:**
```pascal
var Config := TObservability.CreateElasticConfig;
Config.ServiceName := 'mi-app-delphi';
Config.ServiceVersion := '1.0.0';
Config.Environment := 'produccion';
Config.ServerUrl := 'https://apm.miempresa.com:8200';
Config.SecretToken := 'tu-token-secreto';

// Configuraciones avanzadas v�a propiedades personalizadas
var CustomProps := TDictionary<string, string>.Create;
CustomProps.Add('capture_body', 'all');
CustomProps.Add('transaction_sample_rate', '1.0');
Config.CustomProperties := CustomProps;

var Provider := TElasticAPMProvider.Create;
Provider.Configure(Config);
TObservability.RegisterProvider(Provider);
```

#### **Configuraci�n Datadog con Tags Globales:**
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

### ?? Configuraci�n Multi-Proveedor

```pascal
// Registrar m�ltiples proveedores
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

## ?? Ejemplos Pr�cticos

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
      TObservability.LogError('Procesamiento de solicitud fall�', E);
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
    
    // Ejecutar operaci�n de base de datos
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
      TObservability.LogError('Fall� guardar usuario', E);
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
      
      // Actualizar m�tricas cada 10 elementos
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
      TObservability.LogError('Procesamiento en segundo plano fall�', E);
      TObservability.Metrics.Counter('cola.procesamiento.error', 1);
      raise;
    end;
  end;
end;
```

## ??? Instalaci�n

### ?? Requisitos del Sistema

- **Delphi**: 10.3 Rio o superior
- **Plataformas Objetivo**: Windows (32/64-bit), Linux (64-bit)
- **Framework**: Compatible con VCL/FMX
- **Runtime**: Sin dependencias de DLL externas

### ?? Pasos de Instalaci�n

1. **Descargar**: Clona o descarga el repositorio
```bash
git clone https://github.com/Julianoeichelberger/ObservabilitySDK4D.git
```

2. **Agregar Ruta**: Agrega la carpeta `source` al library path de tu proyecto

3. **Incluir Units**: Agrega las units requeridas a tu cl�usula uses
```pascal
uses
  Observability.SDK,
  Observability.Provider.Elastic, // o tu proveedor preferido
  Observability.Provider.Console;
```

4. **Inicializar**: Configura e inicializa en tu aplicaci�n
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

| Clase | Prop�sito | Thread-Safe | M�todos Principales |
|-------|-----------|-------------|-------------------|
| `TObservability` | API est�tica principal | ? S� | `StartTransaction`, `StartSpan`, `Metrics` |
| `TObservabilitySDK` | Instancia del SDK | ? S� | `Initialize`, `RegisterProvider`, `Shutdown` |
| `TElasticAPMProvider` | Integraci�n Elastic APM | ? S� | `Configure`, `SendBatch` |
| `TObservabilityContext` | Contexto de solicitud | ? S� | `Clone`, `CreateChild` |

### ?? Contratos de Interface

| Interface | Prop�sito | M�todos Principales |
|-----------|-----------|-------------------|
| `IObservabilitySpan` | Operaciones de span | `Finish`, `SetAttribute`, `SetOutcome` |
| `IObservabilityMetrics` | Recolecci�n de m�tricas | `Counter`, `Gauge`, `Histogram` |
| `IObservabilityConfig` | Configuraci�n de proveedor | Propiedades para URLs, tokens, etc. |
| `IObservabilityProvider` | Abstracci�n de proveedor | `Initialize`, `GetTracer`, `GetMetrics` |

### ? Caracter�sticas de Rendimiento

#### ?? Benchmarks

- **Creaci�n de Span**: ~50-100?s por span
- **Overhead de Memoria**: ~2-5MB baseline + ~1KB por span activo
- **Lote de Red**: Tama�o de lote configurable (predeterminado: 100 eventos)
- **Procesamiento en Segundo Plano**: Recolecci�n de m�tricas no bloqueante

#### ?? Caracter�sticas de Optimizaci�n

- **Inicializaci�n Lazy**: Los proveedores solo se inicializan cuando se usan
- **Pool de Conexiones**: Los clientes HTTP reutilizan conexiones
- **Procesamiento por Lotes**: M�ltiples eventos enviados en una sola solicitud
- **Circuit Breaking**: Fallback autom�tico en fallas del proveedor

## ?? Mejores Pr�cticas

### ?? Patrones de Transacci�n

```pascal
// ? BUENO: L�mites claros de transacci�n
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

// ? EVITAR: L�mites poco claros
TObservability.StartSpan('HacerTodo');
// Muy amplio, dif�cil de entender el rendimiento
```

### ?? Nomenclatura de M�tricas

```pascal
// ? BUENO: Nombres descriptivos y jer�rquicos
TObservability.Metrics.Counter('http.solicitudes.total');
TObservability.Metrics.Gauge('bd.conexiones.activas');
TObservability.Metrics.Histogram('api.tiempo.respuesta');

// ? EVITAR: Nombres gen�ricos
TObservability.Metrics.Counter('contador');
TObservability.Metrics.Gauge('valor');
```

### ??? Directrices de Atributos

```pascal
// ? BUENO: Atributos significativos
Span.SetAttribute('user.id', '12345');
Span.SetAttribute('http.method', 'POST');
Span.SetAttribute('bd.tabla', 'usuarios');

// ? EVITAR: Atributos de alta cardinalidad en m�tricas
// Evitar IDs �nicos en tags de m�tricas
```

### ??? Manejo de Errores

```pascal
var Span := TObservability.StartSpan('operacion-riesgosa');
try
  // Tu c�digo aqu�
  Span.SetOutcome(Success);
except
  on E: Exception do
  begin
    Span.RecordException(E);
    Span.SetOutcome(Failure);
    TObservability.LogError('Operaci�n fall�', E);
    raise; // Re-lanzar la excepci�n
  end;
end;
```

### ?? Gesti�n de Recursos

- Siempre llama `Span.Finish` en un bloque try-finally
- Usa los m�todos auxiliares del SDK para patrones comunes
- Haz shutdown apropiado del SDK al salir de la aplicaci�n

## ?? Entornos de Ejemplo

Cada proveedor incluye entornos Docker Compose completos para pruebas r�pidas:

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

- El SDK est� dise�ado para overhead m�nimo
- Los spans y m�tricas se procesan asincr�nicamente cuando es posible
- Usa tasas de muestreo en escenarios de alto throughput
- Considera tama�os de lote para logging de alto volumen

## ?? Contribuir

�Las contribuciones son bienvenidas! Por favor:

1. **Fork** el repositorio
2. **Crea** una rama de caracter�stica: `git checkout -b feature/caracteristica-increible`
3. **Commit** tus cambios: `git commit -m 'Agregar caracter�stica incre�ble'`
4. **Push** a la rama: `git push origin feature/caracteristica-increible`
5. **Abre** un Pull Request

### ?? Directrices de Contribuci�n

- Sigue los patrones de c�digo existentes
- Agrega pruebas para nueva funcionalidad
- Actualiza la documentaci�n seg�n sea necesario
- Asegura compatibilidad con Delphi 10.3+

### ?? Reportar Issues

Al reportar problemas, incluye:
- Versi�n de Delphi y plataforma
- Tipo de proveedor y configuraci�n
- C�digo de reproducci�n m�nima
- Salida de debug (si es aplicable)

## ?? Licencia

Este proyecto est� licenciado bajo la Licencia MIT - ve el archivo [LICENSE](LICENSE) para detalles.

```
MIT License

Copyright (c) 2025 Juliano Eichelberger

Se concede permiso, de forma gratuita, a cualquier persona que obtenga una copia
de este software y archivos de documentaci�n asociados (el "Software"), para tratar
en el Software sin restricci�n, incluyendo sin limitaci�n los derechos de usar, copiar,
modificar, fusionar, publicar, distribuir, sublicenciar y/o vender copias del
Software, y para permitir a las personas a quienes se proporcione el Software que lo hagan,
sujeto a las siguientes condiciones:

El aviso de copyright anterior y este aviso de permiso deben incluirse en todas
las copias o partes sustanciales del Software.
```

## ?? Soporte

- **?? Documentaci�n**: Revisa los enlaces de documentaci�n espec�ficos por idioma
- **?? Issues**: [GitHub Issues](https://github.com/Julianoeichelberger/ObservabilitySDK4D/issues)
- **?? Discusiones**: [GitHub Discussions](https://github.com/Julianoeichelberger/ObservabilitySDK4D/discussions)
- **?? Email**: Para soporte comercial, cont�ctanos

---

<div align="center">

**ObservabilitySDK4D** - Haciendo que las aplicaciones Delphi sean observables en entornos cloud modernos.

[? Dar estrella](https://github.com/Julianoeichelberger/ObservabilitySDK4D) � [?? Fork](https://github.com/Julianoeichelberger/ObservabilitySDK4D/fork) � [?? Docs](../README.md) � [?? Issues](https://github.com/Julianoeichelberger/ObservabilitySDK4D/issues)

</div>

---

*Esta documentaci�n cubre ObservabilitySDK4D v1.0.0 - �ltima actualizaci�n: Octubre 2025*