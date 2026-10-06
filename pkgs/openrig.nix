{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchurl,
  nodejs_22,
  makeWrapper,
  tmux,
}:

buildNpmPackage (finalAttrs: {
  pname = "openrig";
  version = "0.6.5";

  src = fetchFromGitHub {
    owner = "mvschwarz";
    repo = "openrig";
    tag = "v${finalAttrs.version}";
    hash = "sha256-w+DB9QZhgHeUEvyAqk0AJISaKnNS96UChTkHgIm5WcI=";
  };

  npmDepsHash = "sha256-Z9ua2sOjhBCzHheeVrtVrei0MvykDFm8KFpcb5rttlo=";
  nodejs = nodejs_22;

  dontNpmBuild = true;
  nativeBuildInputs = [ makeWrapper ];

  publishedPackage = fetchurl {
    url = "https://registry.npmjs.org/@openrig/cli/-/cli-${finalAttrs.version}.tgz";
    hash = "sha512-92i/TYl2+omgpb1IODA+SouaB/2Dg1hJQu4nGGWzfnn6gK8ahPkAIIi0hRNyT9OHMKV91hY+PTs9gc06Ag0mVg==";
  };

  installPhase = ''
    runHook preInstall

    packageDir=$out/lib/node_modules/@openrig/cli
    mkdir -p "$packageDir" $out/bin
    tar -xzf "$publishedPackage" --strip-components=1 -C "$packageDir"
    npm prune --omit=dev --workspace packages/cli --ignore-scripts
    cp -r node_modules "$packageDir/node_modules"
    rm -rf "$packageDir/node_modules/@openrig"

    makeWrapper ${nodejs_22}/bin/node $out/bin/rig \
      --add-flags "$packageDir/dist/bin-wrapper.js" \
      --prefix PATH : ${lib.makeBinPath [ tmux ]}
    makeWrapper ${nodejs_22}/bin/node $out/bin/openrig-tui \
      --add-flags "$packageDir/tui/dist/main.js" \
      --prefix PATH : ${lib.makeBinPath [ tmux ]}

    runHook postInstall
  '';

  meta = {
    description = "Build and run persistent teams of coding agents";
    homepage = "https://openrig.dev";
    license = lib.licenses.asl20;
    mainProgram = "rig";
    platforms = lib.platforms.unix;
  };
})
