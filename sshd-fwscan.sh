#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git
###############################################################################
# Scan sshd log file for brute force attacks and block offending hosts by
# firewall pf. The log file is tailed and hosts are blocked immediately after
# 2 failed login attempts. A list of friendly hosts is kept (ie successful
# login attemtps) to avoid the blocking of friendly hosts.
#
# FREEBSD hosts. Inspired by:
# http://www.freebsdwiki.net/index.php/Block_repeated_illegal_or_failed_SSH_logins
###############################################################################
#
# Invocations:
#
# sshd-fwscan.sh scan <logfile>
# Tail the logfile and adjust host access via pf as required.
#
# sshd-fwscan.sh friend <logfile> <hostip> ...
# Append the host ip(s) to the logfile as a friendly host. ie to remove the
# host from the pf block list table.
#
# sshd-fwscan.sh <ip/name/new_host_to_block> <friendly_hosts> .....
# Invoked by the 'sshd-fwscan.sh scan' invocation.
# 1. Adjusts the pf host block list table by adding the new_host_to_block
# name/ip.
# 2. Remove all hosts in the friendly_hosts list from the pf block list table.
#
# Notes:
#
# show blocked hosts: pfctl -t ssh-violations -T show
#
###############################################################################
#
# Configuration:
#
# Add to /etc/pf.conf
#table ssh-violations persist
#block quick from ssh-violations
#
#
# Either add to /etc/crontab:
#@reboot root sleep 60; /usr/local/etc/sshd-fwscan.sh scan /var/log/auth.log 2>&1 >> /var/log/sshd-fwscan.log
#
# Or jail.conf:
# exec.poststart="/usr/local/etc/sshd-fwscan.sh scan /jail/jail1/var/log/auth.log 2>&1 >> /var/log/sshd-fwscan.log";
# exec.prestop="/usr/local/etc/sshd-fwscan.sh stop";
# Second jail:
# ln -s /usr/local/etc/sshd-fwscan.sh /usr/local/etc/jail2Scan.sh
# exec.poststart="/usr/local/etc/jail2Scan.sh scan /jail/jail2/var/log/auth.log 2>&1 >> /var/log/sshd-fwscan.log";
# exec.prestop="/usr/local/etc/jail2Scan.sh stop";
#
###############################################################################
#
# Additionally use openbl.org to get a list of hosts to exclude:
#
# Add to /etc/crontab:
#15      19      *       *       6       root    (fetch -q --no-verify-peer -o /var/tmp https://www.openbl.org/lists/base.txt.gz; gunzip -qf /var/tmp/base.txt.gz) > /dev/null; cat /var/tmp/base.txt |sed '/#.*$/d' > /var/tmp/openbl.org.txt
#
# Add to /etc/pf.conf:
#table <openbl-org> persist file "/var/tmp/openbl.org.txt"
#block quick from <openbl-org>
#

PROGME=${0##*/}
LOCK=/var/run/$PROGME.pid
PF_SSH_VIOLATIONS=ssh-violations

###############################################################################
# shell variable functionality
###############################################################################
set_avar() {
# Set a dynamic variable
# $1 and $2 are the variable name parts.
# $3 - the variable value.
#
  eval "$1_$2=\$3"
}

_get_avar()
{
  eval "_AVAR=\$$1_$2"
}

get_avar()
{
  _get_avar "$@" && printf "%s\n" "$_AVAR"
}

array_clear()
{
    CNT=`get_avar "$1" 0`
    for i in `jot "-" 0 ${CNT:-"0"} 1`
    do
        unset $1_$i
    done
}

array_iterator() {
#
# Return the elements of an array.
#
# $1 the array name
#
    local ARRAYNAME="$1"
    local VALIDNAME=`echo "$ARRAYNAME" |grep " " -c`
    if [ $VALIDNAME -gt 0 ]; then
        echo "Invalid arrayname \"$ARRAYNAME\"." >/dev/stderr
        exit 1
    fi
    local ARRAYSIZE=`get_avar "$ARRAYNAME" 0`

    if [ ! -z "$ARRAYSIZE" ]; then
        for CNT in `jot "-" 1 "$ARRAYSIZE" 1`
        do
            echo `get_avar "$ARRAYNAME" "$CNT"`
        done
    fi
}

array_add() {
#
# Add an element to an array.
#
# $1 the array name.
# $2 the element value.
#
    local ARRAYNAME="$1"
    local ELEMENT_VALUE="$2"
    local ARRAYSIZE=`get_avar "$ARRAYNAME" 0`
    if [ -z "$ARRAYSIZE" ]; then
        ARRAYSIZE=0
    fi
    ARRAYSIZE=$((ARRAYSIZE+1))
    set_avar "$ARRAYNAME" 0 "$ARRAYSIZE"
    set_avar "$ARRAYNAME" "$ARRAYSIZE" "$ELEMENT_VALUE"
}

array_size() {
    local ARRAYNAME="$1"
    local ARRAYSIZE=`get_avar "$ARRAYNAME" 0`
    echo ${ARRAYSIZE:-0}
}

arrayToList() {
#
# Convert an array to a list.
#
#   $1 - array name
#

    local ARRAYNAME="$1"
    local LIST=""

    for ELEMENT in `array_iterator  "$ARRAYNAME"`
    do
        if [ -z "$LIST" ]; then
            LIST=$ELEMENT
        else
            LIST="$LIST $ELEMENT"
        fi
    done
    echo $LIST
}

listToArray() {
#
# Convert a list to an array.
#
#   $1 - list
#   $2 - array name
#
    local ARRAYLIST="$1"
    local ARRAY_NAME="$2"
    local CNT=0

    for WORD in $ARRAYLIST
    do
        CNT=$((CNT+1))
        set_avar $ARRAY_NAME $CNT $WORD
    done;
    set_avar $ARRAY_NAME 0 $CNT
}

###############################################################################
# main
###############################################################################
if [ "$1" == "scan" ]; then
    if [ -f $LOCK ]; then
        RUNNINGPID=`echo ${LOCK}`
        STATUS=`pgrep -F ${LOCK}`
        if [ -z "$STATUS" ]; then
            echo "Old process $RUNNINGPID died. Restarting..."
        else
            echo "Already running PID: $RUNNINGPID"
            exit 1;
        fi
    fi
    AUTHLOG=$2
    if [ ! -f "$AUTHLOG" ]; then
        echo "No file: $AUTHLOG"
        return;
    fi
    echo SCAN START: `date`
    (tail -n 600 -F $AUTHLOG & echo $! > $LOCK) | awk -v progme="$PROGME" ' \
    function pfcall(foe, friendlist) {
        args=foe
        for (friend in friendlist) {
            #print "friendarg:", friend
            args=(args" "friend)
        }
        cmd=(progme" "args)
        print "cmd:", cmd
        system(cmd)
    }
    {
        TMPHOST=""
        FRIENDLY=0
        if ($0 ~ /Accepted publickey for/) {
            TMPHOST=$(NF-5)
            FRIENDLY=1
        } else if ($0 ~ /^Friend: /) {
            TMPHOST=$(NF)
            FRIENDLY=1
        } else if ($0 ~ /not listed in AllowUsers$/) {
            TMPHOST=$(NF-7)
        } else if ($0 ~ /sshd.*illegal/) {
            TMPHOST=$(NF)
        } else if ($0 ~ /Invalid user/) {
            TMPHOST=$(NF)
        } else if ($0 ~ /Failed keyboard/) {
            TMPHOST=$(NF-3)
        }

        if (length(TMPHOST) > 0) {
            if (FRIENDLY == 1) {
                if (TMPHOST in FOELIST) {
                    print "friend in foes", TMPHOST, FOELIST[TMPHOST]
                    delete FOELIST[TMPHOST];
                }
                if (! (TMPHOST in FRIENDLIST)) {
                    FRIENDLIST[TMPHOST]++;
                    print "friend not in friends", TMPHOST
                    pfcall(TMPHOST, FRIENDLIST);
                } else {
                    FRIENDLIST[TMPHOST]++;
                    print "friend already", TMPHOST, FRIENDLIST[TMPHOST]
                }
            } else {
                if (TMPHOST in FRIENDLIST) {
                    print "foe is a friend", TMPHOST, FRIENDLIST[TMPHOST]
                    print $0
                    pfcall(TMPHOST, FRIENDLIST);
                } else {
                    FOELIST[TMPHOST]++;
                    print "foe", TMPHOST, FOELIST[TMPHOST]
                    if (FOELIST[TMPHOST] == 2) {
                        pfcall(TMPHOST, FRIENDLIST);
                    }
                }
            }

        }
    }'&

elif [ "$1" == "friend" ]; then
    CMDARG=""
    AUTHLOG=""
    for ARG in $@; do
        if [ -z "$CMDARG" ]; then
            CMDARG=$ARG
        elif [ -z "$AUTHLOG" ]; then
            AUTHLOG=$ARG
            if [ ! -w "$AUTHLOG" ]; then
                echo "File not writable: $AUTHLOG"
                return;
            fi
        else
            HOST=$ARG
        fi
        echo Friend: $HOST >> $AUTHLOG
    done;

elif [ "$1" == "stop" ]; then
    if [ -f $LOCK ]; then
        RUNNINGPID=`cat ${LOCK}`
        STATUS=`pgrep -F ${LOCK}`
        if [ -z "$STATUS" ]; then
            echo "Process $RUNNINGPID already died?"
        else
            kill -15 $RUNNINGPID
            if [ $? -eq 0 ]; then
                rm ${LOCK}
            else
                echo Cleanup of PID:$RUNNINGPID failed. Lock: $LOCK
            fi
        fi
    else
        echo Not running? no $LOCK
    fi
else
#    date +'%y%m%d.%H:%M'
#    SSH_SCAN_PID=`pgrep -F ${LOCK}.awk`
#    ps -o rss,cpu,dsiz,ssiz,%mem -p "$SSH_SCAN_PID"
    #Convert to ip list.
    NEWFOE=""
    IP=""
    for HOST in $@; do
        IS_IP=`echo $HOST | egrep -c '[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}'`
        if [ "$IS_IP" -eq 1 ]; then
            IP=$HOST
        else
            #Convert from name to ip
            IP=`host $HOST |head -1 |awk '{print $NF}'`
            IS_IP=`echo $IP| egrep -c '[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}'`
            if [ "$IS_IP" -eq 0 ]; then
                IP=""
                echo can not resolve $HOST
                if [ -z "$NEWFOE" ]; then
                    echo Foe $HOST does not resolve.
                    return
                fi
            fi
        fi
        #Add to the friendlies list if it is an ip.
        if [ -n "$IP" ]; then
            #Pull the foe off the front. ie the first arg.
            if [ -n "$NEWFOE" ]; then
                array_add FRIENDLIST $IP
            else
                NEWFOE=$IP
            fi
        fi
    done;

    #Remove friends from the router foe list.
    for FOE in `pfctl -t $PF_SSH_VIOLATIONS -T show 2>/dev/null`; do
        for FRIEND in `arrayToList FRIENDLIST`; do
            if [ "$FRIEND" = "$FOE" ]; then
                echo pfctl -t $PF_SSH_VIOLATIONS -T delete $FRIEND
                pfctl -t $PF_SSH_VIOLATIONS -T delete $FRIEND
            fi
        done;
        if [ "$FOE" = "$NEWFOE" ]; then
            NEWFOE=""
        fi
    done

    for FRIEND in `arrayToList FRIENDLIST`; do
        if [ "$FRIEND" = "$NEWFOE" ]; then
            NEWFOE=""
        fi
    done;
    if [ -n "$NEWFOE" ]; then
        echo pfctl -t $PF_SSH_VIOLATIONS -T add $NEWFOE
        pfctl -t $PF_SSH_VIOLATIONS -T add $NEWFOE
    fi
fi

#vim:ts=4:sw=4:expandtab:tw=78:ft=vim:fdm=marker:
