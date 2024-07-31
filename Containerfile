FROM scratch
COPY mnt /
COPY rootfs /
COPY manifest /
ARG VERSION=""
# Run commands in container
RUN /chimera-install.sh ${VERSION} && rm /chimera-install.sh
