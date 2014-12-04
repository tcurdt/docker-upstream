NAME     := upstream
HARDWARE := $(shell uname -m)
VERSION  := $(shell cat VERSION)
TAG      := v$(VERSION)

all: release/$(NAME)_$(VERSION)_linux_$(HARDWARE).tgz

release/$(NAME)_$(VERSION)_linux_$(HARDWARE).tgz:
	go get -d
	mkdir -p release
	GOOS=linux go build -o release/$(NAME)
	cd release && tar -czf $(NAME)_$(VERSION)_linux_$(HARDWARE).tgz $(NAME)
	rm release/$(NAME)

clean:
	rm -rf release

release:
	git tag $(TAG)
	git push --tags
	~/bin/gh-release-upload $(TAG) tcurdt/$(NAME) $(NAME)

.PHONY: all clean release
