# Compiling a Custom Linux Kernel (6.1.x) on Ubuntu Server

## Overview

This documents building the Linux kernel from source on an Ubuntu Server VM — configuring it, compiling it, installing it, and getting it to actually boot — including the errors that came up along the way and how they were resolved.

## 1. Update the system

```bash
sudo apt update      # refresh the list of available packages
sudo apt upgrade -y  # upgrade installed packages; -y skips the confirmation prompt
```

## 2. Install build dependencies

```bash
sudo apt install -y build-essential libssl-dev libelf-dev bc bison flex libncurses-dev python3 perl
```

| Package | Why it's needed |
|---|---|
| `build-essential` | GCC, `make`, and the core toolchain |
| `libssl-dev` | cryptography support used during the build |
| `libelf-dev` | ELF binary handling, required by newer kernel build systems |
| `bc` | command-line calculator used by some build scripts |
| `bison`, `flex` | parser/lexer generators |
| `libncurses-dev` | powers the terminal UI for `make menuconfig` |
| `python3`, `perl` | used by various kernel build scripts |

## 3. Download and extract the kernel source

```bash
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.1.144.tar.xz
tar -xf linux-6.1.144.tar.xz
cd linux-6.1.144
```

## 4. Start from the running kernel's config

```bash
cp /boot/config-$(uname -r) .config
```

`uname -r` returns the version of the kernel currently running. Copying its config as a starting point means the custom kernel keeps the drivers and features needed to boot on this hardware (or VM), instead of configuring everything from scratch.

## 5. Configure the kernel

```bash
make menuconfig
```

In the menu:
- `[*]` — built directly into the kernel core
- `[M]` — built as a loadable module (can be loaded/unloaded after boot — more flexible)
- `[ ]` — disabled

Under **General setup → Local version**, I appended my own name, so the running kernel shows up with a recognizable identifier — an easy way to confirm this is my build, not the stock one.

## Troubleshooting: build errors

An earlier attempt with kernel `6.4.12` hit build errors. To reset and start clean:

```bash
make clean
make mrproper
sudo rm -rf linux-6.4.12
```

`make mrproper` resets the source tree completely (including the existing `.config`) — more thorough than `make clean`. After this, I went back to the `6.1.x` branch (`6.1.144`) and repeated the config steps above.

I also had to edit the config directly for a signing-key issue that blocked the build:

```bash
nano .config
```

```
CONFIG_SYSTEM_TRUSTED_KEYS="debian/canonical-certs.pem"
CONFIG_SYSTEM_REVOCATION_KEYS="debian/canonical-revoked-certs.pem"
```

Without valid values here, the build fails trying to find trusted/revocation key files that don't exist for a custom, unsigned build.

## 6. Compile

```bash
make -j$(nproc)
```

`nproc` returns the number of CPU cores available. `-j$(nproc)` tells `make` to compile in parallel across all of them — without it, the build can take several times longer. On this machine, the full compile took about an hour.

## 7. Install

```bash
sudo make modules_install
sudo make install
sudo update-grub
```

This installs the kernel image and modules into `/boot` (`vmlinuz`, `initrd.img`) and regenerates the GRUB config. The `update-grub` output should confirm the new kernel was found:

```
Found linux image: /boot/vmlinuz-6.1.144sonia.abbasnia.final
Found initrd image: /boot/initrd.img-6.1.144sonia.abbasnia.final
```

- **`vmlinuz`** — the compressed kernel binary itself
- **`initrd.img`** — the initial RAM disk, loaded at boot to set up hardware/filesystem access before the real root filesystem is mounted

```bash
sudo reboot
```

## Troubleshooting: kernel missing from the GRUB menu

After reboot, the new kernel didn't show up in the GRUB menu. To add it manually:

```bash
sudo nano /etc/grub.d/40_custom
```

GRUB builds its boot menu from the scripts in `/etc/grub.d/`. `40_custom` is the file meant for manual entries — for cases where a new kernel isn't auto-detected. I ran `lsblk` to confirm which partition held `/boot`, then wrote an entry (see [`40_custom.example`](40_custom.example) in this folder):

```bash
#!/bin/sh
exec tail -n +3 $0

menuentry 'Ubuntu, with Linux 6.1.144sonia.abbasnia.final Manual Boot' {
    recordfail
    load_video
    gfxmode $linux_gfx_mode
    insmod gzio
    insmod part_msdos
    insmod ext2
    set root='(hd0,msdos5)'
    if [ x$feature_platform_search_hint = xy ]; then
        search --no-floppy --fs-uuid --set=root <partition-uuid>
    fi
    linux  /boot/vmlinuz-6.1.144sonia.abbasnia.final root=/dev/sda5 ro quiet
    initrd /boot/initrd.img-6.1.144sonia.abbasnia.final
}
```

A few notes on this file:
- `exec tail -n +3 $0` is a GRUB trick that lets one file hold both a shell shebang *and* GRUB script — it tells GRUB to read starting from line 3, skipping the shell part.
- `insmod gzio`, `part_msdos`, `ext2` load the modules GRUB needs to read kernel files off disk.
- `set root='(hd0,msdos5)'` points GRUB at the exact partition (first disk, 5th partition) holding `vmlinuz`/`initrd.img`.
- The `search --fs-uuid` block is an alternative, UUID-based way to find the same partition — it keeps working even if disk ordering changes (e.g. after adding a new drive).

## Result

```bash
uname -r
# 6.1.144sonia.abbasnia.final
```

