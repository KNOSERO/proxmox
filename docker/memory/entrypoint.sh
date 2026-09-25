#!/usr/bin/env bash
set -Eeuo pipefail

[[ -r /run/memory-secrets/id_home_lab ]] || {
    echo "Brak /run/memory-secrets/id_home_lab. Zamontuj katalog secrets." >&2
    exit 1
}

install -d -m 0700 /root/.ssh
install -m 0600 /run/memory-secrets/id_home_lab /root/.ssh/id_home_lab

for playbook in \
    /opt/memory/server/install/nfs.yml \
    /opt/memory/server/install/gluster.yml \
    /opt/memory/server/config/nfs.yml \
    /opt/memory/server/config/gluster.yml \
    /opt/memory/client/install/nfs.yml \
    /opt/memory/client/install/gluster.yml \
    /opt/memory/client/config/nfs.yml \
    /opt/memory/client/config/gluster.yml; do
    ansible-playbook -i /opt/memory/inventory.ini \
        "$playbook"
done
