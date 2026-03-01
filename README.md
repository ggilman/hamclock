# HamClock Docker

A production-ready, multi-architecture Docker container for [HamClock](https://www.clearskyinstitute.com/ham/HamClock/) by Elwood Downey (WB0OEW).

[![Docker Image](https://img.shields.io/badge/docker-ggilman%2Fhamclock-blue)](https://hub.docker.com/r/ggilman/hamclock)
[![GitHub](https://img.shields.io/badge/github-ggilman%2Fhamclock-green)](https://github.com/ggilman/hamclock)

## Features

- 🚀 **Multi-Architecture Support**: Runs on `linux/amd64` and `linux/arm64`
- 🔒 **Security**: Supports non-root operation with PUID/PGID
- 📦 **Lightweight**: Based on Alpine Linux (3.23.3)
- 🎨 **Multiple Resolutions**: Pre-built binaries for 800x480, 1600x960, 2400x1440, and 3200x1920
- � **Backend Configuration**: Easy switching between community backends (hamclock.com, OHB, or custom)
- �🏥 **Health Monitoring**: Built-in Docker healthcheck
- 💾 **Persistent Storage**: Configuration automatically saved to mounted volume
- 🕐 **Timezone Support**: Respects `TZ` environment variable

## Quick Start

### Using Docker Run

```bash
docker run -d \
  --name hamclock \
  -p 8081:8081 \
  -e TZ=America/New_York \
  -e BACKEND_PRESET=hamclock \
  -v /path/to/config:/config \
  --restart unless-stopped \
  ggilman/hamclock:latest
```

### Using Docker Compose

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
      - BACKEND_PRESET=hamclock  # Recommended - see Backend Configuration
      - PUID=1000  # Optional
      - PGID=1000  # Optional
    volumes:
      - /path/to/config:/config
```

Then run:
```bash
docker-compose up -d
```

Access HamClock at: `http://localhost:8081`

> **⚠️ Important**: The original backend shuts down June 2026. Set `BACKEND_PRESET=hamclock` to use the community server. See [Backend Configuration](#5-backend-configuration) for details.

## Configuration & Persistence

### 1. File Permissions (New!)

By default, this container runs as root. However, if you are running this on a NAS (Synology, Unraid, etc.) or want better security, you can specify a user/group ID.

- **PUID**: The User ID you want the container to run as
- **PGID**: The Group ID you want the container to run as

The container will automatically fix permissions on the `/config` directory to match the user you specified.

**Example with custom user:**
```bash
docker run -d \
  --name hamclock \
  -p 8081:8081 \
  -e PUID=1000 \
  -e PGID=1000 \
  -v /path/to/config:/config \
  ggilman/hamclock:latest
```

To find your PUID and PGID on Linux:
```bash
id $USER
```

### 2. Volume Mapping

We have unified the configuration path. You should map your volume to `/config`.

- **Recommended**: `/config` (Works for both root and non-root users)
- **Legacy**: `/root/.hamclock` (Still supported for backward compatibility)

### 3. Screen Resolutions

HamClock must be started with a specific resolution command. If you do not provide a command, it defaults to **1600x960**.

**Available commands:**

| Resolution | Command |
|------------|---------|
| 800×480    | `hamclock-800x480` |
| 1600×960   | `hamclock-1600x960` *(Default)* |
| 2400×1440  | `hamclock-2400x1440` |
| 3200×1920  | `hamclock-3200x1920` |

**Example - Using 2400x1440:**
```bash
docker run -d \
  --name hamclock \
  -p 8081:8081 \
  -v /path/to/config:/config \
  ggilman/hamclock:latest \
  hamclock-2400x1440
```

**Docker Compose example:**
```yaml
services:
  hamclock:
    image: ggilman/hamclock:latest
    container_name: hamclock
    command: hamclock-2400x1440
    ports:
      - 8081:8081
    volumes:
      - /path/to/config:/config
```

### 4. Timezone

Set the `TZ` environment variable (e.g., `America/New_York`, `Europe/London`) to ensure HamClock displays your local time correctly without manual configuration.

**Common timezone examples:**
- US Eastern: `America/New_York`
- US Pacific: `America/Los_Angeles`
- UK: `Europe/London`
- Central Europe: `Europe/Paris`
- Japan: `Asia/Tokyo`

[Full timezone list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

### 5. Backend Configuration

**⚠️ Important**: The original HamClock backend (`clearskyinstitute.com`) will **shut down in June 2026**. You should configure an alternate backend to ensure your HamClock continues working.

This container supports two methods for backend configuration:

#### Method 1: Use a Preset (Recommended)

Set the `BACKEND_PRESET` environment variable to one of these values:

| Preset | Backend Server | Description |
|--------|---------------|-------------|
| `hamclock` | hamclock.com:80 | **Recommended** - Free community server by W4BAE, production-ready |
| `ohb` | ohb.hamclock.app:80 | Open HamClock Backend - Community self-hosted option |
| `original` | clearskyinstitute.com:80 | Original server (deprecated, stops June 2026) |

**Example with preset:**
```bash
docker run -d \
  --name hamclock \
  -p 8081:8081 \
  -e BACKEND_PRESET=hamclock \
  -v /path/to/config:/config \
  ggilman/hamclock:latest
```

**Docker Compose with preset:**
```yaml
services:
  hamclock:
    image: ggilman/hamclock:latest
    environment:
      - BACKEND_PRESET=hamclock  # W4BAE's server
    ports:
      - 8081:8081
    volumes:
      - /path/to/config:/config
```

#### Method 2: Custom Backend URL

If you're running your own backend or want to use a different server, set `BACKEND_URL` (this takes priority over `BACKEND_PRESET`):

**Example with custom backend:**
```bash
docker run -d \
  --name hamclock \
  -p 8081:8081 \
  -e BACKEND_URL=192.168.1.100:8080 \
  -v /path/to/config:/config \
  ggilman/hamclock:latest
```

**Docker Compose with custom backend:**
```yaml
services:
  hamclock:
    image: ggilman/hamclock:latest
    environment:
      - BACKEND_URL=192.168.1.100:8080
    ports:
      - 8081:8081
    volumes:
      - /path/to/config:/config
```

#### Using .env File

Edit the `.env` file to set your backend preference:

```env
# Option 1: Use a preset
BACKEND_PRESET=hamclock

# Option 2: Use custom URL (takes priority)
#BACKEND_URL=192.168.1.100:8080
```

Then run:
```bash
docker-compose up -d
```

#### No Backend Configuration

If you don't set either variable, HamClock will use its default behavior (currently points to `clearskyinstitute.com`, which stops working June 2026).

#### Backend Information

- **hamclock.com** (W4BAE): Free, production-ready, actively maintained. [More info](https://hamclock.com/)
- **Open HamClock Backend**: Community-driven, self-hostable. [GitHub](https://github.com/BrianWilkinsFL/open-hamclock-backend) | [Docker Hub](https://hub.docker.com/r/komacke/open-hamclock-backend)

## Advanced Usage

### Custom Port

To use a different port (e.g., 8080 instead of 8081):

```bash
docker run -d \
  --name hamclock \
  -p 8080:8081 \
  -v /path/to/config:/config \
  ggilman/hamclock:latest
```

With docker-compose, edit the `.env` file:
```env
PORT=8080
```

### Health Check

The container includes an automatic health check that verifies HamClock is responding on port 8081. You can view the health status with:

```bash
docker inspect --format='{{.State.Health.Status}}' hamclock
```

## Troubleshooting

### Backend Connection Issues

**Problem**: HamClock shows "No data" or blank displays after June 2026.

**Solution**: The original backend (`clearskyinstitute.com`) has shut down. Configure an alternate backend:

```bash
# Stop and remove existing container
docker stop hamclock && docker rm hamclock

# Start with new backend
docker run -d \
  --name hamclock \
  -p 8081:8081 \
  -e BACKEND_PRESET=hamclock \
  -v /path/to/config:/config \
  ggilman/hamclock:latest
```

**For docker-compose**, add to your environment section:
```yaml
environment:
  - BACKEND_PRESET=hamclock
```

Then:
```bash
docker-compose down
docker-compose up -d
```

**Verify backend is set**: Check container logs:
```bash
docker logs hamclock | grep Backend
# Should show: Backend: hamclock.com:80 (W4BAE's server)
```

### Permission Denied Errors

**Problem**: Container logs show permission errors when trying to write to `/config`.

**Solution**: Ensure the PUID and PGID variables match the user who owns the `/path/to/your/config` folder on your host machine.

```bash
# Check ownership of your config directory
ls -la /path/to/your/config

# Set correct PUID/PGID
docker run -d \
  -e PUID=1000 \
  -e PGID=1000 \
  -v /path/to/config:/config \
  ggilman/hamclock:latest
```

### Container Crashing on Startup

**Problem**: Container exits immediately after starting.

**Solution**: Check the logs for specific errors:
```bash
docker logs hamclock
```

Common issues:
- **Port already in use**: Another service is using port 8081
- **Volume permissions**: Ensure PUID/PGID has write access to your volume
- **Upgrading from older version**: Use the new `/config` mount point

### Web Interface Not Loading

**Problem**: Cannot access HamClock at `http://localhost:8081`

**Checklist:**
1. Verify container is running: `docker ps | grep hamclock`
2. Check container health: `docker inspect --format='{{.State.Health.Status}}' hamclock`
3. Verify port mapping: `docker port hamclock`
4. Check firewall rules on your host
5. Try accessing from host IP instead of localhost

### Configuration Not Persisting

**Problem**: Settings reset after restarting container.

**Solution**: Ensure you've mounted a volume to `/config`:
```bash
docker run -d \
  -v /path/to/config:/config \
  ggilman/hamclock:latest
```

## Building from Source

If you want to build the image yourself or customize the build:

### Prerequisites
- Docker with BuildKit support
- At least 2GB free disk space

### Build Commands

**Local build (single architecture):**
```bash
docker build -t hamclock:custom .
```

**With custom build arguments:**
```bash
docker build \
  --build-arg ALPINE_TAG=3.23.3 \
  --build-arg HAMCLOCK_VERSION=4.22 \
  --build-arg BUILD_RESOLUTIONS="1600x960,2400x1440" \
  -t hamclock:custom .
```

**Multi-architecture build (requires Docker buildx):**
```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg ALPINE_TAG=3.23.3 \
  --build-arg HAMCLOCK_VERSION=4.22 \
  -t yourusername/hamclock:latest \
  --push .
```

### Customizing Resolutions

You can customize which resolutions are built by passing the `BUILD_RESOLUTIONS` build argument:

```bash
docker build \
  --build-arg BUILD_RESOLUTIONS="800x480,1600x960" \
  -t hamclock:custom .
```

The default is `800x480,1600x960,2400x1440,3200x1920` which builds all four resolutions.

## Architecture

This container uses a multi-stage build process:

1. **Builder Stage**: Downloads HamClock source, compiles for multiple resolutions, strips debug symbols
2. **Runtime Stage**: Minimal Alpine image with only runtime dependencies

**Base Image**: Alpine Linux 3.23.3  
**Compiled HamClock Versions**: All available resolutions  
**Security**: Runs as non-root user when PUID/PGID specified  

## Version Information

- **HamClock**: Dynamically downloaded from [clearskyinstitute.com](https://www.clearskyinstitute.com/ham/HamClock/)
- **Alpine**: 3.23.3
- **Container Version**: Check image tags on Docker Hub

## Support & Contributing

### Issues

If you encounter problems:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review container logs: `docker logs hamclock`
3. [Open an issue on GitHub](https://github.com/ggilman/hamclock/issues) with logs and your docker-compose.yml (remove sensitive info)

### HamClock Support

For HamClock software issues (not Docker-related):
- Visit: https://www.clearskyinstitute.com/ham/HamClock/
- Contact: Elwood Downey, WB0OEW

## License

HamClock software is created and maintained by Elwood Downey, WB0OEW.  
This Docker container implementation is provided as-is for the amateur radio community.

## Credits

- **HamClock**: Elwood Downey, WB0OEW - https://www.clearskyinstitute.com/ham/HamClock/
- **Docker Container**: ggilman@gmail.com

## Links

- [GitHub Repository](https://github.com/ggilman/hamclock)
- [Docker Hub](https://hub.docker.com/r/ggilman/hamclock)
- [HamClock Official Site](https://www.clearskyinstitute.com/ham/HamClock/)
- [Report Issues](https://github.com/ggilman/hamclock/issues)

