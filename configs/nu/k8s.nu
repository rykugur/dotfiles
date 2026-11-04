
alias kubectl = kubecolor

$env.abbreviations = $env.abbreviations | merge {
  k: "kubectl"
  ka : "kubectl apply"
  kaf : "kubectl apply -f"
  kak : "kubectl apply -k"
  kd : "kubectl describe"
  kdel : "kubectl delete"
  kdes : "kubectl describe"
  kdp : "kubectl describe pod"
  kdn : "kubectl describe node"
  kdd : "kubectl describe deployment"
  ked : "kubectl edit"
  kg : "kubectl get"
  kgcm : "kubectl get configmaps"
  kgd : "kubectl get deployments"
  kgev : "kubectl get events --sort-by=.lastTimestamp"
  kgi : "kubectl get ingress"
  kgn : "kubectl get nodes"
  kgns : "kubectl get namespaces"
  kgp : "kubectl get pods"
  kgpa : "kubectl get pods -A"
  kgpvc : "kubectl get pvc"
  kgs : "kubectl get services"
  kgw : "kubectl get -o wide"
  kgwn : "kubectl get -o wide nodes"
  kgwp : "kubectl get -o wide pods"
  kgws : "kubectl get -o wide services"
  kgy : "kubectl get -o yaml"
  kl : "kubectl logs"
  klf : "kubectl logs -f"
  klp : "kubectl logs --previous"
  kpf : "kubectl port-forward"
  krr : "kubectl rollout restart"
  krs : "kubectl rollout status"
  krh : "kubectl rollout history"
  ktx : "kubectx"
  kns : "kubens"
}

def kubemerge [] {
  ls ~/.kube/*.yaml
    | get name
    | str join ":"
    | do { |kubeconfig| KUBECONFIG=$kubeconfig kubectl config view --flatten | save -f ~/.kube/config } $in
}

def talosmerge [] {
  ls ~/.talos/*.yaml
    | get name
    | str join ":"
    | do { |talosconfig| TALOSCONFIG=$talosconfig talosctl config view | save -f ~/.talos/config } $in
}

alias keit = kubectl exec -it

def "shlink create" [--slug: string --url: string] {
  kubectl --namespace shlink exec -it deployments/shlink -- bin/cli short-url:create --custom-slug $slug $url
}

def "shlink list" [] {
  kubectl --namespace shlink exec -it deployments/shlink -- bin/cli short-url:list
}

alias hf = helmfile
alias fgk = flux get kustomization
alias mk = minikube

def "sops kaf" [filePath: string] {
  use std/log
  
  if (not ($filePath | path exists)) {
    log error $"filePath ($filePath) doesn't exist; exiting."
    return;
  }

  sops -d $filePath | kubectl apply -f -
}

def "k8s base64" [token?: string] {
  use std/log

  let finalToken = $token
  
  if ($finalToken | is-empty) {
    let finalToken = $in
  }

  if ($finalToken | is-empty) {
    log error "No token provided. Either pass as an arg or via stdin."
  }

  $finalToken | base64 -w 0
}
