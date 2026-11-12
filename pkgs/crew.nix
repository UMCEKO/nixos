# crew: usher (admission daemon), crew run/top/wait/jobs, crew plan, crew queue, crew cargo; built from crew-sh/crew.
{ lib, rustPlatform, fetchFromGitHub, protobuf, pkg-config }:

let
  src = fetchFromGitHub {
    owner = "crew-sh";
    repo = "crew";
    rev = "04a0f23d7e77ec1933d20a8116a3d33fc9a100c4";
    hash = "sha256-CBoC2W+aH31rgBOlhPCkUs6+UbqhvnznlkT36zPoXmY=";
  };
in
rustPlatform.buildRustPackage {
  pname = "crew";
  version = "0.1.0-unstable-04a0f23";
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
