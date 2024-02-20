MAKEFLAGS += --silent
BASEDIR=$(shell git rev-parse --show-toplevel)

NAME := demo
RG := rg-$(NAME)
AKS := aks-$(NAME)
LOCATION := westeurope

ifeq ($(origin ACR), undefined)
ACR = acr$(shell whoami)$(NAME)
endif

export AZURE_DEFAULTS_GROUP=$(RG)
export AZURE_DEFAULTS_LOCATION=$(LOCATION)

az-login:
	az account show || az login
	az group exists --name $(RG) || az group create --name $(RG)
	az acr show --name $(ACR) --query loginServer --output tsv || az acr create --name $(ACR) --sku Basic --admin-enabled true
	echo AZURE_DEFAULTS_LOCATION=$(LOCATION)
	echo AZURE_DEFAULTS_GROUP=$(RG)
	echo AKS=$(AKS)
	echo ACR=$(ACR)

aks.create: az-login
	az aks create \
		--name $(AKS) \
		--attach-acr $(ACR) \
		--node-count 1 \
		--generate-ssh-keys \
		--enable-cluster-autoscaler --min-count 1 --max-count 2 \
		--enable-managed-identity \
		--enable-addons monitoring \
		--enable-app-routing
	$(MAKE) kubeconfig
	kubectl cluster-info -o wide
	kubectl get nodes

aks.stop:
	az aks stop --name $(AKS)

aks.start:
	az aks start --name $(AKS)

deploy.demo: az-login ## Build and push image to ACR
	#az acr check-health -n $(ACR) --yes
	#az aks check-acr --name $(AKS) --acr $(ACR).azurecr.io
	#az acr repository list --name $(ACR)
	az acr login --name $(ACR)
	az acr build --image demo/my-app:v1 --registry $(ACR) --file $(BASEDIR)/src/demo/Dockerfile $(BASEDIR)/src/demo
	kubectl apply -f $(BASEDIR)/k8s/demo/manifest.yml
	# Waiting deployment to finish
	kubectl get service demo --watch

kubeconfig:
	type -a kubectl &>/dev/null || az aks install-cli
	az aks get-credentials --name $(AKS) --overwrite-existing

install.extensions:
	az extension add --name aks-preview

IP=$(shell curl -skL ifconfig.me)
set.auth.ip:
	az aks update --name $(AKS) --api-server-authorized-ip-ranges $(IP)/32

acr.login:
	az acr credential show -n $(ACR) --query passwords[0].value --output tsv | docker login $(ACR).azurecr.io -u admin --password-stdin

clean:
	az group delete --name $(RG) --yes --no-wait
	az aks list

-include .env
