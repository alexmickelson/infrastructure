FROM debian

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
  curl \
  gnupg \
  xvfb \
  x11vnc \
  fluxbox \
  chromium \
  ca-certificates \
  x11-utils \
  nodejs \
  npm \
  make \
  g++ \
  pip \
  && npm install -g n \
  && n stable \
  && apt-get install -y pipx python3-venv \
  && pipx install uv \
  && apt-get clean && rm -rf /var/lib/apt/lists/*
ENV PATH="/root/.local/bin:${PATH}"

RUN npx playwright install chrome

# Environment variables
ENV DISPLAY=:99
ENV SCREEN_RESOLUTION=1280x720x24

# Startup script
RUN cat <<'EOF' > /playwright-start.sh
#!/bin/bash

# Start virtual display
Xvfb :99 -screen 0 $SCREEN_RESOLUTION &
sleep 2

# Start window manager
fluxbox &

# Start VNC server
x11vnc -nopw -display :99 -forever -shared &

# Start Playwright MCP
uvx mcpo --port 3901 --config mcpo-config.json

EOF

RUN chmod +x /playwright-start.sh
COPY mcpo-config.json mcpo-config.json
CMD ["/playwright-start.sh"]
