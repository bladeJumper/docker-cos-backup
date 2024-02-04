FROM python:3.10-alpine3.19

RUN pip install coscmd
RUN apk update
RUN apk add curl

COPY entrypoint.sh /
COPY backup.sh /

RUN chmod +x /entrypoint.sh /backup.sh

ENTRYPOINT /entrypoint.sh