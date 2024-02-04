FROM python:3.13.0a3-alpine3.19

RUN pip install coscmd

COPY entrypoint.sh /
COPY backup.sh /

RUN chmod +x /entrypoint.sh /backup.sh

ENTRYPOINT /entrypoint.sh