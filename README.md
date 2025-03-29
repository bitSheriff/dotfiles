# bitSheriff's Setup

![](./doc/img/terminals.png)

## Installation

> [!important] Distribution
> This installation process is designed for Arch Linux. The dotfiles should work on other distributions as well, but some features might not be available.

### Prerequisites

- Ensure you have `git` installed.
- Install `stow` if you haven't already.
- Install `gum` for interactive prompts.
- Install `age` for encrypting secrets.

### Process

The whole installation process is managed by the `setup/setup.sh` script.

```sh
# clone the repository
git clone https://github.com/bitSheriff/dotfiles.git
# set the environment variable, needed for some symbolic links
export DOTFILES_DIR=$(pwd)/dotfiles/
# start the installation process
./setup/setup.sh
```

It will let you choose which configurations you want to install.

## Configuration

The configuration files are located in the `configuration` directory which gets linked with `stow` [^1], so this directory represents the `~` later. Therefore, it can link to `.config` as well as `~/.ssh` and simple files like `.gitconfig`.

## Secrets

> _Secrets_, are configurations, which are not meant to be shared with others. Like API keys, passwords, etc.

The secrets are located in the same directory as the normal configuration files. So how are they secured?
They are handled by the `secrets/secrets.sh` script, by encrypting them with `age`[^2]. Only the encrypted secrets are stored in the repository. Further, a key-file is used to decrypt them and link the real files.

> Which files are secrets?

Well, this depends on the user's needs. You can easily define them in the `setup/secret_files.txt` file.

**Problem:** Because the encrypted file is stored in the repository, they will be always changed, because encrypting them will result in a different hash (for security reasons). So I built a check which creates a hash of the decrypted file and if this hash is different from the real file, you need to encrypt them again.
Additionally, I do the same with the encrypted `.age` file, this way I can check if the secret was updated on the remote server, and I have to update my local file by decrypting it.

| Local Change | Remote Change |           Action            |
| :----------: | :-----------: | :-------------------------: |
|   `false`    |    `false`    |         do nothing          |
|   `false`    |    `true`     | remote update $\to$ decrypt |
|    `true`    |    `false`    | local update $\to$ encrypt  |
|    `true`    |    `true`     |          **shit**           |

If **both** the local and the remote files are changed, we have a real problem. So the only option is to decrypt the remote file to another filename and merge them manually. But I am working on a solution for this.

---

[^1]: https://www.gnu.org/software/stow/

[^2]: https://github.com/FiloSottile/age
