# Proces pamięci masowej

Proces konfiguruje NFS i GlusterFS na hostach `onyx` oraz `ruby`.

Playbooki są podzielone na instalację i konfigurację:

```text
memory/server/install/nfs.yml       instalacja serwera NFS
memory/server/config/nfs.yml        konfiguracja serwera NFS
memory/server/install/gluster.yml   instalacja serwera GlusterFS
memory/server/config/gluster.yml    konfiguracja serwera GlusterFS
memory/client/install/nfs.yml       instalacja clienta NFS
memory/client/config/nfs.yml        konfiguracja clienta NFS
memory/client/install/gluster.yml   instalacja clienta GlusterFS
memory/client/config/gluster.yml    konfiguracja clienta GlusterFS
```

GlusterFS tworzy replikowany wolumen `core_data`:

```text
onyx:/mnt/core_data_onyx
ruby:/mnt/core_data_ruby
```

Wolumen jest dostępny na obu hostach pod `/mnt/core_data`.

USB musi być zamontowany odpowiednio pod `/mnt/core_data_onyx` oraz `/mnt/core_data_ruby`.

NFS działa w obu kierunkach:

```text
onyx eksportuje /mnt/onyx_data
ruby montuje   /mnt/onyx_data

ruby eksportuje /mnt/ruby_data
onyx montuje    /mnt/ruby_data
```

## Przygotuj USB

Formatowanie usunie wszystkie dane z pendrive’a. Wykonaj te kroki tylko dla właściwego urządzenia.

Na każdym hoście wyświetl urządzenia:

```bash
lsblk -f
```

Odmontuj pendrive, który system zamontował automatycznie:

```bash
sudo umount /media/rav/KINGSTON
```

Sformatuj właściwą partycję jako `ext4`:

```bash
sudo mkfs.ext4 -L core_data_onyx /dev/sdX1
sudo blkid /dev/sdX1
```

Otwórz plik `/etc/fstab`:

```bash
sudo nano /etc/fstab
```

Dodaj nowy UUID. Formatowanie zmieni UUID dysku.

Przykład dla `onyx`:

```text
UUID=<NOWY_UUID> /mnt/core_data_onyx ext4 defaults,nofail 0 2
```

Przykład dla `ruby`:

```text
UUID=<NOWY_UUID> /mnt/core_data_ruby ext4 defaults,nofail 0 2
```

Utwórz katalog i zamontuj pendrive:

```bash
sudo mkdir -p /mnt/core_data_onyx
sudo systemctl daemon-reload
sudo mount -a
mountpoint /mnt/core_data_onyx
```

Na `ruby` użyj `/mnt/core_data_ruby`.
Proces nie formatuje, nie montuje i nie zmienia pendrive’ów.

W plikach `host_vars` ustaw ścieżki NFS oraz brick GlusterFS.
Wspólne ustawienia wolumenu są w `memory/group_vars/storage.yml`.

## Uruchom

Uruchom z katalogu repozytorium:

```powershell
podman compose -f docker/memory/compose.yml run --rm --build memory-installer
```

Proces wymaga klucza `secrets/id_home_lab` oraz `secrets/id_home_lab.pub`.
