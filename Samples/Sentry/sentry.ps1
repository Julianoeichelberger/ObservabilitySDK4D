#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Simple Sentry environment management script for ObservabilitySDK4D samples

.DESCRIPTION
    This script helps manage a local Sentry environment using Docker Compose
    for testing the ObservabilitySDK4D Sentry provider implementation.

.PARAMETER Action
    The action to perform: start, stop, status, logs, clean, reset

.EXAMPLE
    .\sentry.ps1 start
    Start the Sentry environment

.EXAMPLE
    .\sentry.ps1 logs
    Show logs from all Sentry services
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "status", "logs", "clean", "reset")]
    [string]$Action
)

# Configuration
$ComposeFile = "docker-compose.yml"
$ProjectName = "observability-sentry"

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

function Start-SentryEnvironment {
    Write-Info "Starting Sentry environment..."
    
    # Start services
    docker-compose -p $ProjectName up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Sentry environment started successfully!"
        Write-Info "Services available:"
        Write-Host "  • Sentry Web UI: http://localhost:9000" -ForegroundColor White
        Write-Host "  • PostgreSQL: localhost:5432 (sentry/sentry)" -ForegroundColor White
        Write-Host "  • Redis: localhost:6379" -ForegroundColor White
        Write-Info ""
        Write-Info "First time setup:"
        Write-Host "  1. Wait for all services to be healthy (check with: .\sentry.ps1 status)" -ForegroundColor White
        Write-Host "  2. Create a superuser: docker exec -it sentry-web sentry createuser" -ForegroundColor White
        Write-Host "  3. Access http://localhost:9000 and create a project" -ForegroundColor White
        Write-Host "  4. Copy the DSN for your Delphi application" -ForegroundColor White
    } else {
        Write-Error "Failed to start Sentry environment"
    }
}

function Stop-SentryEnvironment {
    Write-Info "Stopping Sentry environment..."
    docker-compose -p $ProjectName down
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Sentry environment stopped"
    } else {
        Write-Error "Failed to stop Sentry environment"
    }
}

function Show-SentryStatus {
    Write-Info "Sentry Environment Status:"
    docker-compose -p $ProjectName ps
    
    Write-Info "`nContainer Health Status:"
    $containers = @("sentry-postgres", "sentry-redis", "sentry-web", "sentry-worker", "sentry-cron")
    
    foreach ($container in $containers) {
        $status = docker inspect --format='{{.State.Health.Status}}' $container 2>$null
        if ($status) {
            $statusIcon = switch ($status) {
                "healthy" { "?" }
                "unhealthy" { "?" }
                "starting" { "??" }
                default { "?" }
            }
            Write-Host "  $statusIcon $container`: $status" -ForegroundColor $(if ($status -eq "healthy") { "Green" } elseif ($status -eq "unhealthy") { "Red" } else { "Yellow" })
        } else {
            Write-Host "  ? $container`: not found or no health check" -ForegroundColor Gray
        }
    }
}

function Show-SentryLogs {
    Write-Info "Showing logs from all Sentry services (Ctrl+C to exit)..."
    docker-compose -p $ProjectName logs -f
}

function Clean-SentryEnvironment {
    Write-Warning "This will stop and remove all containers and networks (but keep volumes)"
    $confirm = Read-Host "Continue? (y/N)"
    
    if ($confirm -eq "y" -or $confirm -eq "Y") {
        Write-Info "Cleaning Sentry environment..."
        docker-compose -p $ProjectName down --remove-orphans
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Sentry environment cleaned"
        } else {
            Write-Error "Failed to clean Sentry environment"
        }
    } else {
        Write-Info "Operation cancelled"
    }
}

function Reset-SentryEnvironment {
    Write-Warning "This will DESTROY ALL DATA including databases and volumes!"
    Write-Warning "You will need to reconfigure Sentry from scratch."
    $confirm = Read-Host "Are you sure? Type 'RESET' to confirm"
    
    if ($confirm -eq "RESET") {
        Write-Info "Resetting Sentry environment..."
        docker-compose -p $ProjectName down --volumes --remove-orphans
        
        # Remove any dangling images
        Write-Info "Cleaning up Docker images..."
        docker image prune -f
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Sentry environment completely reset"
            Write-Info "Run '.\sentry.ps1 start' to create a fresh environment"
        } else {
            Write-Error "Failed to reset Sentry environment"
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
    "start" { Start-SentryEnvironment }
    "stop" { Stop-SentryEnvironment }
    "status" { Show-SentryStatus }
    "logs" { Show-SentryLogs }
    "clean" { Clean-SentryEnvironment }
    "reset" { Reset-SentryEnvironment }
}

Write-Info "Done!"