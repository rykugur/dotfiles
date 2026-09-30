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
# Username resolution order: --username, $env.STEAM_USERNAME, then the account
# Steam itself has stored in config/loginusers.vdf (MostRecent/AutoLogin wins).
#
# Depot/manifest are pinned to whatever the appmanifest has staged/installed when
# that information exists; otherwise DepotDownloader resolves the current branch
# depots itself. Override either with --depot/--manifest (see `depot-fill list`).

def "steam-root default" [] {
    $env.HOME | path join ".local/share/Steam"
}

# Account name Steam itself last logged in with. Empty string when unavailable.
def "steam-username default" [steam_root: string] {
    let path = ($steam_root | path join "config" "loginusers.vdf")
    if not ($path | path exists) {
        return ""
    }

    # loginusers.vdf blocks are flat key/value pairs keyed by steamid64.
    let users = (
        open --raw $path
        | parse --regex '"(?<id>\d{17})"\s*\r?\n\s*\{(?<body>[^}]*)\}'
        | each {|u|
            {
                name: ($u.body | parse --regex '"AccountName"\s+"(?<v>[^"]+)"' | get v.0?),
                recent: (($u.body | parse --regex '"MostRecent"\s+"(?<v>\d)"' | get v.0?) == "1"),
                autologin: (($u.body | parse --regex '"AutoLogin"\s+"(?<v>\d)"' | get v.0?) == "1"),
            }
        }
        | where name != null
    )

    if ($users | is-empty) {
        return ""
    }

    let preferred = (
        $users
        | where recent
        | append ($users | where autologin)
        | append $users
        | first
    )
    $preferred.name
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
    # Only StagedDepots/InstalledDepots carry manifest ids. SharedDepots and
    # DlcDownloads do not, and are correctly skipped by this pattern.
    let depots = ($text | parse --regex '"(?<depot>\d+)"\s*\r?\n\s*\{\s*\r?\n\s*"manifest"\s+"(?<manifest>\d+)"')
    {acf_path: $acf_path, installdir: $installdir, depots: $depots}
}

# Show the depot/manifest pairs an appmanifest currently has staged or installed.
# An empty result is normal — it just means DepotDownloader will resolve the
# current branch depots itself instead of being pinned to a specific manifest.
def "depot-fill list" [
    appid: string@"nu-complete steam-apps"   # Steam AppID, e.g. 1867240
    --steam-root: string                     # default: ~/.local/share/Steam
] {
    let steam_root = ($steam_root | default (steam-root default))
    let info = (depot-fill acf $appid $steam_root)
    if ($info.depots | is-empty) {
        print $"No staged/installed depots recorded in ($info.acf_path)."
        print "depot-fill will let DepotDownloader pick the current branch depots."
    }
    $info.depots
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

# Fill in a partially/un-downloaded Steam depot with DepotDownloader instead of
# Steam's own slow client (see Arcanum: wiki/Reference/Slow Steam Downloads.md).
# Requires the game already be queued/installing in Steam (so the appmanifest and
# steamapps/common/<installdir> folder exist) and `depotdownloader` on PATH.
def "depot-fill" [
    appid: string@"nu-complete steam-apps"   # Steam AppID, e.g. 1867240
    --depot (-d): string                     # depot id override (default: from appmanifest, else DepotDownloader decides)
    --manifest (-m): string                  # manifest id override (default: matching manifest for --depot)
    --os-type (-o): string = "windows"       # windows | linux | macos
    --dir: string                            # install dir override (default: steamapps/common/<installdir>)
    --username (-u): string                  # default: $env.STEAM_USERNAME, else Steam's own logged-in account
    --steam-root: string                     # default: ~/.local/share/Steam
    --dry-run                                # print the DepotDownloader invocation instead of running it
] {
    let steam_root = ($steam_root | default (steam-root default))
    # `default` only substitutes null, so empty strings need explicit fallthrough.
    let env_username = ($env.STEAM_USERNAME? | default "")
    let username = if ($username | is-not-empty) {
        $username
    } else if ($env_username | is-not-empty) {
        $env_username
    } else {
        steam-username default $steam_root
    }
    if ($username | is-empty) {
        error make {msg: $"Could not determine a Steam username. Pass --username <you>, export $env.STEAM_USERNAME, or log in once via the Steam client so ($steam_root)/config/loginusers.vdf exists."}
    }

    let info = (depot-fill acf $appid $steam_root)
    let target_dir = ($dir | default ($steam_root | path join "steamapps" "common" $info.installdir))

    # Pin depot/manifest when the appmanifest knows them; otherwise let
    # DepotDownloader resolve the current branch depots for this app itself.
    let depot_id = (
        $depot
        | default ($info.depots | get depot.0? | default null)
    )
    let manifest_id = if ($manifest | is-not-empty) {
        $manifest
    } else if ($depot_id != null) {
        let match = ($info.depots | where depot == $depot_id)
        if ($match | is-empty) { null } else { $match | get manifest.0 }
    } else {
        null
    }

    let pin_args = (
        []
        | append (if $depot_id != null { ["-depot" $depot_id] } else { [] })
        | append (if $manifest_id != null { ["-manifest" $manifest_id] } else { [] })
    )

    if $depot_id == null {
        print $"App ($appid) -> no depot pinned; DepotDownloader will pick current branch depots"
    } else {
        print $"App ($appid) -> depot ($depot_id), manifest ($manifest_id | default 'current for branch')"
    }
    print $"Install dir: ($target_dir)"
    print $"Account: ($username)"

    let args = (
        ["-app" $appid]
        | append $pin_args
        | append ["-os" $os_type "-dir" $target_dir "-username" $username "-remember-password"]
    )

    if $dry_run {
        # quote args containing spaces so the printed line is copy-pasteable;
        # actual execution splats args individually and needs no quoting.
        let shown = ($args | each {|a| if ($a | str contains " ") { $"'($a)'" } else { $a }})
        print $"DepotDownloader ($shown | str join ' ')"
        return
    }

    mkdir $target_dir
    ^DepotDownloader ...$args

    print ""
    print "Done. In Steam: restart, then Properties -> Installed Files -> \"Verify integrity of game files\"."
}
