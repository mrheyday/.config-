#!/bin/zsh
# Executed for each new shell, even non-interactive ones.
# Ergo, nothing here needs to be exported, unless we want it to be available to external commands.

# _After_ setting `autonamedirs`, each param set to an absolute path becomes a ~named dir.
# That's why we need to set it here, before any params are set.
setopt autonamedirs

XDG_CONFIG_HOME=~/.config
ZDOTDIR=$XDG_CONFIG_HOME/zsh
