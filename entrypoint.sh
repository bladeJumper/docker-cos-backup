#!/bin/sh
echo "creating crontab"
echo -e "$CRON_SCHEDULE /backup.sh\n" > /etc/crontabs/root
echo "starting crond"
if [ -n "$WEBHOOK_URL" ]; then
    echo "notifying ${WEBHOOK_URL}"
    if [ -n "$BACKUP_FILE" ]; 
    then
        curl -m 10 --retry 5 $WEBHOOK_URL -F "title=Backup to ${BACKUP_NAME} scheduled" -F "message=crontab: ${CRON_SCHEDULE}"
    fi
    if [ -n "$BACKUP_PG" ]; 
    then
        echo "*:*:*:*:$PG_PASSWORD" > ~/.pgpass
        chmod 0600 ~/.pgpass
        curl -m 10 --retry 5 -X POST $WEBHOOK_URL -H  "accept: application/json" -H  "Content-Type: application/json" -d "{  \"message\": \"crontab: ${CRON_SCHEDULE}\ndatabase host: ${PG_HOST}\",  \"title\": \"Database backup to ${PG_COS_FOLDER}${PG_COS_FILENAME} scheduled\"}"
    fi
fi
crond -f