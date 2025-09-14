alias hf = helmfile

alias kubectl = kubecolor
alias k = kubectl

alias ka = kubectl apply
alias kaf = kubectl apply -f

alias kdel = kubectl delete
alias kdes = kubectl describe

alias keit = kubectl exec -it

alias kg = kubectl get
alias kgn = kubectl get nodes
alias kgp = kubectl get pods
alias kgs = kubectl get services

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
