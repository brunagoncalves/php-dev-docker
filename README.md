# Ambiente PHP / Laravel com Docker

Ambiente compartilhado de desenvolvimento para projetos PHP modernos e Laravel, executado totalmente em Docker.

## Navegação rápida

- [Objetivo](#objetivo)
- [Arquitetura](#arquitetura)
- [Configuração](#variáveis-do-ambiente-docker)
- [Comandos](#comandos-docker)
- [Laravel](#criando-um-projeto-laravel)
- [Nginx](#nginx-dinâmico-por-projeto)
- [Boas práticas](#boas-práticas)

## Objetivo

Este ambiente foi criado para manter PHP, Composer, PostgreSQL, Nginx, Node.js e NPM isolados do macOS.

A ideia é ter uma única infraestrutura Docker compartilhada entre vários projetos PHP/Laravel.

```text
Mac
│
└── ~/Developments/pphp/
    │
    ├── docker-compose.yml
    ├── Makefile
    ├── .env
    ├── docker/
    │   ├── php/
    │   │   └── Dockerfile
    │   └── nginx/
    │
    ├── projeto-a/
    ├── projeto-b/
    └── projeto-c/
```

Os projetos ficam fisicamente no Mac e são montados dentro dos containers através de bind mount.

## Arquitetura

```text
                    navegador
                        │
                        ▼
                  Nginx :80
                        │
                        ▼
                  PHP-FPM :9000
                        │
                 Laravel / PHP
                        │
                        ▼
                 PostgreSQL :5432

Frontend Laravel:

resources/js
    │
    ▼
Node.js + NPM
    │
    ▼
Vite :5173
    │
    ▼
React / Vue
```

Serviços principais:

- **Nginx** (`nginx_dev`) — Servidor HTTP
- **PHP** (`php_dev`) — PHP-FPM, Laravel e Composer
- **Node** (`node_dev`) — NPM, Vite, React e Vue
- **PostgreSQL** (`postgres_dev`) — Bancos dos projetos

## Estrutura e versionamento

```text
~/Developments/pphp/
├── docker-compose.yml
├── Makefile
├── .env
│
├── docker/
│   ├── php/
│   │   └── Dockerfile
│   │
│   └── nginx/
│       └── default.conf
│
├── projeto-a/
├── projeto-b/
└── projeto-c/
```

Este repositório versiona somente a infraestrutura compartilhada: `docker-compose.yml`,
`Makefile`, `docker/`, documentação e o modelo de configuração `.env.example`.
As pastas de projetos na raiz são deliberadamente ignoradas pelo Git, portanto código,
dependências e arquivos `.env` de cada aplicação continuam apenas na máquina local.

Ao adicionar um arquivo novo que faça parte da infraestrutura, inclua-o explicitamente
no `.gitignore`. Assim, uma pasta de projeto criada futuramente não corre o risco de
ser publicada por engano.

Dentro dos containers essa pasta aparece como:

```text
/var/www/html/
├── projeto-a/
├── projeto-b/
└── projeto-c/
```

## Docker Compose

O ambiente utiliza:

- PHP 8.5 FPM
- Composer 2
- PostgreSQL 16
- Node.js 24
- Nginx Alpine

O código dos projetos é montado diretamente em:

```text
/var/www/html
```

Por isso não é necessário rebuildar a imagem sempre que um arquivo PHP, Blade, React ou Vue for alterado.

O `build` só é necessário quando houver alteração no `Dockerfile`, extensões PHP ou configuração da imagem.

A imagem usa a série estável `8.5` do PHP. O `make build` força a busca da
imagem-base atualizada antes de reconstruir, trazendo o patch de segurança mais
recente da série. Depois, execute `make up` para recriar os serviços que usam
a nova imagem.

## Variáveis do ambiente Docker

Arquivo:

```text
~/Developments/pphp/.env
```

Exemplo:

```env
POSTGRES_USER=postgres
POSTGRES_PASSWORD=uma-senha-local-segura
POSTGRES_DB=postgres
POSTGRES_PORT=5432
```

Esse arquivo pertence à infraestrutura Docker.

Ele é diferente do `.env` de cada projeto Laravel.

Para criar sua configuração local a partir do modelo:

```bash
cp .env.example .env
```

## Subindo o ambiente

Na pasta:

```bash
cd ~/Developments/pphp
```

Execute:

```bash
make up
```

Verifique:

```bash
make ps
```

Para exibir as versões:

```bash
make versions
```

Validar a configuração do Nginx:

```bash
make nginx-test
```

## Parando o ambiente

```bash
make down
```

Isso remove os containers, mas mantém o volume do PostgreSQL.

## Atenção

Evitar:

```bash
docker compose down -v
```

O parâmetro `-v` remove também o volume do PostgreSQL.

## Makefile

O `Makefile` centraliza os comandos mais usados.

Para visualizar todos:

```bash
make
```

ou:

```bash
make help
```

## Comandos Docker

### Subir

```bash
make up
```

### Parar

```bash
make down
```

### Apenas parar containers

```bash
make stop
```

### Reiniciar

```bash
make restart
```

### Build

```bash
make build
```

### Rebuild sem cache

```bash
make rebuild
```

### Status

```bash
make ps
```

### Logs gerais

```bash
make logs
```

### Logs de um serviço

```bash
make logs SERVICE=php
```

Exemplos:

```bash
make logs SERVICE=nginx
make logs SERVICE=node
make logs SERVICE=db
```

## Shell dos containers

### PHP

```bash
make php
```

### Node

```bash
make node
```

### PostgreSQL

```bash
make db
```

## Criando um projeto Laravel

Primeiro suba o ambiente:

```bash
make up
```

Depois:

```bash
make laravel-new PROJECT=meu-projeto
```

O projeto será criado em:

```text
~/Developments/pphp/meu-projeto
```

## Criando um projeto Laravel com Livewire

Com o ambiente iniciado (`make up`), execute na pasta deste ambiente:

```bash
make laravel-livewire-new PROJECT=meu-projeto
```

O comando usa o starter kit oficial do Laravel com Livewire, instala as
dependências do frontend e compila os assets, seguindo o mesmo fluxo dos
comandos para React e Vue. O instalador pode solicitar escolhas durante a criação.
O nome é obrigatório e a pasta de destino não pode existir.

Livewire permite criar interfaces interativas com PHP e templates Blade,
como formulários com validação, buscas, filtros e tabelas com paginação,
atualizando partes da página sem recarregá-la inteira e reduzindo a necessidade
de escrever JavaScript.

Depois da criação, siga as seções de PostgreSQL e Nginx deste guia para configurar
o banco e o endereço local do projeto. Para desenvolver o frontend:

```bash
make dev PROJECT=meu-projeto
```

Referências: [Livewire](https://livewire.laravel.com/) e
[starter kits do Laravel](https://laravel.com/docs/starter-kits).

## Composer

Instalar dependências:

```bash
make composer PROJECT=meu-projeto CMD=install
```

Atualizar:

```bash
make composer PROJECT=meu-projeto CMD=update
```

Adicionar pacote:

```bash
make composer PROJECT=meu-projeto CMD="require vendor/pacote"
```

Exemplo:

```bash
make composer PROJECT=meu-projeto CMD="require laravel/sanctum"
```

## Artisan

Sintaxe genérica:

```bash
make artisan PROJECT=meu-projeto CMD="comando"
```

Exemplos:

```bash
make artisan PROJECT=meu-projeto CMD="route:list"
```

```bash
make artisan PROJECT=meu-projeto CMD="make:controller ClienteController"
```

```bash
make artisan PROJECT=meu-projeto CMD="make:model Cliente -m"
```

```bash
make artisan PROJECT=meu-projeto CMD="config:show database"
```

## Atalhos Laravel

### Migrations

```bash
make migrate PROJECT=meu-projeto
```

### Migrate fresh

```bash
make fresh PROJECT=meu-projeto
```

> Este comando apaga todas as tabelas do banco configurado pelo projeto e recria as migrations.

### Rollback

```bash
make rollback PROJECT=meu-projeto
```

### Seed

```bash
make seed PROJECT=meu-projeto
```

### Testes

```bash
make test PROJECT=meu-projeto
```

### Tinker

```bash
make tinker PROJECT=meu-projeto
```

### Limpar caches

```bash
make clear PROJECT=meu-projeto
```

Executa:

```text
php artisan optimize:clear
```

### Otimizar Laravel

```bash
make optimize PROJECT=meu-projeto
```

## PostgreSQL

O ambiente possui uma única instância PostgreSQL, mas ela pode armazenar vários bancos.

Exemplo:

```text
postgres_dev
│
├── postgres
├── meu_projeto_dev
├── financeiro_dev
└── projeto_a_dev
```

Cada projeto utiliza seu próprio database.

### Listar bancos

```bash
make db-list
```

### Criar banco

```bash
make db-create DB=meu_projeto_dev
```

Outro exemplo:

```bash
make db-create DB=financeiro_dev
```

### Remover banco

```bash
make db-drop DB=meu_projeto_dev
```

Esse comando deve ser usado com cuidado.

### Configuração Laravel + PostgreSQL

No `.env` do Laravel:

```env
DB_CONNECTION=pgsql
DB_HOST=db
DB_PORT=5432
DB_DATABASE=meu_projeto_dev
DB_USERNAME=postgres
DB_PASSWORD=root_password
```

#### Importante

Dentro do Docker:

```env
DB_HOST=db
```

Não usar:

```env
DB_HOST=localhost
```

Dentro do container PHP, `localhost` seria o próprio container PHP.

O hostname `db` é resolvido pela rede Docker para o container PostgreSQL.

## Node.js, NPM e Vite

Projetos Laravel que utilizam:

- React
- Vue
- Inertia
- Tailwind
- Vite

utilizam o container `node_dev`.

### Instalar dependências NPM

```bash
make npm-install PROJECT=meu-projeto
```

Também é possível usar:

```bash
make npm PROJECT=meu-projeto CMD=install
```

### Adicionar pacote NPM

```bash
make npm PROJECT=meu-projeto CMD="install axios"
```

Exemplo:

```bash
make npm PROJECT=meu-projeto CMD="install lucide-react"
```

### Rodar Vite

```bash
make dev PROJECT=meu-projeto
```

O comando executado dentro do container é equivalente a:

```bash
npm run dev -- --host 0.0.0.0
```

O terminal permanecerá aberto enquanto o Vite estiver rodando.

Isso é esperado.

Durante o desenvolvimento:

```text
resources/js
    ↓
Vite
    ↓
React / Vue
    ↓
Hot Reload
```

### Build frontend

```bash
make frontend-build PROJECT=meu-projeto
```

Equivalente a:

```bash
npm run build
```

### Porta do Vite

O ambiente atual expõe:

```text
5173
```

Portanto, o fluxo padrão considera um servidor Vite ativo por vez.

Caso seja necessário executar simultaneamente dois projetos com Vite, será necessário configurar portas diferentes e expô-las no `docker-compose.yml`.

Para o uso normal — desenvolver um projeto por vez — a configuração atual é suficiente.

## Nginx dinâmico por projeto

O ambiente utiliza um único Nginx compartilhado e uma configuração dinâmica baseada no nome da pasta do projeto.

Exemplos:

```text
~/Developments/php/meu-projeto
        ↓
http://meu-projeto.localhost
```

```text
~/Developments/php/financeiro
        ↓
http://financeiro.localhost
```

Assim, não é necessário criar um arquivo `.conf` separado para cada aplicação.

### Arquivo de configuração

Crie:

```text
docker/nginx/default.conf
```

Conteúdo:

```nginx
server {
    listen 80 default_server;

    server_name ~^(?<project>[a-zA-Z0-9_-]+)\.localhost$;

    root /var/www/html/$project/public;
    index index.php index.html;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        try_files $uri =404;

        include fastcgi_params;
        fastcgi_pass php:9000;
        fastcgi_index index.php;

        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT $document_root;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

### Como funciona

Ao acessar:

```text
http://meu-projeto.localhost
```

o Nginx captura:

```text
project = meu-projeto
```

e utiliza:

```text
/var/www/html/meu-projeto/public
```

como document root.

Portanto, uma pasta:

```text
~/Developments/php/estoque/
```

com:

```text
~/Developments/php/estoque/public/
```

fica disponível em:

```text
http://estoque.localhost
```

### Uso de `.localhost`

O padrão `.localhost` é apropriado para desenvolvimento local e evita manter manualmente entradas como:

```text
127.0.0.1 meu-projeto.test
127.0.0.1 financeiro.test
```

no arquivo `/etc/hosts`.

### Validar Nginx

Depois de alterar `docker/nginx/default.conf`:

```bash
make nginx-test
```

O resultado esperado é semelhante a:

```text
syntax is ok
test is successful
```

### Recarregar Nginx

```bash
make nginx-reload
```

Esse comando valida a configuração e, se estiver correta, recarrega o Nginx.

Targets usados no `Makefile`:

```makefile
nginx-test:
 $(DC) exec nginx nginx -t

nginx-reload:
 $(DC) exec nginx nginx -t
 $(DC) exec nginx nginx -s reload
```

Adicionar também ao `.PHONY`:

```makefile
.PHONY: nginx-test nginx-reload
```

E ao `help`:

```makefile
 @echo "Nginx:"
 @echo "  make nginx-test                    Valida a configuração do Nginx"
 @echo "  make nginx-reload                  Valida e recarrega o Nginx"
 @echo ""
```

### Segurança

O Nginx aponta somente para:

```text
/projeto/public
```

Em Laravel isso evita expor diretamente arquivos e diretórios como:

```text
.env
artisan
composer.json
app/
config/
vendor/
```

## Fluxo para projeto Laravel existente

Supondo:

```text
~/Developments/php/meu-projeto
```

Subir ambiente:

```bash
make up
```

Criar banco:

```bash
make db-create DB=meu_projeto_dev
```

Instalar Composer:

```bash
make composer PROJECT=meu-projeto CMD=install
```

Configurar o `.env` do Laravel.

Gerar a chave, caso necessário:

```bash
make artisan PROJECT=meu-projeto CMD="key:generate"
```

Executar migrations:

```bash
make migrate PROJECT=meu-projeto
```

Instalar frontend:

```bash
make npm-install PROJECT=meu-projeto
```

Rodar Vite:

```bash
make dev PROJECT=meu-projeto
```

Abrir:

```text
http://meu-projeto.localhost
```

## Fluxo diário

No início do desenvolvimento:

```bash
cd ~/Developments/php

make up
```

Se o projeto utiliza Vite:

```bash
make dev PROJECT=meu-projeto
```

Durante o trabalho:

```bash
make artisan PROJECT=meu-projeto CMD="route:list"
```

```bash
make migrate PROJECT=meu-projeto
```

```bash
make test PROJECT=meu-projeto
```

Ao terminar:

```bash
make down
```

## Quando executar build

Não é necessário executar:

```bash
make build
```

a cada alteração no projeto.

O código está montado via volume.

Execute o build quando houver mudanças em:

```text
docker/php/Dockerfile
```

ou em alguma configuração estrutural da imagem PHP.

Então:

```bash
make build
make up
```

Se houver problemas de cache:

```bash
make rebuild
```

## Persistência do PostgreSQL

O PostgreSQL utiliza volume Docker:

```yaml
volumes:
    postgres_data:
```

Isso significa que:

```bash
make down
```

não remove os bancos.

Os bancos permanecem disponíveis quando o ambiente for iniciado novamente:

```bash
make up
```

## Conceito do ambiente

Este ambiente substitui a necessidade de instalar diretamente no macOS:

```text
PHP
Composer
PostgreSQL
Nginx
Node.js
NPM
```

O Mac precisa essencialmente de:

```text
Docker
Make
Editor / IDE
Git
```

Os projetos permanecem no filesystem normal do Mac.

## Ambiente compartilhado vs Laravel Sail

Laravel Sail cria uma infraestrutura Docker vinculada ao projeto Laravel.

Neste ambiente, a infraestrutura é compartilhada.

```text
Sail

Projeto A
├── PHP
├── Banco
└── serviços


Ambiente compartilhado

Nginx
PHP
Node
PostgreSQL
   │
   ├── Projeto A
   ├── Projeto B
   └── Projeto C
```

A principal vantagem para este cenário é evitar vários containers equivalentes para cada projeto.

Caso algum projeto exija uma versão específica de PHP, PostgreSQL ou algum serviço incompatível com os demais, ele pode possuir seu próprio `docker-compose.yml`.

## Resumo dos principais comandos

```bash
# ambiente
make up
make down
make ps
make logs

# nginx
make nginx-test
make nginx-reload

# shells
make php
make node
make db

# banco
make db-list
make db-create DB=meu_projeto_dev

# composer
make composer PROJECT=meu-projeto CMD=install

# Laravel
make migrate PROJECT=meu-projeto
make test PROJECT=meu-projeto
make tinker PROJECT=meu-projeto

# comando Artisan livre
make artisan PROJECT=meu-projeto CMD="route:list"

# NPM
make npm-install PROJECT=meu-projeto

# frontend / Vite
make dev PROJECT=meu-projeto

# build frontend
make frontend-build PROJECT=meu-projeto
```

## Boas práticas

- Um database PostgreSQL por projeto.
- Não usar `localhost` como `DB_HOST` dentro do Laravel.
- Manter o `root` do Nginx apontando para `/public`.
- Validar alterações do Nginx com `make nginx-test` antes de recarregar.
- Não executar `docker compose down -v` sem intenção de remover os bancos.
- Usar `make build` somente quando a imagem Docker mudar.
- Usar `make down` ao terminar o desenvolvimento se não quiser manter os containers ativos.
- Não versionar arquivos `.env` com senhas.
- Para projetos com requisitos incompatíveis, utilizar um ambiente Docker dedicado.

## Referência rápida

```text
Nginx      → nginx_dev
PHP        → php_dev
Node       → node_dev
PostgreSQL → postgres_dev

Código     → /var/www/html
Postgres   → db:5432
PHP-FPM    → php:9000
Vite       → 5173
```

## Status

Ambiente preparado para:

- PHP moderno
- Laravel
- PostgreSQL
- Composer
- React
- Vue
- Inertia
- Vite
- NPM
- aplicações PHP tradicionais

A infraestrutura permanece compartilhada, enquanto código e bancos continuam separados por projeto.
