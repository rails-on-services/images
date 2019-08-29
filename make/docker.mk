DOCKER_REPO = railsonservices
IMAGE_NAME = $(shell basename $(CURDIR))
COMMIT_SHA = $(shell git rev-parse --short HEAD)

export DOCKER_BUILDKIT=1

.PHONY: docker-build
docker-build:
	docker build --progress=plain $(BUILD_ARGS) -t $(DOCKER_REPO)/$(IMAGE_NAME) .

.PHONY: docker-publish
docker-publish: ## Publish the image with short commit hash as tag
	docker tag $(DOCKER_REPO)/$(IMAGE_NAME) $(DOCKER_REPO)/$(IMAGE_NAME):$(COMMIT_SHA)
	docker push $(DOCKER_REPO)/$(IMAGE_NAME):$(COMMIT_SHA)

.PHONY: docker-publish-latest
docker-publish-latest:
	docker push $(DOCKER_REPO)/$(IMAGE_NAME)