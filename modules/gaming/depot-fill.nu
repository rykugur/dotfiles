# depot-fill: wrap DepotDownloader to fill in a Steam depot Steam itself is
# downloading too slowly (see Arcanum: wiki/Reference/Slow Steam Downloads.md).
#
# Workflow this assumes:
#   1. Click Install/Download on the game in the Steam client (creates the
#      steamapps/common/<installdir> folder + appmanifest_<appid>.acf) and pause it.
#   2. Run `depot-fill <appid>` here to pull the bytes via DepotDownloader instead.
#   3. Back in Steam: restart it, then Properties -> Installed Files -> "Verify
#      integrity of game files" to reconcile.
#
# Auto-detects installdir + the first depot/manifest pair from the appmanifest;
# override with --depot/--manifest when a game has more than one (see `depot-fill list`).
#
# Steam account: pass --username explicitly, or export $env.STEAM_USERNAME in your
# own (untracked) nushell env before sourcing this file.

def "steam-root default" [] {
    $env.HOME | path join ".local/share/Steam"
}

def "nu-complete steam-apps" [] {
    let steam_root = (steam-root default)
    let entries = (
        glob ($steam_root | path join "steamapps" "appmanifest_*.acf")
        | each {|f|
            let text = (open --raw $f)
            let appid = ($text | parse --regex '"appid"\s+"(?<v>\d+)"' | get v.0?)
            let name = ($text | parse --regex '"name"\s+"(?<v>[^"]+)"' | get v.0?)
            if $appid != null {
                {value: $appid, description: ($name | default "unknown")}
            }
        }
        | compact
    )
    {
        options: {
            completion_algorithm: "fuzzy",
            match_description: true,
        },
        completions: $entries,
    }
}

def "depot-fill acf" [appid: string, steam_root: string] {
    let acf_path = ($steam_root | path join "steamapps" $"appmanifest_($appid).acf")
    if not ($acf_path | path exists) {
        error make {msg: $"No appmanifest at ($acf_path). Click Install/Download on the game in Steam first so it creates this file, then re-run."}
    }
    let text = (open --raw $acf_path)
    let installdir = ($text | parse --regex '"installdir"\s+"(?<v>[^"]+)"' | get v.0?)
    if $installdir == null {
        error make {msg: $"Could not find installdir in ($acf_path)"}
    }
    let depots = ($text | parse --regex '"(?<depot>\d+)"\s*\r?\n\s*\{\s*\r?\n\s*"manifest"\s+"(?<manifest>\d+)"')
    {acf_path: $acf_path, installdir: $installdir, depots: $depots}
}

# List the depot/manifest pairs an appmanifest currently has staged or installed,
# for games with more than one depot (base game + DLC/language packs) where
# depot-fill's first-match auto-detect might pick the wrong one.
def "depot-fill list" [
    appid: string@"nu-complete steam-apps"   # Steam AppID, e.g. 1867240
    --steam-root: string                     # default: ~/.local/share/Steam
] {
    let steam_root = ($steam_root | default (steam-root default))
    (depot-fill acf $appid $steam_root).depots
}

# Fill in a partially/un-downloaded Steam depot with DepotDownloader instead of
# Steam's own slow client (see Arcanum: wiki/Reference/Slow Steam Downloads.md).
# Requires the game already be queued/installing in Steam (so the appmanifest and
# steamapps/common/<installdir> folder exist) and `depotdownloader` on PATH.
def "depot-fill" [
    appid: string@"nu-complete steam-apps"   # Steam AppID, e.g. 1867240
    --depot (-d): string                     # depot id override (default: first found in appmanifest)
    --manifest (-m): string                  # manifest id override (default: matching manifest for --depot)
    --os-type (-o): string = "windows"       # windows | linux | macos
    --dir: string                            # install dir override (default: steamapps/common/<installdir>)
    --username (-u): string                  # default: $env.STEAM_USERNAME
    --steam-root: string                     # default: ~/.local/share/Steam
    --dry-run                                # print the DepotDownloader invocation instead of running it
] {
    let username = ($username | default ($env.STEAM_USERNAME? | default ""))
    if ($username | is-empty) {
        error make {msg: "No Steam username given. Pass --username <you>, or export $env.STEAM_USERNAME in your own nushell env."}
    }
    let steam_root = ($steam_root | default (steam-root default))

    let info = (depot-fill acf $appid $steam_root)
    let target_dir = ($dir | default ($steam_root | path join "steamapps" "common" $info.installdir))

    mut depot_id = $depot
    mut manifest_id = $manifest

    if ($depot_id == null) or ($manifest_id == null) {
        if ($info.depots | is-empty) {
            error make {msg: $"Could not auto-detect a depot/manifest pair in ($info.acf_path). Pass --depot and --manifest explicitly, or run 'depot-fill list ($appid)' to see what's there."}
        }
        if $depot_id == null {
            $depot_id = ($info.depots | get depot.0)
        }
        if $manifest_id == null {
            let match = ($info.depots | where depot == $depot_id)
            $manifest_id = if ($match | is-empty) { $info.depots | get manifest.0 } else { $match | get manifest.0 }
        }
    }

    print $"App ($appid) -> depot ($depot_id), manifest ($manifest_id)"
    print $"Install dir: ($target_dir)"

    if $dry_run {
        print $"DepotDownloader -app ($appid) -depot ($depot_id) -manifest ($manifest_id) -os ($os_type) -dir '($target_dir)' -username ($username) -remember-password"
        return
    }

    mkdir $target_dir
    ^DepotDownloader -app $appid -depot $depot_id -manifest $manifest_id -os $os_type -dir $target_dir -username $username -remember-password

    print ""
    print "Done. In Steam: restart, then Properties -> Installed Files -> \"Verify integrity of game files\"."
}
