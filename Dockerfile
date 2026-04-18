FROM ghcr.io/linuxserver/baseimage-selkies:debiantrixie

# title
ENV TITLE=Brasfoot \
  PIXELFLUX_WAYLAND=true

# add local files
COPY /root /

# ports and volumes
EXPOSE 3000

VOLUME /config