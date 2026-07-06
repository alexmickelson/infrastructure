#!/usr/bin/env bash

set -a
source .env
set +a

docker pull renovate/renovate:latest


#docker run -it --rm \
#  -e RENOVATE_TOKEN="$RENOVATE_GITHUB_TOKEN" \
#  -e RENOVATE_PLATFORM=github \
#  -e RENOVATE_REPOSITORIES=alexmickelson/ai_pantheon \
#  -e RENOVATE_AUTO_MERGE=true \
#  -e RENOVATE_IGNORE_TESTS=true \
#  renovate/renovate:latest
docker run -it --rm \
  -e RENOVATE_TOKEN="$RENOVATE_GITHUB_TOKEN" \
  -e RENOVATE_PLATFORM=github \
  -e RENOVATE_REPOSITORIES=alexmickelson/office-infrastructure \
  -e RENOVATE_AUTO_MERGE=true \
  -e RENOVATE_IGNORE_TESTS=true \
  renovate/renovate:latest
  # -e LOG_LEVEL=debug \
