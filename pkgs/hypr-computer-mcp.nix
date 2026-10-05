# The computer-use tool as a stdio MCP server on Hyprland; built here so both hosts run the same binary.
{ rustPlatform, fetchFromGitHub }:

let
  src = fetchFromGitHub {
    owner = "UMCEKO";
    repo = "hypr-computer-mcp";
    rev = "ec2636c9394e999504d34ba0945eee8f8b7183bd";
    hash = "sha256-ZKKjU8NYw5mipBD18SuM5sj1oPFhRkkYHzsPiZCxQ1I=";
  };
in
rustPlatform.buildRustPackage {
  pname = "hypr-computer-mcp";
  version = "0.1.0-unstable-ec2636c";
  inherit src;
  cargoLock.lockFile = "${src}/Cargo.lock";
  meta.mainProgram = "hypr-computer-mcp";
}
