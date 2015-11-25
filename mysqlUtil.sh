#!/bin/sh

PROGNAME=$0
PROG_PID=$$
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
    local ERRSTAT=$1
    local ERRLINE=$2
    local ERRMSG=$3

    if [ $ERRSTAT -ne 0 ]; then
        echo "==== Failure ===="
        if [ -n "$ERRMSG" ]; then
            echo $ERRMSG
        fi
        echo "$PROGNAME failed at ${ERRLINE}."
        exit 1
    fi
    return 0
}

recreate() {
    SCHEMA="$PARAM1"
    DATA="$PARAM2"
    mysql -u ${USERNAME} -p${PASSWD} -e "drop database ${DATABASE}"
    mysql -u ${USERNAME} -p${PASSWD} -e "create database ${DATABASE}"
    checkFail $? recreate:$LINENO "Create database ${DATABASE} failed."
    mysql -u ${USERNAME} -p${PASSWD} ${DATABASE} < "$SCHEMA"
    checkFail $? recreate:$LINENO "Script failed installing schema: $SCHEMA"
    mysql -u ${USERNAME} -p${PASSWD} ${DATABASE} < "$DATA"
    checkFail $? recreate:$LINENO "Script failed installing data: $DATA"
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
