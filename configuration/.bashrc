#
# ~/.bashrc
#

# failsafe source method, only source if file exists
include() {
    [[ -f "$1" ]] && source "$1"
}

# incude own alias, options, path and much more (build to can be used in onter shells as well)
include ~/.config/shell/envvars
include ~/.config/shell/secrets
include ~/.config/shell/autostart
include ~/.config/shell/alias
include ~/.config/shell/options
