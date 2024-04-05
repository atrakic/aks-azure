MAKEFLAGS += --silent

OPTIONS ?= --build --remove-orphans --force-recreate

all:
	DOCKER_BUILDKIT=1 docker-compose up $(OPTIONS) -d

APP ?= lb
healthcheck:
	docker inspect $(APP) --format "{{ (index (.State.Health.Log) 0).Output }}"

test:
	DOCKER_BUILDKIT=1 docker-compose up test-client
	docker exec -it $(APP) cat /etc/nginx/conf.d/default.conf

clean:
	docker-compose down --remove-orphans -v
