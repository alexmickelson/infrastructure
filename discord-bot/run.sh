#!/bin/bash

docker pull node:20
docker pull python:3.12
docker build -t discord-bot .
# docker run -it --rm discord-bot


echo $DISCORD_SECRET
docker rm -f discord-bot || true
docker run -d \
  --name discord-bot \
  -e DISCORD_SECRET=$DISCORD_SECRET \
  --restart always \
  -p 0.0.0.0:5677:5677 \
  -p 0.0.0.0:5678:5678 \
  discord-bot
