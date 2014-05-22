#!/bin/sh
REPO=http://repo1.maven.org/maven2
if [[ -z "$2" ]]; then
    echo Usage: mvnGet.sh groupid artifactid
    exit -1
fi
GROUPID=$1
ARTIFACTID=$2

ARTIFACT_PATH=`echo $GROUPID |sed -e 's^\.^/^g'`
ARTIFACT_PATH=$ARTIFACT_PATH/$ARTIFACTID

echo $ARTIFACT_PATH
curl $REPO/$ARTIFACT_PATH/maven-metadata.xml |grep "<version>"

read -p "Enter version: " VERSION 
mvn org.apache.maven.plugins:maven-dependency-plugin:2.1:get -Dartifact=$GROUPID:$ARTIFACTID:$VERSION -DrepoUrl=http://maven.central.org -DperformRelease

