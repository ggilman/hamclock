#build with "docker build ggilman/hamclock:latest ."
FROM alpine:latest
MAINTAINER George Gilman ggilman@gmail.com
WORKDIR /app
RUN apk update && apk add curl make g++ unzip
RUN rm -fr ESPHamClock
RUN curl -O https://www.clearskyinstitute.com/ham/HamClock/ESPHamClock.zip
RUN unzip ESPHamClock.zip
WORKDIR /app/ESPHamClock
RUN make -j 4 hamclock-web-1600x960
RUN make install
#Expose web view port
EXPOSE 8081
ENTRYPOINT ["/app/ESPHamClock/hamclock-web-1600x960"]
