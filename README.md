# MunkiReport – Docker Compose Setup (Portainer)

## Files

```
docker-compose.yml          ← Main stack definition
local/
  users/
    admin.yml               ← Admin user credentials (local auth)
```

---

## Quick Start

### 1. Generate a bcrypt password hash

MunkiReport's local auth requires a bcrypt hash. Run this to generate one:

```bash
docker run --rm php:8.1-cli php -r \
  "echo password_hash('YourSecurePassword', PASSWORD_BCRYPT) . PHP_EOL;"
```

Copy the output into `local/users/admin.yml` as the `password` value.

### 2. Edit `docker-compose.yml`

Update these values before deploying:

| Variable | Description |
|---|---|
| `MYSQL_ROOT_PASSWORD` | MariaDB root password |
| `MYSQL_PASSWORD` / `CONNECTION_PASSWORD` | App DB password (must match) |
| `WEBHOST` | Your server URL e.g. `http://192.168.1.100:8080` |

### 3. Deploy in Portainer

**Option A – Portainer Stacks UI:**
1. Go to **Stacks → Add stack**
2. Upload `docker-compose.yml` or paste its contents
3. Deploy

**Option B – CLI (on the Portainer host):**
```bash
docker compose up -d
```

### 4. First-time setup

1. Browse to `http://your-host:8080`
2. Log in with **admin** / your chosen password
3. Go to **Admin → Migrations** and run any pending migrations

---

## Auth Notes

- `AUTH_METHODS=LOCAL` enables the local username/password login form.
- `ROLES_ADMIN=admin` grants the `admin` account full admin rights.
- Additional users can be added by placing more `.yml` files in `./local/users/`.
- The user YAML format is: `username`, `realname`, `password` (bcrypt), `email`.

## Updating MunkiReport

Change the image tag in `docker-compose.yml`:
```yaml
image: ghcr.io/munkireport/munkireport-php:v5.9.0   # ← new version
```
Then redeploy the stack.
