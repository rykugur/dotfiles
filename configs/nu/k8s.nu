
$env.abbreviations = $env.abbreviations | merge {
  k: "kubectl"
  ka : "kubectl apply"
  kaf : "kubectl apply -f"
  kd : "kubectl describe"
  kdel : "kubectl delete"
  kdes : "kubectl describe"
  kg : "kubectl get"
  kgn : "kubectl get nodes"
  kgp : "kubectl get pods"
  kgs : "kubectl get services"
  kgw : "kubectl get -o wide"
  kgwn : "kubectl get -o wide nodes"
  kgwp : "kubectl get -o wide pods"
  kgws : "kubectl get -o wide services"
  kpf : "kubectl port-forward"
  ktx : "kubectx"
  kns : "kubens"
}

alias keit = kubectl exec -it

def "shlink create" [slug: string url: string] {
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
