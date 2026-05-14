#!/bin/bash
# =============================================================================
# Generate a bcrypt hash for the MunkiReport admin password.
#
# Prompts for a password, produces a bcrypt hash, and prints a ready-to-paste
# line for .env. The hash is single-quoted so docker compose does not try to
# interpolate the '$' characters in it.
#
# Usage:
#   bash generate-admin-hash.sh
# =============================================================================

set -e

if ! command -v htpasswd >/dev/null 2>&1; then
    echo "Error: htpasswd not found." >&2
    echo "  Debian/Ubuntu: apt-get install apache2-utils" >&2
    echo "  macOS: ships with the system (try /usr/bin/htpasswd)" >&2
    exit 1
fi

read -rsp "New password: " password
echo
read -rsp "Confirm password: " confirm
echo

if [[ -z "$password" ]]; then
    echo "Password cannot be empty." >&2
    exit 1
fi

if [[ "$password" != "$confirm" ]]; then
    echo "Passwords do not match." >&2
    exit 1
fi

# -B = bcrypt, -C 10 = cost factor, -n = stdout, -b = password on command line
hash=$(htpasswd -nbBC 10 admin "$password" | cut -d: -f2)

echo
echo "Add this line to .env (keep the single quotes):"
echo
echo "ADMIN_PASSWORD_HASH='${hash}'"
echo
echo "Then apply with:"
echo "  docker compose up -d --force-recreate munkireport-init"
echo "  docker compose restart munkireport"
