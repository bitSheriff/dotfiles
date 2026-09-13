{
  lib,
  buildKodiAddon,
  fetchFromGitHub,
  requests,
}:

# script.module.tubed.api: not (yet) packaged in nixpkgs' kodiPackages.
# YouTube Data API client library required by Tubed (plugin.video.tubed).
buildKodiAddon rec {
  pname = "tubed-api";
  namespace = "script.module.tubed.api";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "anxdpanic";
    repo = "script.module.tubed.api";
    rev = "v${version}";
    hash = "sha256-hUTPIxkYujKfez0u3zCcjWjmAVYi+W4LzZvPrWd7/Z8=";
  };

  propagatedBuildInputs = [
    requests
  ];

  passthru = {
    pythonPath = "resources/lib/src";
  };

  meta = {
    homepage = "https://github.com/anxdpanic/script.module.tubed.api";
    description = "A module to access YouTube's Data API, required by the Tubed addon";
    license = lib.licenses.gpl2Only;
    teams = [ lib.teams.kodi ];
  };
}
