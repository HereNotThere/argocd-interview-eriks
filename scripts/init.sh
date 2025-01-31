if [ -z "$ENV" ]; then
  echo "ENV is not set"
  exit 1
fi

helm repo add argo https://argoproj.github.io/argo-helm
helm repo add external-secrets https://charts.external-secrets.io
helm repo add jetstack https://charts.jetstack.io 
helm repo update

helm install argocd argo/argo-cd -n argocd --create-namespace

echo "Creating environment $ENV"

kubectl apply -f "./environments/${ENV}/applications.yaml"