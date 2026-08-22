# Android host

Two ways to run the Pixel, because the Nix one is currently blocked:

| | Bootstrap | Status |
| --- | --- | --- |
| **Debian VM** (Android 15+ Linux Terminal) | `setup_debian.sh` | **in use** |
| **nix-on-droid** | `setup.sh` | on ice, see below |

## Debian VM (current)

Android 15+ ships a real Debian VM behind the Terminal app — no proot, so apt
and ordinary binaries just work. `setup_debian.sh` installs the packages, links
`.bashrc`, locates the shared-storage notes directory, and sets up git and ssh.

```sh
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/bitSheriff/dotfiles.git ~/code/dotfiles
~/code/dotfiles/hosts/android/setup_debian.sh
```

Two things to know:

* **The hledger helpers are duplicated** into `.bashrc` as shell functions,
  rather than shared with `../../modules/hledger/scripts.nix`. Deliberate: this
  host has no Nix, and leaving the NixOS module alone beats de-duplicating three
  functions. Fix a bug in one, fix it in the other.
* **hledger is whatever Debian ships** — 1.25 on bookworm, 1.32 on trixie,
  1.52 on sid, against 1.52 on the desktop. Anything below 1.40 silently ignores
  `hledger.conf`; the setup script checks and says so.

Storage lands under `/mnt/shared`, but how much of it is visible depends on the
Android version (16 QPR2 exposes nearly all shared storage, older builds only
Downloads). Rather than guess, `setup_debian.sh` probes for the notes directory
and records the result in `~/.config/dotfiles-notes-path`, which `.bashrc`
sources.

## nix-on-droid (on ice)

Blocked on [nix-on-droid#495](https://github.com/nix-community/nix-on-droid/issues/495):
the proot bundled in the app cannot translate the `TCGETS2`/`TCSETS2` ioctls
current glibc uses, so activation dies with `getting pseudoterminal attributes:
Permission denied`. [PR #529](https://github.com/nix-community/nix-on-droid/pull/529)
fixes it, but F-Droid's newest app build (June 2025) predates it, and the
activation step that would install the patched proot runs *after* the step that
fails. Everything below still describes that setup; it should work once a new
app release lands.

## Layout

| File | What it is |
| --- | --- |
| `default.nix` | the nix-on-droid config: packages, Android integration, storage |
| `home.nix` | home-manager: `.bashrc`, git config, `termux.properties`, shortcuts |
| `commands.nix` | `tda`, `clkin`, `bknotes`, … as real executables |
| `paths.nix` | notes/finance/time paths and the backup remote, shared by the above |
| `setup.sh` | first-run bootstrap only |
| `termux.properties` | extra-keys row, read by the app |

## First run

Install nix-on-droid from F-Droid, open it, let it bootstrap, then:

```sh
bash <(curl -sL https://raw.githubusercontent.com/bitSheriff/dotfiles/master/hosts/android/setup.sh)
```

It enables flakes, switches straight from `github:bitSheriff/dotfiles#android`,
asks for the storage permission, clones the repo to `~/code/dotfiles` for later
edits, and generates an SSH key. Add the printed public key to Forgejo, then run
`bkinit` to attach the notes directory to the backup remote.

The switch comes first on purpose. Nix fetches a `github:` flake ref as a
tarball and needs no git to do it, so the switch is what installs git. Running
`nix run nixpkgs#git` beforehand would download and unpack a second, *unpinned*
copy of nixpkgs first.

**Expect long silences.** Unpacking nixpkgs into the store means writing
~200k files through `proot`, which intercepts every syscall. It prints nothing
while it does so; several quiet minutes is normal, not a hang. Two things help:

* Keep the app in the foreground, or acquire the wakelock from its
  notification. Android suspends backgrounded processes and the build simply
  stops, with no error.
* `nix flake metadata nixpkgs` is the quick probe. If *that* hangs it is the
  fetch/unpack; if it prints, the fetch is cached and evaluation is the slow
  part.

### Getting the repo onto a machine without git

Ranked, because the obvious answer is the slow one:

1. **Don't.** Build from `github:bitSheriff/dotfiles#android` as above. The
   switch installs git; clone afterwards, when it costs nothing.
2. **Need the files before any build?** `nix flake prefetch
   github:bitSheriff/dotfiles` prints a store path. Copy it out and
   `chmod -R u+w`. Uses nothing but nix, but yields a snapshot, not a repo.
3. **Really need git first?** Pin it to the revision `flake.lock` already
   uses, so the nixpkgs fetch is shared with the switch rather than duplicated:
   `nix shell github:NixOS/nixpkgs/<rev-from-flake.lock>#git -c git clone ...`

`nix flake clone` is *not* an option despite the name: it shells out to the
git binary and dies with `executing "git": No such file or directory`.

## Afterwards

```sh
dots-switch     # git pull + nix-on-droid switch
```

## What is shared with the desktop, and what is not

nix-on-droid has no NixOS module system, no systemd and no display server, so
`../../modules` cannot be imported here. The part worth sharing is shared:
`../../modules/hledger/scripts.nix` holds `hl-accounts`, `timedot-add`,
`timeclock-add` and friends as plain derivations, and both the NixOS module
(`../../modules/hledger/default.nix`) and this host import it. Fix a bug in a
script once and both get it.

Everything else here is deliberately phone-shaped:

* **bash, not zsh.** nix-on-droid's default shell, and the phone does not need
  the desktop's zsh plugin stack.
* **Different variable names.** `FINANCE_PATH` / `TIME_PATH` here versus
  `LEDGER_PATH` / `TIMEDOT_PATH` on the desktop, as the old `.bashrc` had them.
* **Commands, not aliases.** On the desktop `tda`, `clkin` etc. are zsh
  aliases. Here they are executables, because a shortcut or an `sh -c` call
  never loads an interactive shell.
* **No commit signing.** `op-ssh-sign` needs the 1Password desktop app.

## Termux differences worth knowing

nix-on-droid is a fork of the Termux *terminal emulator*, not of Termux the
distribution, and it ships under the package id `com.termux.nix`.

* **Termux plugin apps do not work.** Termux:Widget, Termux:API and
  Termux:Boot bind to `com.termux`. The `termux-api` package is therefore gone
  from the package list. The `~/.shortcuts/*` entries are still generated
  because they are usable launchers on their own, but no home-screen widget
  will pick them up.
* **`termux-*` commands are unavailable.** They come from `android-integration`
  options rather than packages, and every one of those has to be compiled on
  the phone — none are in `cache.nixos.org` or `nix-on-droid.cachix.org` — where
  the build dies in `unpackPhase` under proot
  ([nix-on-droid#480](https://github.com/nix-community/nix-on-droid/issues/480)).
  The whole block is commented out in `default.nix` with the details. What that
  costs, and the replacement for each: storage permission via the Android
  settings toggle, wake lock via the app's notification, and a session restart
  instead of `termux-reload-settings`.
* **The home directory moved** from `/data/data/com.termux/files/home` to
  `/data/data/com.termux.nix/files/home`, which is why `paths.nix` exists
  rather than the hard-coded paths the old `.bashrc` had.
* **`ping` is unreliable** inside the proot sandbox, so `bknotes` probes the
  git port over TCP instead.

## Checking changes from a laptop

```sh
just android-check
```

The full activation package cannot be built off-device: nix-on-droid's
`proot-termux-static` is an aarch64 Android binary served from their own
cache, so `nix build` on x86 fails at that point even though the config
itself evaluates fine.
