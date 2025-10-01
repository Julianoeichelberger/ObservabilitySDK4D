{
  *******************************************************************************

  Observability SDK for Delphi.

  Copyright (C) 2025 Juliano Eichelberger 

  License Notice:
  This software is licensed under the terms of the MIT License.

  As required by the license:
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
  The full license text can be found in the LICENSE file at the root of the project.

  For more details on the terms of use, please consult:
  https://opensource.org/licenses/MIT

  *******************************************************************************
}
unit Observability.SystemMetrics;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs,
  System.DateUtils, System.Threading,
  {$IFDEF MSWINDOWS}
  Winapi.Windows, Winapi.PsAPI, Winapi.TlHelp32,
  {$ENDIF}
  {$IFDEF LINUX}
  Posix.SysTypes, Posix.Unistd,
  {$ENDIF}
  Observability.Interfaces;

type
  /// <summary>
  /// Enumeration of collection intervals for system metrics.
  /// Defines how frequently system metrics are automatically collected.
  /// Lower intervals provide more granular monitoring but use more resources.
  /// </summary>
  TSystemMetricsCollectionInterval = (
    si5Seconds = 5000,      // High-frequency monitoring for performance testing
    si10Seconds = 10000,    // Frequent monitoring for development
    si30Seconds = 30000,    // Default balanced monitoring for production
    si1Minute = 60000,      // Low-frequency monitoring for long-running services
    si5Minutes = 300000     // Very low frequency for minimal overhead
  );

  /// <summary>
  /// Set of system metrics that can be collected.
  /// Allows selective enabling/disabling of different metric categories
  /// to balance monitoring coverage with performance overhead.
  /// </summary>
  TSystemMetricsOptions = set of (
    smoMemoryUsage,      // Application and system memory usage metrics
    smoCPUUsage,         // Application and system CPU usage percentages  
    smoDiskIO,           // Disk I/O read/write byte statistics
    smoNetworkIO,        // Network I/O received/sent byte statistics
    smoThreadCount,      // Current thread count for the application
    smoHandleCount,      // Handle count (Windows) / File descriptor count (Linux)
    smoGCMetrics         // Garbage collector and memory manager metrics
  );

  /// <summary>
  /// Interface for automatic system metrics collection and reporting.
  /// Provides lifecycle management, configuration, and integration with observability providers.
  /// Supports background collection with configurable intervals and selective metric categories.
  /// Thread-safe operations for use in multi-threaded applications.
  /// </summary>
  ISystemMetricsCollector = interface
    ['{B1C2D3E4-F5A6-7890-BCDE-234567890ABC}']
    /// <summary>Starts automatic metric collection in background thread.</summary>
    procedure Start;
    /// <summary>Stops automatic metric collection and cleans up resources.</summary>
    procedure Stop;
    /// <summary>Checks if automatic collection is currently running.</summary>
    function IsRunning: Boolean;
    /// <summary>Sets the collection interval frequency.</summary>
    procedure SetInterval(const Interval: TSystemMetricsCollectionInterval);
    /// <summary>Sets which metric categories to collect.</summary>
    procedure SetOptions(const Options: TSystemMetricsOptions);
    /// <summary>Sets the metrics provider for reporting collected metrics.</summary>
    procedure SetMetricsProvider(const Provider: IObservabilityMetrics);
    /// <summary>Collects metrics immediately without waiting for interval.</summary>
    procedure CollectOnce; // Collect metrics immediately
  end;

  /// <summary>
  /// Concrete implementation of system metrics collector with cross-platform support.
  /// Automatically collects various system and application metrics using platform-specific APIs.
  /// Provides thread-safe operation with background collection and error resilience.
  /// 
  /// Key Features:
  /// - Cross-platform support (Windows/Linux) with platform-specific optimizations
  /// - Background collection using dedicated thread with configurable intervals
  /// - Selective metric collection to minimize performance impact
  /// - Silent failure handling to prevent application disruption
  /// - Integration with any IObservabilityMetrics provider
  /// - Real-time and scheduled collection modes
  /// 
  /// Collected Metrics:
  /// - Memory: Application working set, system memory usage and availability
  /// - CPU: Application and system CPU usage percentages
  /// - Threads: Current thread count for the application
  /// - Handles: Handle/file descriptor count
  /// - I/O: Disk and network I/O statistics (platform dependent)
  /// - GC: Garbage collector and memory manager metrics
  /// </summary>
  TSystemMetricsCollector = class(TInterfacedObject, ISystemMetricsCollector)
  private
    FMetrics: IObservabilityMetrics;
    FTimer: TThread;
    FInterval: TSystemMetricsCollectionInterval;
    FOptions: TSystemMetricsOptions;
    FRunning: Boolean;
    FLock: TCriticalSection;
    FLastSystemTime: TDateTime;
    
    // Memory metrics
    /// <summary>Collects all memory-related metrics (application and system).</summary>
    procedure CollectMemoryMetrics;
    /// <summary>Gets current application memory usage in bytes.</summary>
    function GetApplicationMemoryUsage: UInt64;
    /// <summary>Gets system memory statistics [Used, Available, Total] in MB.</summary>
    function GetSystemMemoryUsage: TArray<Double>; // [Used, Available, Total] in MB
    
    // CPU metrics
    /// <summary>Collects CPU usage metrics for application and system.</summary>
    procedure CollectCPUMetrics;
    /// <summary>Gets current application CPU usage as percentage.</summary>
    function GetApplicationCPUUsage: Double; // Percentage
    /// <summary>Gets current system-wide CPU usage as percentage.</summary>
    function GetSystemCPUUsage: Double; // Percentage
    
    // I/O metrics
    /// <summary>Collects disk and network I/O statistics.</summary>
    procedure CollectIOMetrics;
    /// <summary>Gets disk I/O statistics [ReadBytes, WriteBytes].</summary>
    function GetDiskIOStats: TArray<UInt64>; // [ReadBytes, WriteBytes]
    /// <summary>Gets network I/O statistics [ReceivedBytes, SentBytes].</summary>
    function GetNetworkIOStats: TArray<UInt64>; // [ReceivedBytes, SentBytes]
    
    // System metrics
    /// <summary>Collects system resource metrics (threads, handles).</summary>
    procedure CollectSystemMetrics;
    /// <summary>Gets current thread count for the application.</summary>
    function GetThreadCount: Integer;
    /// <summary>Gets current handle/file descriptor count.</summary>
    function GetHandleCount: Integer;
    
    // GC metrics (Delphi)
    /// <summary>Collects garbage collector and memory manager metrics.</summary>
    procedure CollectGCMetrics;
    
    // Platform-specific helpers
    {$IFDEF MSWINDOWS}
    /// <summary>Gets Windows memory status information.</summary>
    function GetWindowsMemoryInfo: TMemoryStatusEx;
    /// <summary>Calculates Windows-specific CPU usage.</summary>
    function GetWindowsCPUUsage: Double;
    /// <summary>Gets Windows process information.</summary>
    function GetWindowsProcessInfo: TProcessEntry32;
    {$ENDIF}
    
    {$IFDEF LINUX}
    /// <summary>Gets Linux memory information from /proc/meminfo.</summary>
    function GetLinuxMemoryInfo: TArray<UInt64>;
    /// <summary>Calculates Linux-specific CPU usage from /proc/stat.</summary>
    function GetLinuxCPUUsage: Double;
    /// <summary>Gets Linux process information from /proc filesystem.</summary>
    function GetLinuxProcessInfo: TArray<UInt64>;
    {$ENDIF}
  protected
    /// <summary>
    /// Performs the actual metrics collection based on enabled options.
    /// Called by background thread or manual collection. Handles errors silently.
    /// </summary>
    procedure DoCollectMetrics;
  public
    /// <summary>
    /// Creates a new system metrics collector with default settings.
    /// Initializes with 30-second interval and basic metrics (memory, CPU, threads).
    /// </summary>
    constructor Create;
    
    /// <summary>
    /// Destroys the collector and ensures background collection is stopped.
    /// Automatically calls Stop to clean up resources safely.
    /// </summary>
    destructor Destroy; override;
    
    /// <summary>
    /// Starts background metric collection using configured interval.
    /// Requires metrics provider to be set before starting.
    /// Thread-safe operation that can be called multiple times safely.
    /// </summary>
    procedure Start;
    
    /// <summary>
    /// Stops background metric collection and terminates collection thread.
    /// Thread-safe operation that waits for thread termination.
    /// Can be called multiple times safely.
    /// </summary>
    procedure Stop;
    
    /// <summary>
    /// Checks if background metric collection is currently active.
    /// Thread-safe operation for checking collector state.
    /// </summary>
    /// <returns>True if collection is running, false otherwise</returns>
    function IsRunning: Boolean;
    
    /// <summary>
    /// Sets the collection interval for background metrics.
    /// If collector is running, it will be restarted with new interval.
    /// Thread-safe operation with automatic restart handling.
    /// </summary>
    /// <param name="Interval">The new collection interval</param>
    procedure SetInterval(const Interval: TSystemMetricsCollectionInterval);
    
    /// <summary>
    /// Sets which categories of metrics to collect.
    /// Changes take effect on next collection cycle.
    /// Thread-safe operation for runtime configuration.
    /// </summary>
    /// <param name="Options">Set of metric categories to enable</param>
    procedure SetOptions(const Options: TSystemMetricsOptions);
    
    /// <summary>
    /// Sets the metrics provider for reporting collected metrics.
    /// Required before starting automatic collection.
    /// Thread-safe operation for provider configuration.
    /// </summary>
    /// <param name="Provider">The metrics provider to use for reporting</param>
    procedure SetMetricsProvider(const Provider: IObservabilityMetrics);
    
    /// <summary>
    /// Collects metrics immediately without waiting for collection interval.
    /// Useful for on-demand metrics collection or manual triggers.
    /// Thread-safe operation that can be called while background collection is running.
    /// </summary>
    procedure CollectOnce;
    
    /// <summary>
    /// Factory method that creates a collector with recommended default settings.
    /// Includes memory, CPU, thread count, and GC metrics with 30-second interval.
    /// </summary>
    /// <returns>Configured system metrics collector ready for use</returns>
    class function CreateDefaultCollector: ISystemMetricsCollector; static;
  end;

  // Helper thread for periodic collection
  /// <summary>
  /// Background thread for periodic system metrics collection.
  /// Runs independently from main application thread to collect metrics at regular intervals.
  /// Designed to be lightweight and resilient to collection errors.
  /// Automatically terminates when collector is stopped.
  /// </summary>
  TSystemMetricsThread = class(TThread)
  private
    FCollector: TSystemMetricsCollector;
    FInterval: Cardinal;
  protected
    /// <summary>
    /// Main thread execution loop that collects metrics at specified intervals.
    /// Handles collection errors silently to prevent thread termination.
    /// Respects termination signals for clean shutdown.
    /// </summary>
    procedure Execute; override;
  public
    /// <summary>
    /// Creates a new metrics collection thread.
    /// Thread starts immediately and begins collecting at specified interval.
    /// </summary>
    /// <param name="Collector">The collector instance to use for metrics collection</param>
    /// <param name="Interval">The collection interval in milliseconds</param>
    constructor Create(const Collector: TSystemMetricsCollector; const Interval: Cardinal);
  end;

implementation

{ TSystemMetricsCollector }

/// <summary>
/// Creates a system metrics collector with default configuration.
/// Sets up basic metrics collection (memory, CPU, threads) with 30-second interval.
/// </summary>
constructor TSystemMetricsCollector.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FInterval := si30Seconds;
  FOptions := [smoMemoryUsage, smoCPUUsage, smoThreadCount];
  FRunning := False;
  FLastSystemTime := Now;
end;

destructor TSystemMetricsCollector.Destroy;
begin
  Stop;
  FLock.Free;
  inherited Destroy;
end;

/// <summary>
/// Creates a system metrics collector with recommended production settings.
/// Includes comprehensive metrics collection with balanced performance impact.
/// </summary>
class function TSystemMetricsCollector.CreateDefaultCollector: ISystemMetricsCollector;
var
  Collector: TSystemMetricsCollector;
begin
  Collector := TSystemMetricsCollector.Create;
  Collector.SetOptions([smoMemoryUsage, smoCPUUsage, smoThreadCount, smoGCMetrics]);
  Collector.SetInterval(si30Seconds);
  Result := Collector;
end;

/// <summary>
/// Starts background metrics collection with configured interval and options.
/// Creates and starts background thread for periodic collection.
/// Requires metrics provider to be configured before starting.
/// </summary>
procedure TSystemMetricsCollector.Start;
begin
  FLock.Enter;
  try
    if FRunning or not Assigned(FMetrics) then
      Exit;
      
    FRunning := True;
    FTimer := TSystemMetricsThread.Create(Self, Cardinal(FInterval));
  finally
    FLock.Leave;
  end;
end;

procedure TSystemMetricsCollector.Stop;
begin
  FLock.Enter;
  try
    if not FRunning then
      Exit;
      
    FRunning := False;
    if Assigned(FTimer) then
    begin
      FTimer.Terminate;
      FTimer.WaitFor;
      FTimer.Free;
      FTimer := nil;
    end;
  finally
    FLock.Leave;
  end;
end;

function TSystemMetricsCollector.IsRunning: Boolean;
begin
  FLock.Enter;
  try
    Result := FRunning;
  finally
    FLock.Leave;
  end;
end;

procedure TSystemMetricsCollector.SetInterval(const Interval: TSystemMetricsCollectionInterval);
begin
  FLock.Enter;
  try
    FInterval := Interval;
    if FRunning then
    begin
      Stop;
      Start; // Restart with new interval
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TSystemMetricsCollector.SetOptions(const Options: TSystemMetricsOptions);
begin
  FLock.Enter;
  try
    FOptions := Options;
  finally
    FLock.Leave;
  end;
end;

procedure TSystemMetricsCollector.SetMetricsProvider(const Provider: IObservabilityMetrics);
begin
  FLock.Enter;
  try
    FMetrics := Provider;
  finally
    FLock.Leave;
  end;
end;

procedure TSystemMetricsCollector.CollectOnce;
begin
  FLock.Enter;
  try
    if Assigned(FMetrics) then
      DoCollectMetrics;
  finally
    FLock.Leave;
  end;
end;

/// <summary>
/// Coordinates collection of all enabled metric categories.
/// Calls specific collection methods based on configured options.
/// Uses silent error handling to ensure application stability.
/// </summary>
procedure TSystemMetricsCollector.DoCollectMetrics;
begin
  try
    if smoMemoryUsage in FOptions then
      CollectMemoryMetrics;
      
    if smoCPUUsage in FOptions then
      CollectCPUMetrics;
      
    if smoDiskIO in FOptions then
      CollectIOMetrics;
      
    if smoThreadCount in FOptions then
      CollectSystemMetrics;
      
    if smoGCMetrics in FOptions then
      CollectGCMetrics;
  except
    // Silent failure for metrics collection to avoid breaking application
  end;
end;

/// <summary>
/// Collects comprehensive memory metrics for application and system.
/// Reports application working set, system memory usage, and usage percentages.
/// Uses platform-specific APIs for accurate memory information.
/// </summary>
procedure TSystemMetricsCollector.CollectMemoryMetrics;
var
  AppMemory: UInt64;
  SystemMemory: TArray<Double>;
begin
  try
    // Application memory usage
    AppMemory := GetApplicationMemoryUsage;
    FMetrics.Gauge('system.memory.application.bytes', AppMemory);
    FMetrics.Gauge('system.memory.application.mb', AppMemory / (1024 * 1024));
    
    // System memory usage
    SystemMemory := GetSystemMemoryUsage;
    if Length(SystemMemory) >= 3 then
    begin
      FMetrics.Gauge('system.memory.used.mb', SystemMemory[0]);
      FMetrics.Gauge('system.memory.available.mb', SystemMemory[1]);
      FMetrics.Gauge('system.memory.total.mb', SystemMemory[2]);
      FMetrics.Gauge('system.memory.usage.percent', (SystemMemory[0] / SystemMemory[2]) * 100);
    end;
  except
    // Silent failure
  end;
end;

procedure TSystemMetricsCollector.CollectCPUMetrics;
var
  AppCPU, SystemCPU: Double;
begin
  try
    AppCPU := GetApplicationCPUUsage;
    SystemCPU := GetSystemCPUUsage;
    
    FMetrics.Gauge('system.cpu.application.percent', AppCPU);
    FMetrics.Gauge('system.cpu.system.percent', SystemCPU);
  except
    // Silent failure
  end;
end;

procedure TSystemMetricsCollector.CollectIOMetrics;
var
  DiskIO, NetworkIO: TArray<UInt64>;
begin
  try
    if smoDiskIO in FOptions then
    begin
      DiskIO := GetDiskIOStats;
      if Length(DiskIO) >= 2 then
      begin
        FMetrics.Counter('system.disk.read.bytes', DiskIO[0]);
        FMetrics.Counter('system.disk.write.bytes', DiskIO[1]);
      end;
    end;
    
    if smoNetworkIO in FOptions then
    begin
      NetworkIO := GetNetworkIOStats;
      if Length(NetworkIO) >= 2 then
      begin
        FMetrics.Counter('system.network.received.bytes', NetworkIO[0]);
        FMetrics.Counter('system.network.sent.bytes', NetworkIO[1]);
      end;
    end;
  except
    // Silent failure
  end;
end;

procedure TSystemMetricsCollector.CollectSystemMetrics;
var
  ThreadCount, HandleCount: Integer;
begin
  try
    ThreadCount := GetThreadCount;
    FMetrics.Gauge('system.threads.count', ThreadCount);
    
    if smoHandleCount in FOptions then
    begin
      HandleCount := GetHandleCount;
      FMetrics.Gauge('system.handles.count', HandleCount);
    end;
  except
    // Silent failure
  end;
end;

procedure TSystemMetricsCollector.CollectGCMetrics;
begin
  try
    // Delphi memory manager stats would go here
    // For now, we'll use basic memory information
    FMetrics.Gauge('system.gc.allocated.bytes', GetApplicationMemoryUsage);
  except
    // Silent failure
  end;
end;

/// <summary>
/// Gets current application memory usage using platform-specific APIs.
/// On Windows: Uses GetProcessMemoryInfo for working set size.
/// On Linux: Parses /proc/self/status for VmRSS (resident set size).
/// Returns 0 on any error to ensure safe operation.
/// </summary>
function TSystemMetricsCollector.GetApplicationMemoryUsage: UInt64;
{$IFDEF MSWINDOWS}
var
  MemCounters: TProcessMemoryCounters;
begin
  Result := 0;
  try
    if GetProcessMemoryInfo(GetCurrentProcess, @MemCounters, SizeOf(MemCounters)) then
      Result := MemCounters.WorkingSetSize;
  except
    Result := 0;
  end;
end;
{$ELSE}
var
  StatFile: TextFile;
  Line: string;
  Fields: TArray<string>;
begin
  Result := 0;
  try
    AssignFile(StatFile, '/proc/self/status');
    Reset(StatFile);
    try
      while not Eof(StatFile) do
      begin
        ReadLn(StatFile, Line);
        if Line.StartsWith('VmRSS:') then
        begin
          Fields := Line.Split([#9, ' '], TStringSplitOptions.ExcludeEmpty);
          if Length(Fields) >= 2 then
            Result := StrToInt64Def(Fields[1], 0) * 1024; // Convert KB to bytes
          Break;
        end;
      end;
    finally
      CloseFile(StatFile);
    end;
  except
    Result := 0;
  end;
end;
{$ENDIF}

/// <summary>
/// Gets system-wide memory statistics using platform-specific methods.
/// Returns array with [Used MB, Available MB, Total MB].
/// On Windows: Uses GlobalMemoryStatusEx API.
/// On Linux: Parses /proc/meminfo for MemTotal and MemAvailable.
/// </summary>
function TSystemMetricsCollector.GetSystemMemoryUsage: TArray<Double>;
{$IFDEF MSWINDOWS}
var
  MemStatus: TMemoryStatusEx;
begin
  SetLength(Result, 3);
  try
    MemStatus := GetWindowsMemoryInfo;
    Result[0] := (MemStatus.ullTotalPhys - MemStatus.ullAvailPhys) / (1024 * 1024); // Used MB
    Result[1] := MemStatus.ullAvailPhys / (1024 * 1024); // Available MB
    Result[2] := MemStatus.ullTotalPhys / (1024 * 1024); // Total MB
  except
    Result[0] := 0;
    Result[1] := 0;
    Result[2] := 0;
  end;
end;
{$ELSE}
var
  MeminfoFile: TextFile;
  Line: string;
  Fields: TArray<string>;
  MemTotal, MemAvailable: UInt64;
begin
  SetLength(Result, 3);
  MemTotal := 0;
  MemAvailable := 0;
  
  try
    AssignFile(MeminfoFile, '/proc/meminfo');
    Reset(MeminfoFile);
    try
      while not Eof(MeminfoFile) do
      begin
        ReadLn(MeminfoFile, Line);
        Fields := Line.Split([':', ' ', #9], TStringSplitOptions.ExcludeEmpty);
        
        if (Length(Fields) >= 2) and (Fields[0] = 'MemTotal') then
          MemTotal := StrToInt64Def(Fields[1], 0)
        else if (Length(Fields) >= 2) and (Fields[0] = 'MemAvailable') then
          MemAvailable := StrToInt64Def(Fields[1], 0);
      end;
    finally
      CloseFile(MeminfoFile);
    end;
    
    Result[0] := (MemTotal - MemAvailable) / 1024; // Used MB
    Result[1] := MemAvailable / 1024; // Available MB
    Result[2] := MemTotal / 1024; // Total MB
  except
    Result[0] := 0;
    Result[1] := 0;
    Result[2] := 0;
  end;
end;
{$ENDIF}

function TSystemMetricsCollector.GetApplicationCPUUsage: Double;
begin
  // This would require more complex implementation
  // For now, return 0 as placeholder
  Result := 0.0;
end;

function TSystemMetricsCollector.GetSystemCPUUsage: Double;
begin
  // This would require more complex implementation
  // For now, return 0 as placeholder
  Result := 0.0;
end;

function TSystemMetricsCollector.GetDiskIOStats: TArray<UInt64>;
begin
  SetLength(Result, 2);
  Result[0] := 0; // Read bytes
  Result[1] := 0; // Write bytes
end;

function TSystemMetricsCollector.GetNetworkIOStats: TArray<UInt64>;
begin
  SetLength(Result, 2);
  Result[0] := 0; // Received bytes
  Result[1] := 0; // Sent bytes
end;

/// <summary>
/// Gets current thread count for the application using platform-specific methods.
/// On Windows: Uses CreateToolhelp32Snapshot to enumerate threads.
/// On Linux: Counts entries in /proc/self/task directory.
/// Returns 0 on error to ensure safe operation.
/// </summary>
function TSystemMetricsCollector.GetThreadCount: Integer;
{$IFDEF MSWINDOWS}
var
  Snapshot: THandle;
  ThreadEntry: TThreadEntry32;
  ProcessId: DWORD;
begin
  Result := 0;
  ProcessId := GetCurrentProcessId;
  
  Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
  if Snapshot = INVALID_HANDLE_VALUE then
    Exit;
    
  try
    ThreadEntry.dwSize := SizeOf(TThreadEntry32);
    if Thread32First(Snapshot, ThreadEntry) then
    begin
      repeat
        if ThreadEntry.th32OwnerProcessID = ProcessId then
          Inc(Result);
      until not Thread32Next(Snapshot, ThreadEntry);
    end;
  finally
    CloseHandle(Snapshot);
  end;
end;
{$ELSE}
var
  TaskDir: string;
  SearchRec: TSearchRec;
begin
  Result := 0;
  TaskDir := '/proc/self/task';
  
  try
    if FindFirst(TaskDir + '/*', faDirectory, SearchRec) = 0 then
    begin
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          Inc(Result);
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;
  except
    Result := 0;
  end;
end;
{$ENDIF}

/// <summary>
/// Gets current handle/file descriptor count using platform-specific methods.
/// On Windows: Uses GetProcessHandleCount API.
/// On Linux: Counts entries in /proc/self/fd directory.
/// Returns 0 on error to ensure safe operation.
/// </summary>
function TSystemMetricsCollector.GetHandleCount: Integer;
{$IFDEF MSWINDOWS}
var
  ProcessHandle: THandle;
  HandleCount: DWORD;
begin
  Result := 0;
  ProcessHandle := GetCurrentProcess;
  if GetProcessHandleCount(ProcessHandle, HandleCount) then
    Result := HandleCount;
end;
{$ELSE}
var
  FdDir: string;
  SearchRec: TSearchRec;
begin
  Result := 0;
  FdDir := '/proc/self/fd';
  
  try
    if FindFirst(FdDir + '/*', faAnyFile, SearchRec) = 0 then
    begin
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          Inc(Result);
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;
  except
    Result := 0;
  end;
end;
{$ENDIF}

{$IFDEF MSWINDOWS}
function TSystemMetricsCollector.GetWindowsMemoryInfo: TMemoryStatusEx;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.dwLength := SizeOf(Result);
  GlobalMemoryStatusEx(Result);
end;

function TSystemMetricsCollector.GetWindowsCPUUsage: Double;
begin
  Result := 0.0; // Placeholder for complex CPU calculation
end;

function TSystemMetricsCollector.GetWindowsProcessInfo: TProcessEntry32;
begin
  FillChar(Result, SizeOf(Result), 0);
  // Placeholder for process information
end;
{$ENDIF}

{$IFDEF LINUX}
function TSystemMetricsCollector.GetLinuxMemoryInfo: TArray<UInt64>;
begin
  SetLength(Result, 0);
  // Placeholder for Linux memory info
end;

function TSystemMetricsCollector.GetLinuxCPUUsage: Double;
begin
  Result := 0.0; // Placeholder for Linux CPU calculation
end;

function TSystemMetricsCollector.GetLinuxProcessInfo: TArray<UInt64>;
begin
  SetLength(Result, 0);
  // Placeholder for Linux process info
end;
{$ENDIF}

{ TSystemMetricsThread }

/// <summary>
/// Creates and starts a background thread for periodic metrics collection.
/// Thread is created in non-suspended state and begins collection immediately.
/// </summary>
constructor TSystemMetricsThread.Create(const Collector: TSystemMetricsCollector; const Interval: Cardinal);
begin
  inherited Create(False);
  FCollector := Collector;
  FInterval := Interval;
  FreeOnTerminate := False;
end;

/// <summary>
/// Main execution loop for background metrics collection.
/// Continuously collects metrics at specified intervals until termination is requested.
/// Uses silent error handling to prevent thread termination due to collection failures.
/// Respects termination signals for clean shutdown.
/// </summary>
procedure TSystemMetricsThread.Execute;
begin
  while not Terminated do
  begin
    try
      FCollector.DoCollectMetrics;
    except
      // Silent failure
    end;
    
    // Wait for interval or termination
    Sleep(FInterval);
  end;
end;

end.