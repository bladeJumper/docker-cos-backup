#!/bin/sh

CUR_TIMESTAMP=`date "+%Y-%m-%d_%H-%M-%S"`
if [[ -n "$BACKUP_FILE" ]];
then
    # generate file name for tar
    if [[ -z ${USE_TIMESTAMP} ]];
    then
        echo "USE_TIMESTAMP env var is not set"
        FILE_NAME=$BACKUP_NAME.tar.gz
        FILE_NAME_FULL=/tmp/$FILE_NAME
    else
        echo "USE_TIMESTAMP env var is set, the archive filename contains current timestamp"
        FILE_NAME=$BACKUP_NAME-$CUR_TIMESTAMP.tar.gz
        FILE_NAME_FULL=/tmp/$FILE_NAME
    fi
    echo "pg dump filename: ${FILE_NAME}"

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
    tar -zcvf $FILE_NAME_FULL $SOURCE
    COMPRESSED_FILE_SIZE=$(( $( stat -c '%s' $FILE_NAME_FULL ) / 1024 / 1024 ))

    # upload to cos
    coscmd -c /etc/cos/cos.conf upload $FILE_NAME_FULL $COS_FOLDER
    # coscmd -c ./cos.conf upload $FILE_NAME $COS_FOLDER

    # GOTIFY notification
    if [ -n "$WEBHOOK_URL" ]; then
        echo "notifying ${WEBHOOK_URL}"
        curl -m 10 --retry 5 -X POST $WEBHOOK_URL -H  "accept: application/json" -H  "Content-Type: application/json" -d "{  \"message\": \"backup uploaded to cos\nUploaded size: ${COMPRESSED_FILE_SIZE} MB\",  \"title\": \"Backup ${FILE_NAME} uploaded to ${COS_FOLDER}\"}"

    fi
fi

CUR_TIMESTAMP=`date "+%Y-%m-%d_%H-%M-%S"`
if [[ -n "$BACKUP_PG" ]];
then
    # check if Postgress target filename is set
    if [[ -z ${PG_COS_FILENAME} ]];
    then
        echo "PG_COS_FILENAME env var is not set so we use the default root path"
        PG_COS_FILENAME=db
    else
        echo "PG_COS_FILENAME env var is set"
    fi

    # populate file name for db dump
    if [[ -z ${USE_TIMESTAMP} ]];
    then
        echo "USE_TIMESTAMP env var is not set"
        FILE_NAME=$PG_COS_FILENAME.out
        FILE_NAME_FULL=/tmp/$FILE_NAME
    else
        FILE_NAME=$PG_COS_FILENAME-$CUR_TIMESTAMP.out
        FILE_NAME_FULL=/tmp/$FILE_NAME
        echo "USE_TIMESTAMP env var is set, the db archive filename contains current timestamp"
    fi
    echo "pg dump filename: ${FILE_NAME}"

    # check if postgresql COS folder is set
    if [[ -z ${PG_COS_FOLDER} ]];
    then
        echo "PG_COS_FOLDER env var is not set so we use the default root path"
        PG_COS_FOLDER=/
    else
        echo "PG_COS_FOLDER env var is set as ${PG_COS_FOLDER}"
    fi

    # Dump DB & compress
    pg_dumpall -h $PG_HOST -U $PG_USERNAME > $FILE_NAME_FULL
    RAW_FILE_SIZE=$(( $( stat -c '%s' $FILE_NAME_FULL ) / 1024 / 1024 ))
    tar -zcvf $FILE_NAME_FULL.tar.gz $FILE_NAME_FULL
    COMPRESSED_FILE_SIZE=$(( $( stat -c '%s' $FILE_NAME_FULL.tar.gz ) / 1024 / 1024 ))

    # upload to cos
    coscmd -c /etc/cos/cos.conf upload $FILE_NAME_FULL.tar.gz $PG_COS_FOLDER

    rm $FILE_NAME_FULL.tar.gz
    rm $FILE_NAME_FULL
    # GOTIFY notification
    if [ -n "$WEBHOOK_URL" ]; then
        echo "notifying ${WEBHOOK_URL}"
        curl -m 10 --retry 5 -X POST $WEBHOOK_URL -H  "accept: application/json" -H "Content-Type: application/json" -d "{  \"message\": \"postgresql backup uploaded\ndatabase host: ${PG_HOST}\nRaw size: ${RAW_FILE_SIZE} MB\nUploaded size: ${COMPRESSED_FILE_SIZE} MB\",  \"title\": \"Database backup ${FILE_NAME} uploaded to folder ${PG_COS_FOLDER}\"}"
    fi
fi