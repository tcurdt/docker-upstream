FROM tcurdt/busybox

ENV UPSTREAM_VERSION 1.1.1

RUN opkg-install \
    curl ca-certificates \
  && mkdir -p /srv/upstream \
  && curl -sL https://github.com/tcurdt/docker-upstream/releases/download/${UPSTREAM_VERSION}/upstream_${UPSTREAM_VERSION}_linux_x86_64.tgz | zcat | tar -C /usr/bin -xf - \
  && opkg-cl remove \
    curl ca-certificates

VOLUME [ "/var/run/docker.sock", "/srv/upstream/generated" ]

COPY src/upstream/nginx.tpl /srv/upstream/nginx.tpl

WORKDIR /srv/upstream

ENTRYPOINT [ "upstream", "--output", "/srv/upstream/generated", "--reload", "nginx", "--template", "nginx.tpl", "--follow" ]
