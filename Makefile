all: clean build-prod

IMAGE_NAME      ?= "omisego/ewallet:latest"
IMAGE_BUILDER   ?= "omisegoimages/ewallet-builder:v1.2"
IMAGE_BUILD_DIR ?= $(PWD)

ASSETS          ?= cd apps/admin_panel/assets &&
ENV_DEV         ?= env MIX_ENV=dev
ENV_TEST        ?= env MIX_ENV=test
ENV_PROD        ?= env MIX_ENV=prod

LANG            := en_US.UTF-8
LC_ALL          := en_US.UTF-8

#
# Setting-up
#

deps: deps-ewallet deps-assets

deps-ewallet:
	mix deps.get

deps-assets:
	cd apps/admin_panel/assets && \
		yarn install

.PHONY: deps deps-ewallet deps-assets

#
# Cleaning
#

clean: clean-ewallet clean-assets clean-test-assets

clean-ewallet:
	rm -rf _build/
	rm -rf deps/

clean-assets:
	rm -rf apps/admin_panel/assets/node_modules
	rm -rf apps/admin_panel/priv/static

clean-test-assets:
	rm -rf private/
	rm -rf public/
	rm -rf _build/test/lib/url_dispatcher/priv/static/private/*
	rm -rf _build/test/lib/url_dispatcher/priv/static/public/test-*
	rm -rf _build/test/lib/url_dispatcher/priv/static/public/test/

.PHONY: clean clean-ewallet clean-assets clean-test-assets

#
# Linting
#

format:
	mix format

check-format:
	mix format --check-formatted

check-credo:
	mix credo

check-dialyzer:
	mix dialyzer --halt-exit-status

.PHONY: format check-format check-credo

#
# Building
#

build-assets: deps-assets
	cd apps/admin_panel/assets && \
		yarn build

# If we call mix phx.digest without mix compile, mix release will silently fail
# for some reason. Always make sure to run mix compile first.
build-prod: deps-ewallet build-assets
	env MIX_ENV=prod mix compile
	env MIX_ENV=prod mix phx.digest
	env MIX_ENV=prod mix release

build-test: deps-ewallet
	env MIX_ENV=test mix compile

.PHONY: build-assets build-prod build-test

#
# Testing
#

test: test-ewallet test-assets

test-ewallet: clean-test-assets build-test
	env MIX_ENV=test mix do ecto.create, ecto.migrate, test

test-assets: build-assets
	cd apps/admin_panel/assets && \
		yarn test

.PHONY: test test-ewallet test-assets

#
# Docker
#

docker-prod:
	docker run --rm -it \
		-v $(PWD):/app \
		-v $(IMAGE_BUILD_DIR)/deps:/app/deps \
		-v $(IMAGE_BUILD_DIR)/apps/admin_panel/assets/node_modules:/app/apps/admin_panel/assets/node_modules \
		-u root \
		--entrypoint /bin/sh \
		$(IMAGE_BUILDER) \
		-c "cd /app && make build-prod"

docker-build:
	docker build \
		--build-arg release_version=$$(awk '/version:/ { gsub(/[^0-9a-z\.\-]+/, "", $$2); print $$2 }' $(PWD)/apps/ewallet/mix.exs) \
		--cache-from $(IMAGE_NAME) \
		-t $(IMAGE_NAME) \
		.

docker: docker-prod docker-build

docker-push: docker
	docker push $(IMAGE_NAME)

.PHONY: docker docker-prod docker-build docker-push
