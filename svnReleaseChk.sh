#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git
# Send a mail to root when the remote svn repo version has changed. 
# Usage: svnReleaseChk.sh [local svn location ] [remote svn location] 

#/usr/src
LOCAL_SVN=$1
#svn://svn.freebsd.org/base/releng/10.2
REMOTE_SVN=$2

LOCAL_VER=`svnlite info ${LOCAL_SVN} |grep "Last Changed Rev:" | cut -f 4 -w`
REMOTE_VER=`svnlite info ${REMOTE_SVN} |grep "Last Changed Rev" |cut -f 4 -w`

if [ ${LOCAL_VER} -ne ${REMOTE_VER} ]; then
    svnlite log -l 1 -v $REMOTE_SVN |mail -s "Update: $REMOTE_SVN" root 
fi
