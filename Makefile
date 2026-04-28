DOCKER_COMPOSE = docker compose

.PHONY: help up down restart logs status backup

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## Levanta n8n
	$(DOCKER_COMPOSE) up -d

down: ## Apaga n8n
	$(DOCKER_COMPOSE) down

restart: ## Reinicia
	$(DOCKER_COMPOSE) down && $(DOCKER_COMPOSE) up -d

logs: ## Ver logs
	$(DOCKER_COMPOSE) logs -f n8n

status: ## Estado
	$(DOCKER_COMPOSE) ps
	docker stats --no-stream

backup: ## Backup
	@mkdir -p /home/operador/backups
	@tar czf /home/operador/backups/n8n-$$(date +%Y%m%d-%H%M%S).tar.gz -C ./data/n8n .
