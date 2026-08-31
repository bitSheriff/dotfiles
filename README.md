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

[3]: https://github.com/nix-community/nix-on-droid
[4]: https://f-droid.org/packages/com.termux.nix
