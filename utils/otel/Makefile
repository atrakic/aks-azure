#export DOCKER_DEFAULT_PLATFORM=linux/amd64
export ID=$(shell git log -1 --format=%h)
export RANDOM=$(shell echo $$RANDOM)

all:
	docker-compose up --build --force-recreate --remove-orphans --no-color -d

clean:
	docker-compose down --remove-orphans -v --rmi local
