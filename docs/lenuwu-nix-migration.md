# `lenuwu-nix` migration checklist

This repo is now wired for the new ThinkPad host name, but the final
`hardware-configuration.nix` still needs to be regenerated on the laptop itself.

1. Boot the NixOS USB on the ThinkPad in UEFI mode.
2. Do not repartition, format, or run the installer against the 4TB SSD.
3. Identify the transplanted root and EFI partitions with `lsblk -f`.
4. Mount the installed system:

```bash
sudo mount /dev/disk/by-uuid/<root-uuid> /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-uuid/<efi-uuid> /mnt/boot
```

5. If you have extra data partitions that should auto-mount later, mount them under `/mnt` before generating the hardware scan.
6. Generate the ThinkPad hardware scan:

```bash
sudo nixos-generate-config --show-hardware-config --root /mnt > /tmp/lenuwu-hardware-configuration.nix
```

7. Replace `hosts/lenuwu-nix/hardware-configuration.nix` in `/mnt/home/krieger/CirnOS` with that generated file.
8. Validate the host:

```bash
sudo nix build 'path:/mnt/home/krieger/CirnOS#nixosConfigurations.lenuwu-nix.config.system.build.toplevel'
```

9. Write the new bootable generation:

```bash
sudo nixos-enter --root /mnt -c 'nixos-rebuild boot --flake path:/home/krieger/CirnOS#lenuwu-nix --install-bootloader'
```

10. Reboot into `lenuwu-nix`.
11. After the first successful boot, finish activation:

```bash
sudo nixos-rebuild switch --flake path:/home/krieger/CirnOS#lenuwu-nix
```
