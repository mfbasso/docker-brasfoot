FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie

# title
ENV TITLE=Brasfoot \
  PIXELFLUX_WAYLAND=true

# add local files
COPY /root /

RUN chmod +x /root/bin/brasfoot.AppImage
RUN mkdir -p /data && chmod 0777 /data

# ports and volumes
EXPOSE 3000

VOLUME ["/config", "/data"]