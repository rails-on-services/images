include ../make/docker.mk

SETUP_VERSION = $(shell curl -s 'https://api.github.com/repos/rails-on-services/setup/commits/master' | jq -r '.sha')
CLI_VERSION = $(shell curl -s 'https://api.github.com/repos/rails-on-services/ros-cli/commits/master' | jq -r '.sha')

BUILD_ARGS = --build-arg SETUP_VERSION=$(SETUP_VERSION) --build-arg CLI_VERSION=$(CLI_VERSION)

.PHONY: build
build: $(if $(USE_KANIKO),docker-kaniko-build,docker-build)

.PHONY: publish
publish: docker-publish

.PHONY: publish-latest
publish-latest: docker-publish-latest
