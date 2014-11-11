#!/bin/sh

# Perform backup of zfs filesystem.
#  - Recursive.
#  - Automatic incremental backup.
#  - Source snapshot consistency check.

#Limitation: file system names must not contain spaces.

usage() {
    echo "Usage ./zfsBup.sh src_zfs dest_zfs user@remote_host"
    echo
    echo example: ./zfsup.sh zpool/data zpool/data/bup root@192.168.1.102
    echo
    echo "No args specified so now running tests ..."
}


G_FILESYSTEM_LIST=""
G_FILESYSTEM_EXCEPTIONS=""
G_MAX_SNAPSHOT=""
G_SNAPSHOT_NAME=""
G_BRANCH_CNT="0"

#BUPFS=zroot/data
BUPFS=$1
REMOTEFS=zroot/bup
REMOTEHOST=root@192.168.1.102
#snapshot of the root
ROOTSS=""
TARGETDIR=${BUPFS##*/}

###############################################################################
set_avar()
{
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

###############################################################################
getRemote() {
   echo get $REMOTEFS/$1
   for line in `ssh $REMOTEHOST zfs list -d 1 -H -o name -t all $REMOTEFS/$1`
   do
        snapcnt=`echo $line | grep -c @`
        if [ 0 -eq "$snapcnt" ]; then
            currentname=$line
         currentss=""
      fi
   done;
   return 0;
}


###############################################################################
doBackup() {
#
# Backup the given filesystem.
#
# $1 = the file system.
#
# return    0 = success 
#           1 = failure and returns the error message
#
# check the local filesystem for snapshot continuity.
    local ZFILESYSTEM=$1
    local ROOTLIST=`zfs list -d 1 -H -o name -t all $ZFILESYSTEM`
    getSnapshotData "$ROOTLIST"
    local RET=$?
    if [ $? -ne 0 ]; then
        return $?
    fi
    local FULLLIST=`zfs list -H -o name -t all $ZFILESYSTEM`
    getSnapshotFilesystems "$FULLLIST" "$G_MAX_SNAPSHOT"

# loop on the local tree sending the data to the remote host
# send new remote filesystem
# send incremental remote filesystem
}

###############################################################################
getSnapshotData() {
#
# Get the G_MAX_SNAPSHOT G_SNAPSHOT_NAME for the filesystem root. 
#
# $1 = the list from `zfs list -d 1 -H -o name -t all zfilesystem`
#
# return    G_MAX_SNAPSHOT G_SNAPSHOT_NAME for the filesystem root. 
#           0 = success 
#           1 = failure and returns the error message

    G_MAX_SNAPSHOT=""
    G_SNAPSHOT_NAME=""
    local LIST=$1
    local LINE=""
    local SNAPCNT=""
    local FIRST="1"

    for LINE in $LIST
    do
        SNAPCNT=`echo "$LINE" | grep -c @`
        if [ 0 -eq "$SNAPCNT" ]; then
            if [ -z "$G_SNAPSHOT_NAME" ]; then
                G_SNAPSHOT_NAME=$LINE
            fi 
        else        
            if [ -z "$G_SNAPSHOT_NAME" ]; then
                G_SNAPSHOT_NAME=${LINE%%@*}
            fi
            if [ "${LINE%%@*}" != "$G_SNAPSHOT_NAME" ]; then
                echo "Name mismatch '${LINE%%@*}' != '$G_SNAPSHOT_NAME'"
                return 1
            fi
            local CURRENTSS=$(getSnapshotVersion $LINE)
            G_MAX_SNAPSHOT="$CURRENTSS"
        fi
    done;
    return 0;
}

###############################################################################
sortSnapshotFilesystems() {
#
# Adjusts G_FILESYSTEM_LIST and G_FILESYSTEM_EXCEPTIONS with the last line
# filesystem snapshot. 
#
# $1 = last line
# $2 = current line
# $3 = snapshot version
#
# return    G_FILESYSTEM_LIST contains all filesystems for the
#               given snapshot.
#           G_FILESYSTEM_EXCEPTIONS contains all filesystems without 
#               the given snapshot.
#           G_SS_STATUS - isValidSnapshot status.
#
#           0 = success 
#           1 = failure and returns the error message
#
    local LASTLINE=$1
    local CURRENTLINE=$2
    local SSVERSION=$3
    isValidSnapshot "$LASTLINE" "$CURRENTLINE" "$SSVERSION" 
    G_SS_STATUS=$?
    if [ $G_SS_STATUS -eq 0 ]; then
        if [ -z  "$G_FILESYSTEM_LIST" ]; then
            G_FILESYSTEM_LIST="$LASTLINE"
        else
            G_FILESYSTEM_LIST="$G_FILESYSTEM_LIST $LASTLINE"
        fi
    elif [ $G_SS_STATUS -eq 1 ]; then
        if [ -z  "$G_FILESYSTEM_EXCEPTIONS" ]; then
            G_FILESYSTEM_EXCEPTIONS="$LASTLINE"
        else
            G_FILESYSTEM_EXCEPTIONS="$G_FILESYSTEM_EXCEPTIONS $LASTLINE"
        fi

    elif [ $G_SS_STATUS -eq 3 ]; then
        echo $MSG
        return 1;
    fi
    return 0;
}

###############################################################################
getSnapshotFilesystems() {
#
# Build a list of all filesystems matching the given snapshot version.
#
# $1 = the list of file systems
# $2 = the snapshot version
#
# return    G_FILESYSTEM_LIST contains all filesystems for the
#               given snapshot.
#           G_FILESYSTEM_EXCEPTIONS contains all filesystems without 
#               the given snapshot.
#           G_BRANCH_CNT is the number of filesystems in G_FILESYSTEM_LIST
#           G_BRANCH_SS_LIST array contains the snapshot identifiers
#               for each branch/filesystem in G_FILESYSTEM_LIST.
#           0 = success 
#           1 = failure and returns the error message
#
    G_FILESYSTEM_LIST=""
    G_FILESYSTEM_EXCEPTIONS=""
    local LIST=$1
    local SSVERSION=$2
    local RET=0
    local CURRENTLINE=""
    local LASTLINE=""
    local FIRST="1"
    if [ $G_BRANCH_CNT -gt 0 ]; then
        while [ $G_BRANCH_CNT -gt 0 ]; do 
           set_avar G_BRANCH_SS_LIST $G_BRANCH_CNT ""
           G_BRANCH_CNT=$((G_BRANCH_CNT-1))
        done;
    fi
    G_BRANCH_CNT=1

    for LINE in $LIST ""
    do
        CURRENTLINE=$LINE
        local SSLIST=""
        if [ "$FIRST" = "0" ]; then
            sortSnapshotFilesystems "$LASTLINE" "$CURRENTLINE" "$SSVERSION"
            if [ $? -eq 1 ]; then
                return 1;
            fi
            #store the snapshots for each branch
            if [ "$G_SS_STATUS" -eq 2 -o "$G_SS_STATUS" -eq 0 ]; then
                #is an intermediate or final snapshot so add to the list.   
                local LASTSS=$(getSnapshotVersion $LASTLINE)
                SSLIST=$(get_avar G_BRANCH_SS_LIST $G_BRANCH_CNT) 
                if [ ! -z "$LASTSS" ]; then
                    if [ -z "$SSLIST" ]; then
                        SSLIST=$LASTSS
                    else
                        SSLIST="$SSLIST $LASTSS"
                    fi
                fi
                set_avar G_BRANCH_SS_LIST $G_BRANCH_CNT "$SSLIST"
            fi

            if [ $G_SS_STATUS -eq 0 ]; then
                #Set the branch counter for the next branch
                G_BRANCH_CNT=$((G_BRANCH_CNT+1))
            elif [ $G_SS_STATUS -eq 1 ]; then
                #is an invalid snapshot collection so clear the list.   
                set_avar G_BRANCH_SS_LIST $G_BRANCH_CNT ""
            fi
        else
            FIRST="0"
        fi
        LASTLINE=$CURRENTLINE
    done
    G_BRANCH_CNT=$((G_BRANCH_CNT-1))
    return 0;
}

###############################################################################
getSnapshotVersion() {
    local TMPSTR=$1
    local SNAPSHOT=${TMPSTR##*@}
    if [ "$TMPSTR" = "$SNAPSHOT" ]; then
        SNAPSHOT="" 
    fi
    echo $SNAPSHOT
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

    local LASTLINE=$1
    local CURRENTLINE=$2
    local LASTNAME=${LASTLINE%%@*}
    local CURRENTNAME=${CURRENTLINE%%@*}

    if [ "$LASTNAME" != "$CURRENTNAME" ]; then
        echo "Error: nameValidation() Names should match: last:$LASTLINE current:$CURRENTLINE"
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
    local LASTLINE=$1
    local CURRENTLINE=$2
    local SSVERSION=$3
    local L_HAS_SNAP=`echo $LASTLINE | grep -c @`
    local C_HAS_SNAP=`echo $CURRENTLINE | grep -c @`
    local LASTNAME="" 
    local CURRENTNAME=""

    if [ -z "$LASTLINE" ]; then
        echo LASTLINE can not be empty.
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
            LASTSS=$(getSnapshotVersion $LASTLINE)
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
assertEqual(){ 
    local arg1="$1"
    local arg2="$2"
    local testName="$3"
    local errorMesg="$4"
    if [ ! -z "$errorMesg" ]; then
        errorMesg=error:$errorMesg
    fi
    if [ "$arg1" != "$arg2" ]; then
        echo "$testName Test Failure: arg1='$arg1' arg2='$arg2' $errorMesg"
    fi
}

## Tests ######################################################################
if [ 3 -ne $# ]; then

    usage

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

    ### getSnapshotFilesystems tests ########################################## 
    TEST="zpool/data@0"
    getSnapshotFilesystems "$TEST" "0" 
    assertEqual $? 0 "getSnapshotFilesystems1" 
    assertEqual "$G_FILESYSTEM_LIST" "$TEST" "getSnapshotFilesystems2"
    assertEqual "$G_FILESYSTEM_EXCEPTIONS" "" "getSnapshotFilesystems3"
    assertEqual "$G_BRANCH_CNT" 1 getSnapshotFilesystems1a
    TESTRET=$(get_avar G_BRANCH_SS_LIST $G_BRANCH_CNT)
    assertEqual "$TESTRET" "0" getSnapshotFilesystems1b

    TEST="zpool/data@0 zpool/data@1 zpool/data/test zpool/data/test1"
    FS="zpool/data@1 zpool/data/test zpool/data/test1"
    FSE=""
    getSnapshotFilesystems "$TEST" "" 
    assertEqual $? 0 "getSnapshotFilesystems4" 
    assertEqual "$G_FILESYSTEM_LIST" "$FS" "getSnapshotFilesystems5"
    assertEqual "$G_FILESYSTEM_EXCEPTIONS" "$FSE" "getSnapshotFilesystems6"
    assertEqual "$G_BRANCH_CNT" 3 getSnapshotFilesystems4a
    TESTRET=$(get_avar G_BRANCH_SS_LIST 1)
    assertEqual "$TESTRET" "0 1" getSnapshotFilesystems4b
    TESTRET=$(get_avar G_BRANCH_SS_LIST 2)
    assertEqual "$TESTRET" "" getSnapshotFilesystems4c
    TESTRET=$(get_avar G_BRANCH_SS_LIST 3)
    assertEqual "$TESTRET" "" getSnapshotFilesystems4d

    TEST="zpool/data@0 zpool/data@1 zpool/data/test zpool/data/test@1"
    FS="zpool/data@1 zpool/data/test@1"
    FSE=""
    getSnapshotFilesystems "$TEST" "" 
    assertEqual $? 0 "getSnapshotFilesystems7" 
    assertEqual "$G_FILESYSTEM_LIST" "$FS" "getSnapshotFilesystems8"
    assertEqual "$G_FILESYSTEM_EXCEPTIONS" "$FSE" "getSnapshotFilesystems9"
    assertEqual "$G_BRANCH_CNT" 2 getSnapshotFilesystems7a
    TESTRET=$(get_avar G_BRANCH_SS_LIST 1)
    assertEqual "$TESTRET" "0 1" getSnapshotFilesystems7b
    TESTRET=$(get_avar G_BRANCH_SS_LIST 2)
    assertEqual "$TESTRET" "1" getSnapshotFilesystems7c

    TEST="zpool/data@0 zpool/data@1 zpool/data/test zpool/data/test@1"
    FS="zpool/data@1 zpool/data/test@1"
    FSE=""
    getSnapshotFilesystems "$TEST" "1" 
    assertEqual $? 0 "getSnapshotFilesystems10" 
    assertEqual "$G_FILESYSTEM_LIST" "$FS" "getSnapshotFilesystems11"
    assertEqual "$G_FILESYSTEM_EXCEPTIONS" "$FSE" "getSnapshotFilesystems12"
    assertEqual "$G_BRANCH_CNT" 2 getSnapshotFilesystems11a
    TESTRET=$(get_avar G_BRANCH_SS_LIST 1)
    assertEqual "$TESTRET" "0 1" getSnapshotFilesystems11b
    TESTRET=$(get_avar G_BRANCH_SS_LIST 2)
    assertEqual "$TESTRET" "1" getSnapshotFilesystems11c

    TEST="zpool/data zpool/data@0 zpool/data/test zpool/data/test@1"
    FS="zpool/data/test@1"
    FSE="zpool/data@0"
    getSnapshotFilesystems "$TEST" "1" 
    assertEqual $? 0 "getSnapshotFilesystems13" 
    assertEqual "$G_FILESYSTEM_LIST" "$FS" "getSnapshotFilesystems14"
    assertEqual "$G_FILESYSTEM_EXCEPTIONS" "$FSE" "getSnapshotFilesystems15"
    assertEqual "$G_BRANCH_CNT" 1 getSnapshotFilesystems13a
    TESTRET=$(get_avar G_BRANCH_SS_LIST 1)
    assertEqual "$TESTRET" "1" getSnapshotFilesystems13b

    TEST="z/d z/d@0 z/d/t@0"
    getSnapshotFilesystems "$TEST" "" >/dev/null
    assertEqual $? 1 "getSnapshotFilesystems16" 

    TEST="z/d z/d@0 z/d/a z/d/b z/d/c z/d/c@0"
    FS="z/d@0 z/d/a z/d/b z/d/c@0"
    FSE=""
    getSnapshotFilesystems "$TEST" "" 
    assertEqual $? 0 "getSnapshotFilesystems17" 
    assertEqual "$G_FILESYSTEM_LIST" "$FS" "getSnapshotFilesystems18"
    assertEqual "$G_FILESYSTEM_EXCEPTIONS" "$FSE" "getSnapshotFilesystems19"
    assertEqual "$G_BRANCH_CNT" 4 getSnapshotFilesystems17a
    TESTRET=$(get_avar G_BRANCH_SS_LIST 1)
    assertEqual "$TESTRET" "0" getSnapshotFilesystems17b
    TESTRET=$(get_avar G_BRANCH_SS_LIST 2)
    assertEqual "$TESTRET" "" getSnapshotFilesystems17c
    TESTRET=$(get_avar G_BRANCH_SS_LIST 3)
    assertEqual "$TESTRET" "" getSnapshotFilesystems17d
    TESTRET=$(get_avar G_BRANCH_SS_LIST 4)
    assertEqual "$TESTRET" "0" getSnapshotFilesystems17e

    TEST="z/d z/d@0 z/d/a z/d/b z/d/c z/d/c@0"
    FS=""
    FSE="z/d@0 z/d/a z/d/b z/d/c@0"
    getSnapshotFilesystems "$TEST" "1" 
    assertEqual $? 0 "getSnapshotFilesystems20" 
    assertEqual "$G_FILESYSTEM_LIST" "$FS" "getSnapshotFilesystems21"
    assertEqual "$G_FILESYSTEM_EXCEPTIONS" "$FSE" "getSnapshotFilesystems22"
    assertEqual "$G_BRANCH_CNT" 0 getSnapshotFilesystems20a

    TEST="z/a z/b z/c z/d"
    FS="z/a z/b z/c z/d"
    FSE=""
    getSnapshotFilesystems "$TEST" "" 
    assertEqual $? 0 "getSnapshotFilesystems23" 
    assertEqual "$G_FILESYSTEM_LIST" "$FS" "getSnapshotFilesystems24"
    assertEqual "$G_FILESYSTEM_EXCEPTIONS" "$FSE" "getSnapshotFilesystems25"
    assertEqual "$G_BRANCH_CNT" 4 getSnapshotFilesystems23a

    ### getSnapshotData tests ################################################# 
    TEST="z/d z/d@0 z/d@1 z/d@2 z/d/c z/d/e"
    getSnapshotData "$TEST"
    assertEqual $? 0 "getSnapshotData1" 
    assertEqual "$G_MAX_SNAPSHOT" "2" "getSnapshotData2" 
    assertEqual "$G_SNAPSHOT_NAME" "z/d" "getSnapshotData3" 


    ### tests complete ######################################################## 
    echo Tests completed ok.
    exit

fi

echo Starting backup ...
exit
###############################################################################
#remotelist=`ssh $REMOTEHOST zfs list -d 1 -H -o name -t all $REMOTEFS/$1`

list=`zfs list -r -H -o name -t all $BUPFS`
echo $list

exit


if [ -z $BUPFS ]; then
   echo Usage zfsBup.sh bupfs
   exit 0;
fi

for line in `zfs list -r -H -o name -t all $BUPFS`
do
   SNAP=`echo $line | grep -c @`
   if [ 0 -eq "$SNAP" ]; then
      CURRENTNAME=$line
      CURRENTSS=""
      getMaxSnapShot $TARGETDIR${CURRENTNAME#*$TARGETDIR}
   else 
      CURRENTSS=${line##*@}
      CURRENTNAME=${line%%@*}
   fi
   if [ -z "$LASTNAME" ]; then
      LASTNAME=${CURRENTNAME}
   fi
   if [ "$CURRENTNAME" = "$LASTNAME" ]; then
   #save the snapshot version
      if [ -z "$CURRENTSS" -a ! -z "$ROOTSS" ]; then
         echo Error1: No snapshot for $CURRENTNAME.
      else
         LASTSS=$CURRENTSS
      fi
   else
   #next file system    
      if [ ! -z "$ROOTSS" ]; then
         if [ "$LASTSS" != "$ROOTSS" ]; then
            echo Error2: Filesystem $LASTNAME has snapshot $LASTSS, not snapshot: $ROOTSS
         else
            echo Filesystem: $LASTNAME@$LASTSS ok.  
         fi 
      else 
         if [ -z "$LASTSS" ]; then
            echo Error0: No snapshot for root file system.
            exit 0;
         else
            echo Filesystem: $LASTNAME@$LASTSS is the root. 
            ROOTSS=$LASTSS
         fi
      fi
      LASTNAME=$CURRENTNAME
   fi 
done;

if [ "$LASTSS" != "$ROOTSS" ]; then
   echo Error2: Filesystem $LASTNAME has snapshot $LASTSS, not snapshot: $ROOTSS
else
   echo Filesystem: $LASTNAME@$LASTSS ok.  
fi 


