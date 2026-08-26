# Liquid Glass KDE Widgets — the macOS-style plasmoids by jaxparrow07.
# Not in nixpkgs. Upstream installs them with `kpackagetool6 -i` into
# ~/.local/share; here they are dropped straight into the store instead, and
# found because home-manager puts ~/.nix-profile/share on XDG_DATA_DIRS.
#
# TWO THINGS THE UPSTREAM LAYOUT FORCES:
#
#   1. Each package's contents/{fonts,ui/components} are SYMLINKS up into the
#      shared 1-common/ directory, which is NOT copied into the plasmoid. So
#      the copy must dereference (`cp -rL`) — upstream's package.sh does the
#      same thing via `tar -ch`. A plain `cp -r` produces plasmoids whose fonts
#      and LiquidGlass.qml dangle, and the widget renders blank.
#
#   2. The install directory must be named after KPlugin.Id, not the source
#      directory — they disagree (packages/clock-digital carries the id
#      ...macoswidgets.clock-square). Plasma resolves widgets by id, so the
#      name is read out of metadata.json rather than assumed.
#
# The GLSL shaders under 1-common/components/shaders are committed prebuilt as
# .qsb, so build-shaders.sh (which needs Qt's `qsb`) is not run here.
{ lib
, stdenvNoCC
, fetchFromGitHub
, jq
}:

stdenvNoCC.mkDerivation {
  pname = "liquidglass-kde-widgets";
  version = "0-unstable-2026-08-03";

  src = fetchFromGitHub {
    owner = "jaxparrow07";
    repo = "liquidglass-kde-widgets";
    rev = "02b4476799c7e3ef22d31b5372dd080a04126921";
    hash = "sha256-8y6PCOgY9ZiT5pUQ3T4A4LsRye3MdUkVT6shj9/D7HI=";
  };

  nativeBuildInputs = [ jq ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -d $out/share/plasma/plasmoids

    for dir in packages/*/; do
      name=$(basename "$dir")

      # test-glass / test-timer are the author's shader scratchpads, not
      # shippable widgets — upstream's own installer offers them separately.
      case "$name" in
        test-*) continue ;;
      esac

      id=$(jq -er '.KPlugin.Id' "$dir/metadata.json")
      cp -rL "$dir" "$out/share/plasma/plasmoids/$id"
    done

    runHook postInstall
  '';

  meta = {
    description = "macOS-style Plasma 6 widgets: clocks, weather, calendar, music, timer";
    homepage = "https://github.com/jaxparrow07/liquidglass-kde-widgets";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
