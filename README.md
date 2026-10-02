# bitSheriff's Setup

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

> _Therapeutic NixOS for a recovering distro-hopper._

## The Philosophy

NixOS is often described as "reproducible," but I prefer "inevitable." This
repository serves as the digital blueprint for my infrastructure. A way to ensure
that even if I wander, I can always find my way back to a working shell.

## The Hosts

I believe a hostname should be more than a UUID; it should have character. When
I first encountered NixOS, I was struck by its phonetic resemblance to the Greek
Isles (_Paxos_, _Naxos_, _Samos_). It felt only right to name my nodes after the
archipelago, mapping the personality of the hardware to the mythology of the
land.

---

### 🏛️ Rhodos

**The Gaming Powerhouse**

- **The Myth:** Home of the _Colossus of Rhodes_, a bronze titan and one of the
  Seven Wonders of the Ancient World.
- **The Hardware:** My primary desktop. Much like the Colossus, it is a massive
  architectural feat (mostly of RGB and silicon) designed to dominate the
  landscape. It represents the "Sun God" of my local network—radiating heat and
  high-fidelity frames.

### ☀️ Delos

**The Academic Framework**

- **The Myth:** The birthplace of Apollo (God of Knowledge) and Artemis.
  Historically a "floating" island that was eventually anchored to the seabed.
- **The Hardware:** My Framework laptop. The "floating" nature of the myth
  perfectly mirrors the modular, swappable nature of the Framework hardware. As
  my university daily driver, it carries the spirit of Apollo: light, mobile,
  and dedicated to the pursuit of knowledge (and the occasional compile-time
  error).

---

### 🏺 Android

**The Pocket Colony**

- **The Myth:** No single island, but the archipelago in miniature—every
  Cycladic settlement had to survive on whatever scraps of soil and stone it
  was given, proof that civilization doesn't need a mainland to take root.

- **The Hardware:** My phone. Since Android won't host a proper NixOS
  installation, it relies on [nix-on-droid][3], a project that brings the Nix
  package manager (built on top of Termux) to Android without requiring root.
  It's a small, sandboxed outpost of nixpkgs living in my pocket—no mainland,
  but still governed by the same laws.

- **Installation:** Install [nix-on-droid from F-Droid][4], launch it once to
  let it bootstrap, then point it at this flake to build and activate the
  configuration:

  ```sh
  just android
  ```

  which expands to:

  ```sh
  nix-on-droid switch --flake .#android
  ```

## Bootstrapping

How a blank machine becomes one of the islands. The first three methods
partition the disk with [disko][5] and **erase it completely**; the last one
keeps an existing NixOS installation. (The phone has its own ritual, see
[Android](#-android).)

Before any of the erasing methods:

- The host has to import its `./disko.nix` in `hosts/<host>/default.nix`, and
  the `fileSystems` / `swapDevices` entries have to be gone from its
  `hardware-configuration.nix` (the two conflict). Only do this when
  reinstalling: a running system rebuilt with a layout it doesn't have won't
  boot.
- The age key (`~/.age/dotfiles.key`) must reach the new system, otherwise it
  can't decrypt its secrets, login password included. The script copies it;
  point `SOPS_AGE_KEY_FILE` at it if it lives elsewhere (e.g. a USB stick).
- On encrypted hosts disko asks for the LUKS passphrase during the install, in
  the terminal the install was started from. Later it is typed on the device
  itself at every boot, so pick one that survives a keyboard layout change.

### 1. From another machine, over SSH

The comfortable way, no USB stick needed. Run the script on a machine that
already has this configuration and answer its questions (target host, user,
which configuration):

```sh
nixos-anywhere
```

It wraps [nixos-anywhere][6]: the target only has to be reachable over SSH,
whether it runs the NixOS installer or some other Linux.

A target that is only on wifi needs a cable for this, or has to be booted
into the NixOS installer and joined to the wifi there first: a running system
is switched into an installer in RAM, and that switch drops the wifi
connection (nothing is erased in that case, a reboot brings the old system
back).

### 2. On the device itself, from the NixOS installer

Boot the installer and run the same script straight from the flake. Leave
host and user empty to install onto the machine in front of you:

```sh
SOPS_AGE_KEY_FILE=/path/to/dotfiles.key \
DOTFILES_DIR=github:bitSheriff/dotfiles \
  nix --extra-experimental-features 'nix-command flakes' \
  run github:bitSheriff/dotfiles#nixos-anywhere
```

This only works from the installer; an installed system can't erase the disk
it is running from.

### ### 3. On top of an existing NixOS installation

Keeps the disk as it is: install NixOS the usual way, clone this repository,
put the age key at `~/.age/dotfiles.key`, then

```sh
just setup
```

which copies the generated hardware configuration into the host's directory,
links the repository to `/etc/nixos` and switches to the chosen configuration.

[3]: https://github.com/nix-community/nix-on-droid

[4]: https://f-droid.org/packages/com.termux.nix

[5]: https://github.com/nix-community/disko

[6]: https://github.com/nix-community/nixos-anywhere
