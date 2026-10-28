{ lib, appimageTools, fetchurl }:
let
  pname = "kopuz-nightly";
  version = "0.68.0-nightly.20261028";
  src = fetchurl {
    url = "https://github.com/temidaradev/kopuz/releases/download/v${version}/Kopuz-Nightly_${version}_x86_64.AppImage";
    hash = "sha256-Xpxxt6R3IgD9rNLNzi8mGwkSswUr+5d2tlqRSjeHQJ8=";
  };
  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${contents}/usr/share/applications/kopuz-nightly.desktop -t $out/share/applications
    cp -r ${contents}/usr/share/icons $out/share/icons
  '';

  meta = {
    description = "Kopuz music player, built nightly from the latest development code";
    homepage = "https://github.com/temidaradev/kopuz";
    license = lib.licenses.eupl12;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
