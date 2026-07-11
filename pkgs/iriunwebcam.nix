# Iriun Webcam — vendor .deb repack (not in nixpkgs, was AUR iriunwebcam).
# The deb also ships modprobe/modules-load configs for v4l2loopback; we drop
# them — system-tweaks.nix declares the same options natively.
{ stdenv
, lib
, fetchurl
, dpkg
, autoPatchelfHook
, wrapQtAppsHook
, qtbase
, qtwayland
, avahi
, alsa-lib
, libdrm
}:

stdenv.mkDerivation rec {
  pname = "iriunwebcam";
  version = "2.9.1";

  src = fetchurl {
    url = "https://iriun.gitlab.io/iriunwebcam-${version}.deb";
    hash = "sha256-slpTyetT96waR7XvcXSZDdl/Ziacc4hgM5XCxX8WC4Q=";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook wrapQtAppsHook ];

  buildInputs = [
    qtbase
    qtwayland # runtime-only: Qt wayland platform plugin, picked up by wrapQtAppsHook
    avahi
    alsa-lib
    libdrm
  ];

  unpackCmd = "dpkg-deb -x $src .";
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 usr/local/bin/iriunwebcam $out/bin/iriunwebcam
    install -Dm644 usr/share/applications/iriunwebcam.desktop $out/share/applications/iriunwebcam.desktop
    install -Dm644 usr/share/pixmaps/iriunwebcam.png $out/share/pixmaps/iriunwebcam.png
    substituteInPlace $out/share/applications/iriunwebcam.desktop \
      --replace-fail /usr/local/bin/iriunwebcam iriunwebcam
    runHook postInstall
  '';

  meta = with lib; {
    description = "Use your phone as a wireless webcam (needs v4l2loopback)";
    homepage = "https://iriun.com";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "iriunwebcam";
  };
}
