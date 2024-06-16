MAKEFLAGS += --silent

BASEDIR=$(shell git rev-parse --show-toplevel)
GITHUB_SHA=$(shell git rev-parse --short HEAD)

ifeq ($(origin CONTAINER_REGISTRY), undefined)
CONTAINER_REGISTRY = acr$(NAME)
endif

export AZURE_DEFAULTS_LOCATION=${AZURE_DEFAULTS_LOCATION:-northeurope}
export AZURE_DEFAULTS_GROUP=${AZURE_DEFAULTS_GROUP:-rg-$(NAME)}

.DEFAULT_GOAL := help

.PHONY: all az-login aks-create build-acr deploy test clean


all: az-login aks-create build-acr deploy test ## Create AKS cluster, build and deploy app, test
	echo "Done"

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
	# wait for webapprouting loadBalancer to be ready
	#kubectl -n app-routing-system wait --for=condition=available --timeout=30s deployment/nginx
	#kubectl -n app-routing-system rollout status deployment/nginx

build-acr: acr-login ## Build and push image to CONTAINER_REGISTRY
	az acr build \
		--image $(IMAGE_NAME) \
		--registry $(CONTAINER_REGISTRY) \
		--file $(BASEDIR)/$(DOCKERFILE) \
		$(BASEDIR)/$(SOURCE_PATH)

deploy: ## Deploy app to AKS
	kubectl apply -f $(BASEDIR)/k8s/$(APP)/manifest.yml
	kubectl -n $(APP) wait --for=condition=available --timeout=600s deployment/$(APP)

aks-show:
	@echo $(shell az aks show --name $(CLUSTER_NAME) -g $(RESOURCE_GROUP) --query provisioningState -o tsv)

LB_IP=$(shell kubectl -n app-routing-system get svc nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
test: ## Test app
	curl -f -k -H "Host: $(APP).$(NAME)" \
		https://$(LB_IP)/

clean: aks-stop ## Delete AKS cluster and resource group
	az group delete --name $(RESOURCE_GROUP) --yes --no-wait
	az aks list
	az acr list
	make -f $(BASEDIR)/src/Makefile clean

.PHONY: help
help:
	cat $(MAKEFILE_LIST) | grep -e "^[a-zA-Z_\-]*: *.*## *" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

-include .github/.env .include.mk
