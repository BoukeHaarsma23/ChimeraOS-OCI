FROM scratch
COPY mnt /
COPY rootfs /
COPY manifest /

# Run commands in container
RUN /chimera-install.sh && rm /chimera-install.sh
RUN pacman-key --init && pacman-key --populate
