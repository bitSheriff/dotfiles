
set shell := ["bash", "-uc"]

# Check the Libraries
check:
    shellcheck "setup/setup.sh"

