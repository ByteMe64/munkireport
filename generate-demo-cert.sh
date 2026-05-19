#!/bin/bash
# =============================================================================
# Generate a self-signed CA and server certificate for local demo use.
#
# Creates a private CA, then signs a server certificate for DOMAIN (read from
# .env or passed as an argument). The CA cert can be trusted on macOS so that
# Mac clients accept the server's TLS certificate without warnings.
#
# Usage:
#   bash generate-demo-cert.sh              # reads DOMAIN from .env
#   bash generate-demo-cert.sh myhost.local # explicit domain
# =============================================================================

set -e

DOMAIN="${1:-}"
CERT_DIR="${CERT_DIR:-}"

if [[ -f .env ]]; then
    [[ -z "$DOMAIN" ]]   && DOMAIN=$(grep '^DOMAIN=' .env | cut -d= -f2)
    [[ -z "$CERT_DIR" ]] && CERT_DIR=$(grep '^CERT_DIR=' .env | cut -d= -f2)
fi

CERT_DIR="${CERT_DIR:-./certs}"

if [[ -z "$DOMAIN" ]]; then
    echo "Error: no domain specified." >&2
    echo "Usage: $0 <domain>" >&2
    echo "Or set DOMAIN in .env" >&2
    exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
    echo "Error: openssl not found." >&2
    exit 1
fi

mkdir -p "$CERT_DIR"

echo "=== Generating demo certificates for: ${DOMAIN} ==="

# --- CA key and certificate (valid 10 years) ---
openssl genrsa -out "${CERT_DIR}/ca.key" 4096 2>/dev/null

openssl req -x509 -new -nodes \
    -key "${CERT_DIR}/ca.key" \
    -sha256 \
    -days 3650 \
    -out "${CERT_DIR}/ca.crt" \
    -subj "/C=US/ST=Demo/L=Demo/O=MunkiReport Demo CA/CN=MunkiReport Demo CA"

# --- Server key, CSR, and signed certificate (valid 1 year) ---
openssl genrsa -out "${CERT_DIR}/server.key" 2048 2>/dev/null

openssl req -new \
    -key "${CERT_DIR}/server.key" \
    -out "${CERT_DIR}/server.csr" \
    -subj "/C=US/ST=Demo/L=Demo/O=MunkiReport/CN=${DOMAIN}"

# SAN extension — covers the DOMAIN, plus localhost and 127.0.0.1 if DOMAIN differs
{
    echo "authorityKeyIdentifier=keyid,issuer"
    echo "basicConstraints=CA:FALSE"
    echo "keyUsage=digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment"
    echo "subjectAltName=@alt_names"
    echo ""
    echo "[alt_names]"
    echo "DNS.1 = ${DOMAIN}"
    DNS_INDEX=2
    if [[ "$DOMAIN" != "localhost" ]]; then
        echo "DNS.${DNS_INDEX} = localhost"
        DNS_INDEX=$((DNS_INDEX + 1))
    fi
    echo "IP.1 = 127.0.0.1"
} > "${CERT_DIR}/server.ext"

openssl x509 -req \
    -in "${CERT_DIR}/server.csr" \
    -CA "${CERT_DIR}/ca.crt" \
    -CAkey "${CERT_DIR}/ca.key" \
    -CAcreateserial \
    -out "${CERT_DIR}/server.crt" \
    -days 365 \
    -sha256 \
    -extfile "${CERT_DIR}/server.ext"

rm -f "${CERT_DIR}/server.csr" "${CERT_DIR}/server.ext" "${CERT_DIR}/ca.srl"

echo ""
echo "=== Certificates generated in ${CERT_DIR}/ ==="
echo "  CA certificate:     ${CERT_DIR}/ca.crt"
echo "  Server certificate: ${CERT_DIR}/server.crt"
echo "  Server key:         ${CERT_DIR}/server.key"
echo ""
echo "=== Trust the CA on macOS (run on each Mac client): ==="
echo "  sudo security add-trusted-cert -d -r trustRoot \\"
echo "    -k /Library/Keychains/System.keychain ${CERT_DIR}/ca.crt"
echo ""
echo "=== Deploy the demo stack: ==="
echo "  docker compose -f docker-compose.yml -f docker-compose.demo.yml up -d --build"
