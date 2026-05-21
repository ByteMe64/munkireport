#!/bin/bash
MUNKIREPORT_VERSION="9.9.9"
URL="https://github.com/munkireport/munkireport-php/archive/refs/tags/v${MUNKIREPORT_VERSION}.tar.gz"
echo "Testing URL: $URL"
curl -fL "$URL" -o /tmp/test.tar.gz
echo "Curl exit code: $?"
tar -xzf /tmp/test.tar.gz -C /tmp --strip-components=1 2>/dev/null
echo "Tar exit code: $?"
