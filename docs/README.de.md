# Observability SDK für Delphi (ObservabilitySDK4D)

[![Lizenz: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Sprachen: [Português](../README.md) | [English](./README.en.md) | [Español](./README.es.md) | Deutsch (Aktuell)

---

`ObservabilitySDK4D` ist ein leistungsstarkes und erweiterbares Framework für Delphi, das entwickelt wurde, um Observability-Funktionen (Tracing, Logging und Metriken) auf einheitliche Weise in Ihre Anwendungen zu integrieren. Mit Unterstützung für mehrere Anbieter wie **Jaeger**, **Elastic APM**, **Datadog**, **Sentry** und andere ermöglicht es Entwicklern, die Gesundheit, Leistung und das Verhalten ihrer Anwendungen zentral zu überwachen.

## ✨ Hauptmerkmale

- **Einheitliche API**: Eine einzige API zur Interaktion mit verschiedenen Observability-Backends.
- **Distributed Tracing**: Verfolgen Sie den Fluss von Operationen über mehrere Dienste hinweg mit Spans und Transaktionen.
- **Strukturiertes Logging**: Senden Sie angereicherte Protokolle mit Tracing-Kontext, Umgebungsinformationen und benutzerdefinierten Attributen.
- **Anwendungsmetriken**: Sammeln Sie wesentliche Metriken wie Zähler (Counters), Messgeräte (Gauges) und Histogramme (Histograms).
- **Anbieterverwaltung**: Unterstützung für mehrere Anbieter, sodass Sie zwischen ihnen wechseln oder mehrere gleichzeitig verwenden können.
- **Flexible Konfiguration**: Konfigurieren Sie jeden Anbieter mit spezifischen Parametern wie Server-Endpunkten, API-Schlüsseln und Abtastraten.
- **Erweiterbar**: Die schnittstellenbasierte Architektur erleichtert die Erstellung eigener Observability-Anbieter.
- **Automatische Span-Verwaltung**: Ein automatischer Span-Stack vereinfacht die Erstellung von verschachtelten Spans.

## 🚀 Schnellstart

Die Integration des SDK in Ihre Anwendung ist einfach. Befolgen Sie die folgenden Schritte, um mit dem Senden von Telemetriedaten zu beginnen.

### 1. Fügen Sie die Pfade zu Ihrem Projekt hinzu

Fügen Sie die Verzeichnisse `source/core` und `source/providers` zum *Search Path* Ihres Delphi-Projekts hinzu.

### 2. Initialisieren Sie das SDK und registrieren Sie einen Anbieter

Initialisieren Sie das SDK in Ihrer Hauptprojektdatei (z. B. `.dpr`) und konfigurieren Sie den gewünschten Anbieter. Dieses Beispiel verwendet den **Jaeger**-Anbieter.

```delphi
uses
  System.SysUtils,
  Observability.SDK,
  Observability.Provider.Jaeger,
  Observability.Interfaces;

begin
  // 1. Erstellen Sie eine Konfiguration für den Jaeger-Anbieter
  // Standardmäßig verbindet er sich mit http://localhost:14268
  var JaegerConfig := TObservability.CreateJaegerConfig;
  JaegerConfig.ServiceName := 'MeineDelphiApp';
  JaegerConfig.ServiceVersion := '1.0.0';
  JaegerConfig.Environment := 'development';

  // 2. Erstellen und registrieren Sie den Jaeger-Anbieter
  var JaegerProvider := TJaegerProvider.Create;
  JaegerProvider.Configure(JaegerConfig);
  TObservability.RegisterProvider(JaegerProvider);

  // 3. Legen Sie den aktiven Anbieter fest
  TObservability.SetActiveProvider(opJaeger);

  // 4. Initialisieren Sie das SDK (dies initialisiert alle registrierten Anbieter)
  TObservability.Initialize;

  // ... Ihre Anwendungslogik hier ...

  // Anwendungsbeispiel
  try
    // Starten Sie eine Transaktion (Wurzeloperation)
    var LTransaction := TObservability.StartTransaction('BestellungVerarbeiten');
    try
      TObservability.LogInfo('Bestellverarbeitung wird gestartet');

      // Starten Sie einen untergeordneten Span für eine bestimmte Operation
      var LSpan := TObservability.StartSpan('LagerbestandPruefen');
      try
        // Arbeit simulieren
        Sleep(100);
        TObservability.AddSpanAttribute('produkt.id', '12345');
      finally
        // Beenden Sie den untergeordneten Span
        LSpan.Finish;
      end;

      // Simulieren Sie einen Fehler
      try
        raise EMyException.Create('Verbindung zum Zahlungsgateway fehlgeschlagen');
      except
        on E: EMyException do
        begin
          TObservability.LogError('Ein Fehler ist bei der Zahlung aufgetreten', E);
          LTransaction.SetOutcome(Failure); // Markieren Sie die Transaktion als fehlgeschlagen
        end;
      end;

    finally
      // Beenden Sie die Haupttransaktion
      LTransaction.Finish;
    end;
  finally
    // 5. Fahren Sie das SDK herunter, wenn die Anwendung beendet wird
    TObservability.Shutdown;
  end;
end.
```

## 📚 Kernkonzepte

### `TObservability` (Statische Klasse)

Die `TObservability`-Klasse ist der Haupteinstiegspunkt für alle SDK-Funktionen. Sie bietet statische Methoden für den Zugriff auf Tracer, Logger, Metriken und die Verwaltung des SDK-Lebenszyklus.

- `RegisterProvider(Provider)`: Registriert einen neuen Anbieter.
- `SetActiveProvider(ProviderType)`: Legt den Standardanbieter fest.
- `Initialize`: Initialisiert alle registrierten Anbieter.
- `Shutdown`: Gibt die Ressourcen aller Anbieter frei.
- `Tracer`: Gibt die `IObservabilityTracer`-Schnittstelle zum Erstellen von Spans zurück.
- `Logger`: Gibt die `IObservabilityLogger`-Schnittstelle zum Senden von Protokollen zurück.
- `Metrics`: Gibt die `IObservabilityMetrics`-Schnittstelle zum Sammeln von Metriken zurück.

### Tracing

Tracing ermöglicht es Ihnen, den Pfad einer Anfrage durch verschiedene Teile Ihres Systems zu visualisieren.

- **Transaktion**: Der Wurzel-Span, der eine übergeordnete Operation darstellt (z. B. eine HTTP-Anfrage, ein Hintergrundjob). Verwenden Sie `TObservability.StartTransaction('OperationsName')`.
- **Span**: Stellt eine einzelne Operation innerhalb einer Transaktion dar. Verwenden Sie `TObservability.StartSpan('SpanName')`, um einen untergeordneten Span des aktuellen Spans oder der Transaktion zu erstellen.
- **Beenden von Spans**: Es ist entscheidend, jeden Span mit `.Finish` zu beenden. Das SDK verwaltet den Span-Stack, sodass Sie `TObservability.FinishSpan` verwenden können, um den neuesten Span zu beenden.

```delphi
var LTransaction := TObservability.StartTransaction('MeineTransaktion');
try
  // ... Code ...
  var LSpan := TObservability.StartSpan('UntergeordneteOperation');
  try
    // ... Code ...
  finally
    LSpan.Finish; // oder TObservability.FinishSpan;
  end;
finally
  LTransaction.Finish;
end;
```

### Logging

Das SDK bietet eine strukturierte Logging-Schnittstelle, die Protokolle automatisch mit dem aktiven Span korreliert.

```delphi
// Informatives Protokoll
TObservability.LogInfo('Benutzer {Username} erfolgreich angemeldet', ['johndoe']);

// Fehlerprotokoll mit Ausnahme
try
  // ...
except
  on E: Exception do
    TObservability.LogError('Fehler bei der Datenverarbeitung', E);
end;
```

### Metriken

Sammeln Sie Metriken, um das Anwendungsverhalten zu überwachen.

```delphi
// Einen Zähler erhöhen
TObservability.Counter('bestellungen.verarbeitet', 1);

// Den Wert eines Messgeräts (Gauge) aufzeichnen
TObservability.Gauge('speicher.verfuegbar.mb', 512);

// Eine Messung zu einem Histogramm hinzufügen
TObservability.Histogram('antwortzeit.ms', 120);
```

## 🛠️ Unterstützte Anbieter

Das SDK ist so konzipiert, dass es backend-agnostisch ist. Nachfolgend sind die enthaltenen Anbieter aufgeführt.

| Anbieter | Tracing | Logging | Metriken | Anmerkungen |
|---|---|---|---|---|
| **Jaeger** | ✅ | ❌ | ❌ | Fokussiert auf Distributed Tracing. |
| **Elastic APM** | ✅ | ✅ | ✅ | Vollständige Observability-Lösung. |
| **Datadog** | ✅ | ✅ | ✅ | Vollständige Überwachungslösung. |
| **Sentry** | ✅ | ✅ | ❌ | Stark bei Fehler- und Leistungsverfolgung. |
| **Console** | ✅ | ✅ | ✅ | Konsolenausgabe, ideal für die Entwicklung. |
| **TextFile** | ✅ | ✅ | ✅ | Speichert Daten in Text-/JSON-Dateien zur Offline-Analyse. |

### Konfigurieren von Anbietern

Jeder Anbieter verfügt über eine Konfigurationserstellungsfunktion, um die Aufgabe zu erleichtern:

- `TObservability.CreateJaegerConfig()`
- `TObservability.CreateElasticConfig()`
- `TObservability.CreateDatadogConfig()`
- `TObservability.CreateSentryConfig()`
- `TObservability.CreateConsoleConfig()`
- `TObservability.CreateTextFileConfig()`

**Beispiel mit Elastic APM:**

```delphi
var ElasticConfig := TObservability.CreateElasticConfig;
ElasticConfig.ServerUrl := 'http://my-elastic-apm:8200';
ElasticConfig.ApiKey := 'my-secret-token';
ElasticConfig.ServiceName := 'MeinDienst';

var ElasticProvider := TElasticAPMProvider.Create;
ElasticProvider.Configure(ElasticConfig);
TObservability.RegisterProvider(ElasticProvider);
TObservability.SetActiveProvider(opElastic);
```

## 🏛️ Architektur

Das SDK basiert auf einem Satz von Kernschnittstellen:

- `IObservabilitySDK`: Der Kern, der die Anbieter verwaltet.
- `IObservabilityProvider`: Der Vertrag für alle Backend-Anbieter.
- `IObservabilityTracer`, `IObservabilityLogger`, `IObservabilityMetrics`: Schnittstellen für die Observability-Funktionen.
- `IObservabilitySpan`: Stellt eine Arbeitseinheit in einem Trace dar.
- `IObservabilityConfig`: Definiert die Einstellungen für die Anbieter.

Diese Architektur ermöglicht es Ihnen, das SDK einfach zu erweitern, indem Sie Ihren eigenen Anbieter erstellen, der die `IObservabilityProvider`-Schnittstelle implementiert.

## 📄 Lizenz

Dieses Projekt ist unter der **MIT-Lizenz** lizenziert. Weitere Informationen finden Sie in der Datei [LICENSE](../LICENSE).
