#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git
#
# Control multiple tomcat instances.
#
ENVLOCATION=$1
COMMAND=$2
COMMAND_LIST="\tstatus - is the instance running\n\tup - upgrade ie clear logs, copy new war
\tstart - start the instance\n\tstop - stop the instance\n\trestart - stop, clear the logs, start\n"

if [ -z "$COMMAND" ]; then
    echo "Path to environment file tomcat.env not set."
    echo
    echo "Usage: tomcatCtl /catalinabase <cmd>"
    echo "       tomcatCtl . <cmd>"
    echo "'.' when pwd is catalinabase or a child of."
    echo "NOTE: catalinabase must contain the tomcat.env"
    echo
    printf "Commands:\n  $COMMAND_LIST"
    exit;
fi

ENVFILE_LOCATION=`find_up.sh  tomcat.env $ENVLOCATION`
if [ -z "$ENVFILE_LOCATION" ]; then
    echo Environment file $ENVFILE_LOCATION/tomcat.env does not exist.
    exit;
fi

#TOMCAT_HOME=${t%/*}
CATALINA_BASE=$ENVFILE_LOCATION
SERVERCONF=$CATALINA_BASE/conf/server.xml
if [ -z "$SERVERCONF" ]; then
    echo Tomcat environment file $SERVERCONF does not exist.
    exit;
fi

ENVFILE=$ENVFILE_LOCATION/tomcat.env

. $ENVFILE
BUP_JAVA_OPTS=$JAVA_OPTS

if [ -z "$JAVA_HOME" ]; then
    echo "Java unconfigured. Exit." > /dev/stderr
    return
fi

#tomcat.env example
#
# JDK_NO=7
# . jdkenv
#
#export CATALINA_HOME=/opt/dev/apache-tomcat-7.0.47
#export CATALINA_BASE=/opt/dev/tomcat7-2
##CATALINA_BASE contains: conf,lib,logs,webapps
#
#export TOMCAT_OPTS=" -agentlib:jdwp=transport=dt_socket,server=y,address=11552,suspend=n"
#export JAVA_OPTS="-Xms1024m -Xmx7168m -XX:NewSize=256m -XX:MaxNewSize=356m -XX:PermSize=256m -XX:MaxPermSize=356m"
#export JAVA_OPTS="${JAVA_OPTS}${TOMCAT_OPTS}"
#
#do_tomcat_configure () {
#    cp /home/daren/test/simple-cas-overlay-template/target/cas.war $CATALINA_BASE/webapps
#}


INSTANCE="catalina.base=$CATALINA_BASE"

start() {
    #sleep 2
    ALREADY_UP=`status`
    if [ -z "$ALREADY_UP" ]; then
        nice -20 $CATALINA_HOME/bin/startup.sh
        echo -e "JAVAOPTS: $JAVA_OPTS"
    else
        echo -e "Already running:\n $ALREADY_UP"
    fi
}

stop() {
    unset JAVA_OPTS
    $CATALINA_HOME/bin/shutdown.sh
    printf "\n"
    PID=`pgrep -fl $INSTANCE`
    if [ -n "$PID" ]; then
        printf "Tomcat process is: $PID"
    else
        printf "Tomcat not running."
    fi
    printf "\n\n"
    CNT=0;

    while [ ! -z "`pgrep -fl $INSTANCE`"  -a $CNT -lt 5 ];  do
        echo -n " waiting$CNT..."; CNT=$((CNT+1)); sleep 1;
    done;

    if [ ! -z "`pgrep -fl $INSTANCE`" ]; then
        echo -e "\n\nKill tomcat: <Enter>"
        echo "Abort:       <ctrl>-c"
        read DUMMY
        pkill -f $INSTANCE --signal 9
        while [ ! -z "`pgrep -fl $INSTANCE`" -a $CNT -lt 5 ]; do
            echo -n " killing$CNT..."; CNT=$((CNT+1)); sleep 1;
        done;
    fi;
    JAVA_OPTS=$BUP_JAVA_OPTS
    export JAVA_OPTS
    echo
}

upgrade() {
    stop
    rm -rf $CATALINA_BASE/webapps
    mkdir $CATALINA_BASE/webapps
    clearCache
    clearLogs
    do_tomcat_configure
    sleep 2
    start
}

clearCache() {
    rm -rf $CATALINA_BASE/conf/Catalina/localhost $CATALINA_BASE/work $CATALINA_BASE/temp
    mkdir  $CATALINA_BASE/work $CATALINA_BASE/temp
}

clearLogs() {
  rm -rf  $CATALINA_BASE/logs
  mkdir  $CATALINA_BASE/logs
}

status() {
    pgrep -fl $INSTANCE
}


case $COMMAND in
status)
    ALREADY_UP=`status`
    if [ -z "$ALREADY_UP" ]; then
        printf "Tomcat is down:\n BASE: $CATALINA_BASE\n HOME: $CATALINA_HOME\n \
 JDK: $JAVA_HOME\n\n"
    else
        printf "Running:\n $ALREADY_UP"
    fi

    exit 0;;
up)
    echo upgrading ...
    upgrade
    exit 0;;
start)
    start
    exit 0;;
stop)
    stop
    exit 0;;
restart)
    stop
    clearCache
    clearLogs
    start
    exit 0;;
*)
    printf "Error no $COMMAND command. Only commands: \n${COMMAND_LIST}."
    exit 1
esac

