# Casting our spell with the modern, secure Ubuntu 24.04 LTS (PHP 8.3)
FROM ubuntu:24.04

# Keep apt-get quiet
ENV DEBIAN_FRONTEND=noninteractive

# Allow Composer to run as root inside the container safely
ENV COMPOSER_ALLOW_SUPERUSER=1

# Install core dependencies (including php-sqlite3 to satisfy Composer)
RUN apt-get update && apt-get install -y \
    nginx \
    php-fpm \
    php-mysql \
    php-sqlite3 \
    php-xml \
    php-mbstring \
    php-curl \
    php-zip \
    curl \
    openssl \
    composer \
    unzip \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Generate a self-signed cert for HTTPS 
RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/munkireport.key \
    -out /etc/nginx/ssl/munkireport.crt \
    -subj "/C=US/ST=State/L=City/O=Security/CN=munkireport.local"

# Fetch MunkiReport v5.8.0 and force Composer to bypass the outdated PHP version lock
WORKDIR /var/www/munkireport
RUN curl -L -o mr.tar.gz https://github.com/munkireport/munkireport-php/archive/refs/tags/v5.8.0.tar.gz && \
    tar -xzf mr.tar.gz --strip-components=1 && \
    rm mr.tar.gz && \
    composer install --no-dev --optimize-autoloader --ignore-platform-reqs

# Automatically patch the missing runningUnitTests method
RUN php -r '$f="/var/www/munkireport/vendor/illuminate/container/Container.php"; $c=file_get_contents($f); $c=substr_replace($c, "    public function runningUnitTests() { return false; }\n}", strrpos($c, "}"), 1); file_put_contents($f, $c);'

# Inject Nginx configuration and entrypoint
COPY nginx.conf /etc/nginx/sites-available/default
COPY entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose HTTPS only
EXPOSE 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
