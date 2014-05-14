#!/bin/bash
#
#
ENVLOCATION=$1
COMMAND=$2
COMMAND_LIST="status, up, start, stop, restart"

if [[ -z "$ENVLOCATION" ]]; then
    echo "Path to environment file tomcat.env not set."
    echo "Usage: tomcatCtl /catalinabase <cmd> || tomcatCtl . <cmd>"
    echo "Where catalinabase contains the tomcat.env"
    echo "cmd: $COMMAND_LIST"
    exit;
fi

ENVFILE_LOCATION=`find_up.sh  tomcat.env $ENVLOCATION`
if [[ -z "$ENVFILE_LOCATION" ]]; then
    echo Environment file $ENVFILE_LOCATION/tomcat.env does not exist. 
    exit;
fi

#TOMCAT_HOME=${t%/*}
CATALINA_BASE=$ENVFILE_LOCATION
SERVERCONF=$CATALINA_BASE/conf/server.xml
if [[ -z "$SERVERCONF" ]]; then
    echo Tomcat environment file $SERVERCONF does not exist. 
    exit;
fi

ENVFILE=$ENVFILE_LOCATION/tomcat.env

source $ENVFILE

#tomcat.env example
#
# JDK_NO=7
# . jdkenv
#
#export CATALINA_HOME=/opt/dev/apache-tomcat-7.0.47
#export CATALINA_BASE=/opt/dev/tomcat7-2
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
    if [[ -z "$ALREADY_UP" ]]; then
        nice -20 $CATALINA_HOME/bin/startup.sh
    else
        echo -e "Already running:\n $ALREADY_UP"
    fi
}

stop() {
    $CATALINA_HOME/bin/shutdown.sh
    echo -e "\n"
    echo  -e "Tomcat process is: \n" 
    pgrep -fl $INSTANCE
    echo -e "\n\n"
    CNT=0;
   
    while [[ ! -z `pgrep -fl $INSTANCE` ]] && [[ $CNT -lt 5 ]];  do 
        echo -n " waiting$CNT..."; CNT=$((CNT+1)); sleep 1; 
    done;
   
    if [[ ! -z `pgrep -fl $INSTANCE` ]]; then
        echo -e "\n\nKill tomcat: <Enter>"
        read -p "Abort:       <ctrl>-c" 
        pkill -f $INSTANCE --signal 9
        while [[ ! -z `pgrep -fl $INSTANCE` ]] && [[ $CNT -lt 5 ]];  
            do echo -n " killing$CNT..."; CNT=$((CNT+1)); sleep 1; 
        done;
    fi;
   
}

upgrade() {
    stop 
    rm -rf $CATALINA_BASE/webapps $CATALINA_BASE/logs $CATALINA_BASE/conf/Catalina/localhost $CATALINA_BASE/work $CATALINA_BASE/temp
    mkdir $CATALINA_BASE/webapps $CATALINA_BASE/logs $CATALINA_BASE/work $CATALINA_BASE/temp

    do_tomcat_configure
    sleep 2 
    start
}

status() {
    pgrep -fl $INSTANCE
}


case $COMMAND in
status)
    status
    exit 0;;
up)
    echo upgrading
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
    start
    exit 0;;
*)
    echo "Error no $COMMAND command. Only $COMMAND_LIST."
    exit 1
esac

