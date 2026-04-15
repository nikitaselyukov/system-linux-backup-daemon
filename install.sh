#!/bin/bash

set -euo pipefail

CONF_DIR="etc/snapshotd"
UNIT_DIR="etc/systemd/system"
BIN_DIR="usr/local/bin"
PROJECT_ROOT="$(cd -- "$(dirname -- "$0")" && pwd)"
WORKER_SRC="$PROJECT_ROOT/code/snapshot_worker.cpp"
WORKER_OUT="$PROJECT_ROOT/rootfs/$BIN_DIR/snapshot_worker"
SERVICE_TEMPLATE="$PROJECT_ROOT/rootfs/$UNIT_DIR/snapshotd.service"
INSTALL_USER="${SUDO_USER:-$USER}"
INSTALL_GROUP="$(id -gn "$INSTALL_USER")"

rm -rf "/$CONF_DIR" "/$UNIT_DIR/snapshotd.service" "/$UNIT_DIR/snapshotd.timer" "/$UNIT_DIR/snapshotd.timer.d"
rm -f "/$BIN_DIR/snapshotctl" "/$BIN_DIR/snapshot_worker"
mkdir -p "/$CONF_DIR" "/$UNIT_DIR" "/$BIN_DIR"

rm -f "$WORKER_OUT"
g++ -O2 -std=c++17 "$WORKER_SRC" -o "$WORKER_OUT"
chmod 755 "$WORKER_OUT"

cp -r "$PROJECT_ROOT/rootfs/$CONF_DIR/"* "/$CONF_DIR/"
cp "$PROJECT_ROOT/rootfs/$UNIT_DIR/snapshotd.timer" "/$UNIT_DIR/"
cp "$SERVICE_TEMPLATE" "/$UNIT_DIR/snapshotd.service"
cp "$PROJECT_ROOT/rootfs/$BIN_DIR/snapshotctl" "/$BIN_DIR/"
cp "$WORKER_OUT" "/$BIN_DIR/"

sed -i "s/__SERVICE_USER__/$INSTALL_USER/g" "/$UNIT_DIR/snapshotd.service"
sed -i "s/__SERVICE_GROUP__/$INSTALL_GROUP/g" "/$UNIT_DIR/snapshotd.service"
sed -i "s|/home/your_user|/home/$INSTALL_USER|g" "/$CONF_DIR/snapshotd.conf"

chmod 640 "/$CONF_DIR/snapshotd.conf"
chmod 755 "/$BIN_DIR/snapshotctl" "/$BIN_DIR/snapshot_worker"

systemctl daemon-reload
systemctl enable --now snapshotd.timer
systemctl status snapshotd.timer --no-pager || true

echo "SnapshotD installed for user: $INSTALL_USER"
echo "Edit /$CONF_DIR/snapshotd.conf or use snapshotctl set <key> <value>."
