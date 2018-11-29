all: clean build-prod

RELEASE_VERSION != awk '/version:/ { gsub(/[^0-9a-z\.\-]+/, "", $$2); print $$2 }' < apps/ewallet/mix.exs
IMAGE_NAME      ?= "omisego/ewallet:dev"
IMAGE_BUILDER   ?= "omisegoimages/ewallet-builder:stable"
IMAGE_BUILD_DIR ?= "/tmp/ewallet-docker"

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

clean: clean-ewallet clean-assets

clean-ewallet:
	rm -rf _build/
	rm -rf deps/

clean-assets:
	rm -rf apps/admin_panel/assets/node_modules
	rm -rf apps/admin_panel/priv/static

.PHONY: clean clean-ewallet clean-assets

#
# Linting
#

format:
	mix format

check-format:
	mix format --check-formatted

check-credo:
	mix credo

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

test-ewallet: build-test
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
		-v $(IMAGE_BUILD_DIR)/elixir_deps:/app/deps \
		-v $(IMAGE_BUILD_DIR)/node_modules:/app/apps/admin_panel/assets/node_modules \
		-u root \
		--entrypoint /bin/sh \
		$(IMAGE_BUILDER) \
		-c "cd /app && make build-prod"

docker-build:
	docker build \
		--build-arg release_version=$(RELEASE_VERSION) \
		--cache-from $(IMAGE_NAME) \
		-t $(IMAGE_NAME) \
		.

docker: docker-prod docker-build

.PHONY: docker docker-prod docker-build
