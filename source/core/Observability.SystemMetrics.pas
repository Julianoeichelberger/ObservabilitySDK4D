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
  TSystemMetricsCollectionInterval = (
    si5Seconds = 5000,
    si10Seconds = 10000,
    si30Seconds = 30000,
    si1Minute = 60000,
    si5Minutes = 300000
  );

  TSystemMetricsOptions = set of (
    smoMemoryUsage,      // Application and system memory usage
    smoCPUUsage,         // Application and system CPU usage
    smoDiskIO,           // Disk I/O statistics
    smoNetworkIO,        // Network I/O statistics
    smoThreadCount,      // Thread count
    smoHandleCount,      // Handle count (Windows) / File descriptor count (Linux)
    smoGCMetrics         // Garbage collector metrics
  );

  ISystemMetricsCollector = interface
    ['{B1C2D3E4-F5A6-7890-BCDE-234567890ABC}']
    procedure Start;
    procedure Stop;
    function IsRunning: Boolean;
    procedure SetInterval(const Interval: TSystemMetricsCollectionInterval);
    procedure SetOptions(const Options: TSystemMetricsOptions);
    procedure SetMetricsProvider(const Provider: IObservabilityMetrics);
    procedure CollectOnce; // Collect metrics immediately
  end;

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
    procedure CollectMemoryMetrics;
    function GetApplicationMemoryUsage: UInt64;
    function GetSystemMemoryUsage: TArray<Double>; // [Used, Available, Total] in MB
    
    // CPU metrics
    procedure CollectCPUMetrics;
    function GetApplicationCPUUsage: Double; // Percentage
    function GetSystemCPUUsage: Double; // Percentage
    
    // I/O metrics
    procedure CollectIOMetrics;
    function GetDiskIOStats: TArray<UInt64>; // [ReadBytes, WriteBytes]
    function GetNetworkIOStats: TArray<UInt64>; // [ReceivedBytes, SentBytes]
    
    // System metrics
    procedure CollectSystemMetrics;
    function GetThreadCount: Integer;
    function GetHandleCount: Integer;
    
    // GC metrics (Delphi)
    procedure CollectGCMetrics;
    
    // Platform-specific helpers
    {$IFDEF MSWINDOWS}
    function GetWindowsMemoryInfo: TMemoryStatusEx;
    function GetWindowsCPUUsage: Double;
    function GetWindowsProcessInfo: TProcessEntry32;
    {$ENDIF}
    
    {$IFDEF LINUX}
    function GetLinuxMemoryInfo: TArray<UInt64>;
    function GetLinuxCPUUsage: Double;
    function GetLinuxProcessInfo: TArray<UInt64>;
    {$ENDIF}
  protected
    procedure DoCollectMetrics;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Start;
    procedure Stop;
    function IsRunning: Boolean;
    procedure SetInterval(const Interval: TSystemMetricsCollectionInterval);
    procedure SetOptions(const Options: TSystemMetricsOptions);
    procedure SetMetricsProvider(const Provider: IObservabilityMetrics);
    procedure CollectOnce;
    
    class function CreateDefaultCollector: ISystemMetricsCollector; static;
  end;

  // Helper thread for periodic collection
  TSystemMetricsThread = class(TThread)
  private
    FCollector: TSystemMetricsCollector;
    FInterval: Cardinal;
  protected
    procedure Execute; override;
  public
    constructor Create(const Collector: TSystemMetricsCollector; const Interval: Cardinal);
  end;

implementation

{ TSystemMetricsCollector }

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

class function TSystemMetricsCollector.CreateDefaultCollector: ISystemMetricsCollector;
var
  Collector: TSystemMetricsCollector;
begin
  Collector := TSystemMetricsCollector.Create;
  Collector.SetOptions([smoMemoryUsage, smoCPUUsage, smoThreadCount, smoGCMetrics]);
  Collector.SetInterval(si30Seconds);
  Result := Collector;
end;

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

constructor TSystemMetricsThread.Create(const Collector: TSystemMetricsCollector; const Interval: Cardinal);
begin
  inherited Create(False);
  FCollector := Collector;
  FInterval := Interval;
  FreeOnTerminate := False;
end;

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