# Jaeger Environment Management Script
# Facilita o gerenciamento do ambiente Docker para testes

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "restart", "logs", "status", "clean", "demo", "production")]
    [string]$Action,
    
    [string]$Service = "all"
)

$ErrorActionPreference = "Stop"

Write-Host "?? Jaeger Environment Manager" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

function Start-Environment {
    param([string]$ProfileName = "")
    
    Write-Host "?? Starting Jaeger environment..." -ForegroundColor Green
    
    if ($ProfileName -eq "") {
        Write-Host "?? Starting development environment (All-in-One)" -ForegroundColor Yellow
        docker-compose up -d jaeger-all-in-one
    } else {
        Write-Host "?? Starting $ProfileName environment" -ForegroundColor Yellow
        docker-compose --profile $ProfileName up -d
    }
    
    Start-Sleep 5
    Show-Status
    Show-Endpoints
}

function Stop-Environment {
    Write-Host "?? Stopping Jaeger environment..." -ForegroundColor Red
    docker-compose down
    Write-Host "? Environment stopped" -ForegroundColor Green
}

function Restart-Environment {
    Write-Host "?? Restarting Jaeger environment..." -ForegroundColor Yellow
    docker-compose restart
    Start-Sleep 5
    Show-Status
}

function Show-Logs {
    param([string]$ServiceName = "")
    
    Write-Host "?? Showing logs..." -ForegroundColor Blue
    
    if ($ServiceName -eq "" -or $ServiceName -eq "all") {
        docker-compose logs --tail=50 -f
    } else {
        docker-compose logs --tail=50 -f $ServiceName
    }
}

function Show-Status {
    Write-Host "?? Container Status:" -ForegroundColor Blue
    docker-compose ps
    
    Write-Host "`n?? Health Checks:" -ForegroundColor Blue
    
    # Test Jaeger UI
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:16686" -TimeoutSec 5 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "  ? Jaeger UI (16686) - OK" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ? Jaeger UI (16686) - Not responding" -ForegroundColor Red
    }
    
    # Test Jaeger Collector
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:14268" -TimeoutSec 5 -UseBasicParsing
        if ($response.StatusCode -eq 404) { # 404 is expected for root path
            Write-Host "  ? Jaeger Collector (14268) - OK" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ? Jaeger Collector (14268) - Not responding" -ForegroundColor Red
    }
    
    # Test Elasticsearch (if running)
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:9200/_cluster/health" -TimeoutSec 5 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "  ? Elasticsearch (9200) - OK" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ??  Elasticsearch (9200) - Not running (normal for dev mode)" -ForegroundColor Yellow
    }
    
    # Test HotROD Demo (if running)
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 5 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "  ? HotROD Demo (8080) - OK" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ??  HotROD Demo (8080) - Not running" -ForegroundColor Yellow
    }
}

function Show-Endpoints {
    Write-Host "`n?? Available Endpoints:" -ForegroundColor Magenta
    Write-Host "  ?? Jaeger UI:          http://localhost:16686" -ForegroundColor White
    Write-Host "  ?? Collector HTTP:     http://localhost:14268/api/traces" -ForegroundColor White
    Write-Host "  ?? Collector gRPC:     localhost:14250" -ForegroundColor White
    Write-Host "  ?? OTLP HTTP:          http://localhost:4318/v1/traces" -ForegroundColor White
    Write-Host "  ?? OTLP gRPC:          localhost:4317" -ForegroundColor White
    Write-Host "  ???  Elasticsearch:      http://localhost:9200 (production mode)" -ForegroundColor Gray
    Write-Host "  ?? HotROD Demo:        http://localhost:8080 (demo mode)" -ForegroundColor Gray
}

function Remove-Environment {
    Write-Host "?? Cleaning Jaeger environment..." -ForegroundColor Red
    Write-Host "This will remove all containers, networks, and volumes!" -ForegroundColor Yellow
    
    $confirm = Read-Host "Are you sure? (y/N)"
    if ($confirm -eq "y" -or $confirm -eq "Y") {
        docker-compose down -v --remove-orphans
        docker system prune -f
        Write-Host "? Environment cleaned" -ForegroundColor Green
    } else {
        Write-Host "? Cleaning cancelled" -ForegroundColor Yellow
    }
}

function Start-Demo {
    Write-Host "?? Starting demo environment with HotROD application..." -ForegroundColor Magenta
    docker-compose --profile demo up -d
    Start-Sleep 10
    Show-Status
    Show-Endpoints
    Write-Host "`n?? Demo Instructions:" -ForegroundColor Cyan
    Write-Host "  1. Open HotROD app: http://localhost:8080" -ForegroundColor White
    Write-Host "  2. Click on various customers to generate traces" -ForegroundColor White
    Write-Host "  3. View traces in Jaeger UI: http://localhost:16686" -ForegroundColor White
    Write-Host "  4. Search for service: 'frontend', 'customer', 'driver', or 'route'" -ForegroundColor White
}

function Start-Production {
    Write-Host "?? Starting production environment with Elasticsearch..." -ForegroundColor Magenta
    docker-compose --profile production up -d
    Write-Host "? Waiting for Elasticsearch to start..." -ForegroundColor Yellow
    Start-Sleep 30
    Show-Status
    Show-Endpoints
    Write-Host "`n?? Production Notes:" -ForegroundColor Cyan
    Write-Host "  • Traces are stored persistently in Elasticsearch" -ForegroundColor White
    Write-Host "  • Separate collector, query, and agent services" -ForegroundColor White
    Write-Host "  • Better for performance testing and production simulation" -ForegroundColor White
}

# Main script logic
switch ($Action) {
    "start" {
        Start-Environment
    }
    "stop" {
        Stop-Environment
    }
    "restart" {
        Restart-Environment
    }
    "logs" {
        Show-Logs -ServiceName $Service
    }
    "status" {
        Show-Status
        Show-Endpoints
    }
    "clean" {
        Remove-Environment
    }
    "demo" {
        Start-Demo
    }
    "production" {
        Start-Production
    }
}

Write-Host "`n?? Quick Commands:" -ForegroundColor Cyan
Write-Host "  .\jaeger.ps1 start      - Start development environment" -ForegroundColor Gray
Write-Host "  .\jaeger.ps1 demo       - Start with HotROD demo app" -ForegroundColor Gray
Write-Host "  .\jaeger.ps1 production - Start production environment" -ForegroundColor Gray
Write-Host "  .\jaeger.ps1 status     - Show status and endpoints" -ForegroundColor Gray
Write-Host "  .\jaeger.ps1 logs       - Show logs (Ctrl+C to exit)" -ForegroundColor Gray
Write-Host "  .\jaeger.ps1 stop       - Stop all services" -ForegroundColor Gray
Write-Host "  .\jaeger.ps1 clean      - Remove everything" -ForegroundColor Gray