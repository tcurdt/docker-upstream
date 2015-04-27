FROM tcurdt/busybox

ENV UPSTREAM_VERSION 1.0.0

RUN opkg-install \
    curl ca-certificates \
  && mkdir -p /srv/upstream \
  && curl -sL https://github.com/tcurdt/docker-upstream/releases/download/v${UPSTREAM_VERSION}/upstream_${UPSTREAM_VERSION}_linux_x86_64.tgz | zcat | tar -C /usr/bin -xf - \
  && opkg-cl remove \
    curl ca-certificates

VOLUME [ "/var/run/docker.sock", "/srv/upstream/generated" ]

COPY src/nginx.tpl /srv/upstream/nginx.tpl

WORKDIR /srv/upstream

ENTRYPOINT [ "upstream", "--output", "/srv/upstream/generated", "--reload", "nginx", "--template", "nginx.tpl" ]
