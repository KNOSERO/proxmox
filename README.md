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
sudo sed -i -E 's/^#?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i -E 's/^#?AuthorizedKeysFile .*/AuthorizedKeysFile .ssh\\/authorized_keys/' /etc/ssh/sshd_config
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
podman compose run --rm --build homelab-installer
```
