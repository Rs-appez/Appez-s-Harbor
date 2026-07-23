#!/bin/sh
# Runs inside the live ISO as root: unattended install, then prepares the
# target system for Packer's SSH connection.
set -eux
BASE="$1"

# 1. Ephemeral root password for the build
_pw=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')
echo "root:${_pw}" | chpasswd   # live-env only; not strictly required but harmless

# 2. Download the base answers file
wget -qO /tmp/answers "${BASE}/answers"

# 3. Inject a non-interactive 'passwd' function into the answers.
#    setup-alpine sources /tmp/answers, so this function shadows /usr/bin/passwd.
{
    echo ""
    echo "# --- Packer automation: bypass interactive root password ---"
    echo "_pass='${_pw}'"
    echo 'passwd() { echo "root:$_pass" | chpasswd; }'
} >> /tmp/answers

# 4. Run fully unattended install
ERASE_DISKS=/dev/sda SWAP_SIZE=0 setup-alpine -f /tmp/answers

# 5. Post-install: mount target and inject qemu-guest-agent + SSH key
mount /dev/sda2 /mnt

ALPINE_VER=$(cut -d. -f1,2 /mnt/etc/alpine-release)
echo "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VER}/community" >> /mnt/etc/apk/repositories
apk add --root /mnt --no-cache qemu-guest-agent
ln -sf /etc/init.d/qemu-guest-agent /mnt/etc/runlevels/default/qemu-guest-agent

# Ensure networking starts on first boot so Packer can reach SSH
ln -sf /etc/init.d/networking /mnt/etc/runlevels/boot/networking 2>/dev/null || true

mkdir -p /mnt/root/.ssh
wget -qO /mnt/root/.ssh/authorized_keys "${BASE}/authorized_keys"
chmod 700 /mnt/root/.ssh
chmod 600 /mnt/root/.ssh/authorized_keys

sync
umount /mnt/boot 2>/dev/null || true
umount /mnt 2>/dev/null || true
reboot
