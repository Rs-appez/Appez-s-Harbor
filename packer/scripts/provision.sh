#!/bin/sh
# Runs over SSH on the installed system.
set -eux

# --- Repositories ---
cat > /etc/apk/repositories <<EOF
https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main
https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/community
EOF
apk upgrade --no-cache

# --- Packages ---
# qemu-guest-agent was pre-installed during the bootstrap installer (setup.sh)
# so Packer could discover this VM's IP via the QEMU agent.
apk add --no-cache \
    cloud-init cloud-utils-growpart e2fsprogs-extra \
    util-linux util-linux-misc ifupdown-ng iproute2 \
    acpid sudo

# --- Services ---
# Ensure the agent is enabled (already linked by setup.sh, but idempotent).
rc-update add qemu-guest-agent default 2>/dev/null || true

rc-update add networking boot
rc-update add acpid default
rc-update add sshd default
rc-update add chronyd default
rc-update add cloud-init-local boot
rc-update add cloud-init default
rc-update add cloud-config default
rc-update add cloud-final default

# --- cloud-init datasource config ---
install -D -m 0644 /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg

# --- ssh hardening ---
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

# --- Golden-image hygiene ---
passwd -l root
rm -f /etc/ssh/ssh_host_*
cloud-init clean --logs --machine-id
rm -f /var/lib/dbus/machine-id
rm -rf /var/cache/apk/* /tmp/* /var/tmp/* /root/.ash_history
find /var/log -type f -exec truncate -s 0 {} +
fstrim -av || true
sync
