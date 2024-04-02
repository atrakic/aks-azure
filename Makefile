MAKEFLAGS += --silent
BASEDIR=$(shell git rev-parse --show-toplevel)
GITHUB_SHA=$(shell git rev-parse --short HEAD)

ifeq ($(origin ACR), undefined)
ACR = acr$(shell whoami)$(NAME)
endif

export AZURE_DEFAULTS_LOCATION=${AZURE_DEFAULTS_LOCATION:-westeurope}
export AZURE_DEFAULTS_GROUP=${AZURE_DEFAULTS_GROUP:-rg-$(NAME)}

all: az-login acr-login aks-create build deploy-demo

az-login: install-extensions
	az account show || az login
	if [ $$(az group exists --name $(RG)) = false ]; then \
		az group create --name $(RG); \
	fi; \
	az acr show --name $(ACR) --query loginServer --output tsv || \
		az acr create --name $(ACR) --sku Basic --admin-enabled true

aks-create:
	az aks show --name $(AKS) --resource-group $(RG) || az aks create \
		--name $(AKS) \
		--resource-group $(RG) \
		--location $(AZURE_DEFAULTS_LOCATION) \
		--attach-acr $(ACR) \
		--node-count 1 \
		--generate-ssh-keys \
		--enable-managed-identity \
		--enable-addons monitoring \
		--enable-app-routing
	$(MAKE) kubeconfig
	kubectl cluster-info
	kubectl get nodes

aks-stop:
	az aks delete --name $(AKS) --resource-group $(RG) ## --yes --no-wait

aks-start:
	az aks start --name $(AKS)

build: ## Build and push image to ACR
	az acr build \
		--image $(IMAGE_NAME) \
		--registry $(ACR) \
		--file $(BASEDIR)/$(DOCKERFILE) \
		$(BASEDIR)/$(SOURCE_PATH)

deploy-demo:
	kubectl apply -f $(BASEDIR)/k8s/demo/manifest.yml
	# Waiting deployment to finish
	kubectl get service demo --watch

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

clean: aks-stop
	az group delete --name $(RG) --yes --no-wait
	az aks list

env-test:
	printenv | grep -E 'RG|ACR|AKS|IMAGE_NAME|DOCKER_PATH|SOURCE_PATH'
	echo IMAGE_NAME=$(IMAGE_NAME)
	echo CONTAINER_REGISTRY=$(CONTAINER_REGISTRY)
	echo ACR=$(ACR)

.PHONY: az-login aks-create aks-stop aks-start build deploy-demo acr-login kubeconfig install.extensions set-auth-ip clean

-include .github/.env
