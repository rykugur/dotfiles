# omp-collab-relay — self-hosted stand-in for the public OMP Collab relay
# (wss://my.omp.sh), so an always-on omp host can run Collab without a
# third-party hop for agent-to-agent traffic.
#
# Vendors exactly the files the relay needs straight out of the oh-my-pi
# monorepo, rather than forking them: `packages/collab-web/scripts/local-relay.ts`,
# its sibling `src/lib/link.ts`, and `packages/wire` — the dependency-free
# constants package both import as `@oh-my-pi/pi-wire`. No `bun install`, no
# lockfile, because none of those three files have an npm dependency; Bun
# resolves the bare `@oh-my-pi/pi-wire` specifier via that package's own
# `exports` field once it's under `node_modules/@oh-my-pi/pi-wire`.
#
# Upstream's own docs call this script "an offline stand-in ... not a
# replacement for the production service": it speaks the exact relay wire
# protocol (room creation, peer routing, content-blind envelope forwarding)
# but ships no browser client, no `/share` blob endpoint, and no `/healthz`.
# Fine for agent-to-agent Collab; anything that needs a browser guest still
# wants ompweb or the public relay.
#
# The script has no bind-address flag — `Bun.serve({ port })` listens on
# every interface. Keep the port closed at the firewall and reach it only
# through a reverse proxy, the same way ompweb and the auth-broker do.
{
  lib,
  stdenvNoCC,
  makeWrapper,
  bun,
  src, # inputs.oh-my-pi
}:
stdenvNoCC.mkDerivation {
  pname = "omp-collab-relay";
  version = "0-unstable";

  inherit src;

  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    dest=$out/share/omp-collab-relay
    mkdir -p "$dest/scripts" "$dest/src/lib" "$dest/node_modules/@oh-my-pi"
    cp packages/collab-web/scripts/local-relay.ts "$dest/scripts/"
    cp packages/collab-web/src/lib/link.ts "$dest/src/lib/"
    cp -r packages/wire "$dest/node_modules/@oh-my-pi/pi-wire"

    makeWrapper ${lib.getExe bun} $out/bin/omp-collab-relay \
      --add-flags "run $dest/scripts/local-relay.ts"

    runHook postInstall
  '';

  meta = {
    description = "Self-hosted stand-in for the public OMP Collab relay (offline local-relay.ts)";
    homepage = "https://github.com/can1357/oh-my-pi/blob/main/packages/collab-web/scripts/local-relay.ts";
    license = lib.licenses.mit;
    mainProgram = "omp-collab-relay";
    platforms = lib.platforms.unix;
  };
}
