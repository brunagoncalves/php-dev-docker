# A tag 8.5 acompanha os patches de segurança mais recentes da série estável
# sempre que a imagem for reconstruída.
FROM php:8.5-fpm-trixie

RUN apt-get update && apt-get install -y --no-install-recommends \
  git \
  unzip \
  curl \
  libpq-dev \
  libicu-dev \
  libzip-dev \
  libxml2-dev \
  libpng-dev \
  && docker-php-ext-install -j$(nproc) \
  gd \
  pdo_pgsql \
  pgsql \
  intl \
  zip \
  bcmath \
  pcntl \
  soap \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
