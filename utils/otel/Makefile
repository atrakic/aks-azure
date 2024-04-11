
export ID=$(shell git log -1 --format=%h)
export RANDOM=$(shell echo $$RANDOM)

all:
	docker-compose up --build --force-recreate --remove-orphans --no-color -d

build: clean ## Build all Docker Containers
	docker-compose build

stop: ## Stop all Docker Containers run in Compose
	docker-compose stop

clean: ## Clean all Docker Containers and Volumes
	docker-compose down --remove-orphans -v --rmi local
	docker-compose rm -f -v

logs: ## Show logs of all Docker Containers
	docker-compose logs -f

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
