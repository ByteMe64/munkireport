#!/bin/bash
set -e

# Forge the .env file for MunkiReport
echo "Creating .env configuration..."
cat <<EOF > /var/www/munkireport/.env
APP_NAME=MunkiReport
APP_ENV=production
APP_DEBUG=false
APP_URL=https://${MR_HOST:-localhost}

DB_CONNECTION=mysql
DB_HOST=${DB_HOST:-db}
DB_PORT=3306
DB_DATABASE=${DB_NAME:-munkireport}
DB_USERNAME=${DB_USER:-munkiuser}
DB_PASSWORD=${DB_PASSWORD:-MunkiSecretPass123!}

# Local Authentication Setup
AUTH_METHODS=LOCAL
EOF

# Ensure proper permissions for the web server
chown -R www-data:www-data /var/www/munkireport

# Start PHP-FPM socket directory if missing
mkdir -p /run/php

# Boot PHP 8.3 FPM
service php8.3-fpm start

# Start Nginx in the foreground
echo "Starting Web Server on HTTPS..."
exec nginx -g "daemon off;"
