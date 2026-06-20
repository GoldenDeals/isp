set -euxo pipefail

REPO_URL="${ISP_REPO_URL:-https://github.com/GoldenDeals/isp.git}"
REPO_DIR="${ISP_REPO_DIR:-/srv/isp}"
SALT_ROOT="$REPO_DIR/salt"
APPLY_INTERVAL_MIN="${ISP_SALT_INTERVAL_MIN:-5}"
SALT_VERSION="${ISP_SALT_VERSION:-onedir}"   # 'onedir' = последний; либо 'onedir 3007.1' для пина

sudo tee /etc/pacman.d/mirrorlist >/dev/null <<'EOF'
Server = https://mirror.yandex.ru/archlinux/$repo/os/$arch
Server = https://mirror.truenetwork.ru/archlinux/$repo/os/$arch
EOF
sudo pacman -Sy --needed --noconfirm reflector || true
sudo reflector --country Russia --protocol https --age 24 --latest 15 --sort rate \
    --save /etc/pacman.d/mirrorlist || true

sudo pacman -Sy --needed --noconfirm qemu-guest-agent git curl cronie
sudo systemctl enable qemu-guest-agent sshd cronie

sudo sed -i '/\bswap\b/d' /etc/fstab || true

# Salt onedir через официальный bootstrap; -X — не запускать демоны (masterless).
curl -fsSL https://github.com/saltstack/salt-bootstrap/releases/latest/download/bootstrap-salt.sh -o /tmp/bootstrap-salt.sh
sudo sh /tmp/bootstrap-salt.sh -X $SALT_VERSION
rm -f /tmp/bootstrap-salt.sh

# Демон minion не нужен — работаем только через salt-call --local.
sudo systemctl disable salt-minion.service 2>/dev/null || true
sudo systemctl stop salt-minion.service 2>/dev/null || true

# Masterless-конфиг: локальный file_client, file_roots в склонированный репозиторий.
sudo install -d -m 0755 /etc/salt/minion.d
sudo tee /etc/salt/minion.d/masterless.conf >/dev/null <<EOF
file_client: local
file_roots:
  base:
    - $SALT_ROOT
EOF

# Клон репозитория состояний.
if [ ! -d "$REPO_DIR/.git" ]; then
    sudo git clone "$REPO_URL" "$REPO_DIR"
fi

# Обёртка: git pull + применение типа узла из grain node_type.
sudo tee /usr/local/bin/isp-salt-apply >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${ISP_REPO_DIR:-/srv/isp}"

cd "$REPO_DIR"
git pull --ff-only --quiet

NODE_TYPE="$(salt-call --local --out=json grains.get node_type 2>/dev/null | sed -n 's/.*"local"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' || true)"
if [ -z "$NODE_TYPE" ] || [ "$NODE_TYPE" = "None" ]; then
  echo "[isp-salt] grain node_type не задан — highstate пропущен"
  exit 0
fi

exec salt-call --local state.apply "types.${NODE_TYPE}"
EOF
sudo chmod 0755 /usr/local/bin/isp-salt-apply

sudo tee /etc/cron.d/isp-salt >/dev/null <<EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/saltstack/salt
*/$APPLY_INTERVAL_MIN * * * * root /usr/local/bin/isp-salt-apply >> /var/log/isp-salt.log 2>&1
EOF
sudo chmod 0644 /etc/cron.d/isp-salt

sudo passwd -l arch || true
sudo cloud-init clean --logs || true
sudo truncate -s 0 /etc/machine-id
sudo rm -f /etc/ssh/ssh_host_*
 
sync
echo "[base] done"
