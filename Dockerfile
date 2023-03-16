#build with "docker build ggilman/hamclock:latest ."
FROM alpine:latest
MAINTAINER George Gilman ggilman@gmail.com
WORKDIR /app

RUN apk update && \
	apk add \
	curl make g++ bash unzip


#Below taken from https://github.com/SP5D/hamclock-web-docker/blob/main/Dockerfile
#It solves issues I intended to fix. May eventually fork that project instead of separate maintenance.
SHELL ["/bin/bash", "-c"]

RUN resolution_variants=("800x480" "1600x960" "2400x1440" "3200x1920") && \
    tempdir=$(mktemp -d) && \
    cd ${tempdir} && \
    curl -O https://www.clearskyinstitute.com/ham/HamClock/ESPHamClock.zip && \
    unzip ESPHamClock.zip && \
    cd ESPHamClock && \
    for resolution in ${resolution_variants[*]}; \
    do \
        make -j $(nproc --all) hamclock-web-${resolution} && \
        make install && \
        mv /usr/local/bin/hamclock /usr/local/bin/hamclock-${resolution}; \
    done; \
    cd && \
    rm -r ${tempdir}

#Create link for data persistance
RUN ln -s /root/.hamclock /config

#Expose web view port
EXPOSE 8081
CMD [ "hamclock-1600x960" ]
