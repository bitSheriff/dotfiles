# Key Rotation

How to replace the age key (`~/.age/dotfiles.key`) that sops uses for
everything in `encrypted/`.

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

## Steps

The flags were checked against age 1.3.2 and sops 3.13.3.

### 1. Generate the new key next to the old one

```sh
age-keygen -pq -o ~/.age/dotfiles-new.key
age-keygen -y ~/.age/dotfiles-new.key    # prints the new public key
```

### 2. Let sops use both keys during the switch

sops needs the old key to open the files and the new one afterwards. It tries
every key in the file, so appending is enough:

```sh
cat ~/.age/dotfiles-new.key >> ~/.age/dotfiles.key
```

### 3. Put the new public key into `.sops.yaml`

Replace the `age:` value of the creation rule with the new public key.

### 4. Re-encrypt every file and give it a new data key

```sh
cd ~/code/dotfiles
for f in encrypted/* encrypted/.face.enc; do
  sops updatekeys -y "$f" && sops rotate -i "$f"
done
```

`updatekeys` switches the recipient. `rotate` replaces the data key; without
it the old key could still open the new versions, because the data key it
unlocked in the git history would be unchanged.

### 5. Check that the new key alone is enough

```sh
for f in encrypted/* encrypted/.face.enc; do
  SOPS_AGE_KEY_FILE=~/.age/dotfiles-new.key sops -d "$f" >/dev/null && echo "ok $f"
done
```

### 6. Bring the new key to every other host before rebuilding it

A host that rebuilds with the new files but only has the old key can't decrypt
the login password. So on each other machine: add the new key to
`~/.age/dotfiles.key` first, then pull and rebuild.

### 7. Rebuild, then remove the old key

Rebuild each host and confirm that login and `pass` work. Then replace
`~/.age/dotfiles.key` on each host with the new key only and update the
offline backup.

Keep the old key offline only if old git history should stay readable,
otherwise delete it.

### 8. Commit and push

Then start changing the secrets.

## Don't delete anything early

Until step 8 is done on all hosts, the key file containing both keys is what
keeps every machine working in between.
