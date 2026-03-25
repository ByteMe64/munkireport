# We cast our spell using the latest Ubuntu LTS (24.04 'Noble Numbat')
FROM ubuntu:24.04

# Keep apt-get quiet during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install core dependencies: Nginx, PHP, necessary extensions, and Composer
RUN apt-get update && apt-get install -y \
    nginx \
    php-fpm \
    php-mysql \
    php-xml \
    php-mbstring \
    php-curl \
    php-zip \
    curl \
    openssl \
    composer \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Generate a self-signed cert for HTTPS 
RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/munkireport.key \
    -out /etc/nginx/ssl/munkireport.crt \
    -subj "/C=US/ST=State/L=City/O=Security/CN=munkireport.local"

# Fetch MunkiReport v5.8.0 from GitHub and install dependencies
WORKDIR /var/www/munkireport
RUN curl -L -o mr.tar.gz https://github.com/munkireport/munkireport-php/archive/refs/tags/v5.8.0.tar.gz && \
    tar -xzf mr.tar.gz --strip-components=1 && \
    rm mr.tar.gz && \
    composer install --no-dev --optimize-autoloader

# Inject Nginx configuration and entrypoint
COPY nginx.conf /etc/nginx/sites-available/default
COPY entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose HTTPS only
EXPOSE 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
