# DockerX Upstream

Dynamically generates your configuration based on container meta data.

In practise this means you are running `nginx` in a docker container.

    docker run --name nginx \
      -p 0.0.0.0:80:80 \
      -p 0.0.0.0:443:443 \
      -v /srv/nginx:/srv/nginx \
      -v /etc/nginx/sites-enabled:/etc/nginx/sites-enabled \
      -v /etc/nginx/upstream.d:/etc/nginx/upstream.d \
      -dt tcurdt/nginx

And you are running another service you want to expose through `nginx`. Please not the label that 

    docker run --name myapp \
      --label org.vafer.upstream=8000 \
      -p 8000:8000
      -dt tcurdt/myapp

Now `upstream` generates the missing upstream configuration bit based on the docker container meta data. When the configuration changes it can even reload/restart other containers.

    upstream \
      --label org.vafer.upstream \
      --template /srv/upstream/nginx.tpl \
      --output /srv/upstream/generated \
      --reload nginx
      --follow # monitor docker containers

Typically you would run upstream inside a container itself as well

    docker run --name upstream \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v /etc/nginx/upstream.d/generated:/srv/upstream/generated \
      -dt tcurdt/dockerx-upstream \
      --label org.vafer.upstream \
      --template /srv/dockerx-upstream/nginx.tpl \
      --output /srv/dockerx-upstream/generated \
      --reload nginx \
      --follow

or just as a one-off command

    docker run --name upstream \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v /etc/nginx/upstream.d/generated:/srv/upstream/generated \
      -t tcurdt/dockerx-upstream \
      --label org.vafer.upstream \
      --template /srv/dockerx-upstream/nginx.tpl \
      --output /srv/dockerx-upstream/generated \
      --reload nginx

Also see the Dockerfile for more details.

The code is released under the Apache License 2.0.
