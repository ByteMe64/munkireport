# Troubleshooting

## Check versions and basic config

### Host OS

**CLI:**
```bash
# Linux
cat /etc/os-release

# macOS
sw_vers
```

**Portainer:** Settings > Environment > the endpoint name shows the Docker host OS and architecture.

### Docker and Compose

**CLI:**
```bash
docker version
docker compose version
```

**Portainer:** Home page shows the Docker engine version for each environment.

### Running container versions

**CLI:**
```bash
# All stack containers — shows image tags
docker compose ps -a --format "table {{.Name}}\t{{.Image}}\t{{.Status}}"

# MunkiReport app version (reads the composer.json inside the container)
docker exec munkireport php -r "echo json_decode(file_get_contents('/var/munkireport/composer.json'))->version ?? 'not set';"

# Ubuntu version (base image)
docker exec munkireport cat /etc/os-release | grep PRETTY_NAME

# PHP version
docker exec munkireport php -v | head -1

# Composer version
docker exec munkireport composer --version

# Apache version
docker exec munkireport apache2ctl -v | head -1

# Traefik version
docker exec traefik traefik version

# MariaDB version
docker exec munkireport-db mariadb --version
```

**Portainer:** Containers > click a container > the Image field shows the tag. Use the Console feature (connect as `/bin/sh`) to run the `php -v` / `mariadb --version` commands above.

### MunkiReport app config (inside the container)

**CLI:**
```bash
# Dump the generated .env the PHP app reads
docker exec munkireport cat /var/munkireport/.env

# Verify admin user YAML
docker exec munkireport cat /var/munkireport/local/users/admin.yml
```

**Portainer:** Containers > munkireport > Console (`/bin/sh`), then run the `cat` commands above.

---

## Common issues

### Clients not registering

1. Verify the passphrase matches on both sides:
   ```bash
   # Server side — check what the app sees
   docker exec munkireport grep CLIENT_PASSPHRASES /var/munkireport/.env

   # Client side (on the Mac)
   defaults read /Library/Preferences/MunkiReport Passphrase
   ```
   These values must be identical. The variable name differs (server: `CLIENT_PASSPHRASES`, client: `Passphrase`) but the value must match.

2. Verify the client can reach the server:
   ```bash
   # On the Mac client
   curl -ksS https://<DOMAIN>/index.php?/report/hash_check
   ```
   A working server returns a response (not a connection error or HTML error page).

3. Check the server URL in the client plist:
   ```bash
   defaults read /Library/Preferences/MunkiReport BaseUrl
   ```
   This must match `https://<DOMAIN>/` exactly (with trailing slash).

### Can't log in to the web UI

1. Verify the admin user was provisioned:
   ```bash
   docker exec munkireport cat /var/munkireport/local/users/admin.yml
   ```
   Check that `username` and `password_hash` look correct. The hash should start with `$2y$10$`.

2. Re-provision the admin user:
   ```bash
   docker compose up -d --force-recreate munkireport-init && docker compose restart munkireport
   ```
   **Portainer:** Containers > munkireport-init > Recreate, then Containers > munkireport > Restart.

### TLS certificate errors

**Production (Let's Encrypt):**

1. Check that `DOMAIN` has a public DNS A record pointing at the host:
   ```bash
   dig +short <DOMAIN>
   ```
2. Check that port 80 is reachable from the internet (required for HTTP-01 challenge).
3. Check Traefik logs for ACME errors:
   ```bash
   docker compose logs traefik | grep -i acme
   ```

**Demo (self-signed):**

1. Verify certs exist:
   ```bash
   # Local demo
   ls -la certs/

   # Portainer demo — certs are in a named volume
   docker exec traefik ls -la /certs/
   ```
2. Verify the CA is trusted on the Mac:
   ```bash
   security find-certificate -c "MunkiReport Demo CA" /Library/Keychains/System.keychain
   ```
   If not found, trust it:
   ```bash
   # Local demo
   sudo security add-trusted-cert -d -r trustRoot \
     -k /Library/Keychains/System.keychain certs/ca.crt

   # Portainer demo — extract from container first
   docker cp cert-init:/certs/ca.crt ./ca.crt
   sudo security add-trusted-cert -d -r trustRoot \
     -k /Library/Keychains/System.keychain ca.crt
   ```

### Database connection errors

1. Check that the `db` container is healthy:
   ```bash
   docker compose ps db
   ```
   Status should show `(healthy)`. If it's stuck on `(health: starting)`, check DB logs:
   ```bash
   docker compose logs db
   ```

2. Verify credentials match between `.env` and what the app sees:
   ```bash
   docker exec munkireport grep CONNECTION_ /var/munkireport/.env
   ```
   `CONNECTION_DATABASE`, `CONNECTION_USERNAME`, and `CONNECTION_PASSWORD` must match `MYSQL_DATABASE`, `MYSQL_USER`, and `MYSQL_PASSWORD` from `.env`.

3. Test the connection from the app container:
   ```bash
   docker exec munkireport php -r "new PDO('mysql:host=db;port=3306;dbname=munkireport', 'munkireport', '<MYSQL_PASSWORD>'); echo 'OK';"
   ```

### Container won't start / keeps restarting

1. Check logs:
   ```bash
   docker compose logs munkireport
   docker compose logs db
   docker compose logs traefik
   ```
   **Portainer:** Containers > click the container > Logs.

2. Check that init containers completed:
   ```bash
   docker compose ps -a | grep init
   ```
   All three init containers (`cert-init`, `munkireport-init`, and `traefik-init`) should show `Exited (0)`.

3. If `munkireport-init` failed, it's usually a missing `ADMIN_PASSWORD_HASH` in `.env`.

### Resetting everything

To destroy all data and start fresh:
```bash
docker compose down -v
```
This removes all containers **and volumes** (database, admin user, certs). You'll need to re-run the full setup.

**Portainer:** Stacks > your stack > Remove (tick "Remove associated volumes").
