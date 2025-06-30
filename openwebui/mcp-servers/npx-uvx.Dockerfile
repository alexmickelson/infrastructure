FROM ghcr.io/astral-sh/uv:debian

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    nodejs \
    npm \
  && npm install -g n \
  && n stable \
  && apt-get clean && rm -rf /var/lib/apt/lists/*