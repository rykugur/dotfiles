#!/usr/bin/env bash
# Refresh pinned fixed-output hashes for locally maintained packages without
# waiting for a build to fail.
#
#   scripts/rehash.sh [--system SYS]... [--write] [--force] PKG...
#   scripts/rehash.sh --all
#
# How it works: a package is evaluated (not built), its whole derivation graph
# is dumped with `nix derivation show -r`, and every fixed-output derivation in
# it is inspected. The ones whose recorded hash literally appears in a tracked
# .nix file in this repo are "ours"; each of those is re-fetched with
# `nix store prefetch-file` and compared. Fixed-output derivations carry their
# hash as plain data, so a stale hash still evaluates and still names its URL —
# which is why this never needs a failing build.
#
# Dependency hashes with no URL (cargoHash, vendorHash, npmDepsHash) cannot be
# prefetched; they are computed by running a fetcher. Those are reported as
# SKIP, and `nix-update` is the tool for them:
#   nix run nixpkgs#nix-update -- --flake --version <ver> <pkg>
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

systems=()
pkgs=()
write=0
force=0
all=0

die() { printf 'rehash: %s\n' "$*" >&2; exit 1; }

while (($#)); do
  case $1 in
    --system) systems+=("${2:?--system needs a value}"); shift 2 ;;
    --write) write=1; shift ;;
    --force) force=1; shift ;;
    --all) all=1; shift ;;
    -h | --help) sed -n '2,25p' "${BASH_SOURCE[0]}" | cut -c3-; exit 0 ;;
    -*) die "unknown flag $1" ;;
    *) pkgs+=("$1"); shift ;;
  esac
done

((${#systems[@]})) || systems=("$(nix eval --impure --raw --expr builtins.currentSystem)")

if ((all)); then
  ((${#pkgs[@]})) && die "--all takes no package names"
  for f in pkgs/*.nix; do
    n=$(basename "$f" .nix)
    [[ $n == default ]] && continue
    pkgs+=("$n")
  done
fi
((${#pkgs[@]})) || die "no packages given (use --all for every pkgs/*.nix)"

# Evaluate against this flake's own nixpkgs and the `additions` overlay, so any
# system can be evaluated from any machine. Going through the flake's
# packages.<system> output instead would drag in flake-parts' cross-system
# transposition, which tries to build foreign-platform derivations and dies
# with "platform mismatch".
pkg_expr() { # system attr
  cat <<EOF
let
  root = $root;
  flake = builtins.getFlake (toString root);
  pkgs = import flake.inputs.nixpkgs {
    system = "$1";
    config.allowUnfree = true;
    overlays = [ (import (root + "/overlays") { inherit (flake) inputs; }).additions ];
  };
in pkgs.$2
EOF
}

# Every encoding a hash might be written in, so we can both find it in a file
# and replace it in the encoding the author used.
hash_forms() { # sri-hash
  local h=$1 algo=${1%%-*} b32 b16
  b32=$(nix hash convert --to nix32 "$h" 2>/dev/null || true)
  b16=$(nix hash convert --to base16 "$h" 2>/dev/null || true)
  printf '%s\n' "$h" ${b32:+"$b32" "$algo:$b32"} ${b16:+"$b16" "$algo:$b16"}
}

# Which tracked .nix file pins this hash, and in what encoding.
locate_hash() { # sri-hash -> "file:line<TAB>literal" or nothing
  local form hit
  while read -r form; do
    [[ -n $form ]] || continue
    hit=$(git grep -n -F -- "$form" -- '*.nix' 2>/dev/null | head -1) || true
    [[ -n $hit ]] && { printf '%s\t%s\n' "${hit%%:*}:$(cut -d: -f2 <<<"$hit")" "$form"; return; }
  done < <(hash_forms "$1")
}

status=0

for system in "${systems[@]}"; do
  for pkg in "${pkgs[@]}"; do
    drvs=$(nix derivation show -r --impure --expr "$(pkg_expr "$system" "$pkg")" 2>/dev/null) || {
      printf '%s [%s]\n  EVAL  unavailable on this system\n' "$pkg" "$system"
      continue
    }

    printf '%s [%s]\n' "$pkg" "$system"

    # Fixed-output derivations, normalised across plain and structured attrs.
    fods=$(jq -r '
      .derivations | to_entries[] | .value as $d
      | ($d.structuredAttrs // ($d.env["__json"] // "{}" | fromjson)) as $s
      | ($d.outputs.out.hash // $s.outputHash // $d.env.outputHash) as $hash
      | select($hash != null)
      | (($s.urls // $d.env.urls // null) | if type == "string" then split(" ") else . end) as $urls
      | (($s.url // $d.env.url // null) | if . == null then [] else [.] end) as $url
      | (($d.outputs.out.method // $s.outputHashMode // $d.env.outputHashMode) // "flat") as $mode
      | [$hash, $mode, $d.outputs.out.path // $d.env.out // "", (($urls // []) + $url | join(" "))]
      | @tsv' <<<"$drvs" | sort -u)

    seen=0
    while IFS=$'\t' read -r hash mode out urls; do
      [[ -n $hash ]] || continue
      found=$(locate_hash "$hash") || true
      [[ -n $found ]] || continue # a nixpkgs hash, not one of ours
      seen=1
      where=${found%%$'\t'*}
      literal=${found##*$'\t'}

      if [[ -z $urls ]]; then
        printf '  SKIP  %s  %s (no URL: cargo/vendor/npm dep hash — use nix-update)\n' \
          "${hash:0:24}…" "$where"
        continue
      fi

      if ((!force)) && [[ -n $out ]] && nix path-info "$out" &>/dev/null; then
        printf '  OK    %s  %s (already realised)\n' "${hash:0:24}…" "$where"
        continue
      fi

      unpack=()
      [[ $mode == nar || $mode == recursive ]] && unpack=(--unpack)
      url=${urls%% *}

      if ! got=$(nix store prefetch-file --json --hash-type "${hash%%-*}" \
        "${unpack[@]}" "$url" 2>/dev/null | jq -r .hash); then
        printf '  FAIL  %s  %s (fetch failed: %s)\n' "${hash:0:24}…" "$where" "$url"
        status=1
        continue
      fi

      if [[ $got == "$hash" ]]; then
        printf '  OK    %s  %s\n' "${hash:0:24}…" "$where"
        continue
      fi

      status=1
      # Replace in whatever encoding the file used.
      replacement=$got
      case $literal in
        *:*) replacement="${got%%-*}:$(nix hash convert --to nix32 "$got")" ;;
        sha*-*) replacement=$got ;;
        *) replacement=$(nix hash convert --to nix32 "$got") ;;
      esac

      if ((write)); then
        file=${where%%:*}
        tmp=$(mktemp)
        # Literal replacement: base64 hashes contain `+` and `/`, so awk's
        # gsub (a regex) and sed would both misfire on them.
        awk -v old="$literal" -v new="$replacement" '
          {
            out = ""; rest = $0
            while ((i = index(rest, old)) > 0) {
              out = out substr(rest, 1, i - 1) new
              rest = substr(rest, i + length(old))
            }
            print out rest
          }' "$file" >"$tmp"
        mv "$tmp" "$file"
        printf '  FIXED %s -> %s  %s\n' "${literal:0:24}…" "$replacement" "$where"
      else
        printf '  STALE %s -> %s  %s\n' "${literal:0:24}…" "$replacement" "$where"
      fi
    done <<<"$fods"
    ((seen)) || printf '  NOTE  no pinned hash of ours in its derivation graph (builtins.fetchurl and friends fetch during evaluation and never become derivations)\n'
  done
done

((write)) || ((status == 0)) || printf '\nRe-run with --write to apply.\n'
exit $status
