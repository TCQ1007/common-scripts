# scripts

## proxy

Toggle HTTP proxy for current shell. Must be sourced.

```bash
source proxy on       # enable proxy (default: http://127.0.0.1:7890)
source proxy off      # disable proxy
source proxy status   # show current proxy variables
```

Custom host/port:

```bash
PROXY_HOST=192.168.1.1 PROXY_PORT=8080 source proxy on
```

## wsl-systemd

Toggle systemd in WSL (`/etc/wsl.conf`). Requires sudo.

```bash
sudo wsl-systemd on      # enable systemd
sudo wsl-systemd off     # disable systemd
sudo wsl-systemd status  # show current setting
```

Changes take effect after `wsl.exe --shutdown` and restart.