#!/bin/bash
# Note: Deleted files are not recorded in the incremental backups.
export BUPDIR="/mnt/o/backup_for_daren"
export FIREFOX=".mozilla/firefox/*.default/bookmarkbackups"
export STAGE=/opt/backups
export ARCHIVE=/opt/backups/archive
export CURRENT=/opt/backups/current
export LOGDIR=${STAGE}/logs

export FULL=$1


if [ -d "/mnt/o/backup_for_daren" ]; then
    echo Doing bup...
    export SNAPDATE=`date +%Y%m%d%H%M`
    export LOGFILE=${LOGDIR}/${SNAPDATE}.log
    export SNAPDIR=${STAGE}/inc/${SNAPDATE}

    mkdir -p ${ARCHIVE}
    mkdir -p ${CURRENT}
    mkdir -p ${LOGDIR}
    mkdir -p ${SNAPDIR}

    {

    #rsync -avhm --compare-dest=${CURRENT} --del --prune-empty-dirs ${HOME}/work/marketing ${SNAPDIR}
    #find ${SNAPDIR} -depth -type d -empty -exec rmdir -v {} \; 
    #cp -a --copy-contents ${SNAPDIR}/* ${CURRENT}

    ###########################################################################
    # HOME files
    mkdir -p ${SNAPDIR}${HOME}
    rsync -avh --compare-dest=${CURRENT}${HOME} \
    ${HOME}/vim \
    ${HOME}/_vimrc \
    ${HOME}/.vim \
    ${HOME}/.vim_java \
    ${HOME}/.bashrc \
    ${HOME}/.gnupg \
    ${HOME}/Documents \
    ${HOME}/bin \
    ${HOME}/work \
    ${HOME}/.fvwm ${SNAPDIR}${HOME}

    ###########################################################################
    # Firefox bookmarks
    mkdir -p ${SNAPDIR}${HOME}/${FIREFOX}
    export FIREFOXBOOKMARK=`ls -1art ${HOME}/${FIREFOX}/*.json |tail -1`
    rsync -avh --compare-dest=${CURRENT}${HOME}/${FIREFOX} ${FIREFOXBOOKMARK} ${SNAPDIR}${HOME}/${FIREFOX}

    ###########################################################################
    # /etc customisations
    sudo mkdir -p ${SNAPDIR}/etc
    sudo mkdir -p ${CURRENT}/etc
    sudo rsync -avh --super --rsync-path="sudo rsync --super" --compare-dest=${CURRENT}/etc \
    /etc/fstab \
    /etc/openvpn \
    /etc/X11/xorg.conf \
    /etc/sudoers ${SNAPDIR}/etc

    ###########################################################################
    # /root customisations
    sudo mkdir -p ${SNAPDIR}/root
    sudo mkdir -p ${CURRENT}/root
    sudo rsync -avh --super --rsync-path="sudo rsync --super" --compare-dest=${CURRENT}/root \
    /root/secret.txt ${SNAPDIR}/root

    ###########################################################################
    # Archive Creation                                                        #
    ###########################################################################

    # Remove empty dirs from the incremental snapshot dir.
    find ${SNAPDIR} -depth -type d -empty -exec rmdir -v {} \; 
    # Copy the new snapshot files to update the CURRENT file stage area.
    cp -a --copy-contents ${SNAPDIR}/* ${CURRENT}

    } 1>> ${LOGFILE} 2>>${LOGFILE}

    if [ -d ${SNAPDIR} ]; then
        {
        if [ -n "${FULL}" ]; then
            # Full backup archive
            echo Create full backup archive.
            export FULL_BUP_FILE=${ARCHIVE}/full_${SNAPDATE}.tar.gz.gpg
            tar -cvzf - ${CURRENT} |gpg -e -r 'Daren Isaacs' --output ${FULL_BUP_FILE}
            rsync -avH ${FULL_BUP_FILE} $BUPDIR
        else
            # Incremental backup archive
            echo Create incremental backup archive.
            export INC_BUP_FILE=${ARCHIVE}/inc_${SNAPDATE}.tar.gz.gpg
            tar -cvzf - ${SNAPDIR} |gpg -e -r 'Daren Isaacs' --output ${INC_BUP_FILE}
            rsync -avH ${INC_BUP_FILE} $BUPDIR
        fi
        } 1>> ${LOGFILE} 2>>${LOGFILE}
    else
        echo Backup files are up to date!
    fi


    NBWORK=${HOME}/NetBeansProjects
    NBPROJ=${HOME}/NetBeansProjects/anzcro-direct-public
    DEST=${BUPDIR}${NBWORK}
#    mkdir -p $DEST
#    rsync -av --exclude target --exclude .svn ${NBPROJ} $DEST/

#    NBPROJ=${HOME}/NetBeansProjects/svn-ozone3
#    DEST=${BUPDIR}${NBPROJ}
#    mkdir -p $DEST
#    rsync -av --exclude target ${NBPROJ}/o3bizlogic $DEST/
#    rsync -av --exclude target ${NBPROJ}/o3dao $DEST/
#    rsync -av --exclude target ${NBPROJ}/o3gui $DEST/
#    rsync -av --exclude target ${NBPROJ}/o3servicelayer $DEST/
   
#    rsync -av --exclude target ${NBWORK}/o4services $DEST/
#    rsync -av --exclude target --exclude extjs  ${NBWORK}/ozone-commons/trunk/oc-fcl $DEST/
#    rsync -av --exclude target --exclude extjs  ${NBWORK}/ozone-commons/trunk/oc-domain $DEST/
#    rsync -av --exclude target --exclude extjs  ${NBWORK}/o4reports/trunk/o4reports-services-impl $DEST/
#    rsync -av --exclude target --exclude extjs  ${NBWORK}/o4reports/trunk/o4reports-dao $DEST/
#    rsync -av --exclude target --exclude extjs  ${NBWORK}/o4reports/trunk/o4reports-domain $DEST/
#    rsync -av --exclude target --exclude extjs  ${NBWORK}/o4reports/trunk/o4reports-springmvc-web $DEST/
#    rsync -av --exclude target --exclude extjs  ${NBWORK}/fcl-ws  $DEST/
#    rsync -av --exclude target --exclude extjs  ${NBWORK}/svn-o3ws  $DEST/
    rsync -av --exclude target --exclude extjs ${NBWORK}/ozone3-maven2/ozone3-passive-air $DEST/ozone3-maven2

else 
    echo Mount O drive!
fi

