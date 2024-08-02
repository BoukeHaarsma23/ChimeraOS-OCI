ARG BUILDER="ghcr.io/boukehaarsma23/chimeraos-builder:main"
ARG SHA=""

FROM ${BUILDER} as builder

FROM archlinux:base

COPY rootfs /
COPY manifest /
COPY --from=builder /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist
COPY --from=builder /tmp/repo /tmp/repo

# Run commands in container
RUN sed -i '/^\[core\]/s/^/\[chos\]\nSigLevel = Optional TrustAll\nServer = file:\/\/\/tmp\/repo\n\n/' /etc/pacman.conf && \
    /chimera-install.sh ${SHA} && \
    rm /chimera-install.sh
