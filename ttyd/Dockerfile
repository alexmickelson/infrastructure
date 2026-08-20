FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates curl dbus-user-session fish fuse-overlayfs podman slirp4netns sudo supervisor ttyd uidmap \
    && groupmod --new-name alex ubuntu \
    && usermod --login alex --home /home/alex --move-home --shell /usr/bin/fish ubuntu \
    && usermod --groups alex alex \
    && usermod --add-subuids 100000-165535 --add-subgids 100000-165535 alex \
    && install --directory --owner=alex --group=alex /home/alex/workspace \
    && printf 'alex ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/alex \
    && chmod 0440 /etc/sudoers.d/alex \
    && visudo --check --file=/etc/sudoers.d/alex \
    && rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.2 --silent --show-error --fail --location \
        https://install.determinate.systems/nix \
    | sh -s -- install linux \
        --extra-conf 'sandbox = false' \
        --init none \
        --no-confirm

ENV HOME=/home/alex
ENV PATH="/nix/var/nix/profiles/default/bin:${PATH}"
ENV NIX_REMOTE=daemon
ENV NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV XDG_RUNTIME_DIR=/tmp/run-user-1000

RUN install --directory --owner=alex --group=alex /tmp/run-user-1000 \
    && ln --symbolic /home/alex/workspace /workspace

WORKDIR /home/alex/workspace
EXPOSE 7681

COPY supervisord.conf /etc/supervisor/supervisord.conf

ENTRYPOINT ["/usr/bin/supervisord", "--nodaemon", "--configuration", "/etc/supervisor/supervisord.conf"]
