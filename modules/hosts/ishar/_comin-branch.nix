# Pilot: deploy from the rollout branch, not master. Imported by both the CT
# template (`_image.nix`) and the real system (`default.nix`) — the seed has to
# agree, or a freshly provisioned container polls a branch that has no
# `nixosConfigurations.ishar` and never converges.
#
# Promotion: delete this file and its two imports, push to the pilot branch,
# let the host converge on that commit (it is then tracking master), then merge.
{ ryk.comin.branch = "comin-rollout-plan"; }
