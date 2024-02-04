FROM python:3.13.0a3-alpine3.19

RUN pip install coscmd

COPY entrypoint.sh /
COPY dobackup.sh /

RUN chmod +x /entrypoint.sh /dobackup.sh

ENTRYPOINT /entrypoint.sh