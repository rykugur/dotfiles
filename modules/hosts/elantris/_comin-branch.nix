# Same pilot pattern as nale: deploy from the rollout branch, not master.
#
# Promotion: delete this file and its import, push to the pilot branch, let
# the host converge on that commit (it is then tracking master), then merge.
{ ryk.comin.branch = "comin-rollout-plan"; }
