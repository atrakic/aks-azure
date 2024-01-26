MAKEFLAGS += --silent
BASEDIR=$(shell git rev-parse --show-toplevel)

NAME := demo
RG := rg-$(NAME)
AKS := aks-$(NAME)
LOCATION := westeurope

ifeq ($(origin ACR), undefined)
ACR = acr$(shell whoami)$(NAME)	# may contain alpha numeric characters only and must be between 5 and 50 characters
endif

export AZURE_DEFAULTS_GROUP=$(RG)
export AZURE_DEFAULTS_LOCATION=$(LOCATION)

all:
	set -x
	echo AZURE_DEFAULTS_LOCATION=$(LOCATION)
	echo AZURE_DEFAULTS_GROUP=$(RG)
	echo NAME=$(NAME)
	echo AKS=$(AKS)

aks.create: az-login
	az group create --name $(RG)
	az acr create --name $(ACR) --sku Basic --admin-enabled true
	az acr login --name $(ACR)
	az aks create \
		--name $(AKS) \
		--attach-acr $(ACR) \
		--node-count 1 \
		--generate-ssh-keys \
		--enable-cluster-autoscaler --min-count 1 --max-count 2 \
		--enable-managed-identity \
		--enable-app-routing
	az aks check-acr --name $(AKS) --acr $(ACR).azurecr.io
	$(MAKE) kubeconfig
	kubectl cluster-info -o wide
	kubectl get nodes

aks.stop:
	az aks stop --name $(AKS)

aks.start:
	az aks start --name $(AKS)
	$(MAKE) set.auth.ip

deploy.demo: az-login
	az acr build --image demo/my-app:v1 --registry $(ACR) --file $(BASEDIR)/src/demo/Dockerfile $(BASEDIR)/src/demo
	kubectl apply -f $(BASEDIR)/deployments/demo/manifest.yml

install.tools:
	az extension add --name aks-preview

#IP=$(shell dig +short "myip.opendns.com" "@resolver1.opendns.com")
IP=$(shell curl -skL ifconfig.me)
set.auth.ip:
	az aks update --name $(AKS) --api-server-authorized-ip-ranges $(IP)/32

kubeconfig:
	az aks get-credentials --name $(AKS) --overwrite-existing

az-login:
	az account show || az login

acr-list:
	az acr check-health -n $(ACR) --yes
	az acr repository list --name $(ACR)

clean:
	az group delete --name $(RG) --yes --no-wait
	az aks list

-include .env
