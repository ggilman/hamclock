# 1. Global ARGs (Must be defined before FROM to be used in FROM)
# Default to 3.23 in case you build manually without the script
ARG ALPINE_TAG=3.23

# Stage 1: Build stage
FROM alpine:${ALPINE_TAG} AS builder
WORKDIR /build

# ARG for versioning - passed from your build script
ARG HAMCLOCK_VERSION=4.22

# Install build dependencies
# binutils is included for the 'strip' command
RUN apk add --no-cache bash curl make g++ unzip linux-headers build-base binutils

# Layer: Download & Build
SHELL ["/bin/bash", "-c"]

# Echoing the version ensures Docker invalidates this cache layer if the version changes
RUN echo "Building HamClock Version: ${HAMCLOCK_VERSION}" && \
    curl -O https://www.clearskyinstitute.com/ham/HamClock/ESPHamClock.zip && \
    unzip ESPHamClock.zip && \
    cd ESPHamClock && \
    chmod +x Makefile && \
    # ---------------------------------------------------------
    # COMPATIBILITY FIX: Force permissive mode
    # This ensures compilation succeeds even if source code has C++ compliance issues
    sed -i 's/^\(CXXFLAGS =\)/\1 -fpermissive/' Makefile && \
    # ---------------------------------------------------------
    resolutions=("800x480" "1600x960" "2400x1440" "3200x1920") && \
    for res in "${resolutions[@]}"; do \
        echo "Building ${res}..." && \
        make -j$(nproc) hamclock-web-${res} && \
        make install && \
        mv /usr/local/bin/hamclock /usr/local/bin/hamclock-${res} && \
        # Strip debug symbols to reduce image size by ~30%
        strip /usr/local/bin/hamclock-${res} && \
        make clean; \
    done

# Stage 2: Runtime stage
FROM alpine:${ALPINE_TAG}
LABEL org.opencontainers.image.authors="ggilman@gmail.com"
WORKDIR /app

# Install runtime dependencies
# tzdata: Critical for HamClock to handle timezones correctly
# shadow/su-exec: Required for the PUID/PGID security feature
RUN apk update && \
    apk add --no-cache bash curl libstdc++ libgcc shadow su-exec tzdata && \
    rm -rf /var/cache/apk/*

# Create generic user
RUN addgroup -S hamuser && adduser -S hamuser -G hamuser

# Copy binaries
COPY --from=builder /usr/local/bin/hamclock-* /usr/local/bin/

# Copy entrypoint script (Ensure this file exists in your folder!)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Setup Folders & Symlinks for PUID/PGID support
# This ensures it works for BOTH root users (legacy) and secure users (new)
RUN mkdir -p /config && \
    ln -s /config /root/.hamclock && \
    ln -s /config /home/hamuser/.hamclock

EXPOSE 8081

HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
    CMD curl -f http://127.0.0.1:8081/live.html || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["hamclock-1600x960"]
