# ompweb — local browser UI for the omp agent (github:kahme247/ompweb).
#
# Upstream ships its own nix/package.nix, but its `lib.fileset.unions` lists
# `next-env.d.ts`, which is gitignored and therefore absent from the repo. The
# flake only evaluates on a working tree where a previous `next build` left
# that file behind, so `nix build github:kahme247/ompweb` fails for everyone
# else. Materialize the source with the file present and call their
# derivation, rather than forking the font patch and npm hash we would then
# have to track by hand.
{
  callPackage,
  runCommand,
  buildNpmPackage,
  src,
}:
let
  prepared = runCommand "ompweb-source" { } ''
    cp -r ${src} "$out"
    chmod -R u+w "$out"
    # Next regenerates this during the build; it only has to exist for the
    # fileset to resolve.
    : > "$out/next-env.d.ts"
  '';
in
callPackage "${prepared}/nix/package.nix" {
  # Upstream's `npmDepsHash` was produced with a different npm than this
  # nixpkgs ships, so its dependency FOD does not reproduce here. Upstream
  # calls `buildNpmPackage` with a `finalAttrs` function, so patch through
  # both call shapes.
  buildNpmPackage =
    argsOrFn:
    let
      npmDepsHash = "sha256-sWlf6K96SKtjdaX5EWwoIT28r46QM17hd/o0qW8hSyY=";
    in
    buildNpmPackage (
      if builtins.isFunction argsOrFn then
        (finalAttrs: argsOrFn finalAttrs // { inherit npmDepsHash; })
      else
        argsOrFn // { inherit npmDepsHash; }
    );
}
