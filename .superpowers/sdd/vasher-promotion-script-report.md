# Vasher Promotion Script Report

## Changed paths

- `scripts/vasher-promote.sh`
- `scripts/tests/test-vasher-promote.sh`
- `.superpowers/sdd/vasher-promotion-script-report.md`

## Safe verification

Command:

```bash
bash scripts/tests/test-vasher-promote.sh
```

Exact output:

```text
hint: Using 'master' as the name for the initial branch. This default branch name
hint: will change to "main" in Git 3.0. To configure the initial branch name
hint: to use in all of your new repositories, which will suppress this warning,
hint: call:
hint:
hint: 	git config --global init.defaultBranch <name>
hint:
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint:
hint: 	git branch -m <name>
hint:
hint: Disable this message with "git config set advice.defaultBranchName false"
hint: Using 'master' as the name for the initial branch. This default branch name
hint: will change to "main" in Git 3.0. To configure the initial branch name
hint: to use in all of your new repositories, which will suppress this warning,
hint: call:
hint:
hint: 	git config --global init.defaultBranch <name>
hint:
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint:
hint: 	git branch -m <name>
hint:
hint: Disable this message with "git config set advice.defaultBranchName false"
To /tmp/tmp.uA8mKTOXB0/remote.git
 * [new branch]      master -> master
Cloning into '/tmp/tmp.uA8mKTOXB0/checkout'...
done.
vasher-promote: checkout must be clean
Switched to a new branch 'feature'
vasher-promote: checkout must be on master
Switched to branch 'master'
To /tmp/tmp.uA8mKTOXB0/remote.git
 * [new branch]      HEAD -> cache-bump
Fetching origin...
From /tmp/tmp.uA8mKTOXB0/remote
 * [new branch]      cache-bump -> origin/cache-bump
Fast-forwarding master to cache-bump...
Updating ea57dde..7a55028
Fast-forward
 file | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
Pushing master...
To /tmp/tmp.uA8mKTOXB0/remote.git
   ea57dde..7a55028  master -> master
Switching NixOS host jezrien...
```

Exit status: `0`.

Command:

```bash
bash -n scripts/vasher-promote.sh scripts/tests/test-vasher-promote.sh
```

Exact output: none. Exit status: `0`.

The test uses a temporary local bare repository and stubbed `sudo`/`nh`; it does not contact a network remote or run a real rebuild.
