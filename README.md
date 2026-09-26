# Homelab Installer

### 1. Utwórz katalog i skopiuj klucz:

```text
homelab-installer/
└── secrets/
    ├── id_home_lab
    └── id_home_lab.pub
```

### 2. Skonfiguruj SSH kluczem

Z katalogu projektu uruchom poniższy skrypt w PowerShellu:

```powershell
$key = [Convert]::ToBase64String(
    [IO.File]::ReadAllBytes("$PWD\secrets\id_home_lab.pub")
)

$setup = @"
set -eu

# Install the SSH public key.
echo $key | base64 -d | sudo tee /tmp/id_home_lab.pub >/dev/null
sudo install -d -m 700 -o rav -g rav /home/rav/.ssh
sudo install -m 600 -o rav -g rav /tmp/id_home_lab.pub /home/rav/.ssh/authorized_keys

# Configure passwordless sudo for Ansible.
echo 'rav ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/99-rav-homelab >/dev/null
sudo chmod 440 /etc/sudoers.d/99-rav-homelab
sudo visudo -cf /etc/sudoers.d/99-rav-homelab

# Verify the rule in a fresh sudo session.
sudo -k
sudo -n true

# Enable public-key authentication and clean up.
sudo sed -i -E 's|^#?PubkeyAuthentication .*|PubkeyAuthentication yes|' /etc/ssh/sshd_config
sudo sed -i -E 's|^#?AuthorizedKeysFile .*|AuthorizedKeysFile .ssh/authorized_keys|' /etc/ssh/sshd_config
sudo rm -f /tmp/id_home_lab.pub
sudo systemctl restart ssh
"@

foreach ($ip in "192.168.0.2", "192.168.0.3") {
    ssh -tt "rav@$ip" $setup
}
```

Skrypt kończy się błędem, jeśli `NOPASSWD` nie działa. Aktualizację systemu wykonuje później instalator Ansible.

### 3. Uruchom instalator K3s

```powershell
podman compose -f docker/homelab/compose.yml run --rm --build homelab-installer
```

### 4. Uruchom instalator NFS i GlusterFS

Formatowanie usunie wszystkie dane z pendrive’a. Wykonaj te kroki tylko dla właściwego urządzenia.

Sprawdź urządzenie:

```bash
lsblk -f
```

Odmontuj pendrive, który system zamontował automatycznie:

```bash
sudo umount /media/rav/KINGSTON
```

Sformatuj partycję jako `ext4`:

```bash
sudo mkfs.ext4 -L core_data_onyx /dev/sda1
sudo blkid /dev/sda1
```

Otwórz plik `/etc/fstab`:

```bash
sudo nano /etc/fstab
```

Dodaj nowy UUID. Formatowanie zmieni UUID dysku:

```text
UUID=<NOWY_UUID> /mnt/gluster_data_onyx ext4 defaults,nofail 0 2
```

Na hoście `ruby` użyj `/mnt/gluster_data_ruby` oraz etykiety `core_data_ruby`.

Zastosuj zmianę:

```bash
sudo mkdir -p /mnt/gluster_data_onyx
sudo systemctl daemon-reload
sudo mount -a
mountpoint /mnt/gluster_data_onyx
```

Nie uruchamiaj instalatora, jeśli `mountpoint` zgłasza błąd.
Instalator utworzy na zamontowanym systemie plików osobny katalog
`/mnt/gluster_data_onyx/brick` dla GlusterFS. Na hoście `ruby` będzie to
`/mnt/gluster_data_ruby/brick`; katalog `lost+found` pozostanie poza brickiem.

```powershell
podman compose -f docker/memory/compose.yml run --rm --build memory-installer
```

Jeśli istnieje stary wolumen GlusterFS i chcesz świadomie utworzyć go od nowa
(operacja usuwa konfigurację wolumenu), uruchom:

```powershell
$env:REBUILD_GLUSTER = "true"
podman compose -f docker/memory/compose.yml run --rm --build memory-installer
$env:REBUILD_GLUSTER = $null
```
