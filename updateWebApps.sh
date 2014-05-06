#!/bin/bash
ORIG_PWD=`pwd`
cd /tomcat
/tomcat/bin/shutdown.sh
echo -e "\n"
echo  -e "tomcat process is: \n" 
pgrep -fl tomcat
echo -e "\n\n"
CNT=0;
#-o  
while [[ ! -z `pgrep -fl tomcat` ]] && [[ $CNT -lt 5 ]];  do echo -n " waiting$CNT..."; CNT=$((CNT+1)); sleep 1; done;

if [[ ! -z `pgrep -fl tomcat` ]]; then
    echo -e "\n\nKill tomcat: <Enter>"
    read -p "Abort:       <ctrl>-c" 
    pkill -f tomcat --signal 9
    while [[ ! -z `pgrep -fl tomcat` ]] && [[ $CNT -lt 5 ]];  do echo -n " killing$CNT..."; CNT=$((CNT+1)); sleep 1; done;
fi;

rm -rf /tomcat/webapps /tomcat/logs /tomcat/conf/Catalina/localhost /tomcat/work
mkdir /tomcat/webapps /tomcat/logs /tomcat/work /tomcat/webapps/groovyScripts
#cp /home/daren/NetBeansProjects/o4services/o4services-impl/target/o4services-impl.war /tomcat/webapps
#cp ~/NetBeansProjects/ozone3-maven2/ozone3-new-gui-package-config/o3ozoneWeb/target/o3ozoneWeb.war /tomcat/webapps 
#ln -s ~/NetBeansProjects/ozone3-maven2/ozone3-new-gui-package-config/o3ozoneWeb/src webapps/test


#cp /home/daren/NetBeansProjects/jpatest/target/app.war /tomcat/webapps

#cp /home/daren/NetBeansProjects/fcl-test/target/fcl-test.war /tomcat/webapps
#cp /home/daren/NetBeansProjects/o4reports/latesttrunk/o4reports-springmvc-web/target/o4reports-springmvc-web.war /tomcat/webapps

cp /home/daren/NetBeansProjects/fcl-ws/trunk/fcl-wservice/target/fcl-wservice.war /tomcat/webapps

#cp /home/daren/NetBeansProjects/ozone3-maven2/ozone3-passive-air/o3server/target/o3server.war /tomcat/webapps
#cp /home/daren/NetBeansProjects/ozone3-maven2/ozone3-passive-air/o3deploy/target/o3deploy-test.war /tomcat/webapps/o3deploy.war
#cp o3gui.uiLockdown2.groovy webapps/groovyScripts

sleep 2
nice -20 /tomcat/bin/startup.sh
cd ${ORIG_PWD}

