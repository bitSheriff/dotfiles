# Configuration
If you store the application specific configurations in `modules/PKG/...` and link it with a relative link, NixOS stores them in a read-only filesystem and links it to the `.config` directory. That means, that the configuration cannot be changed from there and further needs a `nixos-rebuild switch` to update it.

Some programs need a writeable configuration (like noctalia for widgets and plugin updates), so they are stored in this directory and linked with a absolute path. Because everything is stored in `git` neither of the configurations can get lost.
