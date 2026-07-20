#!/usr/bin/env bash
set -a
source .env
set +a

DEBUG_ENABLED=false
for arg in "$@"; do
  case $arg in
    -d|--debug)
      DEBUG_ENABLED=true
      ;;
  esac
done

docker pull renovate/renovate:latest

#docker run -it --rm \
#  -e RENOVATE_TOKEN="$RENOVATE_GITHUB_TOKEN" \
#  -e RENOVATE_PLATFORM=github \
#  -e RENOVATE_REPOSITORIES=alexmickelson/ai_pantheon \
#  -e RENOVATE_AUTO_MERGE=true \
#  -e RENOVATE_IGNORE_TESTS=true \
#  renovate/renovate:latest
# docker run -it --rm \
#   -e RENOVATE_TOKEN="$RENOVATE_GITHUB_TOKEN" \
#   -e RENOVATE_PLATFORM=github \
#   -e RENOVATE_REPOSITORIES=alexmickelson/office-infrastructure \
#   -e RENOVATE_AUTO_MERGE=true \
#   -e RENOVATE_IGNORE_TESTS=true \
#   renovate/renovate:latest

DOCKER_DEBUG_FLAG=""
if [ "$DEBUG_ENABLED" = true ]; then
  DOCKER_DEBUG_FLAG="-e LOG_LEVEL=debug "
fi

docker run --rm \
  $DOCKER_DEBUG_FLAG \
  -e RENOVATE_TOKEN="$RENOVATE_FORGEJO_TOKEN" \
  -e RENOVATE_GITHUB_COM_TOKEN="$RENOVATE_GITHUB_TOKEN" \
  -e RENOVATE_PLATFORM=forgejo \
  -e RENOVATE_ENDPOINT=https://forgejo.alexmickelson.guru \
  -e RENOVATE_REPOSITORIES=alex/infrastructure \
  renovate/renovate:latest
# -e RENOVATE_DRY_RUN=full \
