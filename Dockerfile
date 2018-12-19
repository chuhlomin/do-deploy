FROM alpine:3.8

RUN apk --update add jq && \
    apk add openssh && \ 
    rm -rf /var/cache/apk/*

ADD script.sh /bin/
RUN chmod +x /bin/script.sh

ENTRYPOINT /bin/script.sh
