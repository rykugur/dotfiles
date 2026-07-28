#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
packages_attr='config.home-manager.users.dusty.home.packages'

package_names() {
  nix eval "$repo_root#nixosConfigurations.$1.$packages_attr" \
    --apply 'builtins.map (package: package.name)' --json
}

real_enabled=$(nix eval "$repo_root#nixosConfigurations.jezrien.config.home-manager.users.dusty.ryk.printing3d.enableBambuStudio" --json)
prebuild_enabled=$(nix eval "$repo_root#nixosConfigurations.jezrien-prebuild.config.home-manager.users.dusty.ryk.printing3d.enableBambuStudio" --json)

test "$real_enabled" = true
test "$prebuild_enabled" = false

real_packages=$(package_names jezrien)
prebuild_packages=$(package_names jezrien-prebuild)

jq -e 'any(startswith("bambu-studio"))' <<<"$real_packages" >/dev/null
! jq -e 'any(startswith("bambu-studio"))' <<<"$prebuild_packages" >/dev/null

for package in freecad orca-slicer qidi-slicer; do
  jq -e --arg package "$package" 'any(startswith($package))' <<<"$real_packages" >/dev/null
  jq -e --arg package "$package" 'any(startswith($package))' <<<"$prebuild_packages" >/dev/null
done

nix eval "$repo_root#nixosConfigurations.jezrien-prebuild.config.system.build.toplevel.drvPath" --raw >/dev/null

target_attr=$(nix eval "$repo_root#nixosConfigurations.vasher.config.ryk.vasherPrebuild.targetAttr" --raw)
test "$target_attr" = 'nixosConfigurations.jezrien-prebuild.config.system.build.toplevel'

excluded_packages=$(nix eval "$repo_root#nixosConfigurations.vasher.config.ryk.vasherPrebuild.excludedPackages" --json)
test "$excluded_packages" = '["bambu-studio"]'
