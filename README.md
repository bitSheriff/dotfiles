# bitSheriff's Setup

![](./doc/img/terminals.png)

## Installation

The whole installation process is managed by the `setup/setup.sh` script.

```sh
# clone the repository
git clone https://github.com/bitSheriff/dotfiles.git
# set the environment variable, needed for some symbolic links
export DOTFILES_DIR=$(pwd)/dotfiles/
# start the installation process
./setup/setup.sh
```

## Configuration

The configuration files are located in the `configuration` directory which gets linked with `stow` [^1], so this directory represents the `~` later. Therefore, it can link to `.config` as well as `~/.ssh` and simple files like `.gitconfig`.

## Secrets

---

[^1]: https://www.gnu.org/software/stow/
