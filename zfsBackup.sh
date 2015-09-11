#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git

# Perform backup of zfs filesystem.
#  - Backup to a remote host.
#  - Recursive.
#  - Automatic incremental backup.
#  - Source snapshot consistency check.

#Limitation: Untested with zfs file system names containing spaces.



CONFIG_FILE=~/.zfsBackup
G_ZFS_SRC_FS=$1
G_ZFS_DEST_FS=$2
G_ZFS_USER_HOST=$3

G_MAX_SNAPSHOT=""
G_SNAPSHOT_NAME=""
ZFS_NO_DATA_MESSAGE="dataset does not exist"

# isValidSnapshot return status CONSTANT.
G_SS_STATUS=0

usage() {
cat <<EOF

Usage ./zfsBackup.sh src_zfs dest_zfs user@remote_host

1) Perform a backup.

    - First snapshot the target filesystem

        zfs snapshot -r zroot/zdata@1

    - Execute the backup command

        zfsBackup.sh zroot/data zremote/bup remoteUser@192.168.1.102

2) Execute shell script tests.

    zfsBackup.sh shellTests

3) Execute the zfs tests.

    zfsBackup.sh zfsTests

Note:

1) zremote/bup must exist, remoteUser must have the necessary permissions
for zfs operations ie:

zfs allow -u remoteUser create,destroy,mount,snapshot,receive,send zremote/bup

2) Requires zfs, sh, awk, nc, ssh, cut in the path of the local/remote users.

3) See $CONFIG_FILE for test requirements.

EOF
}

if [ -z "`which jot`" ]; then
    echo Please install athena-jot\(bsd jot\) the sequence generator. > \
        /dev/stderr
    exit 1
fi

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
getRemoteFsList() {
#
# Backup the given filesystem.
#
# $1 = the target filesytem on the remote host.
# $2 = the target user@host.
#
#  return the `zfs list` listing for the target filesystem.
#
#           0 = success
#           1 = failure and returns the error message
#
    local REMOTEFS="$1"
    local USER_HOST="$2"
    CMD="ssh $USER_HOST zfs list -d 1 -H -o name -t all $REMOTEFS 2>&1"
    echo getRemoteFsList Cmd: $CMD >&9
    eval $CMD
    return $?;
}

###############################################################################
sendNewRemoteFileSystem() {
#
# Send the filesystem to the remote host where it does not exist.
#
# $1 = the local filesystem for backup.
# $2 = the location of the filesytem on the remote host.
# $3 = the remote username@hostname
# $4 = the max snapshot version to send
#
# return    0 = success
#           1 = failure and returns the error message
#
    local LOCALFS="$1"
    local REMOTEFS="$2"
    local USER_HOST="$3"
    local REMOTE_HOST="${USER_HOST#*@}"
    local SNAPSHOT_VERSION="$4"

    echo -n "new" > /dev/stdout
    printSSSize $LOCALFS@$SNAPSHOT_VERSION
    RXFIFO=/tmp/rx$$.fifo
    TXFIFO=/tmp/tx$$.fifo
    mkfifo "$RXFIFO"
    mkfifo "$TXFIFO"
    exec 3<>"$RXFIFO"
    exec 4<>"$TXFIFO"

    CMD="nc -v -v -w 120 -l $REMOTE_HOST 8023 | zfs receive -e $REMOTEFS >&3"
    echo Listener cmd: $CMD >&9

    ssh $USER_HOST "$CMD" 2>&3 1>&3 &
    RXPID=$!
    sleep 2
    echo "Sender cmd: zfs send $SEND_INC $LOCALFS@$SNAPSHOT_VERSION  nc -v -v -w 20 $REMOTE_HOST 8023 2>&4" >&9
    local SEND_START_TIME=`date +%s`
    zfs send $SEND_INC $LOCALFS@$SNAPSHOT_VERSION 2>&4 | nc -v -v -w 20 $REMOTE_HOST 8023 2>&4
    RET=$?
    RXMSG=$(while read -t 2 line; do pge="$pge $line"; done <&3; echo $pge)
    TXMSG=$(while read -t 2 line; do pge="$pge $line"; done <&4; echo $pge)
    exec 3<&- 4<&-
    rm $RXFIFO $TXFIFO
    echo "Sender op: $TXMSG" >&9
    echo "Receiver op: $RXMSG" >&9
    if [ `echo "$TXMSG" |grep -c "succeeded!$"` -gt 0 ]; then
        TXMSG=""
    fi
    if [ `echo "$RXMSG" |grep -c "received!$"` -gt 0 ]; then
        RXMSG=""
    fi

    if [ "$RET" -ne 0 -o -n "$TXMSG" -o -n "$RXMSG" ]; then
        echo "Send failed $LOCALFS" > /dev/stderr
        echo "Sender error: $TXMSG" > /dev/stderr
        echo "Receiver error: $RXMSG" > /dev/stderr
        echo "Clean up the receiver listener kill PID:$RXPID" > /dev/stderr
        kill -9 $RXPID
        RET=1
    fi
    printElapsed $SEND_START_TIME
    return $RET;
}

###############################################################################
sendIncrementalFileSystem() {
#
# Send the filesystem to the remote host where it does not exist.
#
# $1 = the local filesystem for backup.
# $2 = the location of the filesytem on the remote host.
# $3 = the remote username@hostname
# $4 = local snapshot version list to send
# $5 = remote snapshot
    local LOCALFS="$1"
    local REMOTEFS="$2"
    local USER_HOST="$3"
    local REMOTE_HOST="${USER_HOST#*@}"
    local LOCAL_SNAPSHOT_VERSION="$4"
    local REMOTE_SNAPSHOT_VERSION="$5"
    local SEND_START_TIME=""

    if [ "$LOCAL_SNAPSHOT_VERSION" = "$REMOTE_SNAPSHOT_VERSION" ]; then
        RET=0
        echo "up to date" > /dev/stdout
    else
        RXFIFO=/tmp/rx$$.fifo
        TXFIFO=/tmp/tx$$.fifo
        mkfifo "$RXFIFO"
        mkfifo "$TXFIFO"
        exec 3<>"$RXFIFO"
        exec 4<>"$TXFIFO"

        echo -n "incremental" > /dev/stdout
        printSSSize $LOCALFS@$LOCAL_SNAPSHOT_VERSION
        CMD="nc -v -v -w 120 -l $REMOTE_HOST 8023 | zfs receive -F -d $REMOTEFS >&3"
        ssh $USER_HOST "$CMD" 2>&3 1>&3 &
        echo ssh $USER_HOST "$CMD" >&9
        RXPID=$!
        sleep 2
        SEND_START_TIME=`date +%s`
        zfs send -I @$REMOTE_SNAPSHOT_VERSION $LOCALFS@$LOCAL_SNAPSHOT_VERSION 2>&4 \
            | nc -v -v -w 40 $REMOTE_HOST 8023 2>&4
        echo "zfs send -I @$REMOTE_SNAPSHOT_VERSION $LOCALFS@$LOCAL_SNAPSHOT_VERSION 2>&4 \
            | nc -v -v -w 40 $REMOTE_HOST 8023 2>&4" >&9

        RET=$?
        RXMSG=$(while read -t 2 line; do pge="$pge $line"; done <&3; echo $pge)
        TXMSG=$(while read -t 2 line; do pge="$pge $line"; done <&4; echo $pge)
        exec 3<&- 4<&-
        rm $RXFIFO $TXFIFO
        echo "Sender op: $TXMSG" >&9
        echo "Receiver op: $RXMSG" >&9

        if [ `echo "$TXMSG" |grep -c "succeeded!$"` -gt 0 ]; then
            TXMSG=""
        fi
        if [ `echo "$RXMSG" |grep -c "received!$"` -gt 0 ]; then
            RXMSG=""
        fi

        if [ "$RET" -ne 0 -o -n "$TXMSG" -o -n "$RXMSG" ]; then
            echo "Send failed $LOCALFS" > /dev/stderr
            echo "Sender error: $TXMSG" > /dev/stderr
            echo "Receiver error: $RXMSG" > /dev/stderr
            echo "Clean up the receiver listener kill PID:$RXPID" > /dev/stderr
            kill -9 $RXPID
            RET=1
        fi
        printElapsed $SEND_START_TIME
    fi
    return $RET;
}

###############################################################################
doBackup() {
#
# Backup the given filesystem.
#
# $1 = the file system.
# $2 = the remote file system destination.
# $3 = user host ie user@remotehost
#
# return    0 = success
#           1 = failure and returns the error message
#

    # check the local filesystem for snapshot continuity.
    local ZFS_SRC_FS="$1"
    local ZFS_DEST_FS="$2"
    local USER_HOST="$3"
    for FS in `zfs list -d 1 -H -o name -t all $ZFS_SRC_FS`
    do
        array_add ROOTLIST "$FS"
    done;

    ERROR_SNAP=`echo $ZFS_SRC_FS | grep -c '@'`
    if [ $ERROR_SNAP -gt 0 ]; then
        echo "The source filesystem ($ZFS_DEST_FS) may"
        echo "not contain a snapshot version."
        return 1
    fi

    ERROR_SNAP=`echo $ZFS_DEST_FS | grep -c '@'`
    if [ $ERROR_SNAP -gt 0 ]; then
        echo "The destination filesystem ($ZFS_DEST_FS) may"
        echo "not contain a snapshot version."
        return 1
    fi

    if [ -z "$3" ]; then
        ERROR_CHILD=`echo $ZFS_DEST_FS | grep -c '^$ZFS_SRC_FS'`
        if [ $ERROR_CHILD -eq 1 ]; then
            echo "The destination filesystem ($ZFS_DEST_FS) may"
            echo "not be a child of the source filesystem ($ZFS_SRC_FS)."
            return 1
        fi
    fi

    local REMOTELIST=""
    SNAPSHOT_DATA=`getSnapshotData ROOTLIST`
    local RET="$?"
    if [ $? -ne 0 ]; then
        echo getSnapshotData failed: $SNAPSHOT_DATA >/dev/stderr
        return $?
    fi
    MAX_SNAPSHOT="${SNAPSHOT_DATA#*@}"
    if [ -z "$MAX_SNAPSHOT" ]; then
        echo No snapshot id for $ZFS_SRC_FS. > /dev/stderr
        return 1
    fi
    for FS in `zfs list -r -H -o name -t all $ZFS_SRC_FS`
    do
        array_add FULL_LIST "$FS"
    done
    local LOCAL_ARRAY_PREFIX=MAIN
    getSnapshotFilesystems FULL_LIST "$MAX_SNAPSHOT" "${LOCAL_ARRAY_PREFIX}"
    if [ $? -ne 0 ]; then
        return $?
    fi
    if [ "`array_size MAIN_EXCEPTIONS_ARRAY`" -ne 0 ]; then
        local M1="Target filesystem snapshot inconsistencies. Please snapshot"
        local M2=" the target filesystem. (ie zfs snapshot -r <zparent>) The root snapshot"
        local M3=" version $MAX_SNAPSHOT is not matched by the child filesystem(s): "
        echo $M1$M2$M3$G_FILESYSTEM_EXECEPTIONSi > /dev/stderr
        return 1
    fi

    # loop on the local tree branches
    local FS_CNT=1
    for FILE in `array_iterator MAIN_FS_ARRAY`
    do
        echo -n "$FILE..." > /dev/stdout
        REMOTE_FS=${ZFS_DEST_FS}/${ZFS_SRC_FS##*/}${FILE##$ZFS_SRC_FS}
        HAS_SNAP=`echo $REMOTE_FS| grep -c @`
        if [ 0 -eq "$HAS_SNAP" ]; then
            echo  Error: No snapshot on source file system: $FILE > /dev/stderr
            return 1
        fi
        local LOCALFILE="${FILE%@*}"
        REMOTE_FS=${ZFS_DEST_FS}/${ZFS_SRC_FS##*/}${LOCALFILE##$ZFS_SRC_FS}
        REMOTELIST=$(getRemoteFsList "$REMOTE_FS" "$USER_HOST")
        echo remotelist=$REMOTELIST >&9
        local RET="$?"
        if [ -z "$REMOTELIST" ]; then
            echo "Remote FS status failure. status: $RET" > /dev/stderr
            return 1
        fi
        DOES_NOT_EXIST=`echo "$REMOTELIST" | grep -c "$ZFS_NO_DATA_MESSAGE"`

        CURRENT_DEST_PATH=$(getRemoteDestination ${ZFS_SRC_FS} ${LOCALFILE}  ${ZFS_DEST_FS})
        # check each remote host branch status
        if [ "$DOES_NOT_EXIST" -ne 0 ]; then
            # send new remote filesystem
            #sendNewRemoteFileSystem "$LOCALFILE" "$REMOTE_FS"
            echo sendNewRemoteFileSystem "$LOCALFILE" "$ZFS_DEST_FS" "$USER_HOST" "$MAX_SNAPSHOT" >&9
            sendNewRemoteFileSystem "$LOCALFILE" "$CURRENT_DEST_PATH" "$USER_HOST" "$MAX_SNAPSHOT"
        else
            if [ $RET -ne 0 ]; then
                echo "Remote FS status failure. status: $RET error: $REMOTELIST" > /dev/stderr
            fi
            # check the REMOTE LIST for the snapshot version.
            listToArray "$REMOTELIST" arrayREMOTELIST
            REMOTE_SNAPSHOT_DATA=`getSnapshotData arrayREMOTELIST`
            REMOTE_SNAPSHOT_VERSION="${REMOTE_SNAPSHOT_DATA##*@}"
            SS_LIST=`get_avar "${LOCAL_ARRAY_PREFIX}_SS_LIST_ARRAY" "$FS_CNT"`
            SS_VERSIONS_TO_SEND=${LOCAL_BRANCH_VERSION#*$REMOTE_SNAPSHOT_VERSION}
            echo sendIncrementalFileSystem $LOCALFILE $ZFS_DEST_FS $USER_HOST $MAX_SNAPSHOT $REMOTE_SNAPSHOT_VERSION >&9
            sendIncrementalFileSystem "$LOCALFILE" "$CURRENT_DEST_PATH" \
            "$USER_HOST" "$MAX_SNAPSHOT" "$REMOTE_SNAPSHOT_VERSION"
        fi

        FS_CNT=$((FS_CNT+1))
    done;
    echo
    # Remount the destination filesystems. ie zfsTest12 where a destination
    # filesystem is detroyed and repopulated.
    ssh $USER_HOST "/bin/sh -c 'zfs unmount ${ZFS_DEST_FS}/${ZFS_SRC_FS##*/}; for FS in \
        \`zfs list -H -r ${ZFS_DEST_FS}/${ZFS_SRC_FS##*/} |cut -f 1 -w - \`; do zfs mount \$FS; done'"
}

###############################################################################
getRemoteDestination() {
#
# Create the path of the remote filesystem.
#
# $1 = the target/parent/root filesystem to copy.
# $2 = the current target ie maybe the same as $1 or a child of $1.
# $3 = the destination filesystem.
#
# return = the path for the destination of $2
    local PARENT_TARGET="$1"
    local CHILD_TARGET="$2"
    local DEST="$3"
    local CHILD_DEST=""

    if [ "${PARENT_TARGET}" = "${CHILD_TARGET}" ]; then
        CHILD_DEST="${DEST}"
    else
        CHILDFS="${CHILD_TARGET##$PARENT_TARGET}" #/child/baby
        BABYBRANCH="/${CHILDFS##*/}"
        CHILDBRANCH="${CHILDFS%%${BABYBRANCH}}"
        PARENTFS="${PARENT_TARGET##*/}"
        CHILD_DEST="${DEST}/${PARENTFS}${CHILDBRANCH}"
    fi

    echo "${CHILD_DEST}"
}

###############################################################################
getSnapshotData() {
#
# Get the G_MAX_SNAPSHOT G_SNAPSHOT_NAME for the filesystem root.
#
# $1 = name of an array containing `zfs list -d 1 -H -o name -t all zfilesystem`
#
# return    G_MAX_SNAPSHOT G_SNAPSHOT_NAME for the filesystem root.
#           0 = success
#           1 = failure and returns the error message

    local MAX_SNAPSHOT=""
    local SNAPSHOT_NAME=""
    local ARRAYNAME="$1"
    local FS=""
    local SNAPCNT=""
    local FIRST="1"
    local CURRENTSS=""

    for FS in `array_iterator "$ARRAYNAME"`
    do
        SNAPCNT=`echo "$FS" | grep -c @`
        if [ 0 -eq "$SNAPCNT" ]; then
            if [ -z "$SNAPSHOT_NAME" ]; then
                SNAPSHOT_NAME="$FS"
            fi
        else
            if [ -z "$SNAPSHOT_NAME" ]; then
                SNAPSHOT_NAME="${FS%%@*}"
            fi
            if [ "${FS%%@*}" != "$SNAPSHOT_NAME" ]; then
                echo "Name mismatch '${FS%%@*}' != '$SNAPSHOT_NAME'"
                return 1
            fi
            CURRENTSS=$(getSnapshotVersion "$FS")
            MAX_SNAPSHOT="$CURRENTSS"
        fi
    done;
    if [ -n "$SNAPSHOT_NAME" ]; then
        echo "$SNAPSHOT_NAME@$MAX_SNAPSHOT"
    fi
    return 0;
}

###############################################################################
sortSnapshotFilesystems() {
#
# Adjusts <PREFIX>_FS_ARRAY and <PREFIX>_EXCEPTIONS_ARRAY with the last filesystem.
#
# $1 = last filesystem.
# $2 = current filesystem.
# $3 = snapshot version.
# $4 = the return array name <PREFIX>.
#
# return    <PREFIX>_FS_ARRAY contains all filesystems for the
#               given snapshot.
#           <PREFIX>_EXCEPTIONS_ARRAY contains all filesystems without
#               the given snapshot.
#           G_SS_STATUS - isValidSnapshot return status.
#
#           0 = success
#           1 = failure and returns the error message
#
    local LASTFS="$1"
    local CURRENTFS="$2"
    local SSVERSION="$3"
    local AN_PREFIX="$4"
    isValidSnapshot "$LASTFS" "$CURRENTFS" "$SSVERSION"
    G_SS_STATUS=$?
    if [ $G_SS_STATUS -eq 0 ]; then
        array_add "${AN_PREFIX}_FS_ARRAY" "$LASTFS"
    elif [ $G_SS_STATUS -eq 1 ]; then
        array_add "${AN_PREFIX}_EXCEPTIONS_ARRAY" "$LASTFS"
    elif [ $G_SS_STATUS -eq 3 ]; then
        echo $MSG
        return 1;
    fi
    return 0;
}

###############################################################################
getSnapshotFilesystems() {
#
# Build an array containing all of the filesystems matching the given
# snapshot version.
#
# $1 = the array name containing the file system list.
# $2 = the snapshot version.
# $3 = the return array name <PREFIX>.
#
# return    <PREFIX>_FS_ARRAY contains all filesystems for the
#               given snapshot.
#           <PREFIX>_EXCEPTIONS_ARRAY contains all filesystems without
#               the given snapshot.
#           <PREFIX>_SS_LIST_ARRAY array contains the snapshot identifiers
#               for each branch/filesystem in _FS_ARRAY.
#           0 = success
#           1 = failure and returns the error message
#
    local ARRAYNAME="$1"
    local SSVERSION="$2"
    local AN_PREFIX="$3"
    array_clear "${AN_PREFIX}_FS_ARRAY"
    array_clear "${AN_PREFIX}_EXCEPTIONS_ARRAY"
    array_clear "${AN_PREFIX}_SS_LIST_ARRAY"

    local RET=0
    local CURRENTLINE=""
    local LASTLINE=""
    local FIRST="1"
    local LASTSS=""

    local BRANCH_CNT=1

    for LINE in `array_iterator $ARRAYNAME` ""
    do
        CURRENTLINE="$LINE"
        local SSLIST=""
        if [ "$FIRST" = "0" ]; then
            sortSnapshotFilesystems "$LASTLINE" "$CURRENTLINE" "$SSVERSION" "$AN_PREFIX"
            if [ $? -eq 1 ]; then
                return 1;
            fi
            #store the snapshots for each branch
            if [ "$G_SS_STATUS" -eq 2 -o "$G_SS_STATUS" -eq 0 ]; then
                #is an intermediate or final snapshot so add to the list.
                LASTSS=$(getSnapshotVersion "$LASTLINE")
                SSLIST=$(get_avar "${AN_PREFIX}_SS_LIST_ARRAY" "$BRANCH_CNT")
                if [ ! -z "$LASTSS" ]; then
                    if [ -z "$SSLIST" ]; then
                        SSLIST="$LASTSS"
                    else
                        SSLIST="$SSLIST $LASTSS"
                    fi
                fi
                set_avar "${AN_PREFIX}_SS_LIST_ARRAY" "$BRANCH_CNT" "$SSLIST"
            fi

            if [ $G_SS_STATUS -eq 0 ]; then
                #Set the branch counter for the next branch
                BRANCH_CNT=$((BRANCH_CNT+1))
            elif [ $G_SS_STATUS -eq 1 ]; then
                #is an invalid snapshot collection so clear the list.
                set_avar "${AN_PREFIX}_SS_LIST_ARRAY" "$BRANCH_CNT" ""
            fi
        else
            FIRST="0"
        fi
        LASTLINE="$CURRENTLINE"
    done
    BRANCH_CNT=$((BRANCH_CNT-1))
    set_avar "${AN_PREFIX}_SS_LIST_ARRAY" "0" "$BRANCH_CNT"
    return 0;
}

###############################################################################
getSnapshotVersion() {
    local TMPSTR="$1"
    local SNAPSHOT="${TMPSTR##*@}"
    if [ "$TMPSTR" = "$SNAPSHOT" ]; then
        SNAPSHOT=""
    fi
    echo "$SNAPSHOT"
    return 0;
}

###############################################################################
nameValidation() {
#
# Do the names match. It is an error when they don't.
#
# $1 = last line
# $2 = current line
#
# return    0 = valid
#           1 = invalid

    local LASTLINE="$1"
    local CURRENTLINE="$2"
    local LASTNAME="${LASTLINE%%@*}"
    local CURRENTNAME="${CURRENTLINE%%@*}"

    if [ "$LASTNAME" != "$CURRENTNAME" ]; then
        echo "Error: nameValidation() Names should match: last:$LASTLINE current:$CURRENTLINE"
        echo "Error: nameValidation() Names should match: lastname:'$LASTNAME' != currentname:'$CURRENTNAME'"
        return 1;
    fi
    return 0;
}

###############################################################################
isValidSnapshot() {
#
# Is the last line a valid snapshot. It is a valid snapshot when:
# - the last line name and current line name differ,
# - the last line snapshot version matches the valid snapshotversion if the,
#       snapshot version is given.
# - the current line should not contain a snapshot version.
#
# $1 = last line
# $2 = current line
# $3 = valid snapshot version or "" for no snapshot matching.
#
# return    0 = valid
#           1 = invalid (when the snapshot is missing or the incorrect version)
#           2 = intermediate snapshot
#           3 = error
#
    local LASTLINE="$1"
    local CURRENTLINE="$2"
    local SSVERSION="$3"
    local L_HAS_SNAP=""
    L_HAS_SNAP=`echo "$LASTLINE" | grep -c @`
    local C_HAS_SNAP=""
    C_HAS_SNAP=`echo "$CURRENTLINE" | grep -c @`
    local LASTNAME=""
    local CURRENTNAME=""

    if [ -z "$LASTLINE" ]; then
        echo LASTLINE can not be empty. >/dev/stderr
        return 3
    fi
    if [ $L_HAS_SNAP -eq 0 ]; then
        if [ $C_HAS_SNAP -eq 0 ]; then
            #Snapshot missing on last.
            if [ -z "$SSVERSION" ]; then
                #No snapshot on last filesystem.
                return 0
            fi
            return 1;
        else
            ret=$(nameValidation "$LASTLINE" "$CURRENTLINE")
            if [ $? -ne 0 ]; then
                echo $ret
                return 3;
            fi
            #Current contains the snapshot.
            return 2;
        fi
    else
        if [ $C_HAS_SNAP -eq 0 ]; then
            #Check the last for the correct snapshot version.
            #Current and last names do not need to match.
            LASTSS=$(getSnapshotVersion "$LASTLINE")
            if [ -z "$SSVERSION"  -o "$LASTSS" = "$SSVERSION"  ]; then
                #Is a valid snapshot.
                return 0;
            fi
            return 1;
        else
            #Check the name is the same ie should be a newer snapshot.
            ret=$(nameValidation "$LASTLINE" "$CURRENTLINE")
            if [ $? -ne 0 ]; then
                echo $ret
                return 3;
            fi
            return 2;
        fi
    fi
}

###############################################################################
printSSSize() {
    local SNAPSHOT=$1
    local FS_SIZE=`zfs get -H written $SNAPSHOT |cut -f3 -w -`
    echo -n "...$FS_SIZE..." > /dev/stdout
    if [ $ZFS_BACKUP_DEBUG -eq 1 ]; then
        echo > /dev/stdout
    fi;
}

###############################################################################
printElapsed() {
    local STARTSECS=$1
    local ENDSECS=`date +%s`
    local ELAPSEDSEC=$(($ENDSECS - $STARTSECS))
    local ELAPSED="$(($ELAPSEDSEC/3600))hr.$(($ELAPSEDSEC%3600/60))min.$(($ELAPSEDSEC%60))sec"

    if [ $ZFS_BACKUP_DEBUG -eq 1 ]; then
        echo Elapsed $SNAPSHOT...$ELAPSED > /dev/stdout
    else
        echo "$ELAPSED" > /dev/stdout
    fi;
}

###############################################################################
assertEqual(){
    local arg1="$1"
    local arg2="$2"
    local testName="$3"
    local errorMesg="$4"
    local doExitOnError="$5"
    if [ ! -z "$errorMesg" ]; then
        errorMesg=error:$errorMesg
    fi
    if [ "$arg1" != "$arg2" ]; then
        echo "$testName Test Failure: arg1='$arg1' arg2='$arg2' $errorMesg" >/dev/stderr
    fi
    if [ "$doExitOnError" = "exit" -a "$arg1" != "$arg2" ]; then
        return 1
    fi
}

## Shell Tests ################################################################
shellTests(){

    ### array tests ###########################################################
    echo
    array_add tst w
    array_add tst x
    array_add tst y
    assertEqual "$tst_0" "3" arrayValidation1
    assertEqual "$tst_1" "w" arrayValidation2
    assertEqual "$tst_2" "x" arrayValidation3
    assertEqual "$tst_3" "y" arrayValidation4
    assertEqual "$tst_4" "" arrayValidation5
    echo array add test done.
    array_clear tst
    assertEqual "`array_size  tst`" "0"
    assertEqual "$tst_0" "" arrayValidation6
    assertEqual "$tst_1" "" arrayValidation7
    assertEqual "$tst_2" "" arrayValidation8
    assertEqual "$tst_3" "" arrayValidation9
    echo array clear test done.
    RET=$(array_iterator "A B" 2>&1)
    assertEqual "$RET" "Invalid arrayname \"A B\"." arrayValidation10
    echo array_iterator  tests done.

    ### nameValidation tests ##################################################
    RET=$(nameValidation "zpool/data" "zpool/data")
    assertEqual $? 0 "nameValidation1" "$RET"

    RET=$(nameValidation "zpool/data" "zpool/data@1")
    assertEqual $? 0 "nameValidation2" "$RET"

    RET=$(nameValidation "zpool/data@" "zpool/data@1")
    assertEqual $? 0 "nameValidation3" "$RET"

    RET=$(nameValidation "zpool/data@1" "zpool/data")
    assertEqual $? 0 "nameValidation4" "$RET"

    RET=$(nameValidation "zpool/data@" "zpool/data")
    assertEqual $? 0 "nameValidation5" "$RET"

    RET=$(nameValidation "zpool" "zpool/data")
    assertEqual $? 1 "nameValidation6" "$RET"

    RET=$(nameValidation "zpool/" "zpool")
    assertEqual $? 1 "nameValidation6" "$RET"
    echo nameValidation tests ok.

    ### isValidSnapshot tests #################################################
    RET=$(isValidSnapshot "zpool/data" "zpool/data" "0")
    assertEqual $? 1 "isValidSnapshot0" "$RET"

    RET=$(isValidSnapshot "zpool/data@0" "zpool/data/dummy" "0")
    assertEqual $? 0 "isValidSnapshot1" "$RET"

    RET=$(isValidSnapshot "zpool/data@0" "" "0")
    assertEqual $? 0 "isValidSnapshot2" "$RET"

    RET=$(isValidSnapshot "zpool/data@0" "" "1")
    assertEqual $? 1 "isValidSnapshot3" "$RET"

    RET=$(isValidSnapshot "zpool/data" "zpool/data@0" "0")
    assertEqual $? 2 "isValidSnapshot4" "$RET"

    RET=$(isValidSnapshot "zpool/data@2" "zpool/data@3" "0")
    assertEqual $? 2 "isValidSnapshot5" "$RET"

    RET=$(isValidSnapshot "zpool/data" "zpool/datablah@3" "0")
    assertEqual $? 3 "isValidSnapshot6" "$RET"

    RET=$(isValidSnapshot "zpool/data" "zpool/datablah@3" "0")
    assertEqual $? 3 "isValidSnapshot7" "$RET"

    RET=$(isValidSnapshot "zpool/data@0" "zpool/datablah@3" "0")
    assertEqual $? 3 "isValidSnapshot8" "$RET"

    RET=$(isValidSnapshot "zpool/data@0" "" "")
    assertEqual $? 0 "isValidSnapshot9" "$RET"

    RET=$(isValidSnapshot "zpool/data@0" "zpool/data1" "")
    assertEqual $? 0 "isValidSnapshot10" "$RET"

    RET=$(isValidSnapshot "zpool/data@0" "zpool/datablah@3" "")
    assertEqual $? 3 "isValidSnapshot11" "$RET"

    RET=$(isValidSnapshot "zpool/data@0" "zpool/data@3" "")
    assertEqual $? 2 "isValidSnapshot11" "$RET"
    echo isValidSnapshot tests ok.

    ### getSnapshotFilesystems tests ##########################################
    TEST="zpool/data@0"
    array_clear TEST
    listToArray "$TEST" TEST
    getSnapshotFilesystems TEST 0 G
    assertEqual $? 0 "getSnapshotFilesystems1"
    assertEqual "`arrayToList G_FS_ARRAY`" "$TEST" "getSnapshotFilesystems2"
    assertEqual "`arrayToList G_EXCEPTIONS_ARRAY`" "" "getSnapshotFilesystems3"
    assertEqual "`array_size G_FS_ARRAY`" 1 getSnapshotFilesystems1a
    TESTRET=$(get_avar G_SS_LIST_ARRAY "`array_size G_FS_ARRAY`")
    assertEqual "$TESTRET" "0" getSnapshotFilesystems1b

    TEST="zpool/data@0 zpool/data@1 zpool/data/test zpool/data/test1"
    array_clear TEST
    listToArray "$TEST" TEST
    FS="zpool/data@1 zpool/data/test zpool/data/test1"
    FSE=""
    getSnapshotFilesystems TEST "" G
    assertEqual $? 0 "getSnapshotFilesystems4"
    assertEqual "`arrayToList G_FS_ARRAY`" "$FS" "getSnapshotFilesystems5"
    assertEqual "`arrayToList G_EXCEPTIONS_ARRAY`" "$FSE" "getSnapshotFilesystems6"
    assertEqual "`array_size G_FS_ARRAY`" 3 getSnapshotFilesystems4a
    TESTRET=$(get_avar G_SS_LIST_ARRAY 1)
    assertEqual "$TESTRET" "0 1" getSnapshotFilesystems4b
    TESTRET=$(get_avar G_SS_LIST_ARRAY 2)
    assertEqual "$TESTRET" "" getSnapshotFilesystems4c
    TESTRET=$(get_avar G_SS_LIST_ARRAY 3)
    assertEqual "$TESTRET" "" getSnapshotFilesystems4d

    TEST="zpool/data@0 zpool/data@1 zpool/data/test zpool/data/test@1"
    array_clear TEST
    listToArray "$TEST" TEST
    FS="zpool/data@1 zpool/data/test@1"
    FSE=""
    getSnapshotFilesystems TEST "" G
    assertEqual $? 0 "getSnapshotFilesystems7"
    assertEqual "`arrayToList G_FS_ARRAY`" "$FS" "getSnapshotFilesystems8"
    assertEqual "`arrayToList G_EXCEPTIONS_ARRAY`" "$FSE" "getSnapshotFilesystems9"
    assertEqual "`array_size G_FS_ARRAY`" 2 getSnapshotFilesystems7a
    TESTRET=$(get_avar G_SS_LIST_ARRAY 1)
    assertEqual "$TESTRET" "0 1" getSnapshotFilesystems7b
    TESTRET=$(get_avar G_SS_LIST_ARRAY 2)
    assertEqual "$TESTRET" "1" getSnapshotFilesystems7c

    TEST="zpool/data@0 zpool/data@1 zpool/data/test zpool/data/test@1"
    array_clear TEST
    listToArray "$TEST" TEST
    FS="zpool/data@1 zpool/data/test@1"
    FSE=""
    getSnapshotFilesystems TEST 1 G
    assertEqual $? 0 "getSnapshotFilesystems10"
    assertEqual "`arrayToList G_FS_ARRAY`" "$FS" "getSnapshotFilesystems11"
    assertEqual "`arrayToList G_EXCEPTIONS_ARRAY`" "$FSE" "getSnapshotFilesystems12"
    assertEqual "`array_size G_FS_ARRAY`" 2 getSnapshotFilesystems11a
    TESTRET=$(get_avar G_SS_LIST_ARRAY 1)
    assertEqual "$TESTRET" "0 1" getSnapshotFilesystems11b
    TESTRET=$(get_avar G_SS_LIST_ARRAY 2)
    assertEqual "$TESTRET" "1" getSnapshotFilesystems11c

    TEST="zpool/data zpool/data@0 zpool/data/test zpool/data/test@1"
    array_clear TEST
    listToArray "$TEST" TEST
    FS="zpool/data/test@1"
    FSE="zpool/data@0"
    getSnapshotFilesystems TEST 1 G
    assertEqual $? 0 "getSnapshotFilesystems13"
    assertEqual "`arrayToList G_FS_ARRAY`" "$FS" "getSnapshotFilesystems14"
    assertEqual "`arrayToList G_EXCEPTIONS_ARRAY`" "$FSE" "getSnapshotFilesystems15"
    assertEqual "`array_size G_FS_ARRAY`" 1 getSnapshotFilesystems13a
    TESTRET=$(get_avar G_SS_LIST_ARRAY 1)
    assertEqual "$TESTRET" "1" getSnapshotFilesystems13b

    TEST="z/d z/d@0 z/d/t@0"
    array_clear TEST
    listToArray "$TEST" TEST
    getSnapshotFilesystems TEST "" G >/dev/null
    assertEqual $? 1 "getSnapshotFilesystems16"

    TEST="z/d z/d@0 z/d/a z/d/b z/d/c z/d/c@0"
    array_clear TEST
    listToArray "$TEST" TEST
    FS="z/d@0 z/d/a z/d/b z/d/c@0"
    FSE=""
    getSnapshotFilesystems TEST "" G
    assertEqual $? 0 "getSnapshotFilesystems17"
    assertEqual "`arrayToList G_FS_ARRAY`" "$FS" "getSnapshotFilesystems18"
    assertEqual "`arrayToList G_EXCEPTIONS_ARRAY`" "$FSE" "getSnapshotFilesystems19"
    assertEqual "`array_size G_FS_ARRAY`" 4 getSnapshotFilesystems17a
    TESTRET=$(get_avar G_SS_LIST_ARRAY 1)
    assertEqual "$TESTRET" "0" getSnapshotFilesystems17b
    TESTRET=$(get_avar G_SS_LIST_ARRAY 2)
    assertEqual "$TESTRET" "" getSnapshotFilesystems17c
    TESTRET=$(get_avar G_SS_LIST_ARRAY 3)
    assertEqual "$TESTRET" "" getSnapshotFilesystems17d
    TESTRET=$(get_avar G_SS_LIST_ARRAY 4)
    assertEqual "$TESTRET" "0" getSnapshotFilesystems17e

    TEST="z/d z/d@0 z/d/a z/d/b z/d/c z/d/c@0"
    array_clear TEST
    listToArray "$TEST" TEST
    FS=""
    FSE="z/d@0 z/d/a z/d/b z/d/c@0"
    getSnapshotFilesystems TEST "1" G
    assertEqual $? 0 "getSnapshotFilesystems20"
    assertEqual "`arrayToList G_FS_ARRAY`" "$FS" "getSnapshotFilesystems21"
    assertEqual "`arrayToList G_EXCEPTIONS_ARRAY`" "$FSE" "getSnapshotFilesystems22"
    assertEqual "`array_size G_FS_ARRAY`" "0" getSnapshotFilesystems20a

    TEST="z/a z/b z/c z/d"
    array_clear TEST
    listToArray "$TEST" TEST
    FS="z/a z/b z/c z/d"
    FSE=""
    getSnapshotFilesystems TEST "" G
    assertEqual $? 0 "getSnapshotFilesystems23"
    assertEqual "`arrayToList G_FS_ARRAY`" "$FS" "getSnapshotFilesystems24"
    assertEqual "`arrayToList G_EXCEPTIONS_ARRAY`" "$FSE" "getSnapshotFilesystems25"
    assertEqual "`array_size G_FS_ARRAY`" 4 getSnapshotFilesystems23a
    echo getSnapshotFilesystems tests ok.

    ### getSnapshotData tests #################################################
    array_clear TEST
    listToArray "z/d z/d@0 z/d@1 z/d@2 z/d/c z/d/e" TEST
    SNAPSHOTDATA=`getSnapshotData "TEST"`
    assertEqual $? 0 "getSnapshotData1"
    assertEqual "${SNAPSHOTDATA#*@}" "2" "getSnapshotData2"
    assertEqual "${SNAPSHOTDATA%@*}" "z/d" "getSnapshotData3"
    echo getSnapshotData tests ok.

    ### getRemoteDestination tests ############################################
    RET=`getRemoteDestination zfszroot/tmp/zfsBackupTest/source \
                         zfszroot/tmp/zfsBackupTest/source \
                         zfszroot/tmp/zfsBackupTest/dest`
    assertEqual "$RET" "zfszroot/tmp/zfsBackupTest/dest" \
                    "getRemoteDestination1" "" exit

    RET=`getRemoteDestination zfszroot/tmp/zfsBackupTest/source \
                         zfszroot/tmp/zfsBackupTest/source/child/baby \
                         zfszroot/tmp/zfsBackupTest/dest`

    assertEqual "$RET" "zfszroot/tmp/zfsBackupTest/dest/source/child" \
                    "getRemoteDestination2" "" exit

    RET=`getRemoteDestination zfszroot/tmp/zfsBackupTest/source \
                         zfszroot/tmp/zfsBackupTest/source/child/toddler/baby \
                         zfszroot/tmp/zfsBackupTest/dest`
    assertEqual "$RET" "zfszroot/tmp/zfsBackupTest/dest/source/child/toddler" \
                    "getRemoteDestination3" "" exit

    echo getRemoteDestination tests ok.

    # printElapsed() test
    local TMPDEBUG=$ZFS_BACKUP_DEBUG
    ZFS_BACKUP_DEBUG=0
    local TIMESTART=`date +%s`
    TIMESTART="$(($TIMESTART - 3723))"
    local MSG=`printElapsed $TIMESTART`
    if [ ! 1 -eq `echo $MSG |grep -c '1hr.2min.3sec$'` ]; then
        ZFS_BACKUP_DEBUG=$TMPDEBUG
        echo "printStatusTest1 failed"
        return 1
    fi
    ZFS_BACKUP_DEBUG=$TMPDEBUG

    echo printElapsed test ok.

    ### tests complete ########################################################
}

## Configuration creation #####################################################
configCreate() {
    if [ -f "${CONFIG_FILE}" ]; then
        return 0
    fi

    (cat <&3  >>${CONFIG_FILE}) 3<<EOF

#Set to ZFS_BACKUP_DEBUG=1 to enable debug.
ZFS_BACKUP_DEBUG=0

#Test configuration for zfsBackup.sh

#TESTER must have:
# -passwordless ssh access to localhost ie ssh to itself
# -permissions given by :
#   zfs allow -u \$TESTER create,destroy,mount,snapshot,receive,send,hold,rollback \$TESTFS
#   chown \$TESTER:\$TESTER \$TESTFS_MOUNT
# -host requirement :
#   sysctl vfs.usermount=1

TESTER=user
TESTFS=zroot/tmp/zfsBackupTest
TESTFS_MOUNT=/tmp/zfsBackupTest
TEST_SSH_LOCALHOST=localhost
#Set to TEST_OUTPUT=1 to enable test output.
TEST_OUTPUT=0
EOF

    echo The default configuration created in ${CONFIG_FILE}
}

## ZFS Tests ##################################################################
zfsTests() {
    echo Start zfs tests.
    if [ ! -x "`which zfs`" ]; then
        echo zfs executable not available!
        exit 1
    fi
    if [ ! -d ${TESTFS_MOUNT} ]; then
        echo Error \$TESTFS_MOUNT=${TESTFS_MOUNT} does not exist.
        echo Check ${CONFIG_FILE}
        exit 1
    elif [ "$TESTER" != "$USER" ]; then
        echo Error \$TESTER=$TESTER!=${USER}
        echo The configured user is not the user executing the script.
        echo Check ${CONFIG_FILE}
        exit 1
    fi

    if [ "$TEST_OUTPUT" -eq 1 -o "$ZFS_BACKUP_DEBUG" -eq 1 ]; then
        exec 8<>/dev/stdout
    else
        exec 8<>/dev/null
    fi

    RET=`ssh ${TESTER}@${TEST_SSH_LOCALHOST} 'echo ok'`
    assertEqual $RET "ok" "zfsTest0" \
        "Command failed: ssh ${TESTER}@${TEST_SSH_LOCALHOST} \
         Please check ${CONFIG_FILE} " exit

    # Test setup
    RET=`zfs list ${TESTFS}`
    assertEqual $? 0 "zfsTest1" \
        "${TESTFS} does not exist." exit

    # Cleanup from previous test failure
    # We don't clean up after a failed tests for easy debugging.
    zfs destroy -r ${TESTFS}/dest 2>/dev/null
    zfs destroy -r ${TESTFS}/source 2>/dev/null

    RET=`zfs create ${TESTFS}/source`
    assertEqual $? 0 "zfsTest2" \
        "Could not create ${TESTFS}/source " exit

    RET=`zfs create ${TESTFS}/dest`
    assertEqual $? 0 "zfsTest3" \
       "Could not create ${TESTFS}/dest" exit

    echo Test new parent file system. 
    ###########################################################################
    echo data1 > ${TESTFS_MOUNT}/source/file1.txt
    assertEqual $? 0 "zfsTest4" \
        "Could not create file ${TESTFS_MOUNT}/source/file1.txt" exit

    RET=`grep -c data1 ${TESTFS_MOUNT}/source/file1.txt`
    assertEqual $RET 1 "zfsTest5" \
        "File ${TESTFS_MOUNT}/source/file1.txt data does not exist." exit

    zfs snapshot -r ${TESTFS}/source@1
    assertEqual $? 0 "zfsTest6" "Snapshot creation failed ${TESTFS}/source@1." exit

    zfsBackup.sh ${TESTFS}/source ${TESTFS}/dest ${TESTER}@${TEST_SSH_LOCALHOST} >&8
    sleep 1 #Reading before the mount is completed, so wait a bit.
    assertEqual `ls ${TESTFS_MOUNT}/dest/source/file1.txt`\
    "${TESTFS_MOUNT}/dest/source/file1.txt"  1 "zfsTest7" "Backup failed." exit

    echo Test new child file system.
    ###########################################################################
    zfs create ${TESTFS}/source/child
    assertEqual $? 0 "zfsTest8" \
        "Could not create ${TESTFS}/source/child " exit

    echo data2 > ${TESTFS_MOUNT}/source/child/file2.txt
    assertEqual $? 0 "zfsTest9" \
        "Could not create file ${TESTFS_MOUNT}/source/child/file2.txt" exit

    zfs snapshot -r ${TESTFS}/source@2
    assertEqual $? 0 "zfsTest10" "Snapshot creation failed ${TESTFS}/source@2." exit

    zfsBackup.sh ${TESTFS}/source ${TESTFS}/dest ${TESTER}@${TEST_SSH_LOCALHOST} >&8

    assertEqual "`ls ${TESTFS_MOUNT}/dest/source/child/file2.txt`" \
    "${TESTFS_MOUNT}/dest/source/child/file2.txt" "zfsTest11" "Backup failed." exit

    echo Simulate a failed send of the child filesystem.
    ###########################################################################
    # zfsTest12 caused a headache where the destination file system was not
    # remounted to reflect the most recent snapshot. On completion of the backup
    # the destination filesystems are remounted.
    assertEqual $? 0 "zfsTest12" \
        "Could not destroy the child fs ${TESTFS_MOUNT}/dest/source/child" exit

    echo Backup and check the child@2 snapshot is resent.
    ###########################################################################
    zfsBackup.sh ${TESTFS}/source ${TESTFS}/dest ${TESTER}@${TEST_SSH_LOCALHOST} >&8

    assertEqual "`ls ${TESTFS_MOUNT}/dest/source/child/file2.txt`" \
    "${TESTFS_MOUNT}/dest/source/child/file2.txt" "zfsTest13" "Backup failed." exit

    echo Snapshot existing files with updated child data.
    ###########################################################################
    echo data3 > ${TESTFS_MOUNT}/source/child/file2.txt
    zfs snapshot -r ${TESTFS}/source@3
    assertEqual $? 0 "zfsTest14" "Could not snapshot ${TESTFS}/source" exit

    zfsBackup.sh ${TESTFS}/source ${TESTFS}/dest ${TESTER}@${TEST_SSH_LOCALHOST} >&8

    assertEqual $? 0 "zfsTest15" "Backup snapshot 3 failed." exit

    RET=`grep -c data3 ${TESTFS_MOUNT}/dest/source/child/file2.txt`
    assertEqual "$RET" 1 "zfsTest16" \
        "File ${TESTFS_MOUNT}/dest/source/child/file2.txt data does not exist." exit

    echo Simulate a fail send os child@3
    ###########################################################################
    zfs rollback -r ${TESTFS}/dest/source/child@2
    assertEqual $? 0 "zfsTest17" \
        "Could not rollback the child fs ${TESTFS_MOUNT}/dest/source/child@2" exit

    RET=`grep -c data2 ${TESTFS_MOUNT}/dest/source/child/file2.txt`
    assertEqual "$RET" 1 "zfsTest18" \
        "File ${TESTFS_MOUNT}/dest/source/child/file2.txt snapshot2 data does not exist." exit

    zfsBackup.sh ${TESTFS}/source ${TESTFS}/dest ${TESTER}@${TEST_SSH_LOCALHOST} >&8

    assertEqual $? 0 "zfsTest19" "Redo backup snapshot 3 failed." exit

    RET=`grep -c data3 ${TESTFS_MOUNT}/dest/source/child/file2.txt`
    assertEqual $RET 1 "zfsTest20" \
        "File ${TESTFS_MOUNT}/dest/source/child/file2.txt data does not exist." exit

    echo Snapshot test1.
    ###########################################################################
    zfs create ${TESTFS}/source/rename
    sleep 1
    touch ${TESTFS_MOUNT}/source/rename/1
    sleep 1
    zfs snapshot -r ${TESTFS}/source/rename@1
    zfsBackup.sh ${TESTFS}/source/rename ${TESTFS}/dest ${TESTER}@${TEST_SSH_LOCALHOST} >&8
    zfs rename ${TESTFS}/source/rename ${TESTFS}/source/ren
    sleep 1
    zfs rename ${TESTFS}/dest/rename ${TESTFS}/dest/ren
    zfs umount ${TESTFS}/source/ren
    zfs mount ${TESTFS}/source/ren
    sleep 1
    touch ${TESTFS_MOUNT}/source/ren/2
    zfs snapshot -r ${TESTFS}/source/ren@2
    zfsBackup.sh ${TESTFS}/source/ren ${TESTFS}/dest ${TESTER}@${TEST_SSH_LOCALHOST} >&8

    echo Snapshot test2.
    zfs rename ${TESTFS}/dest/ren ${TESTFS}/dest/blah
    zfs rename ${TESTFS}/dest/blah ${TESTFS}/dest/ren
    touch ${TESTFS_MOUNT}/source/ren/3
    zfs snapshot -r ${TESTFS}/source/ren@3
    zfsBackup.sh ${TESTFS}/source/ren ${TESTFS}/dest ${TESTER}@${TEST_SSH_LOCALHOST} >&8

    echo Snapshot test3.
    touch ${TESTFS_MOUNT}/dest/ren
    touch ${TESTFS_MOUNT}/source/ren/4
    zfs snapshot -r ${TESTFS}/source/ren@4
    zfsBackup.sh ${TESTFS}/source/ren ${TESTFS}/dest ${TESTER}@${TEST_SSH_LOCALHOST} >&8
    touch ${TESTFS_MOUNT}/dest/ren/test.touch
    touch ${TESTFS_MOUNT}/source/ren/5
    zfs snapshot -r ${TESTFS}/source/ren@5
    zfsBackup.sh ${TESTFS}/source/ren ${TESTFS}/dest ${TESTER}@${TEST_SSH_LOCALHOST} >&8

    zfs destroy -r ${TESTFS}/source/ren@1,2,3,4
    zfs destroy -r ${TESTFS}/dest/ren@1,2,3,4

    zfs snapshot -r ${TESTFS}/source/ren@6
    zfsBackup.sh ${TESTFS}/source/ren ${TESTFS}/dest ${TESTER}@${TEST_SSH_LOCALHOST} >&8

    zfs umount ${TESTFS}/dest/ren
    zfs mount ${TESTFS}/dest/ren

    if [ -f ${TESTFS_MOUNT}/source/ren/1 -a -f ${TESTFS_MOUNT}/source/ren/2 -a \
        -f ${TESTFS_MOUNT}/source/ren/3 -a -f ${TESTFS_MOUNT}/source/ren/4 -a \
        -f ${TESTFS_MOUNT}/source/ren/5 -a -f ${TESTFS_MOUNT}/dest/ren/1 -a \
        -f ${TESTFS_MOUNT}/dest/ren/2 -a -f ${TESTFS_MOUNT}/dest/ren/3 -a \
        -f ${TESTFS_MOUNT}/dest/ren/4 -a -f ${TESTFS_MOUNT}/dest/ren/5 ]; then
        echo Snapshot tests completed ok.
    else
        echo Snapshot tests failed.
        return 1
    fi



    # Only do the test tear down if all the tests succeed.
    echo Cleaning up ${TESTFS}/dest ${TESTFS}/source
    RET=`zfs destroy -r ${TESTFS}/dest`
    assertEqual $? 0 "zfsTest-2" \
        "Could not remove ${TESTFS}/dest" exit

    RET=`zfs destroy -r ${TESTFS}/source`
    assertEqual $? 0 "zfsTest-1" \
        "Could not remove ${TESTFS}/source " exit

}

### MAIN #####################################################################

configCreate
. ${CONFIG_FILE}

if [ "$ZFS_BACKUP_DEBUG" -eq 1 ]; then
    exec 9<>/dev/stderr
else
    exec 9<>/dev/null
fi

if [ 3 -ne $# ]; then
    if [ "zfsTests" = "$1" ]; then
        zfsTests
        echo ZFS tests completed, check the output for errors. >/dev/stdout
        exit 0
    elif [ "shellTests" = "$1" ]; then
        shellTests
        echo Shell tests completed, check the output for errors. >/dev/stdout
        exit 0
    fi
    usage
    exit 0
else
    #Not a test so no use for these:
    unset TESTER TESTFS TESTFS_MOUNT TEST_SSH_LOCALHOST
fi

echo ================================================================================
echo Starting backup ...
doBackup $G_ZFS_SRC_FS $G_ZFS_DEST_FS $G_ZFS_USER_HOST
if [ $? -ne 0 ]; then
    echo Backup failure.
else
    echo Backup complete.
fi
echo ================================================================================
