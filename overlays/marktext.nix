{
  lib,
  appimageTools,
  fetchurl,
}:
let
  pname = "marktext";
  version = "0.20.0-rc.1";

  src = fetchurl {
    url = "https://github.com/marktext/marktext/releases/download/v${version}/marktext-linux-${version}.AppImage";
    hash = "sha256-yGOzHtgwD7fERgOfoRdX9oJpm8CxdabMg1x7syBXxTo=";
  };

  # Extract once so we can pull the .desktop file and icon out of the image.
  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/marktext.desktop \
      $out/share/applications/marktext.desktop
    substituteInPlace $out/share/applications/marktext.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=marktext %U'
    install -Dm444 ${appimageContents}/usr/share/icons/hicolor/256x256/apps/marktext.png \
      $out/share/icons/hicolor/256x256/apps/marktext.png
  '';

  meta = {
    description = "Next generation markdown editor (upstream AppImage, pinned to ${version})";
    homepage = "https://github.com/marktext/marktext";
    changelog = "https://github.com/marktext/marktext/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "marktext";
    platforms = [ "x86_64-linux" ];
  };
}
