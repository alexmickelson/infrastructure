FROM python:3.10-slim

RUN apt-get update && \
    apt-get install -y git curl && \
    git clone https://github.com/novnc/noVNC.git /opt/novnc && \
    pip install websockify && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/novnc

RUN echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0; url=/vnc.html"></head><body></body></html>' > /opt/novnc/index.html