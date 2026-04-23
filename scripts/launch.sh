#!/bin/bash
set -e

# Enable and start docker
sudo systemctl enable docker
sudo systemctl start docker

sudo k3d cluster delete curashutaa || true

sudo k3d cluster create curashutaa \
  --agents 1 \
  --port "8080:80@loadbalancer"

export KUBECONFIG=$(k3d kubeconfig write curashutaa)

sudo kubectl wait --for=condition=Ready nodes --all --timeout=120s

# create namespaces (argocd & dev)

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
# Setup argoCD
sudo kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

sudo kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=180s

# Apply application
sudo kubectl apply -f /vagrant/p3/confs/application.yml

# expose the appication on a port
echo "ArgoCD UI:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
# sudo kubectl port-forward svc/argocd-server -n argocd 8080:443
