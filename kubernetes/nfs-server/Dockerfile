FROM alpine:latest

RUN apk add --no-cache nfs-utils bash

RUN mkdir -p /exports

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 2049 20048

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

