# =============================================================================
# MunkiReport - Custom Image
# Base:  Ubuntu 24.04 LTS (Noble Numbat)
# PHP:   8.5
# Web:   Apache 2.4
# App:   MunkiReport (version set via MUNKIREPORT_VERSION build arg)
# =============================================================================

FROM ubuntu:24.04

ARG MUNKIREPORT_VERSION=5.8.0

LABEL maintainer="your-team@example.com"
LABEL description="MunkiReport v${MUNKIREPORT_VERSION} on Ubuntu 24.04 LTS with PHP 8.5"

# Prevent apt from prompting during build
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# ---------------------------------------------------------------------------
# System packages + PHP 8.5 + Apache
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    ca-certificates \
    curl \
    unzip \
    && add-apt-repository ppa:ondrej/php \
    && apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    php8.5 \
    php8.5-cli \
    php8.5-mysql \
    php8.5-mbstring \
    php8.5-xml \
    php8.5-curl \
    php8.5-ldap \
    php8.5-zip \
    php8.5-sqlite3 \
    libapache2-mod-php8.5 \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Install Composer
# ---------------------------------------------------------------------------
RUN curl -fsSL https://getcomposer.org/installer -o /tmp/composer-setup.php \
    && php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm /tmp/composer-setup.php

# ---------------------------------------------------------------------------
# Download MunkiReport source and install dependencies via Composer
# ---------------------------------------------------------------------------
RUN curl -fsSL -L \
    https://github.com/munkireport/munkireport-php/archive/refs/tags/v${MUNKIREPORT_VERSION}.tar.gz \
    -o /tmp/munkireport.tar.gz \
    && mkdir -p /var/munkireport \
    && tar -xzf /tmp/munkireport.tar.gz -C /var/munkireport --strip-components=1 \
    && rm /tmp/munkireport.tar.gz \
    && cd /var/munkireport \
    && composer install --no-dev --optimize-autoloader --no-interaction

# ---------------------------------------------------------------------------
# Apache virtual host — document root is MunkiReport's public/ folder
# ---------------------------------------------------------------------------
RUN echo '<VirtualHost *:80>\n\
    DocumentRoot /var/munkireport/public\n\
    ServerName munkireport\n\
    <Directory /var/munkireport/public>\n\
        AllowOverride All\n\
        Require all granted\n\
        Options -Indexes\n\
    </Directory>\n\
    ErrorLog ${APACHE_LOG_DIR}/munkireport_error.log\n\
    CustomLog ${APACHE_LOG_DIR}/munkireport_access.log combined\n\
</VirtualHost>' > /etc/apache2/sites-available/munkireport.conf \
    && a2dissite 000-default \
    && a2ensite munkireport \
    && a2enmod rewrite php8.5

# ---------------------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------------------
RUN chown -R www-data:www-data /var/munkireport \
    && chmod -R 755 /var/munkireport

# ---------------------------------------------------------------------------
# Expose and start Apache in the foreground
# ---------------------------------------------------------------------------
EXPOSE 80

CMD ["apache2ctl", "-D", "FOREGROUND"]