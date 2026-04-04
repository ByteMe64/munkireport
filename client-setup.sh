#!/bin/bash
# =============================================================================
# MunkiReport Client Setup
# =============================================================================
# Installs and configures the MunkiReport client on a Mac.
#
# Usage:
#   sudo bash client-setup.sh
#
# Requirements:
#   - Must be run as root (sudo)
#   - Internet access to the MunkiReport server and GitHub
#
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Configuration — update these before running
# -----------------------------------------------------------------------------
SERVER_URL="https://your-domain-here/"
PASSPHRASE="your-client-passphrase-here"

# -----------------------------------------------------------------------------
# Checks
# -----------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root: sudo bash $0"
    exit 1
fi

echo "=== MunkiReport Client Setup ==="
echo "Server: ${SERVER_URL}"
echo ""

# -----------------------------------------------------------------------------
# Step 1 — Write MunkiReport preferences
# -----------------------------------------------------------------------------
echo "--- Writing preferences ---"
defaults write /Library/Preferences/MunkiReport ServerURL "${SERVER_URL}"
defaults write /Library/Preferences/MunkiReport Passphrase -string "${PASSPHRASE}"
echo "Preferences written to /Library/Preferences/MunkiReport.plist"

# -----------------------------------------------------------------------------
# Step 2 — Install Mac Admins Python 3.10 if not present
# Python is required by the MunkiReport module scripts.
# https://github.com/macadmins/python
# -----------------------------------------------------------------------------
PYTHON_PATH="/Library/ManagedFrameworks/Python/Python3.framework/Versions/3.10/bin/python3.10"

if [[ -f "${PYTHON_PATH}" ]]; then
    echo "--- Mac Admins Python 3.10 already installed, skipping ---"
else
    echo "--- Installing Mac Admins Python 3.10 ---"
    curl -fsSL -o /tmp/munkireport-python.pkg \
        https://github.com/macadmins/python/releases/download/v3.10.9.80716/python_macos_universal2-3.10.9.80716.pkg
    installer -pkg /tmp/munkireport-python.pkg -target /
    rm -f /tmp/munkireport-python.pkg
    echo "Python 3.10 installed"
fi

# -----------------------------------------------------------------------------
# Step 3 — Install MunkiReport client scripts from server
# -----------------------------------------------------------------------------
echo "--- Installing MunkiReport client scripts ---"
/bin/bash -c "$(curl -fsSL "${SERVER_URL}index.php?/install")"

# -----------------------------------------------------------------------------
# Step 4 — Trigger initial check-in
# -----------------------------------------------------------------------------
echo "--- Running initial check-in ---"
/usr/local/munkireport/munkireport-runner

echo ""
echo "=== Setup complete ==="
echo "The Mac should now appear in the MunkiReport dashboard at ${SERVER_URL}"
