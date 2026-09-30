# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Docker packaging of the upstream HamClock C++ app (https://github.com/openhamclock/hamclock), published as `ggilman/hamclock` on Docker Hub for `linux/amd64` and `linux/arm64`. There is no application source here: the Dockerfile clones the upstream tag `v${APP_VERSION}` and compiles it. This repo holds the Dockerfile, the entrypoint, the compose/env files and the user docs (`README.md`, and `README_BRIEF.md` for the Docker Hub summary).

We do not own, maintain or publish the HamClock source; we only publish the container image. Scope work accordingly:
- Upstream bugs and features are out of scope. Don't propose changes to HamClock itself or suggest contributing upstream unless asked.
- If upstream code needs adjusting to build or run in the container, do it at build time in the Dockerfile (like the existing `-fpermissive` Makefile `sed`), never by vendoring or forking the source.
- Upgrading HamClock means changing `<upstream_version>` in `config.xml` to an existing upstream release tag.

## Building and releasing

**All builds go through `../scripts/build.sh`** (i.e. `~/scripts/build.sh`, outside this repo). Do not build with raw `docker build`/`docker compose build`. Run it from the repo root because it reads and writes `./config.xml`:

- `~/scripts/build.sh -d` does a native debug build, tags it `debug` and pushes it. The version is not bumped. Output is logged to `build_debug_<timestamp>.log`, which is gitignored.
- `~/scripts/build.sh -p` does the production multi-arch build and pushes `latest` plus `<major>.<minor>`. It bumps the minor version in `config.xml`.
- `-n` does a native-only release. `-r X.Y` forces a version. `-c` disables the cache. `-v` gives plain progress output. `-t TAG` adds an extra tag.
- Every mode first runs a local `docker build`, then checks that `<executable><name>` from `config.xml` (for example `hamclock-1600x960`) exists in the image before it pushes.
- Multi-arch builds use the buildx builder `mybuilder`. This is a hybrid builder: a local arm64 node plus a remote amd64 node at `tcp://192.168.111.58:2375`.

`config.xml` is the source of truth for a release:
- `<upstream_version>` is passed to the Dockerfile as `APP_VERSION`.
- Each child of `<build>` is passed as `BUILD_<NAME>`, so `<resolutions>` becomes `BUILD_RESOLUTIONS`.
- `<version>` is the image version, which is separate from the upstream HamClock version.

The script ignores the Dockerfile's `BASE_OS_TAG` default. It passes the current Alpine latest-stable version (major.minor) that it fetches from dl-cdn.alpinelinux.org.

There is no test suite. Validate changes with `../scripts/build.sh -d` and then run the `debug` image with `docker run -p 8081:8081 ...`. The healthcheck is a TCP probe on port 8081. Note that `-d` still pushes the `debug` tag to Docker Hub, so ask before running it.

## Architecture

**Dockerfile (multi-stage, Alpine):**
- The builder stage loops over the comma-separated `BUILD_RESOLUTIONS`. For each one it runs `make hamclock-web-<WxH>` and `make install`, renames the result to `/usr/local/bin/hamclock-<WxH>`, strips it and runs `make clean`.
- The Makefile is patched with `-fpermissive` so that upstream C++ compliance issues do not break the build.
- The runtime stage copies only the binaries.
- The image default `CMD` is `hamclock-1600x960`. Users choose a resolution by overriding the command.

**Runtime design decisions (documented in README; keep them):**
- The runtime image deliberately excludes `curl` and the build toolchain. As a result, HamClock's in-app live update does not work, by design. The reasons are CVE-2026-3805 and the immutable-container model.
- `apk upgrade` runs in the runtime stage to pick up CVE fixes.
- The image runs as the non-root user `hamuser` by default.
- `/config` is the persistent volume. It is symlinked from both `/root/.hamclock` and `/home/hamuser/.hamclock`.

**entrypoint.sh:**
- It resolves the backend and appends `-b <host:port>` to the command. `BACKEND_URL` takes priority over `BACKEND_PRESET`.
- Presets are `hamclock` → `hamclock.com:80` (the default), `ohb` → `ohb.hamclock.app:80` and `original` → `clearskyinstitute.com:80` (deprecated).
- PUID/PGID remapping (`groupmod`/`usermod`, `chown /config`, then `su-exec`) happens only when the container runs as root, which means the user must set `user: root`. Under the default `hamuser` these variables are ignored.

`sync_and_run.sh` is a legacy rsync-based config sync. The image does not use it and `.dockerignore` excludes it.

## Conventions

- When you change behavior, update the Dockerfile's header comment block listing the build arguments, and update `README.md`. The README is the user-facing documentation.
- The upstream HamClock author (WB0OEW) is SK. The original backend at clearskyinstitute.com shut down in June 2026, so new work should target the community backends.
