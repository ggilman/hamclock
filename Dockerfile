# 1. Global ARGs (Must be defined before FROM to be used in FROM)
# Production: values passed via build arguments
# Docker Compose: values passed from .env file
# Defaults below are fallback for manual builds
ARG ALPINE_TAG=3.23.3

# Stage 1: Build stage
FROM alpine:${ALPINE_TAG} AS builder
WORKDIR /build

# ARG for versioning - passed from build arguments or .env
ARG HAMCLOCK_VERSION=4.22
# ARG for customizable resolutions - passed from build arguments or .env
ARG BUILD_RESOLUTIONS="800x480,1600x960,2400x1440,3200x1920"

# Install build dependencies
# binutils is included for the 'strip' command
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache bash curl make g++ unzip linux-headers build-base binutils

# Layer: Download & Build
SHELL ["/bin/bash", "-c"]

# Download layer - separate for better caching
RUN echo "Downloading HamClock Version: ${HAMCLOCK_VERSION}" && \
    curl -fsSL -O https://www.clearskyinstitute.com/ham/HamClock/ESPHamClock.zip && \
    unzip -q ESPHamClock.zip

# Build layer - invalidated only if source changes
RUN cd ESPHamClock && \
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
    rm -rf ESPHamClock.zip ESPHamClock

# Stage 2: Runtime stage
FROM alpine:${ALPINE_TAG}

# Re-declare ARGs for use in labels (ARGs don't persist across stages)
ARG HAMCLOCK_VERSION=4.22
ARG ALPINE_TAG=3.23.3

LABEL org.opencontainers.image.authors="W4GHG" \
      org.opencontainers.image.version="${HAMCLOCK_VERSION}" \
      org.opencontainers.image.description="HamClock Web Application" \
      org.opencontainers.image.source="https://www.clearskyinstitute.com/ham/HamClock/" \
      org.opencontainers.image.vendor="Community" \
      org.opencontainers.image.licenses="Unknown" \
      org.opencontainers.image.base.name="alpine:${ALPINE_TAG}"
WORKDIR /app

# Install runtime dependencies and create user in a single layer
# tzdata: Critical for HamClock to handle timezones correctly
# shadow/su-exec: Required for the PUID/PGID security feature
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache bash curl libstdc++ libgcc shadow su-exec tzdata && \
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

EXPOSE 8081

HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://127.0.0.1:8081/live.html || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["hamclock-1600x960"]
