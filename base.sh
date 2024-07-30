# This allows using pacstrap -N in a rootless container.
echo 'root:1000:5000' > /etc/subuid
echo 'root:1000:5000' > /etc/subgid

# Install packages in our mount which we copy into a container
pacstrap -c -G mnt \
	amd-ucode \
	base \
	cpupower \
	distrobox \
	efibootmgr \
	flatpak \
	gamescope \
	gamescope-session-git \
	gamescope-session-steam-git \
	cosmic-applets-git \
	cosmic-icons-git \
	cosmic-randr-git \
	cosmic-applibrary-git \
	cosmic-launcher-git \
	cosmic-screenshot-git \
	cosmic-bg-git \
	cosmic-notifications-git \
	cosmic-settings-daemon-git \
	cosmic-comp-git \
	cosmic-osd-git \
	cosmic-settings-git \
	cosmic-greeter-git \
	cosmic-panel-git \
	cosmic-workspaces-git \
	linux \
	chos/lib32-mesa \
	chos/lib32-vulkan-mesa-layers \
	chos/lib32-vulkan-radeon \
	chos/mesa \
	chos/mesa-vdpau \
	chos/vulkan-mesa-layers \
	chos/vulkan-radeon \
	nano \
	steam \
	which \
	zenergy-dkms-git