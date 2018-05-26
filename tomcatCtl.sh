#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git
#
# Control multiple tomcat instances.
#
ENVLOCATION=$1
COMMAND=$2
COMMAND_PARAM=$3
COMMAND_LIST="\tstatus - is the instance running
\tup - upgrade ie clear logs, copy new war
\tstart - start the instance
\tstop - stop the instance
\tstop <waitsec> - stop the instance allowing waitsec
\trestart - stop, clear the logs, start
\tclean - stop, archive the logs, clear cache, backup webapps
\tcreateConf - create a new configuration file at the location.\n\n"

usage() {
    cat <<EOF

Usage: tomcatCtl /catalinabase <cmd>"
       tomcatCtl . <cmd>"

Note:   -  '.' when pwd is catalinabase or a child of catalinabase,
        -  catalinabase must contain the tomcat.env.

EOF
printf "Commands:\n  $COMMAND_LIST\n"

}

createConfig() {
    local CONFIG_FILE=$1
        (cat <&3  >>${CONFIG_FILE}) 3<<EOF
# tomcat.env example
#
# Set the jdk.
JDK_NO=7
. jdkenv
#
export CATALINA_HOME="path to the tomcat installation"
##CATALINA_BASE contains: conf,lib,logs,webapps
export CATALINA_BASE="path to the tomcat instance"

#Debug settings
#export TOMCAT_OPTS=" -agentlib:jdwp=transport=dt_socket,server=y,address=11552,suspend=n"
#export JAVA_OPTS="-Xms1024m -Xmx7168m -XX:NewSize=256m -XX:MaxNewSize=356m -XX:PermSize=256m -XX:MaxPermSize=356m"
#export JAVA_OPTS="${JAVA_OPTS}${TOMCAT_OPTS}"

#Customise for the upgrade command.
do_tomcat_configure () {
    #cp /home/daren/test/simple-cas-overlay-template/target/cas.war $CATALINA_BASE/webapps
}
EOF
}

start() {
    #sleep 2
    TC_STATUS=`status`
    if [ -z "$TC_STATUS" ]; then
        if [ ! -d "$CATALINA_BASE/logs" ]; then
            mkdir $CATALINA_BASE/logs
        fi
        nice -20 $CATALINA_HOME/bin/startup.sh
        echo "JAVAOPTS: $JAVA_OPTS"
    else
        echo "Already running: $TC_STATUS"
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
    if [ -z "${COMMAND_PARAM}" ]; then
        local WAIT_SEC=5
    else
        local WAIT_SEC=${COMMAND_PARAM}
    fi

    while [ ! -z "`pgrep -fl $INSTANCE`"  -a $CNT -lt ${WAIT_SEC} ];  do
       echo -n " waiting $CNT..."
       CNT=$((CNT+1)); sleep 1;
    done;

    if [ ! -z "${COMMAND_PARAM}" -a ! $CNT -lt ${WAIT_SEC} ]; then
        echo "Shutdown $INSTANCE failed."
        exit 1
    fi

    if [ ! -z "`pgrep -fl $INSTANCE`" ]; then
        echo
        echo  "Kill tomcat: <Enter>"
        echo "Abort:       <ctrl>-c"
        read DUMMY
        pkill -f $INSTANCE --signal 9
        while [ ! -z "`pgrep -fl $INSTANCE`" -a $CNT -lt 5 ]; do
            echo -n " killing$CNT..."; CNT=$((CNT+1)); sleep 1;
        done;
        if [ ! $CNT -lt 5 ]; then
            echo "Could not kill ${INSTANCE}."
        fi
    fi;
    JAVA_OPTS=$BUP_JAVA_OPTS
    export JAVA_OPTS
    echo
}

upgrade() {
    checkRemoveWebApps
    stop
    rm -rf $CATALINA_BASE/webapps
    mkdir $CATALINA_BASE/webapps
    clearCache
    clearLogs
    do_tomcat_configure
    sleep 2
    start
}

clean() {
    if [ 1 -eq `status | grep -c Running` ]; then
        stop
    fi
    mkdir -p $CATALINA_BASE/webapps_old
    checkFail $? "Could not create $CATALINA_BASE/webapps_old"
    cp -f $CATALINA_BASE/webapps/*war $CATALINA_BASE/webapps_old
    checkFail $? "Could not backup $CATALINA_BASE/webapps"
    archiveLogs
    clearCache
}

clearCache() {
    rm -rf $CATALINA_BASE/conf/Catalina/localhost $CATALINA_BASE/work $CATALINA_BASE/temp
    checkFail $? "Could not remove $CATALINA_BASE/conf/Catalina/localhost $CATALINA_BASE/work $CATALINA_BASE/temp"
    mkdir  $CATALINA_BASE/work $CATALINA_BASE/temp
    checkFail $? "Could not create  $CATALINA_BASE/work $CATALINA_BASE/temp"
}

clearLogs() {
    rm -rf  $CATALINA_BASE/logs
    checkFail $? "Could not remove $CATALINA_BASE/logs."
    mkdir  $CATALINA_BASE/logs
    checkFail $? "Could not create $CATALINA_BASE/logs."
}

archiveLogs() {
    mkdir  -p ${CATALINA_BASE}/archive
    checkFail $? "Could not create $CATALINA_BASE/archive."
    NOWDATE=`date +%Y%m%d%H%M`
    tar -cvzf ${CATALINA_BASE}/archive/log${NOWDATE}.tar.gz ${CATALINA_BASE}/logs
    checkFail $? "Could not archive logs: tar -cvzf ${CATALINA_BASE}/archive/log${NOWDATE}.tar.gz ${CATALINA_BASE}/logs"
    clearLogs
}

status() {
    pgrep -fl $INSTANCE
}

checkFail() {
    if [ $1 -ne 0 ]; then
        echo "==== Failure ===="
        echo $2
        exit 1
    fi
}

initEnv() {
   CATALINA_BASE=$ENVFILE_LOCATION
   SERVERCONF=$CATALINA_BASE/conf/server.xml
   if [ ! -f "$SERVERCONF" ]; then
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
}

last() {
 echo "Complete `date '+%H:%M:%S'`"
}

checkRemoveWebApps() {
  CURRENT_PWD=`pwd`
  WEB_APPS="${CATALINA_BASE}/webapps"
  IN_CHILD=`echo $CURRENT_PWD |grep -c ${WEB_APPS}`
  if [ 1 -eq ${IN_CHILD} ]; then
    echo "Error: Your current path '${WEB_APPS}' is to be removed and will not exist!"
    exit 1
  fi
}

####### main #################################################################

if [ -z "$COMMAND" ]; then
    usage
    exit 1;
fi

ENVFILE_LOCATION=`find_up.sh  tomcat.env $ENVLOCATION`
if [ -z "$ENVFILE_LOCATION" ]; then
    if [ "$COMMAND" != "createConf" ]; then
        echo Environment file "$ENVLOCATION/tomcat.env" does not exist.
        exit;
    fi
else
    CATALINA_BASE=""
    SERVERCONF=""
    ENVFILE=""
    initEnv
    INSTANCE="catalina.base=$CATALINA_BASE"
fi

case $COMMAND in
status)
    TC_STATUS=`status`
    if [ -z "$TC_STATUS" ]; then
        printf "Tomcat is down:\n BASE: $CATALINA_BASE\n HOME: $CATALINA_HOME\n \
 JDK: $JAVA_HOME\n\n"
    else
        printf "Running:\n $TC_STATUS\n"
    fi
    exit 0;;
up)
    echo upgrading ...
    upgrade
    last
    exit 0;;
start)
    start
    last
    exit 0;;
stop)
    stop
    exit 0;;
restart)
    stop
    clearCache
    clearLogs
    start
    last
    exit 0;;
clean)
    clean
    exit 0;;
createConf)
    createConfig $ENVLOCATION/tomcat.env
    exit 0;;
*)
    printf "Error no $COMMAND command. Only commands: \n${COMMAND_LIST}."
    exit 1
esac

