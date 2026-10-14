{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "herdr-navigator";
  version = "0.3.3";

  src = fetchFromGitHub {
    owner = "thanhdat77";
    repo = "herdr-navigator";
    tag = "v${version}";
    hash = "sha256-3YuLh09WE3Todmrxm6D3zZxTM6j/tTwnbgklyyIpPsA=";
  };
  cargoHash = "sha256-nIbFZx0AH4DtcgmmI3Bxh123t5ye4vRRx+Dl3L7z5KA=";

  # Upstream's test fixtures key workspaces by literal "/tmp", while production
  # canonicalizes it to "/private/tmp" on Darwin.
  postPatch = ''
    substituteInPlace src/app.rs \
      --replace-fail '            "/tmp".into(),' \
      '            canonical_str(Path::new("/tmp")).unwrap_or_else(|| "/tmp".into()),'
  '';

  postInstall = ''
    pluginDir="$out/share/herdr/plugins/herdr-navigator"
    mkdir -p "$pluginDir"
    substitute "$src/herdr-plugin.toml" "$pluginDir/herdr-plugin.toml" \
      --replace-fail "./target/release/herdr-navigator" "$out/bin/herdr-navigator"
  '';

  meta = {
    description = "Fuzzy navigator for Herdr workspaces, agents, projects, and sessions";
    homepage = "https://github.com/thanhdat77/herdr-navigator";
    license = lib.licenses.mit;
    mainProgram = "herdr-navigator";
    platforms = lib.platforms.unix;
  };
}
