{
  lib,
  stdenvNoCC,
  fetchurl,
  writeText,
  tsx,
}:

let
  # nixpkgs' tsx keeps `dist/` and its bundled esbuild but drops the package
  # manifest, so a bare `import "tsx/esm/api"` cannot resolve. Re-create the
  # manifest; every target below was verified present in tsx 4.23.12's `dist/`.
  tsxManifest = writeText "tsx-package.json" (
    builtins.toJSON {
      name = "tsx";
      inherit (tsx) version;
      type = "module";
      main = "./dist/loader.mjs";
      exports = {
        "." = "./dist/loader.mjs";
        "./cjs" = "./dist/cjs/index.cjs";
        "./cli" = "./dist/cli.mjs";
        "./esm" = "./dist/esm/index.mjs";
        "./repl" = "./dist/repl.mjs";
        "./cjs/api" = {
          import = "./dist/cjs/api/index.mjs";
          require = "./dist/cjs/api/index.cjs";
        };
        "./esm/api" = {
          import = "./dist/esm/api/index.mjs";
          require = "./dist/esm/api/index.cjs";
        };
        "./preflight" = "./dist/preflight.cjs";
        "./patch-repl" = "./dist/patch-repl.cjs";
        "./package.json" = "./package.json";
        "./suppress-warnings" = "./dist/suppress-warnings.cjs";
      };
    }
  );
in
stdenvNoCC.mkDerivation {
  pname = "pi-intercom";
  version = "0.18.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/pi-intercom/-/pi-intercom-0.18.1.tgz";
    hash = "sha256-FmOlMOtIKyPaZtkOJwvTJrvlaKnHw9PMdXW8f0U1p+0=";
  };

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    tar -xzf "$src" --strip-components=1 -C "$out"

    # The tarball ships TypeScript sources only. `cli.mjs` and the detached
    # broker both load them through tsx, which npm would have installed as a
    # runtime dependency. Nothing installs it here, so the broker died at
    # startup with "Cannot find module .../node_modules/tsx/dist/loader.mjs"
    # and every intercom call failed. broker/spawn.ts falls back to exactly
    # that path when `require.resolve("tsx")` fails, so the layout matters.
    mkdir -p "$out/node_modules/tsx"
    ln -s ${tsx}/lib/tsx/dist "$out/node_modules/tsx/dist"
    ln -s ${tsx}/lib/tsx/node_modules "$out/node_modules/tsx/node_modules"
    cp ${tsxManifest} "$out/node_modules/tsx/package.json"
    runHook postInstall
  '';

  meta = {
    description = "Pi-compatible inter-session communication extension";
    homepage = "https://github.com/nicobailon/pi-intercom";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
