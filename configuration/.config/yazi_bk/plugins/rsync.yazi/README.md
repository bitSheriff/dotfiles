# Rsync.yazi

A [yazi](https://yazi-rs.github.io/) plugin for simple rsync copying locally and up to remote servers.

![Demo](assets/demo.gif)
Thanks to [chrissabug](https://x.com/chrissabug) for creating lovely art!

## Pre-Reqs

1. yazi latest version preferred
2. rsync
3. passwordless authentication if copying to a remote server

## Installation

```sh
ya pkg add GianniBYoung/rsync
```

## Usage

Add the binds to your `~/.config/yazi/keymap.toml`

**WARNING:** Make sure the chosen binding isn't already in use!!

```toml
[[mgr.prepend_keymap]]
on   = [ "R" ]
run  = "plugin rsync"
desc = "Copy files using rsync"
```

### Specify Default Remote Server

```toml
[[mgr.prepend_keymap]]
on   = [ "R" ]
run  = "plugin rsync 'user@server.com'"
desc = "Copy files using rsync to default location"
```

### Remember Last Target

Use `--remember` to cache the last used target. On next invocation, the input field will be pre-filled with the cached target.

```toml
[[mgr.prepend_keymap]]
on   = [ "R" ]
run  = "plugin rsync -- --remember"
desc = "Copy files using rsync (remember target)"
```

**Note:** The target is stored in `~/.config/yazi/plugins/rsync.yazi/.last_target`

## Troubleshooting

Basic logging information is sent to `~/.local/state/yazi/yazi.log`

*Note: This plugin has only been tested on Linux

## Contributing

Run into a bug or want a certain feature added? Submit an issue!

- Give it a star if you like it ⭐!
- PRs welcome :)
