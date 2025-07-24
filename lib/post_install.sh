echo "---Installing paru - rust-based AUR helper (User password required) ---"
sudo mkdir -p /tmp/paru
sudo chown -R ${USER} /tmp/paru
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru
makepkg -si --noconfirm
cd
sleep 2
echo "Installing system packages, tools and messaging apps. Agree to handle jack2 conflict for pipewire-jack package. (User password and several confirmations will be required)" 
paru -Syu --needed \
    pipewire \
    pipewire-audio \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    pipewire-libcamera \
    pipewire-v4l2 \
    gst-plugin-pipewire \
    libpipewire \
    wireplumber \
    wireplumber-docs \
    libwireplumber \
    pavucontrol \
    sof-firmware \
    libinput \
    otf-font-awesome \
    ttf-liberation \
    ttf-liberation-mono-nerd \
    ttf-jetbrains-mono-nerd \
    ttf-ms-win11-auto \
    vivaldi-snapshot \
    vivaldi-snapshot-ffmpeg-codecs \
    signal-desktop \
    vesktop-bin \
    zapzap \
    mpv \
    oh-my-zsh-git \
    oh-my-posh-bin \
    p7zip \
    p7zip-gui \
    rsync \
    zoxide \
    wget

systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service

gum confirm "Install OnlyOffice desktop editors? (Free open-source Microsoft Office clone)" && paru -S --noconfirm onlyoffice-bin

gum confirm "Install development tools?" && paru -S --noconfirm \
    code \
    drawio-desktop-bin \
    jdk-temurin \
    jetbrains-toolkit \

# KVM
gum confirm "Install packages for KVM/QEMU with virt-manager?" && paru -S --noconfirm \
    virt-manager \
    libvirt \
    libvirt-dbus \
    libvirt-glib \
    libvirt-python \
    libvirt-storage-gluster \
    libvirt-storage-iscsi-direct \
    qemu-audio-alsa \
    qemu-audio-dbus \
    qemu-audio-pipewire \
    qemu-audio-sdl \
    qemu-audio-spice \
    qemu-base \
    qemu-block-curl \
    qemu-block-iscsi \
    qemu-block-nfs \
    qemu-block-ssh \
    qemu-chardev-baum \
    qemu-chardev-spice \
    qemu-common \
    qemu-desktop \
    qemu-docs \
    qemu-emulators-full \
    qemu-guest-agent \
    qemu-hw-display-qxl \
    qemu-hw-display-virtio-gpu \
    qemu-hw-display-virtio-gpu-gl \
    qemu-hw-display-virtio-gpu-pci \
    qemu-hw-display-virtio-gpu-pci-gl \
    qemu-hw-uefi-vars \
    qemu-hw-usb-host \
    qemu-hw-usb-redirect \
    qemu-img \
    qemu-system-x86 \
    qemu-system-x86-firmware \
    qemu-tools \
    qemu-ui-egl-headless \
    qemu-ui-gtk \
    qemu-ui-opengl \
    qemu-ui-sdl \
    qemu-ui-spice-app \
    qemu-ui-spice-core \
    qemu-user \
    qemu-user-static \
    qemu-user-static-binfmt \
    dnsmasq \
    openbsd-netcat \
    dmidecode && \
    sudo systemctl enable --now libvirtd.service libvirtd.socket

# Gaming
gum confirm "Install packages for gaming?" && paru -S --noconfirm \
    steam \
    lutris \
    heroic-games-launcher-bin \
    wine-staging \
    winetricks \
    wine-mono \
    wine-gecko \
    gamemode \
    lib32-gamemode \
    mangohud \
    mesa \
    lib32-mesa \
    xf86-video-amdgpu \
    vulkan-tools \
    lib32-vulkan-icd-loader \
    vulkan-icd-loader \
    vulkan-radeon \
    lib32-vulkan-radeon

if [ ! -d ${HOME}/.oh-my-zsh ]; then
    mkdir -p ${HOME}/.oh-my-zsh/custom
    cat<<'ZSH_EOF' > ${HOME}/.oh-my-zsh/custom/environment.zsh
export TERM=xterm-256color

autoload -U select-word-style
select-word-style bash

bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char
bindkey "^[[3;5~" kill-word
bindkey "^H" backward-kill-word
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

PATH=$USER/.local/sh:$USER/.local/bin:$PATH
ZSH_EOF
fi


if [ ! -d ${HOME}/.config/kitty ]; then
cat<<'KITTY_EOF' > ${HOME}/.config/kitty/custom.conf
term xterm-256color
enable_audio_bell no
map ctrl+delete no_op
map ctrl+shift+delete send_text all \x1b[3;5~
KITTY_EOF
fi

gum confirm "Configure Swedish locale settings?" && for se_locale in \
      "LC_NUMERIC=sv_SE.UTF-8" \
      "LC_TIME=sv_SE.UTF-8" \
      "LC_MONETARY=sv_SE.UTF-8" \
      "LC_PAPER=sv_SE.UTF-8" \
      "LC_MEASUREMENT=sv_SE.UTF-8"
    do
      echo "${se_locale}" | sudo tee -a /etc/locale.conf
    done

echo "Removing post-install script launcher from autostart..."
rm ${HOME}/.config/autostart/kitty-post-install.desktop

gum confirm "Reboot recommended, continue?" && systemctl reboot
