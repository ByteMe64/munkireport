## MunkiReport SSL CA fix

### 1. Add CA cert to System keychain
```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /path/to/ca.crt
```

### 2. Verify cert chain is valid
```bash
echo | openssl s_client -connect munkireport.net:443 2>/dev/null | openssl x509 -noout -issuer -subject
```

### 3. Verify SAN covers munkireport.net
```bash
echo | openssl s_client -connect munkireport.net:443 2>/dev/null | openssl x509 -noout -text | grep -A1 "Subject Alt"
```

### 4. Test the client run
```bash
sudo /usr/local/munkireport/munkireport-runner
```

> **Key fix:** The CA must be in the **System** keychain, not the login keychain — `munkireport-runner` executes as root and won't see user-level trust.