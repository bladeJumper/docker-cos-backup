#!/bin/sh
echo "creating crontab"
echo -e "$CRON_SCHEDULE /backup.sh\n" > /etc/crontabs/root
echo "starting crond"
crond -f
if [ -n "$WEBHOOK_URL" ]; then
    curl -m 10 --retry 5 $WEBHOOK_URL -F "title=Backup to ${BACKUP_NAME} Scheduled" -F "message=crontab: ${CRON_SCHEDULE}"
fi