# 1. Global ARGs (Must be defined before FROM to be used in FROM)
# Production: values passed via build arguments
# Docker Compose: values passed from .env file
# Defaults below are fallback for manual builds
ARG ALPINE_TAG=3.23.4
ARG HAMCLOCK_VERSION=4.24.0

# Stage 1: Build stage
FROM alpine:${ALPINE_TAG} AS builder
WORKDIR /build

# ARG for versioning - passed from build arguments or .env
ARG HAMCLOCK_VERSION
# ARG for customizable resolutions - passed from build arguments or .env
ARG BUILD_RESOLUTIONS="800x480,1600x960,2400x1440,3200x1920"

# Install build dependencies
# binutils is included for the 'strip' command
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache bash git make g++ linux-headers build-base binutils

# Layer: Download & Build
SHELL ["/bin/bash", "-c"]

# Clone source from GitHub
RUN echo "Cloning HamClock v${HAMCLOCK_VERSION} from git..." && \
    git clone --depth 1 --branch v${HAMCLOCK_VERSION} https://github.com/openhamclock/hamclock hamclock

# Build layer - invalidated only if source changes
RUN cd hamclock/ESPHamClock && \
    # ---------------------------------------------------------
    # COMPATIBILITY FIX: Force permissive mode
    # This ensures compilation succeeds even if source code has C++ compliance issues
    sed -i 's/^\(CXXFLAGS =\)/\1 -fpermissive/' Makefile && \
    # ---------------------------------------------------------
    IFS=',' read -ra resolutions <<< "${BUILD_RESOLUTIONS}" && \
    for res in "${resolutions[@]}"; do \
        echo "Building ${res}..." && \
        make -j$(nproc) hamclock-web-${res} && \
        make install && \
        mv /usr/local/bin/hamclock /usr/local/bin/hamclock-${res} && \
        # Strip debug symbols to reduce image size by ~30%
        strip /usr/local/bin/hamclock-${res} && \
        make clean; \
    done && \
    # Clean up build artifacts
    cd /build && \
    rm -rf hamclock

# Stage 2: Runtime stage
FROM alpine:${ALPINE_TAG}

# Re-declare ARGs for use in labels (ARGs don't persist across stages)
ARG HAMCLOCK_VERSION
ARG ALPINE_TAG

LABEL org.opencontainers.image.authors="W4GHG" \
      org.opencontainers.image.version="${HAMCLOCK_VERSION}" \
      org.opencontainers.image.description="HamClock Web Application" \
      org.opencontainers.image.source="https://github.com/openhamclock/hamclock" \
      org.opencontainers.image.vendor="Community" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.base.name="alpine:${ALPINE_TAG}"
WORKDIR /app

# Install runtime dependencies and create user in a single layer
# tzdata: Critical for HamClock to handle timezones correctly
# shadow/su-exec: Required for the PUID/PGID security feature
# apk upgrade: patches pre-installed base packages against known CVEs
# curl and build toolchain (make, g++, etc.) are intentionally excluded:
#   curl: CVE-2026-3805 (HIGH); not required since live update is unsupported in this image
#   build toolchain: live self-update requires recompilation inside the container, which
#     conflicts with the immutable-container model and introduces unnecessary attack surface
RUN --mount=type=cache,target=/var/cache/apk \
    apk upgrade --no-cache && \
    apk add --no-cache bash libstdc++ libgcc shadow su-exec tzdata && \
    # Create generic user
    addgroup -S hamuser && adduser -S hamuser -G hamuser

# Copy binaries
COPY --from=builder /usr/local/bin/hamclock-* /usr/local/bin/

# Copy entrypoint script and setup directories in a single layer
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    # Setup Folders & Symlinks for PUID/PGID support
    # This ensures it works for BOTH root users (legacy) and secure users (new)
    mkdir -p /config && \
    ln -s /config /root/.hamclock && \
    ln -s /config /home/hamuser/.hamclock

# Default to non-root user (satisfies Docker Scout; override with --user root to enable PUID/PGID remapping)
USER hamuser

EXPOSE 8081

HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD bash -c 'echo > /dev/tcp/127.0.0.1/8081' 2>/dev/null

ENTRYPOINT ["/entrypoint.sh"]
CMD ["hamclock-1600x960"]
