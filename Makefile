NAME       := upstream
HARDWARE   := $(shell uname -m)
VERSION    := $(shell cat src/upstream/VERSION)
TAG        := $(VERSION)
PWD        := $(shell pwd)
TOKEN      := $(shell cat $$HOME/.github-release)
TGZ_LINUX  := $(NAME)_$(VERSION)_linux_$(HARDWARE).tgz
TGZ_DARWIN := $(NAME)_$(VERSION)_darwin_$(HARDWARE).tgz

OBJECTS    := build/$(TGZ_LINUX) build/$(TGZ_DARWIN)

all: $(OBJECTS)

clean:
	rm -rf build .godeps

.godeps:
	GOPATH=$(PWD)/.godeps:$(PWD) gpm install

build/$(TGZ_LINUX): .godeps
	mkdir -p build
	GOPATH=$(PWD)/.godeps:$(PWD) GOOS=linux go build -o build/$(NAME) upstream
	cd build && tar -czf $(TGZ_LINUX) $(NAME)
	mv build/$(NAME) build/$(NAME)-linux

boot2docker: build/$(TGZ_LINUX)
	scp -i ~/.ssh/id_boot2docker build/$(NAME)-linux docker@`boot2docker ip`:

build/$(TGZ_DARWIN): .godeps
	mkdir -p build
	GOPATH=$(PWD)/.godeps:$(PWD) GOOS=darwin go build -o build/$(NAME) upstream
	cd build && tar -czf $(TGZ_DARWIN) $(NAME)
	mv build/$(NAME) build/$(NAME)-darwin

release: all
	git tag -f -a "$(TAG)" -m "release $(TAG)"
	git push --tags
	GITHUB_TOKEN=$(TOKEN) github-release release \
		--user tcurdt \
		--repo docker-upstream \
		--tag $(TAG)
	GITHUB_TOKEN=$(TOKEN) github-release upload \
		--user tcurdt \
		--repo docker-upstream \
		--tag $(TAG) \
		--name $(TGZ_LINUX) \
		--file build/$(TGZ_LINUX)
	GITHUB_TOKEN=$(TOKEN) github-release upload \
		--user tcurdt \
		--repo docker-upstream \
		--tag $(TAG) \
		--name $(TGZ_DARWIN) \
		--file build/$(TGZ_DARWIN)

.PHONY: all clean release boot2docker
