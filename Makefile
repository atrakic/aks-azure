#MAKEFLAGS += --silent

BASEDIR=$(shell git rev-parse --show-toplevel)
GITHUB_SHA=$(shell git rev-parse --short HEAD)

ifeq ($(origin ACR), undefined)
ACR = acr$(shell whoami)$(NAME)
endif

export AZURE_DEFAULTS_LOCATION=${AZURE_DEFAULTS_LOCATION:-westeurope}
export AZURE_DEFAULTS_GROUP=${AZURE_DEFAULTS_GROUP:-rg-$(NAME)}

all: az-login acr-login aks-create build deploy-demo test

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
	kubectl get nodes -o wide

build: ## Build and push image to ACR
	az acr build \
		--image $(IMAGE_NAME) \
		--registry $(ACR) \
		--file $(BASEDIR)/$(DOCKERFILE) \
		$(BASEDIR)/$(SOURCE_PATH)

deploy-demo:
	kubectl apply -f $(BASEDIR)/k8s/demo/manifest.yml
	kubectl wait --for=condition=available --timeout=600s deployment/$(NAME)
	
test:	
	curl -k -H "Host: demo.adtr" https://$(shell kubectl get ing $(NAME) -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/healthz

clean: aks-stop
	az group delete --name $(RG) --yes --no-wait
	az aks list

.PHONY: az-login aks-create aks-stop aks-start build deploy-demo acr-login kubeconfig install-extensions set-auth-ip clean

-include .github/.env .include.mk
