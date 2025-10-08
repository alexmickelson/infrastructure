#!/bin/bash

docker pull linuxserver/beets
docker rm -f beets || true
docker run -d \
    --name=beets \
    -v /data/media/music/sydnie-untagged/NewPipe:/sydnie \
    -v /data/media/music/Alex-untagged:/alex \
    -v /home/alex/beets/output:/config \
    -v /data/media/music/tagged:/config/music \
    -e PUID=1000 \
    -e PGID=1000 \
    linuxserver/beets

# docker exec -it -u 1000 beets bash -c "beet import -is /alex/*"