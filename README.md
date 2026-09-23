# Homelab Installer

### 1. Utwórz katalog i skopiuj klucz:

```text
homelab-installer/
└── secrets/
    ├── id_home_lab
    └── id_home_lab.pub
```

### 2. Skonfiguruj SSH kluczem

Z katalogu projektu uruchom jedną komendę w PowerShellu:

```powershell
$key=[Convert]::ToBase64String([IO.File]::ReadAllBytes("$PWD\secrets\id_home_lab.pub")); foreach($ip in "192.168.0.2","192.168.0.3"){ ssh -tt "rav@$ip" "echo $key | base64 -d | sudo tee /tmp/id_home_lab.pub >/dev/null; sudo apt-get update && sudo apt-get upgrade -y && sudo install -d -m 700 -o rav -g rav /home/rav/.ssh && sudo install -m 600 -o rav -g rav /tmp/id_home_lab.pub /home/rav/.ssh/authorized_keys && echo 'rav ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/rav-homelab >/dev/null && sudo chmod 440 /etc/sudoers.d/rav-homelab && sudo visudo -cf /etc/sudoers.d/rav-homelab && sudo sed -i -E 's/^#?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && sudo sed -i -E 's/^#?AuthorizedKeysFile .*/AuthorizedKeysFile .ssh\\/authorized_keys/' /etc/ssh/sshd_config && sudo systemctl restart ssh; sudo rm -f /tmp/id_home_lab.pub" }
```

### 3. Uruchom instalator K3s

```powershell
podman compose run --rm --build homelab-installer
```
