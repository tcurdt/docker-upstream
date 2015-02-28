# docker build -t tcurdt/upstream . && docker push tcurdt/upstream
# docker run --name nginx-upstream --rm -it --entrypoint "bash" -v /var/run/docker.sock:/var/run/docker.sock -v /etc/nginx/upstream.d/generated:/srv/upstream/generated tcurdt/upstream

FROM ubuntu:14.04
RUN DEBIAN_FRONTEND=noninteractive apt-get -y update && \
  apt-get install -y \
    curl

# FROM progrium/busybox
# RUN opkg-install curl

RUN mkdir -p /srv/upstream
RUN touch /srv/upstream/generated
RUN curl -sL https://github.com/tcurdt/docker-upstream/releases/download/v0.0.1/upstream_0.0.1_linux_x86_64.tgz | tar -C /usr/local/bin -xzf -

VOLUME [ "/var/run/docker.sock", "/srv/upstream/generated" ]

COPY nginx.tpl /srv/upstream/nginx.tpl

WORKDIR /srv/upstream

ENTRYPOINT [ "upstream", "--output", "/srv/upstream/generated", "--reload", "nginx", "--template", "nginx.tpl" ]
