NAME     := upstream
HARDWARE := $(shell uname -m)
VERSION  := $(shell cat src/upstream/VERSION)
TAG      := $(VERSION)
TOKEN    := $(shell cat $$HOME/.github-release)
ARCHIVE  := $(NAME)_$(VERSION)_linux_$(HARDWARE).tgz

OBJECTS  := release/$(ARCHIVE)

all: $(OBJECTS)

build:
	GOOS=linux go build upstream

release/$(ARCHIVE):
	source `type -p gvp`
	gpm install
	mkdir -p release
	GOOS=linux go build -o release/$(NAME) upstream
	cd release && tar -czf $(ARCHIVE) $(NAME)
	rm release/$(NAME)

clean:
	rm -rf release

tag:
	git tag -f -a "$(TAG)" -m "release $(TAG)"

release:
	git push --tags
	GITHUB_TOKEN=$(TOKEN) github-release upload \
		--user tcurdt \
		--repo docker-upstream \
		--tag $(TAG) \
		--name $(ARCHIVE) \
		--file release/$(ARCHIVE)

.PHONY: all build clean tag release 
