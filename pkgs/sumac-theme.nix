# Sumac — a macOS 12 style theme set for KDE Plasma, by doncsugar.
# Not in nixpkgs; this repacks the upstream repo into the XDG layout Plasma
# expects. Pure data (SVG/QML/desktop files), so there is nothing to compile.
#
# The repo ships THREE flavours, and all of them are installed here so they can
# be picked in System Settings without a rebuild:
#   Sumac            "regular" — the safe one, what home/plasma.nix selects
#   Summaculate      closer to macOS, "may break a few things" (upstream's words)
#   SumacDoncsugar   the author's own daily-driver variant
#
# NOTE: the icon packs are inheritance-only (a lone index.theme with
# `Inherits=WhiteSur-dark`) — they carry no actual icons. whitesur-icon-theme
# MUST be installed alongside or every icon falls back to hicolor. That
# dependency is wired up in home/plasma.nix, not here, because propagating it
# would drag the icons into any closure that only wants the Plasma style.
{ lib
, stdenvNoCC
, fetchFromGitHub
}:

stdenvNoCC.mkDerivation {
  pname = "sumac-theme";
  # Upstream tags nothing; this is the tip of master as of the last bump.
  version = "0-unstable-2024-04-03";

  src = fetchFromGitHub {
    owner = "doncsugar";
    repo = "sumac-theme";
    rev = "2a7641866350a4ced2c96d8e8549584daf446051";
    hash = "sha256-v6iNN+O7c1V9/RHzM/4VgThkmlEnoBY6LUjvlgdro3k=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -d \
      $out/share/plasma/desktoptheme \
      $out/share/plasma/look-and-feel \
      $out/share/aurorae/themes \
      $out/share/color-schemes \
      $out/share/icons \
      $out/share/Kvantum

    # Plasma styles: sumac-day-plasma, sumac-night-plasma. The glob skips the
    # sibling `src/` and `genthemes.sh` that generate them.
    cp -r plasma-styles/*-plasma        $out/share/plasma/desktoptheme/

    # Global themes. The directory names really do end in ".desktop" upstream —
    # that is the look-and-feel package id, not a stray file extension.
    cp -r global-themes/org.kde.*       $out/share/plasma/look-and-feel/

    # aurorae/ nests one level deeper than the others: <flavour>/<theme>/.
    # Flatten it, since KWin wants every theme directly under themes/.
    cp -r aurorae/*/*                   $out/share/aurorae/themes/

    cp    color-schemes/*/*.colors      $out/share/color-schemes/
    cp -r icon-packs/Sumac-*            $out/share/icons/
    cp -r kvantum/*                     $out/share/Kvantum/

    # Wallpapers. The repo does NOT ship a usable wallpaper package —
    # wallpaper-themes/sumac-wallpapers/ holds only a metadata.json, and the
    # actual layout is assembled by its genthemes.sh from the two SVGs in
    # wallpaper-themes/src/. That assembly is reproduced here, including the
    # spaces in the filenames and the relative symlinks, because Plasma keys
    # the light/dark pair off the images/ vs images_dark/ directory names.
    wp=$out/share/wallpapers/sumac-wallpapers
    install -d $wp/contents/src/images $wp/contents/images $wp/contents/images_dark
    cp wallpaper-themes/sumac-wallpapers/metadata.json $wp/
    cp wallpaper-themes/src/sumac-day-13.svg   "$wp/contents/src/images/Sumac Day 13.svg"
    cp wallpaper-themes/src/sumac-night-13.svg "$wp/contents/src/images/Sumac Night 13.svg"
    ln -s "../src/images/Sumac Day 13.svg"   $wp/contents/images/6000x6000.svg
    ln -s "../src/images/Sumac Night 13.svg" $wp/contents/images_dark/6000x6000.svg

    runHook postInstall
  '';

  meta = {
    description = "macOS 12 style theme set for KDE Plasma (Plasma style, Aurorae, Kvantum, colors, icons)";
    homepage = "https://github.com/doncsugar/sumac-theme";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
