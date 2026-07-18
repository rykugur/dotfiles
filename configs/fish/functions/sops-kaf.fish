function sops-kaf
    test (count $argv) -eq 1; or return 2
    test -f "$argv[1]"; or begin
        echo "file does not exist: $argv[1]" >&2
        return 1
    end
    sops -d "$argv[1]" | kubectl apply -f -
end
