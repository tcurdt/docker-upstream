# FROM ubuntu:14.04
FROM busybox

RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && \
  apt-get install -y \
    curl

RUN mkdir -p /src/upstream
RUN touch /src/upstream/generated
RUN curl -s https://github.com/tcurdt/docker-upstream/archive/upstream_0.0.1_linux_x86_64.tgz | tar -C /usr/local -xzf -

VOLUME [ "/var/run/docker.sock", "/src/upstream/generated" ]

WORKDIR /srv/upstream

ENTRYPOINT [ "upstream", "--output", "/srv/upstream/generated" ]
CMD "--reload nginx --template nginx.tpl"
