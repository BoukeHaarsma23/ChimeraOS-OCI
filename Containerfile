ARG BUILDER="ghcr.io/boukehaarsma23/chimeraos-builder:main"
FROM ${BUILDER} as builder

FROM archlinux:base as frzr-image
ARG SHA=""
ARG VARIANT=""
COPY rootfs /
COPY manifest /
COPY --from=builder /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist
COPY --from=builder /tmp/repo /tmp/repo

# Run commands in container
RUN cp /etc/pacman.conf /etc/pacman.conf.bak && \
    sed -i '/^\[core\]/s/^/\[chos\]\nSigLevel = Optional TrustAll\nServer = file:\/\/\/tmp\/repo\n\n/' /etc/pacman.conf && \
    /chimera-install.sh ${SHA} ${VARIANT} && \
    rm /chimera-install.sh && \
    rm -rf /tmp/repo && \
    mv /etc/pacman.conf.bak /etc/pacman.conf

FROM scratch
COPY --from=frzr-image / /