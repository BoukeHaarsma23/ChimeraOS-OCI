FROM scratch
COPY mnt /
COPY rootfs /

# post installation steps.
RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime
RUN locale-gen
RUN systemctl enable systemd-timesyncd.service
