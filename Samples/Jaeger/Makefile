# Jaeger Environment Makefile
# Cross-platform commands for managing Jaeger test environment

.PHONY: help start stop restart status logs clean demo production test

# Default target
help: ## Show this help message
	@echo "Jaeger Environment Commands:"
	@echo "============================"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

start: ## Start development environment (All-in-One)
	@echo "?? Starting Jaeger development environment..."
	docker-compose up -d jaeger-all-in-one
	@sleep 5
	@$(MAKE) status

stop: ## Stop all services
	@echo "?? Stopping Jaeger environment..."
	docker-compose down

restart: ## Restart all services
	@echo "?? Restarting Jaeger environment..."
	docker-compose restart
	@sleep 5
	@$(MAKE) status

status: ## Show status and health checks
	@echo "?? Container Status:"
	docker-compose ps
	@echo ""
	@echo "?? Health Checks:"
	@curl -s http://localhost:16686 > /dev/null && echo "  ? Jaeger UI (16686) - OK" || echo "  ? Jaeger UI (16686) - Not responding"
	@curl -s http://localhost:14268 > /dev/null && echo "  ? Jaeger Collector (14268) - OK" || echo "  ? Jaeger Collector (14268) - Not responding"
	@curl -s http://localhost:9200/_cluster/health > /dev/null && echo "  ? Elasticsearch (9200) - OK" || echo "  ??  Elasticsearch (9200) - Not running"
	@curl -s http://localhost:8080 > /dev/null && echo "  ? HotROD Demo (8080) - OK" || echo "  ??  HotROD Demo (8080) - Not running"
	@echo ""
	@echo "?? Available Endpoints:"
	@echo "  ?? Jaeger UI:          http://localhost:16686"
	@echo "  ?? Collector HTTP:     http://localhost:14268/api/traces"
	@echo "  ?? Collector gRPC:     localhost:14250"
	@echo "  ?? OTLP HTTP:          http://localhost:4318/v1/traces"
	@echo "  ?? OTLP gRPC:          localhost:4317"

logs: ## Show logs from all services
	@echo "?? Showing logs (Ctrl+C to exit)..."
	docker-compose logs -f --tail=50

logs-jaeger: ## Show logs from Jaeger All-in-One
	@echo "?? Showing Jaeger logs (Ctrl+C to exit)..."
	docker-compose logs -f --tail=50 jaeger-all-in-one

clean: ## Remove all containers, networks, and volumes
	@echo "?? This will remove all containers, networks, and volumes!"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ] || (echo "? Cleaning cancelled" && exit 1)
	docker-compose down -v --remove-orphans
	docker system prune -f
	@echo "? Environment cleaned"

demo: ## Start demo environment with HotROD application
	@echo "?? Starting demo environment with HotROD application..."
	docker-compose --profile demo up -d
	@sleep 10
	@$(MAKE) status
	@echo ""
	@echo "?? Demo Instructions:"
	@echo "  1. Open HotROD app: http://localhost:8080"
	@echo "  2. Click on various customers to generate traces"
	@echo "  3. View traces in Jaeger UI: http://localhost:16686"
	@echo "  4. Search for service: 'frontend', 'customer', 'driver', or 'route'"

production: ## Start production environment with Elasticsearch
	@echo "?? Starting production environment with Elasticsearch..."
	docker-compose --profile production up -d
	@echo "? Waiting for Elasticsearch to start..."
	@sleep 30
	@$(MAKE) status
	@echo ""
	@echo "?? Production Notes:"
	@echo "  • Traces are stored persistently in Elasticsearch"
	@echo "  • Separate collector, query, and agent services"
	@echo "  • Better for performance testing and production simulation"

test: ## Test connection to Jaeger
	@echo "?? Testing Jaeger connectivity..."
	@echo "Testing Jaeger UI..."
	@curl -f http://localhost:16686 > /dev/null 2>&1 && echo "? Jaeger UI is accessible" || echo "? Jaeger UI is not accessible"
	@echo "Testing Jaeger Collector..."
	@curl -f http://localhost:14268 > /dev/null 2>&1 && echo "? Jaeger Collector is accessible" || echo "? Jaeger Collector is not accessible"

open: ## Open Jaeger UI in browser
	@echo "?? Opening Jaeger UI..."
	@if command -v xdg-open > /dev/null; then xdg-open http://localhost:16686; \
	elif command -v open > /dev/null; then open http://localhost:16686; \
	elif command -v start > /dev/null; then start http://localhost:16686; \
	else echo "Please open http://localhost:16686 manually"; fi

# Development shortcuts
dev: start ## Alias for start
prod: production ## Alias for production

# Windows-specific targets (if running in WSL or similar)
start-windows: ## Start with Windows-specific optimizations
	@echo "?? Starting Jaeger for Windows environment..."
	docker-compose up -d jaeger-all-in-one
	@echo "?? Tip: If you have issues, try running Docker Desktop as administrator"
	@$(MAKE) status