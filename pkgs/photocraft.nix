{ lib, appimageTools, fetchurl }:
let
  pname = "photocraft";
  version = "0.7.0";
  src = fetchurl {
    url = "https://github.com/storytold/photocraft/releases/download/v${version}/photocraft-${version}-linux-x86_64.AppImage";
    hash = "sha256-h+vONrzfazHRapyiLOKfmtjbaBheTZgRiADRwt54rEI=";
  };
  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${contents}/usr/share/applications/ai.storyteller.photocraft.desktop -t $out/share/applications
    install -Dm444 ${contents}/usr/share/mime/packages/ai.storyteller.photocraft.xml -t $out/share/mime/packages
    cp -r ${contents}/usr/share/icons $out/share/icons
  '';

  meta = {
    description = "Photoshop-style layered image editor with PSD support";
    homepage = "https://github.com/storytold/photocraft";
    license = with lib.licenses; [ mit asl20 ];
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
