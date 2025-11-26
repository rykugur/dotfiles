alias hf = helmfile

# alias kubectl = kubecolor
alias k = kubectl

alias ka = kubectl apply
alias kaf = kubectl apply -f

alias kd = kubectl describe

alias kdel = kubectl delete
alias kdes = kubectl describe

alias keit = kubectl exec -it

alias kg = kubectl get
alias kgn = kubectl get nodes
alias kgp = kubectl get pods
alias kgs = kubectl get services

alias kgw = kubectl get -o wide
alias kgwn = kubectl get -o wide nodes
alias kgwp = kubectl get -o wide pods
alias kgws = kubectl get -o wide services

alias kpf = kubectl port-forward

alias ktx = kubectx
alias kns = kubens

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
