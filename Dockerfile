# =============================================================================
# MunkiReport - Custom Image
# Base:  Ubuntu 24.04 LTS (Noble Numbat)
# PHP:   8.3
# Web:   Apache 2.4
# App:   MunkiReport v5.8.0
# =============================================================================

FROM ubuntu:24.04

LABEL maintainer="your-team@example.com"
LABEL description="MunkiReport v5.8.0 on Ubuntu 24.04 LTS with PHP 8.3"

# Prevent apt from prompting during build
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# ---------------------------------------------------------------------------
# System packages + PHP 8.3 + Apache
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    php8.3 \
    php8.3-cli \
    php8.3-mysql \
    php8.3-mbstring \
    php8.3-xml \
    php8.3-curl \
    php8.3-ldap \
    php8.3-zip \
    php8.3-sqlite3 \
    libapache2-mod-php8.3 \
    curl \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Download and install MunkiReport v5.8.0
# ---------------------------------------------------------------------------
RUN curl -fsSL \
    https://github.com/munkireport/munkireport-php/releases/download/v5.8.0/munkireport-php-v5.8.0.tar.gz \
    -o /tmp/munkireport.tar.gz \
    && mkdir -p /var/munkireport \
    && tar -xzf /tmp/munkireport.tar.gz -C /var/munkireport --strip-components=1 \
    && rm /tmp/munkireport.tar.gz

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
    && a2enmod rewrite php8.3

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
