function kubemerge
    set -l kubeconfigs
    for config in "$HOME"/.kube/*.yaml
        test -f "$config"; and set --append kubeconfigs "$config"
    end

    test (count $kubeconfigs) -gt 0; or return 1
    set -lx KUBECONFIG (string join : $kubeconfigs)
    kubectl config view --flatten > "$HOME"/.kube/config
end
