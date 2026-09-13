{
  lib,
  buildKodiAddon,
  fetchFromGitHub,
  requests,
  arrow,
  infotagger,
  inputstream-adaptive,
  pyxbmct,
  tubed-api,
}:

# plugin.video.tubed: not (yet) packaged in nixpkgs' kodiPackages.
#
# Tubed is a from-scratch rewrite of the YouTube client by the same author as
# plugin.video.youtube (anxdpanic). We use it as a replacement for the
# official youtube addon, which suffers from a long-standing freezing bug
# (video image freezes while audio keeps playing) tied to its
# inputstream.adaptive/MPEG-DASH handling:
# https://github.com/anxdpanic/plugin.video.youtube/issues/1406
buildKodiAddon rec {
  pname = "tubed";
  namespace = "plugin.video.tubed";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "anxdpanic";
    repo = "plugin.video.tubed";
    rev = "v${version}";
    hash = "sha256-q/ppR3e9obkfutADGnyu83gqmsDC98twaishCh5P+ow=";
  };

  # Tubed hardcodes MEDIA_PATH/PRIVACY_POLICY_MARKDOWN under
  # special://home/addons/<id>/ (the writable per-user addons dir). Under
  # home-manager's Kodi packaging, addons are installed into KODI_HOME
  # (special://xbmc/addons/<id>/, the read-only install root) instead, so
  # special://home/addons/plugin.video.tubed never exists and opening the
  # addon crashes with FileNotFoundError on PRIVACY.md. Point it at
  # special://xbmc/addons instead, which resolves correctly here.
  postPatch = ''
    substituteInPlace resources/lib/src/constants/config.py \
      --replace-fail "special://home/addons/" "special://xbmc/addons/"
  '';

  propagatedBuildInputs = [
    requests
    arrow
    infotagger
    inputstream-adaptive
    pyxbmct
    tubed-api
  ];

  passthru = {
    pythonPath = "resources/lib";
  };

  meta = {
    homepage = "https://github.com/anxdpanic/plugin.video.tubed";
    description = "Tubed, a YouTube client for Kodi (replacement for plugin.video.youtube, avoids its MPEG-DASH freezing bug)";
    license = lib.licenses.gpl2Only;
    teams = [ lib.teams.kodi ];
  };
}
