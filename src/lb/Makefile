MAKEFLAGS += --silent

OPTIONS ?= --build --remove-orphans --force-recreate

all:
	DOCKER_BUILDKIT=1 docker-compose up $(OPTIONS) -d

APP ?= lb
healthcheck:
	docker inspect $(APP) --format "{{ (index (.State.Health.Log) 0).Output }}"

test:
	DOCKER_BUILDKIT=1 docker-compose up $(OPTIONS) test-client

clean:
	docker-compose down --remove-orphans -v
