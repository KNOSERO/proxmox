#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="/opt/memory"
INVENTORY="$ROOT_DIR/inventory.ini"
REMOTE_STATE_DIR="${INSTALL_STATE_DIR:-/var/lib/memory-installer}"

[[ -r /run/memory-secrets/id_home_lab ]] || {
    echo "Brak /run/memory-secrets/id_home_lab. Zamontuj katalog secrets." >&2
    exit 1
}

install -d -m 0700 /root/.ssh
install -m 0600 /run/memory-secrets/id_home_lab /root/.ssh/id_home_lab

run_install_stage() {
    local name="$1"
    local playbook="$2"
    local marker="$REMOTE_STATE_DIR/${name}.done"

    if [[ "${INSTALL_FORCE:-false}" != "true" ]] && \
       ansible all -i "$INVENTORY" -b -e ansible_become_flags=-n -m shell \
       -a "test -f $marker" >/dev/null 2>&1; then
        echo "===== SKIP: $name ====="
        return
    fi

    echo "===== START: $name ====="
    ansible-playbook -i "$INVENTORY" "$playbook"

    ansible all -i "$INVENTORY" -b -e ansible_become_flags=-n -m file \
        -a "path=$REMOTE_STATE_DIR state=directory mode=0755" >/dev/null
    ansible all -i "$INVENTORY" -b -e ansible_become_flags=-n -m file \
        -a "path=$marker state=touch mode=0644" >/dev/null
    echo "===== DONE: $name ====="
}

run_install_stage server-nfs "$ROOT_DIR/server/install/nfs.yml"
run_install_stage server-gluster "$ROOT_DIR/server/install/gluster.yml"
run_install_stage client-nfs "$ROOT_DIR/client/install/nfs.yml"
run_install_stage client-gluster "$ROOT_DIR/client/install/gluster.yml"

for playbook in \
    "$ROOT_DIR/server/config/nfs.yml" \
    "$ROOT_DIR/server/config/gluster.yml" \
    "$ROOT_DIR/client/config/nfs.yml" \
    "$ROOT_DIR/client/config/gluster.yml"; do
    echo "===== CONFIGURE: $playbook ====="
    ansible-playbook -i "$INVENTORY" "$playbook"
done
