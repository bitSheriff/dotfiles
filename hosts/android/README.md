# Android host

Two ways to run the Pixel, because the Nix one is currently blocked:

| | Bootstrap | Status |
| --- | --- | --- |
| **Debian VM** (Android 15+ Linux Terminal) | `setup_debian.sh` | **in use** |
| **nix-on-droid** | `nix-on-droid switch --flake github:bitSheriff/dotfiles/master#android` | works |

## Debian VM (official beta for Linux Terminal on Android)

Android 15+ ships a real Debian VM behind the Terminal app — no proot, so apt
and ordinary binaries just work. `setup_debian.sh` installs the packages, links
`.bashrc`, locates the shared-storage notes directory, and sets up git and ssh.

```sh
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/bitSheriff/dotfiles.git ~/code/dotfiles
~/code/dotfiles/hosts/android/setup_debian.sh
```

## nix-on-droid

## Layout

| File | What it is |
| --- | --- |
| `default.nix` | the nix-on-droid config: packages, Android integration, storage |
| `home.nix` | home-manager: `.bashrc`, git config, `termux.properties`, shortcuts |
| `commands.nix` | `tda`, `clkin`, `bknotes`, … as real executables |
| `paths.nix` | notes/finance/time paths and the backup remote, shared by the above |
| `ssh.nix` | decrypts the sops-managed SSH keys and `~/.ssh/hosts` on every switch |
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

## SSH keys from sops

The same `private`, `uni` and `work` keys as on the desktop, from
`encrypted/ssh_keys.yaml`, plus the shared host list as `~/.ssh/hosts`.
`ssh.nix` decrypts them with plain `sops` during `nix-on-droid switch`;
sops-nix is not used because its home-manager module relies on a systemd user
service, and nix-on-droid has none (details in the file header).

The phone needs its own age key, like every host in `.sops.yaml`, named after
the host as everywhere else (`~/.age/<hostname>.key`). Once:

```sh
# on the phone
mkdir -p ~/.age && age-keygen -pq -o ~/.age/android.key
```

Add the printed public key to `.sops.yaml` as `&android` and list it under
`creation_rules`, then on a machine that already holds a key:

```sh
nix run .#update-keys   # re-encrypts encrypted/* for the new recipient
git commit -am "[sops] android recipient" && git push
```

`dots-switch` on the phone then installs the keys. Before the age key exists,
the switch only prints a reminder, so the bootstrap is not blocked. The
`id_ed25519` that `setup.sh` generates stays as the bootstrap key for `bkinit`;
the sops keys are what `~/.ssh/hosts` points at.

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

