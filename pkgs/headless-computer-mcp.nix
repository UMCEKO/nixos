# The computer-use tool as an MCP server on an app in a private headless sway, with recording for PR clips.
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  sway,
  grim,
  wf-recorder,
  ffmpeg,
}:

let
  src = fetchFromGitHub {
    owner = "UMCEKO";
    repo = "headless-computer-mcp";
    rev = "eca3d9d836da7bae4565c8b3e43d53d77c7e85a2";
    hash = "sha256-9sf4Sxz94ds8/KYg8VqOr8qKv7Qdxle8h7xBdnrTCRM=";
  };
in
rustPlatform.buildRustPackage {
  pname = "headless-computer-mcp";
  version = "0.1.0-unstable-eca3d9d";
  inherit src;
  cargoLock.lockFile = "${src}/Cargo.lock";
  nativeBuildInputs = [ makeWrapper ];
  postInstall = ''
    wrapProgram $out/bin/headless-computer-mcp \
      --suffix PATH : ${
        lib.makeBinPath [
          sway
          grim
          wf-recorder
          ffmpeg
        ]
      }
  '';
  meta.mainProgram = "headless-computer-mcp";
}
