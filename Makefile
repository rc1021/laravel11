# Platform and architecture detection
platform := $(shell uname -s)
arch := $(shell uname -m)

# Fix architecture format
ifeq ($(arch), arm64)
    arch_fixed := aarch64
else ifeq ($(arch), aarch64)
    arch_fixed := aarch64
else ifeq ($(arch), x86_64)
    arch_fixed := x86_64
else ifeq ($(arch), x64)
    arch_fixed := x86_64
else
    $(error "Unsupported architecture: $(arch)")
endif

# Fix OS format
ifeq ($(platform), Darwin)
    platform_fixed := macos
else ifeq ($(platform), Linux)
    platform_fixed := linux
else
    $(error "Current OS is not supported")
endif

direnv-reload:
	@if [ -f .envrc ]; then \
		if command -v direnv >/dev/null 2>&1; then \
			echo "Found .envrc and direnv installed. Reloading direnv..."; \
			direnv allow; \
		else \
			echo "direnv is not installed. Please install direnv to proceed."; \
		fi; \
	else \
		echo "No .envrc file found. Skipping direnv reload."; \
	fi
.PHONY: direnv-reload

.bin: .bin/php .bin/composer
.PHONY: .bin

.bin/php:
	mkdir -p .bin && \
	curl -#fSL -o .bin/php.tgz \
		"https://dl.static-php.dev/static-php-cli/bulk/php-$(PHP_VERSION)-cli-$(platform_fixed)-$(arch_fixed).tar.gz" && \
	tar -xvzf .bin/php.tgz -C .bin && \
	rm -rf .bin/php.tgz

.bin/composer:
	mkdir -p .bin && \
	curl -#fSL -o .bin/composer \
		"https://getcomposer.org/download/latest-stable/composer.phar" && \
	chmod u+x .bin/composer

.env:
	cp .env.example .env

vendor: .env direnv-reload .bin/composer
	composer install

app-key:
	@if [ -z "$$(grep "^APP_KEY=" .env | cut -d '=' -f2)" ]; then \
		php artisan key:generate; \
	fi
.PHONY: app-key

init: .bin .env vendor app-key
.PHONY: init

start-docker:
	docker-compose up -d
.PHONY: start-docker
