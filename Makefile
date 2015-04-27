NAME     := upstream
HARDWARE := $(shell uname -m)
VERSION  := $(shell cat src/upstream/VERSION)
TAG      := v$(VERSION)

OBJECTS  := release/$(NAME)_$(VERSION)_linux_$(HARDWARE).tgz

all: $(OBJECTS)

build:
	GOOS=linux go build upstream

release/$(NAME)_$(VERSION)_linux_$(HARDWARE).tgz:
	source `type -p gvp`
	gpm install
	mkdir -p release
	GOOS=linux go build -o release/$(NAME) upstream
	cd release && tar -czf $(NAME)_$(VERSION)_linux_$(HARDWARE).tgz $(NAME)
	rm release/$(NAME)

clean:
	rm -rf release

release: all
	git tag $(TAG)
	git push --tags
	FILENAME=$(NAME)_$(VERSION)_linux_$(HARDWARE).tgz
	GITHUB_TOKEN=`cat $HOME/.github-release` github-release upload \
		--user tcurdt \
		--repo docker-upstream \
		--tag $(TAG) \
		--name $(FILENAME) \
		--file release/$(FILENAME)

.PHONY: all clean release build
