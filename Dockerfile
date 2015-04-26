FROM tcurdt/busybox

RUN opkg-install \
    curl \
    ca-certificates \
  && mkdir -p /srv/upstream \
  && curl -sL https://github.com/tcurdt/docker-upstream/releases/download/v0.0.1/upstream_0.0.1_linux_x86_64.tgz | zcat | tar -C /usr/bin -xf - \
  && opkg-cl remove \
    curl \
    ca-certificates

VOLUME [ "/var/run/docker.sock", "/srv/upstream/generated" ]

COPY nginx.tpl /srv/upstream/nginx.tpl

WORKDIR /srv/upstream

ENTRYPOINT [ "upstream", "--output", "/srv/upstream/generated", "--reload", "nginx", "--template", "nginx.tpl" ]

# docker run --name upstream \
#   --entrypoint /bin/sh \
#   -v /var/run/docker.sock:/var/run/docker.sock \
#   -v /etc/nginx/upstream.d/generated:/srv/upstream/generated \
#   --rm -it tcurdt/upstream
