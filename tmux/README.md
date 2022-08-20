# README

## Setup
### Alias
To add the alias to the current shell add the following lines to your `.zshrc` or `.bashrc`


```bash
if [ -f ~/.config/tmux/alias ]; then
    source ~/.config/tmux/alias
else
    print "404: ~/.config/tmux/alias not found."
fi
```

