# crew: usher (admission daemon), crew run/top/wait/jobs, crew plan, crew queue, crew cargo; built from crew-sh/crew.
{ lib, rustPlatform, fetchFromGitHub, protobuf, pkg-config }:

let
  src = fetchFromGitHub {
    owner = "crew-sh";
    repo = "crew";
    rev = "bd8228137d30d07f617436e727455d766b54526c";
    hash = "sha256-AVy+ALAZJs6oDD59uyU7GGJSiRFTrg5+71j6sNQwLZQ=";
  };
in
rustPlatform.buildRustPackage {
  pname = "crew";
  version = "0.1.0-unstable-bd82281";
  inherit src;
  cargoLock.lockFile = "${src}/Cargo.lock";
  nativeBuildInputs = [ protobuf pkg-config ];
  PROTOC = "${protobuf}/bin/protoc";
  # The tests need systemd user scopes, git identities and a live socket; they run in crew's own CI.
  doCheck = false;
  meta = {
    description = "Tools for running many AI coding agents on one Linux machine";
    homepage = "https://crew.umceko.dev";
    license = with lib.licenses; [ mit asl20 ];
    mainProgram = "crew";
  };
}
