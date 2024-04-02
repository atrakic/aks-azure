aks-stop:
	az aks delete --name $(AKS) --resource-group $(RG) ## --yes --no-wait

aks-start:
	az aks start --name $(AKS)

acr-login: az-login
	az acr login --name $(ACR)
  #az acr check-health -n $(ACR) --yes
  #az aks check-acr --name $(AKS) --acr $(ACR).azurecr.io
  #az acr repository list --name $(ACR)

kubeconfig:
	type -a kubectl &>/dev/null || az aks install-cli
	az aks get-credentials --name $(AKS) --overwrite-existing

install-extensions:
	az extension add --name aks-preview

IP=$(shell curl -skL ifconfig.me)
set-auth-ip:
	az aks update --name $(AKS) --api-server-authorized-ip-ranges $(IP)/32
