docker run --name upstream \
  --entrypoint /bin/sh \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /etc/nginx/upstream.d/generated:/srv/upstream/generated \
  --rm -it tcurdt/upstream
