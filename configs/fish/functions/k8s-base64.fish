function k8s-base64
    test (count $argv) -le 1; or return 2
    set -l token $argv[1]
    if test -z "$token"
        read --null token
    end
    test -n "$token"; or begin
        echo 'No token provided.' >&2
        return 2
    end
    printf %s "$token" | base64 -w 0
end
