#!/bin/sh

COMMAND=$1
USERNAME=$2
PASSWD=$3
DATABASE=$4
PARAM1=$5
PARAM2=$6

usage() {
    cat <<EOF
Usage mysqlUtil.sh command username passwd database param1 param2

eg:
    mysqlUtil.sh recreate user pass testdb /opt/script/schema.sql /opt/script/data.sql

EOF
}

checkFail() {
    if [ $1 -ne 0 ]; then
        echo "==== Failure ===="
        echo $2
        echo "Removing marker ${DEPLOYTARGET} ${DEPLOY_STAGE}/deploy"
        ssh ${DEPLOYTARGET} "rm ${DEPLOY_STAGE}/deploy" > /dev/null
        exit 1
    fi
}

recreate() {
    SCHEMA="$PARAM1"
    DATA="$PARAM2"
    mysql -u ${USERNAME} -p${PASSWD} -e "drop database ${DATABASE}"
    mysql -u ${USERNAME} -p${PASSWD} -e "create database ${DATABASE}"
    checkFail $? "Create database ${DATABASE} failed."
    mysql -u ${USERNAME} -p${PASSWD} ${DATABASE} < "$SCHEMA"
    checkFail $? "Script failed: $SCHEMA"
    mysql -u ${USERNAME} -p${PASSWD} ${DATABASE} < "$DATA"
    checkFail $? "Script failed: $DATA"
}

case $COMMAND in

recreate)
    recreate
    exit 0;;

*)
    printf "Error: no $COMMAND command."
    usage
    exit 1;;
esac
