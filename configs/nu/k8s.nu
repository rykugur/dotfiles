
$env.abbreviations = $env.abbreviations | merge {
  k: "kubectl"
  ka : "kubectl apply"
  kaf : "kubectl apply -f"
  kd : "kubectl describe"
  kdel : "kubectl delete"
  kdes : "kubectl describe"
  keit : "kubectl exec -it"
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

alias hf = helmfile
alias fgk = flux get kustomization
alias mk = minikube

def "kaf sops" [filePath: string] {
  use std/log
  
  if (not ($filePath | path exists)) {
    log error $"filePath ($filePath) doesn't exist; exiting."
    return;
  }

  sops -d $filePath | kubectl apply -f -
}
