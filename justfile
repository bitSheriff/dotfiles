set shell := ["bash", "-uc"]

default: update

# Update the configuration and the whole system
update:
    # pull the newest changes
    @git pull
     
    # link the new files
    @bash setup/setup.sh link

    # start a system update
    @bash ~/bin/sysupdate
