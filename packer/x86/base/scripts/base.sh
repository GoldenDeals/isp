set -euxo pipefail
 
sudo pacman -Sy --needed --noconfirm qemu-guest-agent
sudo systemctl enable qemu-guest-agent sshd
sudo sed -i '/\bswap\b/d' /etc/fstab || true
sudo passwd -l arch || true
sudo cloud-init clean --logs || true
sudo truncate -s 0 /etc/machine-id
sudo rm -f /etc/ssh/ssh_host_*
 
sync
echo "[base] done"
