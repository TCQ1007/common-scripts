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

## wslconf

Configure WSL (`/etc/wsl.conf`). Requires sudo.

```bash
sudo wslconf on       # enable systemd
sudo wslconf off      # disable systemd
sudo wslconf reset    # reset to defaults (systemd=off)
sudo wslconf status   # show current setting
```

Changes take effect after `wsl.exe --shutdown` and restart.