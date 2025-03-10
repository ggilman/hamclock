# Stage 1: Build stage
FROM alpine:latest AS builder
WORKDIR /build

# Install bash first
RUN apk update && apk upgrade && apk add bash

SHELL ["/bin/bash", "-c"]

RUN apk add curl make g++ unzip linux-headers build-base

RUN resolution_variants=("800x480" "1600x960" "2400x1440" "3200x1920") && \
    tempdir=$(mktemp -d) && \
    cd ${tempdir} && \
    curl -O https://www.clearskyinstitute.com/ham/HamClock/ESPHamClock.zip && \
    unzip ESPHamClock.zip && \
    cd ESPHamClock && \
    chmod +x Makefile && \
    sed -i 's/^\(CXXFLAGS =\)/\1 -fpermissive/' Makefile && \
    for resolution in ${resolution_variants[*]}; \
    do \
        make -j 4 hamclock-web-${resolution} 2>&1 | tee make_output.log; \
        make install; \
        mv /usr/local/bin/hamclock /usr/local/bin/hamclock-${resolution}; \
        make clean; \
    done && cat make_output.log

# Stage 2: Runtime stage
FROM alpine:latest
LABEL org.opencontainers.image.authors="ggilman@gmail.com"
WORKDIR /app

RUN apk update && apk add curl libstdc++ libgcc && rm -rf /var/cache/apk/*

COPY --from=builder /usr/local/bin/hamclock-* /usr/local/bin/

RUN ln -s /root/.hamclock /config

VOLUME /config

EXPOSE 8081

HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
    CMD sleep 5 && curl -f http://127.0.0.1:8081/live.html || exit 1

CMD ["hamclock-1600x960"]
