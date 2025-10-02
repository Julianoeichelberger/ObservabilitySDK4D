#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Datadog Agent environment management script for ObservabilitySDK4D samples

.DESCRIPTION
    This script helps manage a local Datadog Agent environment using Docker Compose
    for testing the ObservabilitySDK4D Datadog provider implementation.

.PARAMETER Action
    The action to perform: start, stop, status, logs, clean, reset

.EXAMPLE
    .\datadog.ps1 start
    Start the Datadog Agent environment

.EXAMPLE
    .\datadog.ps1 logs
    Show logs from Datadog Agent
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "status", "logs", "clean", "reset", "config")]
    [string]$Action
)

# Configuration
$ComposeFile = "docker-compose.yml"
$ProjectName = "observability-datadog"
$EnvFile = ".env"

function Write-Info($message) {
    Write-Host "??  $message" -ForegroundColor Cyan
}

function Write-Success($message) {
    Write-Host "? $message" -ForegroundColor Green
}

function Write-Warning($message) {
    Write-Host "??  $message" -ForegroundColor Yellow
}

function Write-Error($message) {
    Write-Host "? $message" -ForegroundColor Red
}

function Test-DockerCompose {
    try {
        $null = docker-compose --version
        return $true
    }
    catch {
        Write-Error "Docker Compose is not installed or not available in PATH"
        return $false
    }
}

function Initialize-Environment {
    if (-not (Test-Path $EnvFile)) {
        Write-Info "Creating environment file..."
        @"
# Datadog Configuration
DD_API_KEY=your-api-key-here
DD_SITE=datadoghq.com

# Optional: Application Key for extended features
# DD_APP_KEY=your-app-key-here
"@ | Out-File -FilePath $EnvFile -Encoding utf8

        Write-Warning "Please edit .env file and set your DD_API_KEY"
        Write-Info "You can get your API key from: https://app.datadoghq.com/organization-settings/api-keys"
        return $false
    }
    return $true
}

function Start-DatadogEnvironment {
    if (-not (Initialize-Environment)) {
        return
    }
    
    # Check if API key is set
    $envContent = Get-Content $EnvFile
    $apiKeyLine = $envContent | Where-Object { $_ -match "DD_API_KEY=(.+)" }
    if ($apiKeyLine -match "your-api-key-here") {
        Write-Error "Please set your DD_API_KEY in the .env file"
        Write-Info "Edit .env file and replace 'your-api-key-here' with your actual Datadog API key"
        return
    }
    
    Write-Info "Starting Datadog Agent environment..."
    
    # Start services
    docker-compose -p $ProjectName up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Datadog Agent started successfully!"
        Write-Info "Services available:"
        Write-Host "  • APM Traces: localhost:8126" -ForegroundColor White
        Write-Host "  • DogStatsD Metrics: localhost:8125 (UDP)" -ForegroundColor White
        Write-Host "  • Agent API: localhost:5002" -ForegroundColor White
        Write-Host "  • Datadog Dashboard: https://app.datadoghq.com/" -ForegroundColor White
        Write-Info ""
        Write-Info "Delphi Configuration:"
        Write-Host "  Config.ServerUrl := 'http://localhost:8126';" -ForegroundColor Cyan
        Write-Host "  Config.ApiKey := 'your-datadog-api-key';" -ForegroundColor Cyan
        Write-Host "  Config.ServiceName := 'MyDelphiApp';" -ForegroundColor Cyan
        Write-Host "  Config.Environment := 'development';" -ForegroundColor Cyan
    } else {
        Write-Error "Failed to start Datadog Agent environment"
    }
}

function Stop-DatadogEnvironment {
    Write-Info "Stopping Datadog Agent environment..."
    docker-compose -p $ProjectName down
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Datadog Agent environment stopped"
    } else {
        Write-Error "Failed to stop Datadog Agent environment"
    }
}

function Show-DatadogStatus {
    Write-Info "Datadog Agent Status:"
    docker-compose -p $ProjectName ps
    
    Write-Info "`nAgent Health Check:"
    $agentStatus = docker exec datadog-agent agent status 2>$null
    if ($agentStatus) {
        Write-Success "Agent is running"
        Write-Info "Datadog Agent Status Summary:"
        $agentStatus | Select-String -Pattern "(API Key|Running|Forwarder|DogStatsD|APM Agent)"
    } else {
        Write-Warning "Agent container not running or not accessible"
    }
    
    Write-Info "`nContainer Health:"
    $healthStatus = docker inspect --format='{{.State.Health.Status}}' datadog-agent 2>$null
    if ($healthStatus) {
        $statusIcon = switch ($healthStatus) {
            "healthy" { "?" }
            "unhealthy" { "?" }
            "starting" { "??" }
            default { "?" }
        }
        Write-Host "  $statusIcon datadog-agent: $healthStatus" -ForegroundColor $(if ($healthStatus -eq "healthy") { "Green" } elseif ($healthStatus -eq "unhealthy") { "Red" } else { "Yellow" })
    } else {
        Write-Host "  ? datadog-agent: not found" -ForegroundColor Gray
    }
}

function Show-DatadogLogs {
    Write-Info "Showing logs from Datadog Agent (Ctrl+C to exit)..."
    docker-compose -p $ProjectName logs -f datadog-agent
}

function Show-Configuration {
    Write-Info "Datadog Configuration Guide:"
    Write-Host ""
    Write-Host "1. Environment Setup:" -ForegroundColor Yellow
    Write-Host "   • Edit .env file with your Datadog API key" -ForegroundColor White
    Write-Host "   • Get API key from: https://app.datadoghq.com/organization-settings/api-keys" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Delphi Application Configuration:" -ForegroundColor Yellow
    Write-Host "   var Config: IObservabilityConfig;" -ForegroundColor Cyan
    Write-Host "   begin" -ForegroundColor Cyan
    Write-Host "     Config := TObservabilityConfig.Create;" -ForegroundColor Cyan
    Write-Host "     Config.ApiKey := 'your-datadog-api-key';" -ForegroundColor Cyan
    Write-Host "     Config.ServiceName := 'MyDelphiApp';" -ForegroundColor Cyan
    Write-Host "     Config.ServiceVersion := '1.0.0';" -ForegroundColor Cyan
    Write-Host "     Config.Environment := 'development';" -ForegroundColor Cyan
    Write-Host "     " -ForegroundColor Cyan
    Write-Host "     // For APM (traces)" -ForegroundColor Cyan
    Write-Host "     Config.ServerUrl := 'http://localhost:8126';" -ForegroundColor Cyan
    Write-Host "     " -ForegroundColor Cyan
    Write-Host "     Provider := TDatadogProvider.Create;" -ForegroundColor Cyan
    Write-Host "     Provider.Initialize(Config);" -ForegroundColor Cyan
    Write-Host "   end;" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "3. Available Endpoints:" -ForegroundColor Yellow
    Write-Host "   • APM (Traces): localhost:8126" -ForegroundColor White
    Write-Host "   • DogStatsD (Metrics): localhost:8125 (UDP)" -ForegroundColor White
    Write-Host "   • Agent API: localhost:5002" -ForegroundColor White
    Write-Host ""
    Write-Host "4. Datadog Dashboard:" -ForegroundColor Yellow
    Write-Host "   • APM: https://app.datadoghq.com/apm/traces" -ForegroundColor White
    Write-Host "   • Metrics: https://app.datadoghq.com/metric/explorer" -ForegroundColor White
    Write-Host "   • Logs: https://app.datadoghq.com/logs" -ForegroundColor White
}

function Remove-DatadogEnvironment {
    Write-Warning "This will stop and remove all containers and networks (but keep volumes)"
    $confirm = Read-Host "Continue? (y/N)"
    
    if ($confirm -eq "y" -or $confirm -eq "Y") {
        Write-Info "Cleaning Datadog Agent environment..."
        docker-compose -p $ProjectName down --remove-orphans
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Datadog Agent environment cleaned"
        } else {
            Write-Error "Failed to clean Datadog Agent environment"
        }
    } else {
        Write-Info "Operation cancelled"
    }
}

function Reset-DatadogEnvironment {
    Write-Warning "This will DESTROY ALL DATA including agent configuration and logs!"
    Write-Warning "You will need to reconfigure the agent from scratch."
    $confirm = Read-Host "Are you sure? Type 'RESET' to confirm"
    
    if ($confirm -eq "RESET") {
        Write-Info "Resetting Datadog Agent environment..."
        docker-compose -p $ProjectName down --volumes --remove-orphans
        
        # Remove environment file
        if (Test-Path $EnvFile) {
            Remove-Item $EnvFile
            Write-Info "Removed environment configuration file"
        }
        
        # Remove any dangling images
        Write-Info "Cleaning up Docker images..."
        docker image prune -f
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Datadog Agent environment completely reset"
            Write-Info "Run '.\datadog.ps1 start' to create a fresh environment"
        } else {
            Write-Error "Failed to reset Datadog Agent environment"
        }
    } else {
        Write-Info "Operation cancelled - you must type 'RESET' exactly"
    }
}

# Main script execution
if (-not (Test-Path $ComposeFile)) {
    Write-Error "Docker Compose file '$ComposeFile' not found in current directory"
    exit 1
}

if (-not (Test-DockerCompose)) {
    exit 1
}

switch ($Action) {
    "start" { Start-DatadogEnvironment }
    "stop" { Stop-DatadogEnvironment }
    "status" { Show-DatadogStatus }
    "logs" { Show-DatadogLogs }
    "config" { Show-Configuration }
    "clean" { Remove-DatadogEnvironment }
    "reset" { Reset-DatadogEnvironment }
}

Write-Info "Done!"