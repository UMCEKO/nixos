{ pkgs, ... }:
let
  # pyenv python3.10 links glibc 2.40, stock gperftools links 2.42 and its libpthread breaks the interpreter
  forgeGlibc = "/nix/store/5m9amsvvh2z8sl7jrnc87hzy21glw6k1-glibc-2.40-66";

  tcmallocForge = pkgs.runCommand "tcmalloc-forge" { nativeBuildInputs = [ pkgs.patchelf ]; } ''
    mkdir -p $out/lib
    cp ${pkgs.gperftools}/lib/libtcmalloc_minimal.so.4.*.* $out/lib/libtcmalloc_minimal.so.4
    chmod +w $out/lib/libtcmalloc_minimal.so.4
    patchelf --set-rpath ${forgeGlibc}/lib:${pkgs.stdenv.cc.cc.lib}/lib $out/lib/libtcmalloc_minimal.so.4
  '';

  ldconfigShim = pkgs.writeShellScriptBin "ldconfig" ''
    if [ "$1" = "-p" ]; then
        echo "1 libs found in cache \`/etc/ld.so.cache'"
        printf '\tlibtcmalloc_minimal.so.4 (libc6,x86-64) => %s\n' ${tcmallocForge}/lib/libtcmalloc_minimal.so.4
        exit 0
    fi
    exec ${pkgs.glibc.bin}/bin/ldconfig "$@"
  '';
in
{
  environment.systemPackages = [ pkgs.bc ];

  systemd.tmpfiles.rules = [
    "d /sbin 0755 root root -"
    "L+ /sbin/ldconfig - - - - ${ldconfigShim}/bin/ldconfig"
  ];
}
