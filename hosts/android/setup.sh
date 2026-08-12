setup_bash() {
    # delete the olf .bashrc first
    rm -rf ~/.bashrc
    # link the versioned one
    ln -s $(pwd)/.bashrc ~/.bashrc
}

echo "Setting up bash"
setup_bash
