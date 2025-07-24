#!/bin/bash
# lib/install.sh - Base system installation and configuration functions
# Install base system
install_base_system() {
  echo "Installing base system..."
  pacstrap /mnt base \
    linux-zen \
    linux-zen-headers \
    linux-firmware \
    btrfs-progs \
    base-devel \
    amd-ucode \
    efibootmgr \
    firewalld \
    networkmanager \
    plymouth \
    plasma-meta \
    sudo
  # Generate fstab
  genfstab -U /mnt >> /mnt/etc/fstab
}

# Configure the installed system
configure_system() {
  echo "Configuring system..."
  create_chroot_script
  arch-chroot /mnt /configure_system.sh
  rm /mnt/configure_system.sh
  sleep 2
  cryptsetup open --batch-mode ${USRVOL_PART} usrvol <<< "$LUKS_PASSWORD"
  sleep 5
  mount -t btrfs -o subvol=@home,"$BTRFS_OPTS" /mnt/home
  echo ${SCRIPT_DIR}
  ls ${SCRIPT_DIR}/lib
  df -h
  ls -lav /mnt/home
  sleep 20
  cp ${SCRIPT_DIR}/lib/post_install.sh /mnt/home/${USERNAME}/post_install.sh
  arch-chroot /mnt chown $USERNAME:$USERNAME /home/${USERNAME}/post_install.sh && chmod +x /home/${USERNAME}/post_install.sh
  cp -r ${SCRIPT_DIR}/lib/.local /mnt/home/${USERNAME}/
  arch-chroot /mnt chmod +x /home/${USERNAME}/.local/bin/timeshift-wayland
  cp -r ${SCRIPT_DIR}/conf/usr/.* /mnt/home/${USERNAME}/
  arch-chroot /mnt chown -R $USERNAME:$USERNAME /home/${USERNAME}/.*
  ls -lav /mnt/home/${USERNAME}
  sleep 5
}

# Create configuration script for chroot environment
create_chroot_script() {
  cat > /mnt/configure_system.sh << EOF
  #!/bin/bash
  # Configuration script for chroot environment
  set -e

  # Set timezone
  echo "Setting timezone..."
  ln -sf /usr/share/zoneinfo/TIMEZONE_PLACEHOLDER /etc/localtime
  hwclock --systohc

  # Prereqs for arch-chroot env
  echo "Enabling extra and multilib repositories..."
  sed -i \
    -e '/^#\?\[extra\]/s/^#//' \
    -e '/^\[extra\]/,+1{/^#\?Include.*mirrorlist/s/^#//}' \
    -e '/^#\?\[multilib\]/s/^#//' \
    -e '/^\[multilib\]/,+1{/^#\?Include.*mirrorlist/s/^#//}' /etc/pacman.conf
  pacman -Syu --noconfirm --needed \
    dolphin \
    audiocd-kio \
    baloo \
    dolphin-plugins \
    kio-admin \
    kio-gdrive \
    kompare \
    ffmpegthumbs \
    icoutils \
    kdegraphic-thumbnailers \
    kdesdk-thumbnailers \
    kimageformats \
    libappimage \
    qt6-imageformats \
    taglib \
    kde
    nmap \
    neovim \
    pacman-contrib \
    git \
    gum \
    kitty \
    realtime-privileges \
    ttf-jetbrains-mono-nerd \
    timeshift \
    tmux \
    zsh \
    zsh-autocomplete \
    zsh-autosuggestions \
    zsh-completions \
    zsh-doc \
    zsh-history-substring-search \
    zsh-syntax-highlighting

  # User configuration
  echo "Creating user USERNAME_PLACEHOLDER..."
  useradd -m -G realtime,storage,wheel -s /bin/zsh "USERNAME_PLACEHOLDER"
  echo 'USERNAME_PLACEHOLDER:USER_PASSWORD_PLACEHOLDER' | chpasswd -c SHA512

  # Root configuration
  echo 'root:ROOT_PASSWORD_PLACEHOLDER' | chpasswd -c SHA512
  
  # Sudo config
  sed -i -e '/^#\? %wheel.*) ALL.*/s/^# //' /etc/sudoers
  sleep 2

  # Set locale
  echo "Setting locale..."
  mv /etc/locale.gen /etc/locale.gen.bak
  for locale in \
      "en_US.UTF-8 UTF-8" \
      "en_GB.UTF-8 UTF-8" \
      "sv_SE.UTF-8 UTF-8"
  do
    echo "${locale}" >> /etc/locale.gen
  done
  locale-gen
  echo "LANG=en_GB.UTF-8" > /etc/locale.conf
  sleep 2

  # Install and configure systemd-boot
  echo "Installing systemd-boot..."
  bootctl install
  efibootmgr --create --disk $DISK --part 1 --label "netboot.xyz" --loader /EFI/netboot.xyz/netboot.xyz.efi
  
  # Create swapfile
  echo "Creating 8GB swapfile..."
  btrfs filesystem mkswapfile --size 8g --uuid clear /.swapvol/swapfile
  swapon /.swapvol/swapfile
  echo "/.swapvol/swapfile none swap defaults 0 0" >> /etc/fstab

  # Configure Plymouth theme
  echo "Setting Monoarch Plymouth theme..."
  git clone https://aur.archlinux.org/plymouth-theme-monoarch.git /tmp/plymouth-theme-monoarch
  chown -R nobody /tmp/plymouth-theme-monoarch
  cd /tmp/plymouth-theme-monoarch
  sudo -u nobody makepkg -s
  cd
  pacman -U --noconfirm "/tmp/plymouth-theme-monoarch/"*.pkg.tar.zst

  # Enable package cache cleanup
  echo "Enabling automatic package cache cleanup..."
  systemctl enable firewalld.service NetworkManager.service paccache.timer sddm.service
  
  # Cleanup
  echo "Cleaning up package cache..."
  pacman -Scc --noconfirm
  echo "Rebuilding initramfs and setting default Plymouth theme to monoarch"
  plymouth-set-default-theme -R monoarch
EOF
  
  # Replace chroot script placeholders
  sed -i -e "s/USERNAME_PLACEHOLDER/$USERNAME/g" /mnt/configure_system.sh
  sed -i -e "s/USER_PASSWORD_PLACEHOLDER/$USER_PASSWORD/g" /mnt/configure_system.sh
  sed -i -e "s/ROOT_PASSWORD_PLACEHOLDER/$ROOT_PASSWORD/g" /mnt/configure_system.sh
  sed -i -e "s|TIMEZONE_PLACEHOLDER|$TIMEZONE|g" /mnt/configure_system.sh
  chmod +x /mnt/configure_system.sh
  
  # Copy systemd-boot files into system and configuring
  cp -r "${SCRIPT_DIR}/conf/boot" /mnt
  arch-chroot /mnt chown -R 0:0 /boot/loader
  sed -i -e "s/SYSVOL_UUID_PLACEHOLDER/$(blkid -s UUID -o value $SYSVOL_PART)/" /mnt/boot/loader/entries/arch.conf

  # Copy system conf files into system and configuring
  cp -r "${SCRIPT_DIR}/conf/etc" /mnt
  arch-chroot /mnt chown -R 0:0 /etc/{crypttab,mkinitcpio.conf,hosts,vconsole.conf}
  sed -i -e "s/USRVOL_UUID_PLACEHOLDER/$(blkid -s UUID -o value $USRVOL_PART)/" /mnt/etc/crypttab
  sed -i -e "s/HOSTNAME_PLACEHOLDER/$HOSTNAME/g" \
    -e "s/LANDOMAIN_PLACEHOLDER/$LANDOMAIN/g" \
    -e "s/DOMAINSUFFIX_PLACEHOLDER/$DOMAINSUFFIX/g" /mnt/etc/hosts
  echo "$HOSTNAME" > /mnt/etc/hostname
}
