# =============================================================================
# MunkiReport - Custom Image
# Base:  Ubuntu 24.04 LTS (Noble Numbat)
# =============================================================================
# To upgrade PHP or MunkiReport, update the version values in .env and rebuild.
# No edits to this file are needed for routine version upgrades.
# =============================================================================

FROM ubuntu:24.04

ARG PHP_VERSION=8.3
ARG MUNKIREPORT_VERSION=5.8.0

LABEL maintainer="your-team@example.com"
LABEL description="MunkiReport on Ubuntu 24.04 LTS"
LABEL munkireport.version="${MUNKIREPORT_VERSION}"
LABEL php.version="${PHP_VERSION}"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV PHP_VERSION=${PHP_VERSION}
ENV MUNKIREPORT_VERSION=${MUNKIREPORT_VERSION}

# ---------------------------------------------------------------------------
# System packages + PHP + Apache
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    php${PHP_VERSION} \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-ldap \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-sqlite3 \
    libapache2-mod-php${PHP_VERSION} \
    curl \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# PHP hardening
# ---------------------------------------------------------------------------
RUN PHP_INI="/etc/php/${PHP_VERSION}/apache2/php.ini" \
    && sed -i "s/^expose_php.*/expose_php = Off/" "$PHP_INI" \
    && sed -i "s/^display_errors.*/display_errors = Off/" "$PHP_INI" \
    && sed -i "s/^;log_errors.*/log_errors = On/" "$PHP_INI" \
    && sed -i "s/^;session.cookie_httponly.*/session.cookie_httponly = 1/" "$PHP_INI" \
    && sed -i "s/^;session.cookie_secure.*/session.cookie_secure = 1/" "$PHP_INI"

# ---------------------------------------------------------------------------
# Install Composer
# ---------------------------------------------------------------------------
RUN curl -fsSL https://getcomposer.org/installer -o /tmp/composer-setup.php \
    && php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm /tmp/composer-setup.php

# ---------------------------------------------------------------------------
# Download MunkiReport and install dependencies
# ---------------------------------------------------------------------------
RUN curl -fsSL -L \
    "https://github.com/munkireport/munkireport-php/archive/refs/tags/v${MUNKIREPORT_VERSION}.tar.gz" \
    -o /tmp/munkireport.tar.gz \
    && mkdir -p /var/munkireport \
    && tar -xzf /tmp/munkireport.tar.gz -C /var/munkireport --strip-components=1 \
    && rm /tmp/munkireport.tar.gz \
    && cd /var/munkireport \
    && composer install --no-dev --optimize-autoloader --no-interaction

# ---------------------------------------------------------------------------
# Apache virtual host
# ---------------------------------------------------------------------------
RUN echo '<VirtualHost *:80>\n\
    DocumentRoot /var/munkireport/public\n\
    ServerName munkireport.local\n\
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
    && a2enmod rewrite php${PHP_VERSION}

# ---------------------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------------------
RUN chown -R www-data:www-data /var/munkireport \
    && chmod -R 755 /var/munkireport

EXPOSE 80

CMD ["apache2ctl", "-D", "FOREGROUND"]
