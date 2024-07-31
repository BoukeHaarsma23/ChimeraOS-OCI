set -e
set -x

# This will prevent frzr bootloader from erroring when installing kernels
# due to the pacman hook being executed at kernel-install time
export FRZR_IMAGE_GENERATION=1

source /manifest
pacman-key --init
pacman-key --populate

# Reinstall linux as workaround now for initramfs
pacman --noconfirm -S linux

if [ -n "${PACKAGE_OVERRIDES}" ]; then 
	pacman --noconfirm -U --overwrite '*' ${PACKAGE_OVERRIDES}; 
fi

echo "LANG=en_US.UTF-8" > /etc/locale.conf
locale-gen

# enable services
systemctl enable ${SERVICES}

# enable user services
systemctl --global enable ${USER_SERVICES}

# disable root login
passwd --lock root

# add root to the frzr group
sudo usermod -a -G frzr root

# create user
groupadd -r autologin
useradd -m ${USERNAME} -G autologin,wheel,plugdev,frzr
echo "${USERNAME}:${USERNAME}" | chpasswd

# set the default editor, so visudo works
echo "export EDITOR=/usr/bin/vim" >> /etc/bash.bashrc

echo "[Seat:*]
autologin-user=${USERNAME}
" > /etc/lightdm/lightdm.conf.d/00-autologin-user.conf

echo "${SYSTEM_NAME}" > /etc/hostname

# enable multicast dns in avahi
sed -i "/^hosts:/ s/resolve/mdns resolve/" /etc/nsswitch.conf

# configure ssh
echo "
AuthorizedKeysFile	.ssh/authorized_keys
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
PrintMotd no # pam does that
Subsystem	sftp	/usr/lib/ssh/sftp-server
" > /etc/ssh/sshd_config

# Write the fstab file
# WARNING: mounting partitions using LABEL exposes us to a bug where multiple disks cannot have frzr systems and how to solve this still is an open question
echo "
LABEL=frzr_root /frzr_root btrfs     defaults,x-initrd.mount,subvolid=5,rw,noatime,nodatacow                                                                                                                                                                                                                                                                                                                                                                                                                                                           0   2
LABEL=frzr_root /home      btrfs     defaults,x-systemd.rw-only,subvol=/home,rw,noatime,nodatacow,nofail                                                                                                                                                                                                                                                                                                                                                                                                                                               0   0
overlay         /boot      overlay   defaults,x-systemd.requires-mounts-for=/frzr_root,x-systemd.requires-mounts-for=/sysroot/frzr_root,x-initrd.mount,lowerdir=/sysroot/frzr_root/kernels/boot:/sysroot/frzr_root/device_quirks/${SYSTEM_NAME}-${VERSION}/boot:/sysroot/boot,upperdir=/sysroot/frzr_root/deployments_data/${SYSTEM_NAME}-${VERSION}/boot_overlay/upperdir,workdir=/sysroot/frzr_root/deployments_data/${SYSTEM_NAME}-${VERSION}/boot_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,comment=bootoverlay             0   0
overlay         /usr       overlay   defaults,x-systemd.requires-mounts-for=/frzr_root,x-systemd.requires-mounts-for=/sysroot/frzr_root,x-initrd.mount,lowerdir=/sysroot/frzr_root/kernels/usr:/sysroot/frzr_root/device_quirks/${SYSTEM_NAME}-${VERSION}/usr:/sysroot/usr,upperdir=/sysroot/frzr_root/deployments_data/${SYSTEM_NAME}-${VERSION}/usr_overlay/upperdir,workdir=/sysroot/frzr_root/deployments_data/${SYSTEM_NAME}-${VERSION}/usr_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,comment=usroverlay                   0   0
overlay         /etc       overlay   defaults,x-systemd.requires-mounts-for=/frzr_root,x-systemd.requires-mounts-for=/sysroot/frzr_root,x-initrd.mount,x-systemd.rw-only,lowerdir=/sysroot/frzr_root/kernels/etc:/sysroot/frzr_root/device_quirks/${SYSTEM_NAME}-${VERSION}/etc:/sysroot/etc,upperdir=/sysroot/frzr_root/deployments_data/${SYSTEM_NAME}-${VERSION}/etc_overlay/upperdir,workdir=/sysroot/frzr_root/deployments_data/${SYSTEM_NAME}-${VERSION}/etc_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,comment=etcoverlay 0   0
overlay         /var       overlay   defaults,x-systemd.requires-mounts-for=/frzr_root,x-systemd.requires-mounts-for=/sysroot/frzr_root,x-initrd.mount,x-systemd.rw-only,lowerdir=/sysroot/frzr_root/kernels/var:/sysroot/frzr_root/device_quirks/${SYSTEM_NAME}-${VERSION}/var:/sysroot/var,upperdir=/sysroot/frzr_root/deployments_data/${SYSTEM_NAME}-${VERSION}/var_overlay/upperdir,workdir=/sysroot/frzr_root/deployments_data/${SYSTEM_NAME}-${VERSION}/var_overlay/workdir,index=off,metacopy=off,xino=off,redirect_dir=off,comment=varoverlay 0   0
" > /etc/fstab

echo "
LSB_VERSION=1.4
DISTRIB_ID=${SYSTEM_NAME}
DISTRIB_RELEASE=\"${LSB_VERSION}\"
DISTRIB_DESCRIPTION=${SYSTEM_DESC}
" > /etc/lsb-release

echo "NAME=\"${SYSTEM_DESC}\"
VERSION=\"${DISPLAY_VERSION}\"
VERSION_ID=\"${VERSION_NUMBER}\"
BUILD_ID=\"${BUILD_ID}\"
PRETTY_NAME=\"${SYSTEM_DESC} ${DISPLAY_VERSION}\"
ID=${SYSTEM_NAME}
ID_LIKE=arch
ANSI_COLOR=\"1;31\"
HOME_URL=\"${WEBSITE}\"
DOCUMENTATION_URL=\"${DOCUMENTATION_URL}\"
BUG_REPORT_URL=\"${BUG_REPORT_URL}\"" > /usr/lib/os-release

# install extra certificates
trust anchor --store /extra_certs/*.crt

# run post install hook
postinstallhook

# record installed packages & versions
pacman -Q > /manifest

# preserve installed package database
mkdir -p /usr/var/lib/pacman
cp -a /var/lib/pacman/local /usr/var/lib/pacman/

# Since frzr pre-v1.0.0 has an hardcoded cp of /boot/vmlinuz-linux and /boot/initramfs-linux.img
# create two empty files so that the cp command won't fail: these will be  replaced by a migration hook.
#
# Note: The following is kept for compatibility with older frzr
# 		This can safely be removed when the compatibility with
# 		frzr pre-v1.0.0 will be dropped
if [ "${KERNEL_PACKAGE}" = "linux" ]; then
	echo "Kernel is named 'linux' nothing to do."
else
	touch /boot/vmlinuz-linux
	touch /boot/initramfs-linux.img
fi

# clean up/remove unnecessary files
# Keep every file in /var except for logs (populated by GitHub CI)
# the pacman database: it was backed up to another location and
# will be restored by an unlock hook
rm -rf \
/extra_certs \
/home \
/var/log \
/var/lib/pacman/local \

rm -rf ${FILES_TO_DELETE}

# create necessary directories
mkdir -p /home
mkdir -p /frzr_root
mkdir -p /efi
mkdir -p /var/log