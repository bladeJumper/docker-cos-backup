FROM alpine:3.15

RUN \
	apk -Uuv add groff less python3 py3-pip curl && \
	pip3 install --no-cache-dir coscmd==1.8.6.34 && \
	apk --purge -v del py-pip && \
	rm /var/cache/apk/*

COPY entrypoint.sh /
COPY dobackup.sh /

RUN chmod +x /entrypoint.sh /backup.sh

ENTRYPOINT /entrypoint.sh