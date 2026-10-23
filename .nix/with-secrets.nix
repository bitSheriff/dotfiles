# Wraps a program so its API keys reach only that program, instead of being
# exported in the shell and inherited by every process started from it.
#
# `secrets` maps an environment variable to the path of a sops-nix secret. The
# file is read when the program starts, so nothing lands in the nix store, and
# it works from launchers and systemd units too, not only from zsh. `env` are
# plain, non-secret variables set alongside.
#
# The program refuses to start when a secret can't be read - better than e.g.
# a server silently coming up without its password.
{ pkgs, lib }:

{
  pkg,
  secrets,
  env ? { },
}:
let
  prog = pkg.meta.mainProgram;

  setEnv = lib.mapAttrsToList (
    name: value: "--set ${lib.escapeShellArg name} ${lib.escapeShellArg value}"
  ) env;

  # shell snippet run by the wrapper before the real program; `$(< file)` is
  # a bash builtin, so it works with an empty PATH as well (systemd units)
  readSecret =
    name: path:
    "${name}=\"$(< ${lib.escapeShellArg path})\""
    + " || { echo \"${prog}: could not read the secret for ${name}\" >&2; exit 1; }"
    + "; export ${name}";

  loadSecret = lib.mapAttrsToList (
    name: path: "--run ${lib.escapeShellArg (readSecret name path)}"
  ) secrets;
in
pkgs.symlinkJoin {
  inherit (pkg) pname version meta;
  paths = [ pkg ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/${prog} \
      ${lib.concatStringsSep " \\\n  " (setEnv ++ loadSecret)}
  '';
}
