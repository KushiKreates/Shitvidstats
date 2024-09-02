#!/bin/bash
[ -z "$HOME" ] && [ -d "/home/container" ] && export HOME="/home/container"
export HOSTNAME="$(cat /proc/sys/kernel/hostname)"
# Copyright(C) 2024 nulldaemon. All rights reserved.
# !!! Unauthorized copies of this software will be treated lawfully. !!!
# *** THIS SOFTWARE IS UNDER PROPRIETARY ASSET. ALL BUT NOT LIMITED TO ACTIONS
#     SUCH AS COPYING, DISTRIBUTING, MODIFYING THE SOFTWAE WITHOUT PROPER AUTH
#     -ORIZATION IS CONSIDERED A "BREACH OF CONTRACT" AND CAN BE USED AGAINST
#     YOU AT ANY CIRCUMSTANCES. FAILING TO FOLLOW MAY LEAD TO SEVERE LEGAL CON
#     -SEQUENCES.                                  < nulldaemon license, v1.0 > ***

# >> ⚙️ User-Configuration <<
install_path="$HOME/cache/$(echo "$HOSTNAME" | md5sum | sed 's+ .*++g')"
shared_path="$HOME/shared"
user_passwd="$HOSTNAME"
retailer_mode=false
DOCKER_RUN="$install_path/dockerd \
    --kill-on-exit -r $install_path -b /dev -b /proc -b /sys -b /tmp \
    -b $install_path/etc/hostname:/proc/sys/kernel/hostname \
    -b $install_path$HOME/shared:$shared_path \
    -b $install_path:$install_path /bin/sh -c"

getarch() {
  case "$(uname -m)" in
  x86_64)
    [ -z "$1" ] && echo "x86_64" || echo "$1"
    ;;
  aarch64)
    [ -z "$2" ] && echo "aarch64" || echo "$2"
    ;;
  *)
    echo "Unsupport architecture: $(uname -m)"
    exit 1
    ;;
  esac
}

if_x86_64() { [ "$(uname -m)" == "x86_64" ] && echo "$1"; }

# [ 🖧 Mirrors ]
mirror_alpine="https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/$(getarch)/alpine-minirootfs-3.20.2-$(getarch).tar.gz"
mirror_proot="https://github.com/proot-me/proot/releases/download/v5.3.0/proot-v5.3.0-$(getarch)-static"

d.stat() { echo -ne "\033[1;37m==> \033[1;34m$@\033[0m\n"; }
d.dftr() { echo -ne "\033[1;33m!!! DISABLED FEATURE: \033[1;31m$@ \033[1;33m!!!\n"; }
d.warn() { echo -ne "\033[1;33mwarning: \033[1;31m$@\[033;0m\n"; }

die() {
  echo -ne "\n\033[41m               \033[1;37mA FATAL ERROR HAS OCCURED               \033[0m\n"
  echo -ne "\033[1;33m   Please save the error logs and dm \033[1;32mn5ll\033[1;33m on\033[1;35m Discord\033[1;33m\033[0m\n"
  sleep 5
  exit 1
}

printlogo() {
  printf "\033[1m[[ pterodesk reimagined installer ]]\033[0m\n"
}

bootstrap_theming() {
  d.stat "Installing pterodesk theme..."
  mkdir temp
  cd temp
  mkdir -p "$install_path/usr/share/themes"
  mkdir -p "$install_path/usr/share/icons"
  mkdir -p "$install_path$HOME/.local/share/pterodesk"
  mkdir -p "$install_path$HOME/.config"
  mkdir -p "$install_path$HOME/shared"
  mkdir -p "$shared_path"
  curl -L "https://raw.githubusercontent.com/notnulldaemon/pterodesk-cdn/main/logo.png" -o "$install_path$HOME/.local/share/pterodesk/logo.png"
  curl -L "https://github.com/notnulldaemon/pterodesk-cdn/raw/main/Orchis-Grey.tar.xz" -o theme.tar.xz
  tar -xf theme.tar.xz -C "$install_path/usr/share/themes"
  curl -L "https://github.com/notnulldaemon/pterodesk-cdn/raw/main/Tela-circle-black.tar.xz" -o icon.tar.xz
  tar -xf icon.tar.xz -C "$install_path/usr/share/icons"
  git clone https://github.com/vinceliuice/WhiteSur-cursors.git --depth=1
  cp -rv WhiteSur-cursors/dist/ "$install_path/usr/share/icons"
  curl -L "https://raw.githubusercontent.com/notnulldaemon/pterodesk-cdn/main/pterodesk.png" -o \
    "$install_path/usr/share/backgrounds/xfce/xfce-shapes.svg"
  curl -LO https://github.com/notnulldaemon/pterodesk-cdn/raw/main/theme.tar.gz
  tar -xvf theme.tar.gz -C "$install_path$HOME/.config"

  rm -rf $HOME/.config
  cd ..
  rm -rf temp
}

bootstrap_system() {
  # Printing the watermark
  printlogo

  _CHECKPOINT=$PWD

  d.stat "Initializing the Alpine rootfs image..."
  curl -L "$mirror_alpine" -o a.tar.gz && tar -xf a.tar.gz || die
  rm -rf a.tar.gz

  d.stat "Downloading a Docker Daemon..."
  curl -L "$mirror_proot" -o dockerd || die
  chmod +x dockerd

  d.stat "Bootstrapping system..."
  touch etc/{passwd,shadow,groups}

  # copy shit
  cp /etc/resolv.conf "$install_path/etc/resolv.conf" -v
  cp /etc/hosts "$install_path/etc/hosts" -v
  cp /etc/localtime "$install_path/etc/localtime" -v
  cp /etc/passwd "$install_path"/etc/passwd -v
  cp /etc/group "$install_path"/etc/group -v
  sed -i "s+1000+$(id -u)+g" "$install_path/etc/"{passwd,group}
  sed -i "s+$HOME+$install_path$HOME+g" "$install_path/etc/passwd"
  cp /etc/nsswitch.conf "$install_path"/etc/nsswitch.conf -v
  echo "pterodesk" >"$install_path"/etc/hostname
  mkdir -p "$install_path$HOME"

  ./dockerd -r . -b /dev -b /sys -b /proc -b /tmp \
    --kill-on-exit -w $HOME /bin/sh -c "apk update && apk add bash xorg-server git python3 py3-pip py3-numpy openssl \
      xinit xvfb fakeroot firefox tigervnc xfce4 xfce4-terminal font-noto mesa-dri-gallium font-jetbrains-mono \
      py3-urllib3 py3-typing-extensions py3-redis py3-cparser py3-idna py3-charset-normalizer py3-certifi gcompat \
      py3-requests py3-cffi py3-cryptography py3-jwcrypto curl neofetch $(if_x86_64 virtualgl) \
        --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing \
        --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community; \
    git clone https://github.com/notnulldaemon/noVNC /usr/lib/noVNC && \
    cd /usr/lib/noVNC
    openssl req -x509 -sha256 -days 356 -nodes -newkey rsa:2048 -subj '/CN=$(curl -L checkip.pterodactyl-installer.se)/C=US/L=San Fransisco' -keyout self.key -out self.crt & \
    cp vnc.html index.html && \
    ln -s /usr/bin/fakeroot /usr/bin/sudo && \
    pip install websockify --break-system-packages && \
    mkdir -p $HOME/.vnc && echo '$user_passwd' | vncpasswd -f > $HOME/.vnc/passwd && \
    firefox -CreateProfile pterodesk --headless && \
    curl -L 'https://github.com/yokoffing/Betterfox/raw/main/user.js' -o \"$HOME/.mozilla/firefox/\$(ls '$HOME/.mozilla/firefox' | grep pterodesk)/user.js\""
  sed -i "s+Profile=1+Profile=0+g" "$install_path$HOME/.mozilla/firefox/profiles.ini"
  sed -i "1aexport USER=root" "$install_path/usr/bin/fakeroot"
  cat >"$install_path$HOME/.vnc/config" <<EOF
session=xfce
geometry=1600x800
rfbport=5901
EOF
  bootstrap_theming
}

run_system() {
  #!/bin/bash

 echo "   ___   _____________  ___   __      _______   ____  __  _____    _   ____  _______  "
 echo "  / _ | / __/_  __/ _ \/ _ | / / ____/ ___/ /  / __ \/ / / / _ \  | | / /  |/  / __/  "
 echo " / __ |_\ \  / / / , _/ __ |/ /_/___/ /__/ /__/ /_/ / /_/ / // /  | |/ / /|_/ /\ \    "
 echo "/_/ |_/___/ /_/ /_/|_/_/ |_/____/   \___/____/\____/\____/____/   |___/_/  /_/___/    "
 echo ""
 echo "POWERED by nulldaemon's Petrodesk"
 echo "How to use my virtual machine? Please head over to https://<your server ip adress with port> and enter your server's id as the password "
 echo "========================================================================================"
 echo "©️2024, Astral-Cloud (The best hosting provider!)"

  # abort if file
  if [ -f "$HOME/.do-not-start" ]; then
    rm -rf "$HOME/.do-not-start"
    cp /etc/resolv.conf "$install_path/etc/resolv.conf" -v
    $DOCKER_RUN /bin/sh
    exit
  fi
  # Starting NoVNC
  $install_path/dockerd --kill-on-exit -r $install_path -b /dev -b /proc -b /sys -b /tmp -w "/usr/lib/noVNC" /bin/sh -c \
    "./utils/novnc_proxy --vnc localhost:5901 --listen 0.0.0.0:$SERVER_PORT --cert self.crt --key self.key --ssl-only" &>/dev/null &

  # Set up VNCPasswd
  chmod 0600 "$install_path$HOME/.vnc/passwd" # prerequisite

  $DOCKER_RUN "export PATH=$install_path/bin:$install_path/usr/bin:$PATH HOME=$install_path$HOME LD_LIBRARY_PATH='$install_path/usr/lib:$install_path/lib:/usr/lib:/usr/lib64:/lib64:/lib'; \
    cd $install_path$HOME; \
    export MOZ_DISABLE_CONTENT_SANDBOX=1 \
    MOZ_DISABLE_SOCKET_PROCESS_SANDBOX=1 \
    MOZ_DISABLE_RDD_SANDBOX=1 \
    MOZ_DISABLE_GMP_SANDBOX=1 \
    HOME='$install_path$HOME' \
    HOSTNAME=pterodesk; \
    $(if_x86_64 "vglrun -d egl") vncserver :0" &>/dev/null
}

cd "$install_path" || {
  mkdir -p "$install_path"
  cd "$install_path"
}
if [ -d "bin" ]; then
  run_system
else
  bootstrap_system
fi
