export ENV 

# Renders values.yaml files for the specified environment
render_values: _check_env
	@echo "Generating values for $(ENV)"

	ENV=$(ENV) python ./templates/environment.py \
		--params "./environments/${ENV}/values.yaml" \
		--destination "./environments/${ENV}/rendered" \
		--templates "./templates"
	
	@echo "Values rendered for $(ENV)"
	$(MAKE) _format_values

# Creates the environment in the cluster
init: _check_env _add_helm_repos
	@echo "Creating environment $(ENV)"

	$(MAKE) render_values ENV=$(ENV)

	helm install argocd argo/argo-cd -n argocd --create-namespace
	
	# wait for argocd to be ready
	kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

	kubectl apply -f "./environments/${ENV}/applications.yaml"

_format_values:
	@echo "Formatting values.yaml files"
	yarn prettier:fix

# Checks if the ENV variable is set
_check_env:
	@if [ -z "$(ENV)" ]; then \
		echo "ERROR: ENV is not set"; \
		exit 1; \
	fi
	@echo "ENV is set to $(ENV)"

# Adds the necessary helm repos
_add_helm_repos:
	helm repo add argo https://argoproj.github.io/argo-helm
	helm repo add external-secrets https://charts.external-secrets.io
	helm repo add external-dns https://charts.bitnami.com/bitnami
	helm repo add jetstack https://charts.jetstack.io 
	helm repo update
