In this exercise, we'd like you to add a new service to the gamma environment
of the argocd app of apps repo. This will be a simple stateless nginx lb fetched
from bitnami's helm repo. Please add the service as a LoadBalancer type, with a replica count of 2. Once the chart template and values are created, you can test by running the following make targets:

Please follow README.md to setup your pyenv and installing dependencies, which is needed for running jinja template rendering scripts.

```
make render_values ENV=gamma
make debug_chart CHART=nginx NAMESPACE=default ENV=gamma
```

Stretch goal:

Update the deployment to serve an index.html file below:
```
<!DOCTYPE html>
<html>
<head><title>Hello World</title></head>
<body><h1>Hello, World!</h1></body>
</html>
```

To test:

update the svc with `kubectl` and curl http://<external-ip>:<port>