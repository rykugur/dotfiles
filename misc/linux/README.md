Quickie readme...

Cat these files to the appropriate targets to install base packages needed. E.g.:

Bash: 

```
pacman -S $(cat pacman.txt)
yaourt -S $(cat yaourt.txt)
```

fish:

```
pacman -S (cat pacman.txt)
yaourt -S
```

If you're feeling lazy, see [dotfiles]/configs/yaourtrc, specifically the settings for EDITFILES and BUILD_NOCONFIRM to have yaourt skip prompts and build everything. Warning: use at your own risk.
