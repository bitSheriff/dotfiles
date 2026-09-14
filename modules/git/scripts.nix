# The git helper scripts, as plain derivations.
#
# Mirrors the pattern used by ../hledger/scripts.nix: this file takes only
# `pkgs` and returns packages, keeping the scripts self-contained and
# decoupled from home-manager/NixOS module wiring, which lives in ./default.nix.
{ pkgs }:

{
  worktree-init = pkgs.writeShellScriptBin "worktree-init" ''
    url=''${1}
    dir=''${2}
    mkdir ''${dir}
    cd ''${dir}
    git clone --bare ''${url} .bare
    echo "gitdir: ./.bare" >.git
    git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
    git fetch
    git for-each-ref --format='%(refname:short)' refs/heads | xargs -n1 -I{} git branch --set-upstream-to=origin/{}
    git worktree add main
  '';
}
