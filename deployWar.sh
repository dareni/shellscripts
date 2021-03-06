#!/bin/sh
 # vim: tabstop=4 shiftwidth=4 expandtab:

PROGNAME=$0
COMMAND=${1}
TARGET_HOST=${2}
TARGET_USER=${3}
TOMCAT_HOME=${4}
WAR_LOCATION=${5}
INSTALLATION_NAME=${6}

DEPLOYTARGET=${TARGET_USER}@${TARGET_HOST}
DEPLOY_STAGE=${TOMCAT_HOME}/deployBin/${INSTALLATION_NAME}
TCSHUTDOWNTIME=60

usage() {
    cat <<EOF
Usage deployWar.sh targethost targetUser tomcatHome warName installationName
Where:
       command - prepare,complete
       targethost eg 192.168.1.6
       targetUser - owner of the tomcat eg tomcatMan
       tomcathome - location of the tomcat installation eg /home/tomcat
       warLocation - URL of the deployable
       installationName - installation name

EOF
}

if [ $# -ne 6 ]; then
    usage
    exit 1;
fi
if [ "$COMMAND" != prepare -a "$COMMAND" != complete ]; then
    echo Incorrect command parameter: $COMMAND
    usage
    exit 1
fi

isTomcatUp() {
    local STATUS=`ssh ${DEPLOYTARGET} "tomcatCtl.sh ${TOMCAT_HOME} status"`
    if [ 1 -eq `echo $STATUS | grep -c Running` ]; then
        echo up
    elif [ 1 -eq `echo $STATUS | grep -c "Tomcat is down"` ]; then
        echo down
    else
        echo "isTomcatUp Fail $STATUS" >/dev/stderr
        return 1
    fi
    return 0
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

        (MARKER=`ssh ${DEPLOYTARGET} ls ${DEPLOY_STAGE}/deploy`) > /dev/null 2>/dev/null
        if [ "$MARKER" == "${DEPLOY_STAGE}/deploy" ]; then
            echo "Removing marker ${DEPLOYTARGET} ${DEPLOY_STAGE}/deploy"
            ssh ${DEPLOYTARGET} "rm ${DEPLOY_STAGE}/deploy"
        fi
        exit 1
    fi
}

ssh ${DEPLOYTARGET} "ls ${TOMCAT_HOME}/tomcat.env" > /dev/null
checkFail $? $LINENO "Invalid Tomcat home - ${TOMCAT_HOME}/tomcat.env does not exist."

#check for deploy marker
ssh ${DEPLOYTARGET} "ls ${DEPLOY_STAGE}/deploy" > /dev/null 2>/dev/null
checkFail $? $LINENO "Add empty file ${DEPLOY_STAGE}/deploy to confirm deployment to this location."

ssh ${DEPLOYTARGET} "mv -f ${DEPLOY_STAGE}/version.txt ${DEPLOY_STAGE}/version.txt.last; echo ${WAR_LOCATION} > ${DEPLOY_STAGE}/version.txt"
rsync ${WAR_LOCATION} ${DEPLOYTARGET}:${DEPLOY_STAGE}/${INSTALLATION_NAME}.war
checkFail $? $LINENO "Copy war failure."

STATUS=`isTomcatUp`
if [ "$STATUS" = "down" ]; then
    echo Tomcat already down!
    ssh ${DEPLOYTARGET} "ls ${TOMCAT_HOME}/webapps/${INSTALLATION_NAME}.war" > /dev/null
    if [ $? -eq 0 ]; then
        # Tomcat stopped without cleanup.
        echo Do cleanup.
        ssh ${DEPLOYTARGET} "tomcatCtl.sh ${TOMCAT_HOME} clean"
    fi
else
    echo Do shutdown.
    ssh ${DEPLOYTARGET} "tomcatCtl.sh ${TOMCAT_HOME} stop 30"
    checkFail $? $LINENO "Shutdown failed."
    ssh ${DEPLOYTARGET} "tomcatCtl.sh ${TOMCAT_HOME} clean"
    checkFail $? $LINENO "Clean failed."
fi

#deploy
ssh ${DEPLOYTARGET} "cp -f ${TOMCAT_HOME}/webapps/${INSTALLATION_NAME}.war ${TOMCAT_HOME}/webapps_old; rm -rf ${TOMCAT_HOME}/webapps/${INSTALLATION_NAME}"
ssh ${DEPLOYTARGET} "cp -f ${DEPLOY_STAGE}/${INSTALLATION_NAME}.war ${TOMCAT_HOME}/webapps"
checkFail $? $LINENO "Deploy war failure."

if [ "$COMMAND" = complete ]; then
    #tomcat start
    ssh ${DEPLOYTARGET} "tomcatCtl.sh ${TOMCAT_HOME} start"
    checkFail $? $LINENO "Start tomcat failure."

    #remove the deploy marker
    ssh ${DEPLOYTARGET} "rm -f ${DEPLOY_STAGE}/deploy"
    checkFail $? $LINENO "Deploy marker removal ${DEPLOYTARGET} ${DEPLOY_STAGE}/deploy failure."
fi

