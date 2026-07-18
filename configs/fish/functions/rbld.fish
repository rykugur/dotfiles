function rbld
    argparse -n rbld b/boot -- $argv; or return
    if set -q _flag_boot
        rbld-boot
    else
        rbld-switch
    end
end
