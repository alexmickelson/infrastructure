FROM tailscale/tailscale:latest

RUN apk add --no-cache \
  openssh-client \
  bash \
  fish \
  shadow

RUN echo "/usr/bin/fish" >> /etc/shells && sed -i 's|/root:/bin/ash|/root:/usr/bin/fish|' /etc/passwd
COPY ./ssh-config.sh /ssh-config.sh
RUN chmod +x /ssh-config.sh
