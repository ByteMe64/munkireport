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

# NEW: Explicitly grant the 'admin' user administrator privileges
ROLES_ADMIN="admin, admin@localhost"
EOF

# Ensure proper permissions for the web server
chown -R www-data:www-data /var/www/munkireport

# Wait for MariaDB to be fully ready before trying to migrate/add users
echo "Waiting for database to come online..."
while ! mysqladmin ping -h"${DB_HOST:-db}" -u"${DB_USER:-munkiuser}" -p"${DB_PASSWORD:-MunkiSecretPass123!}" --silent; do
    sleep 2
done
echo "Database is ready!"

# Navigate to the MunkiReport directory
cd /var/www/munkireport

# Automate the database migrations (the --force flag stops it from asking "Are you sure?")
echo "Running database migrations..."
php please migrate --force

# Automate creating the admin login
echo "Creating default admin user..."
# The new command is user:create and prompts for Name, Email, and Password.
# We use printf to automatically answer those three prompts in order.
printf "admin\nadmin@localhost\n%s\n" "${MR_ADMIN_PASSWORD:-AdminSecret123!}" | php please user:create || true

# Start PHP-FPM socket directory if missing
mkdir -p /run/php

# Boot PHP 8.3 FPM
service php8.3-fpm start

# Start Nginx in the foreground
echo "Starting Web Server on HTTPS..."
exec nginx -g "daemon off;"
