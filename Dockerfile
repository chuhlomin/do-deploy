FROM alpine:3.10

RUN apk --update add jq && \
    apk add openssh && \ 
    rm -rf /var/cache/apk/*

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
