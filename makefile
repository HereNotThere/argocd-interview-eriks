# ENV is required to be set
ifndef ENV
$(error ENV is not set)
endif

# init command
init:
	helm repo add argo https://argoproj.github.io/argo-helm
	helm repo add external-secrets https://charts.external-secrets.io
	helm repo add external-dns https://charts.bitnami.com/bitnami
	helm repo add jetstack https://charts.jetstack.io 
	helm repo update

	helm install argocd argo/argo-cd -n argocd --create-namespace

	echo "Creating environment $ENV"

	make create_apps
	
create_apps:
	# wait for argocd to be ready
	kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

	kubectl apply -f "./environments/${ENV}/applications.yaml"

generate:
	echo "Generating values for $ENV"

	python ./templates/environment.py \
		--params "./environments/${ENV}/values.yaml" \
		--destination "./environments/${ENV}/rendered" \
		--templates "./templates"