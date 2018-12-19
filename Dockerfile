FROM alpine:3.8

ADD script.sh /bin/
RUN chmod +x /bin/script.sh

ENTRYPOINT /bin/script.sh
