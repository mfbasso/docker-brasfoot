# Stage 1: Download and extract Brasfoot installer
FROM alpine:3.20 AS builder

RUN apk add --no-cache wget p7zip

RUN wget -q -O /tmp/brasfoot22-23.exe "https://www.brasfoot.com/download22/brasfoot22-23.exe"

RUN mkdir -p /opt/brasfoot && \
  7z x -y /tmp/brasfoot22-23.exe -o/opt/brasfoot/ || true && \
  test -f /opt/brasfoot/bf22-23.exe && \
  icon="$(find /opt/brasfoot -type f -iname '*.png' | head -n 1 || true)" && \
  if [ -n "$icon" ]; then cp -f "$icon" /opt/brasfoot/brasfoot.png; fi && \
  rm -f /tmp/brasfoot22-23.exe

# Stage 2: Java 8 runtime
FROM eclipse-temurin:8-jre-jammy AS java8

# Stage 3: Runtime image
FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie

# title
ENV TITLE=Brasfoot \
  NO_FULL=true \
  NO_DECOR=true \
  PIXELFLUX_WAYLAND=true

COPY --from=builder /opt/brasfoot /opt/brasfoot
COPY --from=java8 /opt/java/openjdk /usr/local/java8

# add local files
COPY /root /

RUN chmod +x /usr/bin/brasfoot

# ports and volumes
EXPOSE 3000

VOLUME ["/config", "/data"]