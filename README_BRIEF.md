# HamClock Docker

A production-ready, multi-architecture Docker container for [HamClock](https://www.clearskyinstitute.com/ham/HamClock/) by Elwood Downey (WB0OEW). Source is now maintained by the community at [github.com/openhamclock/hamclock](https://github.com/openhamclock/hamclock).

## Features

- 🚀 **Multi-Architecture**: `linux/amd64` and `linux/arm64`
- 🔒 **Security**: Defaults to non-root `hamuser`; optional PUID/PGID remapping for NAS deployments
- 📦 **Lightweight**: Alpine Linux 3.24
- 🎨 **Multiple Resolutions**: 800x480, 1600x960, 2400x1440, 3200x1920
- 🌐 **Backend Configuration**: Easy switching between community backends (hamclock.com, OHB, or custom)
- 🏠 **Self-Hosting Ready**: Run HamClock + backend together

## ⚠️ Important: Backend Configuration

**Version 2.0 and up automatically default to `hamclock.com`** (W4BAE's community server), ensuring HamClock continues working beyond the June 2026 shutdown of the original `clearskyinstitute.com` backend. You can optionally configure other backend servers using environment variables, or self-host your own backend using Open HamClock Backend (OHB).

**Previous versions (tagged `legacy`)** point to the original `clearskyinstitute.com` backend and will stop working in June 2026. Upgrade to the latest version to ensure continued operation.

## Quick Start

```bash
docker run -d \
  --name hamclock \
  -p 8081:8081 \
  -e TZ=America/New_York \
  -v /path/to/config:/config \
  --restart unless-stopped \
  ggilman/hamclock:latest
```

Access at: `http://localhost:8081`

## Docker Compose

```yaml
services:
  hamclock:
    image: ggilman/hamclock:latest
    container_name: hamclock
    restart: unless-stopped
    ports:
      - 8081:8081
    environment:
      - TZ=America/New_York
    volumes:
      - /path/to/config:/config
```

**With PUID/PGID remapping** (NAS/Unraid — requires `user: root` to allow UID remapping at startup):
```yaml
services:
  hamclock:
    image: ggilman/hamclock:latest
    user: root          # required for PUID/PGID remapping
    environment:
      - TZ=America/New_York
      - PUID=1000
      - PGID=1000
    volumes:
      - /path/to/config:/config
```

## Configuration

### Available Resolutions
- `hamclock-800x480`
- `hamclock-1600x960` (default)
- `hamclock-2400x1440`
- `hamclock-3200x1920`

### Backend Options (v2.0+)
- **BACKEND_PRESET**: `hamclock` (default v2.0+), `ohb`, or `original`
- **BACKEND_URL**: Custom backend server (e.g., `192.168.1.100:8080`)

## Known CVEs

| CVE | Component | Notes |
|-----|-----------|-------|
| CVE-2025-60876 (MEDIUM) | `busybox` wget | No Alpine 3.24 patch available as of September 2026. Not exploitable here — `wget` is not used in this image (healthcheck uses `bash /dev/tcp`). |

## Limitations

- **Live update not supported**: HamClock's built-in self-update (which recompiles from source) requires `curl` and a full C++ build toolchain. Both are excluded for security reasons — including them would roughly triple the runtime image size and introduce HIGH-severity CVEs. Update by pulling a new image instead: `docker pull ggilman/hamclock:latest`.

## Documentation

**Full documentation, troubleshooting, and self-hosting guide:**  
📖 [https://github.com/ggilman/hamclock](https://github.com/ggilman/hamclock)

## Credits

- **HamClock Creator**: Elwood Downey, WB0OEW (SK) — original source at [clearskyinstitute.com](https://www.clearskyinstitute.com/ham/HamClock/)
- **Community Source**: Now maintained at [github.com/openhamclock/hamclock](https://github.com/openhamclock/hamclock)
- **Community Backends**: W4BAE (hamclock.com), KO4AQF & KN4LNB (OHB)
- **Docker Container**: George Gilman, W4GHG

*73, Elwood. Your work lives on.*
