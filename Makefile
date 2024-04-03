#MAKEFLAGS += --silent

BASEDIR=$(shell git rev-parse --show-toplevel)
GITHUB_SHA=$(shell git rev-parse --short HEAD)

ifeq ($(origin CONTAINER_REGISTRY), undefined)
CONTAINER_REGISTRY = acr$(NAME)
endif

#export AZURE_DEFAULTS_LOCATION=${AZURE_DEFAULTS_LOCATION:-westeurope}
#export AZURE_DEFAULTS_GROUP=${AZURE_DEFAULTS_GROUP:-rg-$(NAME)}

all: az-login acr-login aks-create build deploy-aspnetapp test

az-login: install-extensions
	az account show || az login
	if [ $$(az group exists --name $(RESOURCE_GROUP)) = false ]; then \
		az group create --name $(RESOURCE_GROUP); \
	fi; \
	az acr show --name $(CONTAINER_REGISTRY) --query loginServer --output tsv || \
		az acr create --name $(CONTAINER_REGISTRY) --sku Basic --admin-enabled true

aks-create:
	az aks show --name $(CLUSTER_NAME) --resource-group $(RESOURCE_GROUP) || az aks create \
		--name $(CLUSTER_NAME) \
		--resource-group $(RESOURCE_GROUP) \
		--location $(AZURE_DEFAULTS_LOCATION) \
		--attach-acr $(CONTAINER_REGISTRY) \
		--node-count 1 \
		--generate-ssh-keys \
		--enable-managed-identity \
		--enable-addons monitoring \
		--enable-app-routing
	$(MAKE) kubeconfig
	kubectl cluster-info
	kubectl get nodes -o wide

build: ## Build and push image to CONTAINER_REGISTRY
	az acr build \
		--image $(IMAGE_NAME) \
		--registry $(CONTAINER_REGISTRY) \
		--file $(BASEDIR)/$(DOCKERFILE) \
		$(BASEDIR)/$(SOURCE_PATH)

deploy-aspnetapp:
	kubectl apply -f $(BASEDIR)/k8s/aspnetapp/manifest.yml
	kubectl wait --for=condition=available --timeout=600s deployment/aspnetapp

test:
	curl -k -H "Host: aspnetapp.$(NAME)" https://$(shell kubectl get ing $(NAME) -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/healthz

clean: aks-stop
	az group delete --name $(RESOURCE_GROUP) --yes --no-wait
	az aks list

.PHONY: az-login aks-create aks-stop aks-start build deploy-aspnetapp acr-login kubeconfig install-extensions set-auth-ip clean

-include .env .include.mk
