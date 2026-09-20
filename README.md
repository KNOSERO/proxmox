# Homelab Installer

Samodzielny instalator homelab uruchamiany w Dockerze lub Podmanie.

## Zakres

Instalator wykonuje kolejno:

1. Konfigurację SSH na `onyx` i `ruby`.
2. Proxmox na `onyx` i `ruby`.
3. ZRAM.
4. Keepalived failover z VIP `192.168.0.150`.

Nie wykonuje:

- partycjonowania dysków,
- RAID/mdadm,
- ZFS/zpool,
- montowania dysków,
- NFS i GlusterFS — nie są częścią tego projektu.

Żaden playbook nie konfiguruje dysków ani urządzeń blokowych.

## Wymagania

- Docker z Docker Compose albo Podman z `podman compose`;
- dwa hosty: `onyx` (`192.168.0.2`) i `ruby` (`192.168.0.3`);
- działający klucz SSH `secrets/id_home_lab`;
- opcjonalnie hasło SSH w zmiennej `ANSIBLE_PASSWORD` przy pierwszym uruchomieniu;
- dostęp `sudo` przez użytkownika `rav`;
- hosty uruchomione z interfejsem `vmbr0` dla failover.

## Uruchomienie

Utwórz katalog i skopiuj klucz:

```text
homelab-installer/
└── secrets/
    └── id_home_lab
```

Uruchom pełną instalację:

```powershell
 $env:ANSIBLE_PASSWORD = "haslo-do-ssh"
docker compose run --rm homelab-installer
Remove-Item Env:ANSIBLE_PASSWORD
```

Jeżeli klucz publiczny jest już zainstalowany na obu serwerach, zmienna `ANSIBLE_PASSWORD` nie jest potrzebna.

Na Podmanie:

```powershell
podman compose run --rm homelab-installer
```

Stan etapów jest zapisywany bezpośrednio na serwerach w:

```text
/var/lib/homelab-installer/<etap>.done
```

Aby wymusić ponowienie wszystkich etapów:

```powershell
$env:INSTALL_FORCE = "true"
docker compose run --rm homelab-installer
Remove-Item Env:INSTALL_FORCE
```
