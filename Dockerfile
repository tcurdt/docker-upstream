FROM tcurdt/busybox

ENV UPSTREAM_VERSION 1.2.0

RUN opkg-install \
    curl ca-certificates \
  && mkdir -p /srv/dockerx-upstream \
  && curl -sL https://github.com/tcurdt/dockerx-upstream/releases/download/${UPSTREAM_VERSION}/dockerx-upstream_${UPSTREAM_VERSION}_linux_x86_64.tgz | zcat | tar -C /usr/bin -xf - \
  && opkg-cl remove \
    curl ca-certificates

VOLUME [ "/var/run/docker.sock", "/srv/dockerx-upstream/generated" ]

COPY src/upstream/nginx.tpl /srv/dockerx-upstream/nginx.tpl

WORKDIR /srv/dockerx-upstream

ENTRYPOINT [ "dockerx-upstream" ]
CMD [ "--template", "/srv/dockerx-upstream/nginx.tpl", "upstream", "--output", "/srv/dockerx-upstream/generated", "--label", "org.vafer.upstream", "--reload", "nginx", "--follow" ]
