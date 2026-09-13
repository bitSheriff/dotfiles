{
  lib,
  buildKodiAddon,
  fetchFromGitHub,
}:

# script.module.pyxbmct: not (yet) packaged in nixpkgs' kodiPackages.
# Required by Tubed (plugin.video.tubed) for its settings/search dialogs.
buildKodiAddon rec {
  pname = "pyxbmct";
  namespace = "script.module.pyxbmct";
  version = "1.3.2";

  src = fetchFromGitHub {
    owner = "romanvm";
    repo = "script.module.pyxbmct";
    rev = "1.3.2-2";
    hash = "sha256-mStm78CCKn+7H3YWGStncgxCF40s45ogB+gEcJ4i+98=";
  };

  passthru = {
    pythonPath = "lib";
  };

  meta = {
    homepage = "https://github.com/romanvm/script.module.pyxbmct";
    description = "PyXBMCt UI mini-framework, a Kodi addon dependency required by Tubed";
    license = lib.licenses.gpl3Only;
    teams = [ lib.teams.kodi ];
  };
}
