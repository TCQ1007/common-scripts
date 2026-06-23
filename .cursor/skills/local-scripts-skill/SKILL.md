---
name: local-scripts-skill
description: >-
  Personal shell utilities in ~/scripts: HTTP proxy toggle, PyPI/HuggingFace
  mirrors, WSL systemd config, Zone.Identifier cleanup, nginx reverse proxy
  (mineru/minio), Docker Desktop installer. Use when working with ~/scripts,
  proxy, wslconf, env.sh, clean_zone, nginx-proxy, mineru-api, or WSL setup.
---

# Local Scripts (`~/scripts`)

Git repo at `~/scripts`. Scripts live on disk — **run or source them directly**, do not copy logic into generated one-offs unless extending the repo.

## Critical: source vs execute

| Script | Must use |
|--------|----------|
| `proxy` | `source ~/scripts/proxy …` |
| `env.sh` | `source ~/scripts/env.sh …` |
| `wslconf` | `sudo ~/scripts/wslconf …` (not sourced) |
| `clean_zone.sh` | execute: `~/scripts/clean_zone.sh [dirs…]` |

Sourcing is required for `proxy` and `env.sh` so env vars and venv activation persist in the current shell.

## proxy — HTTP proxy toggle

```bash
source ~/scripts/proxy on       # default http://127.0.0.1:7890
source ~/scripts/proxy off
source ~/scripts/proxy status

PROXY_HOST=192.168.1.1 PROXY_PORT=8080 source ~/scripts/proxy on
```

Sets/unsets: `http_proxy`, `https_proxy`, `all_proxy`, `no_proxy`.

## env.sh — mirrors & dev environment

```bash
source ~/scripts/env.sh uv hf py312
source ~/scripts/env.sh mineru-api-start
```

| Alias | Effect |
|-------|--------|
| `uv` | `UV_INDEX=https://mirrors.aliyun.com/pypi/simple` |
| `hf` | `HF_ENDPOINT=https://hf-mirror.com` |
| `py312` | activate `~/py312` venv |
| `mineru-api-start` | `MINERU_MODEL_SOURCE=modelscope` + run `mineru-api --host 0.0.0.0 --port 8000` |

Add new aliases in the `case` branch of `env.sh`, not inline in chat.

## wslconf — WSL `/etc/wsl.conf`

Requires sudo. Changes need `wsl.exe --shutdown` then restart WSL.

```bash
sudo ~/scripts/wslconf on       # enable systemd
sudo ~/scripts/wslconf off
sudo ~/scripts/wslconf reset    # defaults: systemd=off, user=will, automount off, appendWindowsPath=false
sudo ~/scripts/wslconf status
```

## clean_zone.sh — Zone.Identifier cleanup

Removes WSL `*:Zone.Identifier` alternate data streams from Windows copies.

```bash
~/scripts/clean_zone.sh                              # default: ~/scripts, ~/workspace/mineru-api-test
~/scripts/clean_zone.sh ~/scripts ~/some/other/dir
```

## nginx-proxy — reverse proxy (Docker)

Path: `~/scripts/nginx-proxy/`. Routes port 80 → host services:

| Path | Backend |
|------|---------|
| `/mineru/` | `host.docker.internal:8080` |
| `/minio/` | `host.docker.internal:9001` |
| `/api/`, referer-based fallback | mineru or minio per `$http_referer` |

```bash
cd ~/scripts/nginx-proxy
docker compose up -d        # start
docker compose down         # stop
docker compose logs -f      # logs
```

Config: `nginx/nginx.conf`, `nginx/conf.d/default.conf`.

## Install-DockerDesktop.ps1 — Windows only

Run in **PowerShell on Windows** (not WSL bash). Interactive installer with optional proxy (`127.0.0.1:7890`), custom install dir, and `--wsl-default-data-root` for WSL disk location.

One-liner (edit paths):

```powershell
$exe="Docker Desktop Installer.exe"; $proxy="http://127.0.0.1:7890"; $dir="E:\Software\DockerDesktop"; $data="D:\Software\DockerData"
& $exe install --quiet --accept-license "--installation-dir=$dir" "--wsl-default-data-root=$data" --user
```

## Agent workflow

1. Identify which script fits the task (table above).
2. Prefer existing scripts over reimplementing the same env/proxy/WSL logic.
3. For `proxy` / `env.sh`: always `source`; verify with `status` or echoed exports.
4. For `wslconf` / nginx changes: remind user WSL reboot or `docker compose` restart may be needed.
5. To extend behavior: edit files in `~/scripts` and commit there — not workspace copies.

## Reference

Full upstream README: `~/scripts/README.md`
