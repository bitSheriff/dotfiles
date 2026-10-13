# Key Rotation

How to replace an age key that sops uses for everything in `encrypted/`.

## Which key is where

Every host has its own key, and every one of them can open every file:

| File                      | Recipient in `.sops.yaml` | Where it lives                      |
| ------------------------- | ------------------------- | ----------------------------------- |
| `~/.age/<hostname>.key`   | `&<hostname>`             | only on that host                   |
| `~/.age/dotfiles.key`     | `&general`                | offline backup, bootstrap of new hosts |

A host reads exactly one file, `~/.age/<hostname>.key`: `sops.age.keyFile`
(system and home-manager) and `SOPS_AGE_KEY_FILE` for the shell all point
there, with the host name taken from `networking.hostName`. On the phone the
host name is `android`. sops never searches a directory; it tries every key
*inside* the file it is given, which is what step 2 below relies on.

## When

Not on a schedule. This repository is public and keeps its history, so
everything ever encrypted to a key stays decryptable with that key. A new key
only protects secrets that are new as well. Rotate when something happened:

- the key may have been read by something untrusted,
- a device holding it was lost, stolen, sold or sent for repair,
- a backup medium containing it went missing,
- a machine that had it is no longer in use.

A real rotation is two things, in this order:

1. a new key (this document),
2. new values for the secrets themselves (passwords, tokens, SSH keys, TOTP
   seeds), so that they are only ever encrypted to the new key.

Because the keys are per host, usually only one key changes, and the other
hosts keep theirs. For a lost or retired machine, remove its recipient instead
of replacing it (step 3), the rest is the same.

## Steps

The flags were checked against age 1.3.2 and sops 3.13.3. `<host>` is the
host whose key is being replaced; run steps 1 and 2 on that host.

### 1. Generate the new key next to the old one

```sh
age-keygen -pq -o ~/.age/<host>-new.key
age-keygen -y ~/.age/<host>-new.key    # prints the new public key
```

### 2. Let sops use both keys during the switch

sops needs the old key to open the files and the new one afterwards. It tries
every key in the file, so appending is enough:

```sh
cat ~/.age/<host>-new.key >> ~/.age/<host>.key
```

### 3. Put the new public key into `.sops.yaml`

Replace the value of the `&<host>` anchor with the new public key. For a
machine that is gone, delete its anchor and its line under `creation_rules`.

### 4. Re-encrypt every file and give it a new data key

```sh
cd ~/code/dotfiles
nix run .#update-keys    # sops updatekeys: recipients as in .sops.yaml
nix run .#rotate-keys    # sops -r -i: a fresh data key for every file
```

`updatekeys` switches the recipients. `rotate` replaces the data key; without
it the old key could still open the new versions, because the data key it
unlocked in the git history would be unchanged. Both scripts cover
`encrypted/.face.enc` as well, so check with `grep -c recipient` on the
dotfile if in doubt.

### 5. Check that the new key alone is enough

```sh
for f in encrypted/* encrypted/.face.enc; do
  SOPS_AGE_KEY_FILE=~/.age/<host>-new.key sops -d "$f" >/dev/null && echo "ok $f"
done
```

### 6. Rebuild, then remove the old key

Rebuild `<host>` and confirm that login and `pass` work. Then replace
`~/.age/<host>.key` with the new key only:

```sh
mv ~/.age/<host>-new.key ~/.age/<host>.key
chmod 600 ~/.age/<host>.key
```

The other hosts only have to pull and rebuild; their keys are untouched. If
the general key was rotated, update the offline backup instead.

Keep the old key offline only if old git history should stay readable,
otherwise delete it.

### 7. Commit and push

Then start changing the secrets.

## Don't delete anything early

Until step 6 is done, the key file containing both keys is what keeps the
host working in between.
