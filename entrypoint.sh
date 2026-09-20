#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="/opt/homelab"
INVENTORY="$ROOT_DIR/homelab/inventory.ini"
REMOTE_STATE_DIR="${INSTALL_STATE_DIR:-/var/lib/homelab-installer}"

run_stage() {
    local name="$1"
    local playbook_dir="$2"
    local playbook="$3"
    local marker="$REMOTE_STATE_DIR/${name}.done"

    if [[ "${INSTALL_FORCE:-false}" != "true" ]] && \
       ansible all -i "$INVENTORY" -b -m shell -a "test -f $marker" >/dev/null 2>&1; then
        echo "===== SKIP: $name ====="
        return
    fi

    echo "===== START: $name ====="
    (
        cd "$ROOT_DIR/$playbook_dir"
        playbook_args=(-i "$INVENTORY" "$playbook")
        if [[ "$name" == "ssh" && -n "${ANSIBLE_PASSWORD:-}" ]]; then
            playbook_args+=(--extra-vars "ansible_password=${ANSIBLE_PASSWORD}")
        fi
        ansible-playbook "${playbook_args[@]}"
    )

    ansible all -i "$INVENTORY" -b -m file \
        -a "path=$REMOTE_STATE_DIR state=directory mode=0755" >/dev/null
    ansible all -i "$INVENTORY" -b -m file \
        -a "path=$marker state=touch mode=0644" >/dev/null
    echo "===== DONE: $name ====="
}

[[ -r /root/.ssh/id_home_lab ]] || {
    echo "Brak /root/.ssh/id_home_lab. Zamontuj katalog secrets." >&2
    exit 1
}

run_stage ssh homelab/ssh playbook.yml
run_stage proxmox homelab/proxmox playbook.yml
run_stage zram homelab/memory playbook.yml
run_stage failover homelab/failover playbook.yml

echo "===== HOMELAB INSTALLATION COMPLETE ====="
