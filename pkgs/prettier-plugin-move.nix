{
  lib,
  stdenv,
  fetchurl,
  prettier,
  makeWrapper,
}:
let
  webTreeSitter = fetchurl {
    url = "https://registry.npmjs.org/web-tree-sitter/-/web-tree-sitter-0.20.8.tgz";
    hash = "sha256-heYj81/m2EHXEm2OYdouzvzXN7poODeQH/taFCtZG+Y=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "prettier-plugin-move";
  version = "0.3.5";

  src = fetchurl {
    url = "https://registry.npmjs.org/@mysten/prettier-plugin-move/-/prettier-plugin-move-${finalAttrs.version}.tgz";
    hash = "sha256-EgsMeGfZymev4duK9tEdgSw03xddIj0C4fSJFSrdWEY=";
  };

  sourceRoot = "package";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    # out/index.js loads ../tree-sitter-move.wasm at runtime, so the two
    # must stay siblings under the same directory. web-tree-sitter is the
    # only npm runtime dep and gets resolved via a sibling node_modules.
    pluginDir=$out/lib/prettier-plugin-move
    mkdir -p $pluginDir/node_modules/web-tree-sitter
    cp -r out tree-sitter-move.wasm $pluginDir/
    tar -xzf ${webTreeSitter} --strip-components=1 -C $pluginDir/node_modules/web-tree-sitter
    # The plugin also `require('prettier')` directly, so expose the
    # nixpkgs prettier package through the same node_modules.
    ln -s ${prettier}/lib/node_modules/prettier $pluginDir/node_modules/prettier

    makeWrapper ${lib.getExe prettier} $out/bin/prettier-move \
      --add-flags "--plugin $pluginDir/out/index.js"

    runHook postInstall
  '';

  meta = {
    description = "Prettier plugin for the Move language, wrapped as a standalone prettier-move CLI";
    homepage = "https://github.com/MystenLabs/sui/tree/main/external-crates/move/tooling/prettier-move";
    license = lib.licenses.asl20;
    mainProgram = "prettier-move";
    platforms = lib.platforms.unix;
  };
})
