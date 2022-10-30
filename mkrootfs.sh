#!/bin/zsh
## HoloISO rootfs generator

# Start by allocating a RAW disk file
sudo fallocate -l 20G rootfs.img

# Mount it
sudo losetup -f -P rootfs.img

# Build the goddamn image
sudo pacman -S --noconfirm btrfs-progs
mkdir /tmp/rootfs_install
HOLO_INSTALL_DIR="${HOLO_INSTALL_DIR:-/tmp/rootfs_install}"
sudo mkfs -t btrfs /dev/loop3
sudo btrfs filesystem label /dev/loop3 holo-root
sudo mount /dev/loop3 ${HOLO_INSTALL_DIR}

# Start the installation
SYSTEM_LOCALE="${SYSTEM_LOCALE:-en_US.UTF-8 UTF-8}"
CMD_PACMAN_INSTALL=(/usr/bin/pacman --noconfirm -S --needed --disable-download-timeout --overwrite="*")
CMD_PACMAN_UPDATE=(/usr/bin/pacman -Sy)

sudo pacstrap ${HOLO_INSTALL_DIR} base base-devel intel-ucode amd-ucode linux-neptune linux-neptune-headers core-main/linux-firmware
sudo cp post_install/pacman.conf ${HOLO_INSTALL_DIR}/etc/pacman.conf
sudo cp post_install/mirrorlist_steamos ${HOLO_INSTALL_DIR}/etc/pacman.d/mirrorlist
sudo cp post_install/mirrorlist_holoiso ${HOLO_INSTALL_DIR}/etc/pacman.d/holo_mirrorlist
sudo arch-chroot ${HOLO_INSTALL_DIR} ${CMD_PACMAN_UPDATE}
sudo arch-chroot ${HOLO_INSTALL_DIR} ${CMD_PACMAN_INSTALL} holoiso/grub breeze-grub efibootmgr inetutils mkinitcpio neofetch networkmanager sddm-wayland
sudo arch-chroot ${HOLO_INSTALL_DIR} systemctl enable NetworkManager systemd-timesyncd sddm
echo "\nSetting up locale..."
sudo echo "${SYSTEM_LOCALE}" >> ${HOLO_INSTALL_DIR}/etc/locale.gen
sudo arch-chroot ${HOLO_INSTALL_DIR} locale-gen
sudo echo "LANG=$(echo ${SYSTEM_LOCALE} | cut -d' ' -f1)" > ${HOLO_INSTALL_DIR}/etc/locale.conf
echo "\nInstalling DE..."
sudo arch-chroot ${HOLO_INSTALL_DIR} ${CMD_PACMAN_INSTALL} pipewire-jack
sudo arch-chroot ${HOLO_INSTALL_DIR} ${CMD_PACMAN_INSTALL} holoiso-main holoiso-updateclient wireplumber ${GAMEPAD_DRV}
sudo arch-chroot ${HOLO_INSTALL_DIR} ${CMD_PACMAN_INSTALL} mesa lib32-mesa nvidia-utils nvidia-dkms lib32-nvidia-utils vulkan-intel lib32-vulkan-intel holoiso/gamescope
sudo arch-chroot ${HOLO_INSTALL_DIR} ${CMD_PACMAN_INSTALL} flatpak packagekit-qt5 rsync unzip vim
sudo arch-chroot ${HOLO_INSTALL_DIR} systemctl enable cups bluetooth sddm holoiso-reboot-tracker
sudo arch-chroot ${HOLO_INSTALL_DIR} flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo arch-chroot ${HOLO_INSTALL_DIR} sed -i "s/steamdeck_stable/steamdeck_publicbeta" /usr/bin/steam

echo "\nImage creation finished. Unmount rootfs."
sudo umount -l /dev/loop3
sudo losetup -d /dev/loop3

echo "\nPackaging and uploading..."
sudo gzip -c rootfs.img  > rootfs.img.gz
curl --upload-file rootfs.img.gz https://transfer.sh/rootfs_holoiso_$(date +%Y%m%d.%H%M).img.gz