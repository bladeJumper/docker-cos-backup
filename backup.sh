#!/bin/sh

# generate file name for tar
if [[ -z ${USE_TIMESTAMP} ]];
then
    echo "USE_TIMESTAMP env var is not set"
    FILE_NAME=/tmp/$BACKUP_NAME.tar.gz
else
    echo "USE_TIMESTAMP env var is set, the archive filename contains current timestamp"
    FILE_NAME=/tmp/$BACKUP_NAME-`date "+%Y-%m-%d_%H-%M-%S"`.tar.gz
fi

# Check if TARGET variable is set
if [[ -z ${SOURCE} ]];
then
    echo "SOURCE env var is not set so we use the default value (/data)"
    SOURCE=./data
else
    echo "SOURCE env var is set"
fi

# Check if COS folder is set
if [[ -z ${COS_FOLDER} ]];
then
    echo "COS_FOLDER env var is not set so we use the default root path"
    COS_FOLDER=/
else
    echo "SOURCE env var is set"
fi

# archive data
echo "creating archive"
tar -zcvf $FILE_NAME $SOURCE

# upload to cos
coscmd -c /etc/cos/cos.conf upload $FILE_NAME $COS_FOLDER
# coscmd -c ./cos.conf upload $FILE_NAME $COS_FOLDER

# GOTIFY notification
if [ -n "$WEBHOOK_URL" ]; then
    echo "notifying ${WEBHOOK_URL}"
    curl -m 10 --retry 5 $WEBHOOK_URL -F "title=Backup ${FILE_NAME} uploaded to ${COS_FOLDER}" -F "message=backup uploaded to cos"
fi