# Pop!_OS Migration Kit for `emanon`

This kit implements the migration plan for:
- Reinstalling to Pop!_OS with existing `/home` reuse
- Reusing `nvme1n1p1` as shared data mount at `/home/emanon/emanon_labs`
- Setting up shared access model for a future test user

## 1) Before Reinstall (run on current Ubuntu)

```bash
cd ~/Data/Projects/Program/Scripts/OSSetup/popos-migration
./scripts/export-current-state.sh
```

Outputs are written to `reports/<timestamp>/`.

## 2) Installer Partition Mapping (Pop!_OS Custom Advanced)

Use this exact mapping:
- `/boot/efi` -> `/dev/nvme0n1p1` (DO NOT format)
- `/` -> `/dev/nvme0n1p2` (format)
- `/home` -> `/dev/nvme1n1p2` (DO NOT format)
- `/dev/nvme1n1p1` -> leave unassigned during install

Create user with username: `emanon`.

## 3) After First Boot into Pop!_OS

Run setup script:

```bash
cd ~/Data/Projects/Program/Scripts/OSSetup/popos-migration
sudo ./scripts/postinstall-setup-emanon-labs.sh
```

By default it will:
- Use device: `/dev/nvme1n1p1`
- Mount to: `/home/emanon/emanon_labs`
- Create/ensure group: `labshare`
- Add user `emanon` to `labshare`
- Set permissions + ACL for shared read/write
- Add fstab entry with `defaults,noatime,nofail`

Optional destructive clean format (if you want empty labs partition):

```bash
sudo ./scripts/postinstall-setup-emanon-labs.sh --format
```

## 4) Verify Setup

```bash
./scripts/verify-emanon-labs.sh
```

## 5) Add future test user

```bash
sudo usermod -aG labshare <testuser>
```

The test user must log out and log in again for group changes to apply.

## Notes
- If `setfacl` is missing, install package `acl` and rerun postinstall script.
- If mountpoint already exists in `/etc/fstab` with different value, script will stop and print the conflicting line.
