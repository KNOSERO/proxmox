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
       ansible all -i "$INVENTORY" -b -e ansible_become_flags=-n -m shell -a "test -f $marker" >/dev/null 2>&1; then
        echo "===== SKIP: $name ====="
        return
    fi

    echo "===== START: $name ====="
    (
        cd "$ROOT_DIR/$playbook_dir"
        playbook_args=(-i "$INVENTORY" "$playbook")
        ansible-playbook "${playbook_args[@]}"
    )

    ansible all -i "$INVENTORY" -b -e ansible_become_flags=-n -m file \
        -a "path=$REMOTE_STATE_DIR state=directory mode=0755" >/dev/null
    ansible all -i "$INVENTORY" -b -e ansible_become_flags=-n -m file \
        -a "path=$marker state=touch mode=0644" >/dev/null
    echo "===== DONE: $name ====="
}

[[ -r /root/.ssh/id_home_lab ]] || {
    install -d -m 0700 /root/.ssh
    install -m 0600 /run/homelab-secrets/id_home_lab /root/.ssh/id_home_lab
    install -m 0644 /run/homelab-secrets/id_home_lab.pub /root/.ssh/id_home_lab.pub
}

[[ -r /root/.ssh/id_home_lab ]] || {
    echo "Brak /run/homelab-secrets/id_home_lab. Zamontuj katalog secrets." >&2
    exit 1
}

if [[ "${SSH_CHECK_ONLY:-false}" == "true" ]]; then
    echo "===== TEST LOGOWANIA SSH ====="
    ansible all -i "$INVENTORY" -m ping
    echo "===== LOGOWANIE SSH OK ====="
    exit 0
fi

run_stage k3s homelab/k3s playbook.yml
run_stage zram homelab/memory playbook.yml

echo "===== HOMELAB INSTALLATION COMPLETE ====="
