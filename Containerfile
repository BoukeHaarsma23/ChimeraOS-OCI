FROM scratch
COPY mnt /
COPY rootfs /
COPY manifest /
ARG SHA=""
# Run commands in container
RUN /chimera-install.sh ${SHA} && rm /chimera-install.sh
