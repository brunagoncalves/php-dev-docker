SHELL := /bin/bash

DC := docker compose
ROOT := /var/www/html

# PHP CLI necessário para o Wayfinder executar Artisan no container Node.
NODE_PHP_PACKAGES := php85 php85-bcmath php85-ctype php85-curl php85-dom \
	php85-fileinfo php85-intl php85-mbstring php85-openssl php85-pcntl \
	php85-pdo php85-pdo_pgsql php85-pdo_sqlite php85-session \
	php85-tokenizer php85-xml php85-xmlreader php85-xmlwriter php85-zip

PROJECT ?= $(project)
CMD ?= $(cmd)
DB ?= $(db)
SERVICE ?= $(service)

.DEFAULT_GOAL := help

.PHONY: \
	help build rebuild up down stop restart ps logs \
	php node db versions check-project check-db \
	composer artisan migrate fresh rollback seed test tinker \
	node-php npm npm-install dev frontend-build \
	db-list db-create db-drop \
	laravel-new laravel-react-new laravel-vue-new laravel-livewire-new clear optimize \
	nginx-test nginx-reload

help:
	@echo ""
	@echo "PHP Development Environment"
	@echo "==========================="
	@echo ""
	@echo "Ambiente:"
	@echo "  make build                         Build das imagens"
	@echo "  make rebuild                       Rebuild sem cache"
	@echo "  make up                            Sobe o ambiente"
	@echo "  make down                          Para e remove os containers"
	@echo "  make stop                          Apenas para os containers"
	@echo "  make restart                       Reinicia os containers"
	@echo "  make ps                            Status dos containers"
	@echo "  make logs                          Logs de todos os serviços"
	@echo "  make logs SERVICE=php              Logs de um serviço"
	@echo "  make versions                      Exibe versões instaladas"
	@echo ""
	@echo "Nginx:"
	@echo "  make nginx-test                    Valida a configuração do Nginx"
	@echo "  make nginx-reload                  Valida e recarrega o Nginx"
	@echo ""
	@echo "Shells:"
	@echo "  make php                           Abre shell no PHP"
	@echo "  make node                          Abre shell no Node"
	@echo "  make db                            Abre psql"
	@echo ""
	@echo "Laravel / Composer:"
	@echo "  make composer PROJECT=app CMD=install"
	@echo "  make artisan PROJECT=app CMD=\"route:list\""
	@echo "  make migrate PROJECT=app"
	@echo "  make fresh PROJECT=app"
	@echo "  make rollback PROJECT=app"
	@echo "  make seed PROJECT=app"
	@echo "  make test PROJECT=app"
	@echo "  make tinker PROJECT=app"
	@echo "  make clear PROJECT=app"
	@echo "  make optimize PROJECT=app"
	@echo ""
	@echo "Frontend:"
	@echo "  make node-php                      Prepara PHP CLI no container Node (Wayfinder)"
	@echo "  make npm PROJECT=app CMD=install"
	@echo "  make npm-install PROJECT=app"
	@echo "  make dev PROJECT=app"
	@echo "  make frontend-build PROJECT=app"
	@echo ""
	@echo "PostgreSQL:"
	@echo "  make db-list"
	@echo "  make db-create DB=app_dev"
	@echo "  make db-drop DB=app_dev"
	@echo ""
	@echo "Projetos:"
	@echo "  make laravel-new PROJECT=meu-projeto"
	@echo "  make laravel-react-new PROJECT=meu-projeto    Cria Laravel + React/Inertia"
	@echo "  make laravel-vue-new PROJECT=meu-projeto      Cria Laravel + Vue/Inertia"
	@echo "  make laravel-livewire-new PROJECT=meu-projeto Cria Laravel + Livewire"
	@echo ""

build:
	$(DC) build --pull

rebuild:
	$(DC) build --pull --no-cache

up:
	$(DC) up -d

down:
	$(DC) down

stop:
	$(DC) stop

restart:
	$(DC) restart

ps:
	$(DC) ps

logs:
	@if [ -n "$(SERVICE)" ]; then \
		$(DC) logs -f "$(SERVICE)"; \
	else \
		$(DC) logs -f; \
	fi

versions:
	@echo ""
	@echo "PHP:"
	@$(DC) exec php php -v
	@echo ""
	@echo "Composer:"
	@$(DC) exec php composer --version
	@echo ""
	@echo "Node:"
	@$(DC) exec node node --version
	@echo ""
	@echo "NPM:"
	@$(DC) exec node npm --version
	@echo ""
	@echo "PostgreSQL:"
	@$(DC) exec db postgres --version
	@echo ""

php:
	$(DC) exec php bash

node:
	$(DC) exec node sh

db:
	$(DC) exec db sh -lc 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"'

check-project:
	@if [ -z "$(PROJECT)" ]; then \
		echo "Erro: informe PROJECT."; \
		echo "Exemplo: make artisan PROJECT=clientflow CMD=migrate"; \
		exit 1; \
	fi
	@if [ ! -d "$(PROJECT)" ]; then \
		echo "Erro: projeto '$(PROJECT)' não encontrado em $$(pwd)."; \
		exit 1; \
	fi

check-db:
	@if [ -z "$(DB)" ]; then \
		echo "Erro: informe DB."; \
		echo "Exemplo: make db-create DB=clientflow_dev"; \
		exit 1; \
	fi

composer: check-project
	$(DC) exec -w $(ROOT)/$(PROJECT) php composer $(CMD)

artisan: check-project
	$(DC) exec -w $(ROOT)/$(PROJECT) php php artisan $(CMD)

migrate: check-project
	$(DC) exec -w $(ROOT)/$(PROJECT) php php artisan migrate

fresh: check-project
	$(DC) exec -w $(ROOT)/$(PROJECT) php php artisan migrate:fresh

rollback: check-project
	$(DC) exec -w $(ROOT)/$(PROJECT) php php artisan migrate:rollback

seed: check-project
	$(DC) exec -w $(ROOT)/$(PROJECT) php php artisan db:seed

test: check-project
	$(DC) exec -w $(ROOT)/$(PROJECT) php php artisan test

tinker: check-project
	$(DC) exec -w $(ROOT)/$(PROJECT) php php artisan tinker

clear: check-project
	$(DC) exec -w $(ROOT)/$(PROJECT) php php artisan optimize:clear

optimize: check-project
	$(DC) exec -w $(ROOT)/$(PROJECT) php php artisan optimize

node-php:
	$(DC) exec -T -u root node sh -lc ' \
		if ! apk info -e $(NODE_PHP_PACKAGES) >/dev/null 2>&1; then \
			apk add --no-cache $(NODE_PHP_PACKAGES) || exit $$?; \
		fi; \
		ln -sf /usr/bin/php85 /usr/local/bin/php \
	'

npm: check-project node-php
	$(DC) exec -w $(ROOT)/$(PROJECT) node npm $(CMD)

npm-install: check-project node-php
	$(DC) exec -w $(ROOT)/$(PROJECT) node npm install

dev: check-project node-php
	$(DC) exec -w $(ROOT)/$(PROJECT) node npm run dev -- --host 0.0.0.0

frontend-build: check-project node-php
	$(DC) exec -w $(ROOT)/$(PROJECT) node npm run build

db-list:
	$(DC) exec db sh -lc 'psql -U "$$POSTGRES_USER" -d postgres -c "\l"'

db-create: check-db
	$(DC) exec db sh -lc 'createdb -U "$$POSTGRES_USER" "$(DB)"'
	@echo "Banco '$(DB)' criado."

db-drop: check-db
	$(DC) exec db sh -lc 'dropdb -U "$$POSTGRES_USER" --if-exists "$(DB)"'
	@echo "Banco '$(DB)' removido."

laravel-new:
	@if [ -z "$(PROJECT)" ]; then \
		echo "Erro: informe PROJECT."; \
		echo "Exemplo: make laravel-new PROJECT=meu-projeto"; \
		exit 1; \
	fi
	@if [ -e "$(PROJECT)" ]; then \
		echo "Erro: '$(PROJECT)' já existe."; \
		exit 1; \
	fi
	$(DC) exec -w $(ROOT) php composer create-project laravel/laravel $(PROJECT)

laravel-react-new:
	@if [ -z "$(PROJECT)" ]; then \
		echo "Erro: informe PROJECT."; \
		echo "Exemplo: make laravel-react-new PROJECT=meu-projeto"; \
		exit 1; \
	fi
	@if [ -e "$(PROJECT)" ]; then \
		echo "Erro: '$(PROJECT)' já existe."; \
		exit 1; \
	fi
	$(DC) exec -w $(ROOT) php sh -lc ' \
		composer global require laravel/installer && \
		"$$(composer global config bin-dir --absolute)/laravel" new "$$1" --react --no-node --no-boost \
	' -- "$(PROJECT)"
	$(MAKE) npm-install PROJECT="$(PROJECT)"
	$(MAKE) frontend-build PROJECT="$(PROJECT)"

laravel-vue-new:
	@if [ -z "$(PROJECT)" ]; then \
		echo "Erro: informe PROJECT."; \
		echo "Exemplo: make laravel-vue-new PROJECT=meu-projeto"; \
		exit 1; \
	fi
	@if [ -e "$(PROJECT)" ]; then \
		echo "Erro: '$(PROJECT)' já existe."; \
		exit 1; \
	fi
	$(DC) exec -w $(ROOT) php sh -lc ' \
		composer global require laravel/installer && \
		"$$(composer global config bin-dir --absolute)/laravel" new "$$1" --vue --no-node --no-boost \
	' -- "$(PROJECT)"
	$(MAKE) npm-install PROJECT="$(PROJECT)"
	$(MAKE) frontend-build PROJECT="$(PROJECT)"

laravel-livewire-new:
	@if [ -z "$(PROJECT)" ]; then \
		echo "Erro: informe PROJECT."; \
		echo "Exemplo: make laravel-livewire-new PROJECT=meu-projeto"; \
		exit 1; \
	fi
	@if [ -e "$(PROJECT)" ]; then \
		echo "Erro: '$(PROJECT)' já existe."; \
		exit 1; \
	fi
	$(DC) exec -w $(ROOT) php sh -lc ' \
		composer global require laravel/installer && \
		"$$(composer global config bin-dir --absolute)/laravel" new "$$1" --livewire --no-node --no-boost \
	' -- "$(PROJECT)"
	$(MAKE) npm-install PROJECT="$(PROJECT)"
	$(MAKE) frontend-build PROJECT="$(PROJECT)"

nginx-test:
	$(DC) exec nginx nginx -t

nginx-reload:
	$(DC) exec nginx nginx -t
	$(DC) exec nginx nginx -s reload
