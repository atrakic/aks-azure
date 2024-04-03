aks-stop:
	az aks delete --name $(CLUSTER_NAME) --resource-group $(RESOURCE_GROUP) ## --yes --no-wait

aks-start:
	az aks start --name $(CLUSTER_NAME)

acr-login:
	az acr login --name $(CONTAINER_REGISTRY)
  #az acr check-health -n $(CONTAINER_REGISTRY) --yes
  #az aks check-acr --name $(CLUSTER_NAME) --acr $(CONTAINER_REGISTRY).azurecr.io
  #az acr repository list --name $(CONTAINER_REGISTRY)

kubeconfig:
	type -a kubectl &>/dev/null || az aks install-cli
	az aks get-credentials --name $(CLUSTER_NAME) --overwrite-existing

install-extensions:
	az extension add --name aks-preview

IP=$(shell curl -skL ifconfig.me)
set-auth-ip:
	az aks update --name $(CLUSTER_NAME) --api-server-authorized-ip-ranges $(IP)/32
