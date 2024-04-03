MAKEFLAGS += --silent

BASEDIR=$(shell git rev-parse --show-toplevel)
GITHUB_SHA=$(shell git rev-parse --short HEAD)

ifeq ($(origin CONTAINER_REGISTRY), undefined)
CONTAINER_REGISTRY = acr$(NAME)
endif

export AZURE_DEFAULTS_LOCATION=${AZURE_DEFAULTS_LOCATION:-westeurope}
export AZURE_DEFAULTS_GROUP=${AZURE_DEFAULTS_GROUP:-rg-$(NAME)}

all: az-login aks-create build deploy-aspnetapp test

az-login: install-extensions ## Login to Azure and set defaults
	az account show || az login
	if [ $$(az group exists --name $(RESOURCE_GROUP)) = false ]; then \
		az group create --name $(RESOURCE_GROUP); \
	fi

aks-create: ## Create AKS cluster
	az acr show --name $(CONTAINER_REGISTRY) -g $(RESOURCE_GROUP) --query loginServer --output tsv || \
		az acr create --name $(CONTAINER_REGISTRY) -g $(RESOURCE_GROUP) --sku Basic --admin-enabled true
	az aks show --name $(CLUSTER_NAME) -g $(RESOURCE_GROUP) || az aks create \
		--name $(CLUSTER_NAME) \
		-g $(RESOURCE_GROUP) \
		--location $(AZURE_DEFAULTS_LOCATION) \
		--attach-acr $(CONTAINER_REGISTRY) \
		--node-count 1 \
		--generate-ssh-keys \
		--enable-managed-identity \
		--enable-addons monitoring \
		--enable-app-routing # --enable-cluster-autoscaler --min-count 1 --max-count 2
	## az aks nodepool add -g $(RESOURCE_GROUP) --cluster-name $(CLUSTER_NAME) -n nodepool2 --enable-node-public-ip
	$(MAKE) kubeconfig
	kubectl cluster-info
	kubectl get nodes -o wide

build: acr-login ## Build and push image to CONTAINER_REGISTRY
	az acr build \
		--image $(IMAGE_NAME) \
		--registry $(CONTAINER_REGISTRY) \
		--file $(BASEDIR)/$(DOCKERFILE) \
		$(BASEDIR)/$(SOURCE_PATH)

deploy-aspnetapp: ## Deploy aspnetapp to AKS
	kubectl apply -f $(BASEDIR)/k8s/aspnetapp/manifest.yml
	kubectl wait --for=condition=available --timeout=600s deployment/aspnetapp

test-aks:
	@echo $(shell az aks show --name $(CLUSTER_NAME) -g $(RESOURCE_GROUP) --query provisioningState -o tsv)
	# list all nodes and their ips


test: ## Test aspnetapp
	curl -k -H "Host: aspnetapp.$(NAME)" \
		https://$(shell kubectl -n aspnetapp get ing aspnetapp -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/environment
	#curl --cacert <(kubectl -n cert-manager get secret test-ca-secret -o jsonpath='{.data.ca\.crt}' | base64 -d) https://aspnetapp.$(NAME)/environment

clean: aks-stop ## Delete AKS cluster and resource group
	az group delete --name $(RESOURCE_GROUP) --yes --no-wait
	az aks list
	az acr list

.PHONY: az-login aks-create aks-stop aks-start build deploy-aspnetapp acr-login kubeconfig install-extensions set-auth-ip clean test test-aks all az-create-application-insights

-include .env .include.mk
