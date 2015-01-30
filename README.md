Shell Scripts
=============

A collection of usefull scripts.

jdkenv - A script to allow easy configuration of java jdk or jre environment by
    setting the PATH and JAVA_HOME from a selection of java environments. Does
    a clean up of the PATH to avoid invalid path elements. 

zfsBackup.sh - Allow recursive zfs backup of filesystems to a remote host. The 
    parent and child filesystem snapshot versions are verified with the remote
    destination. Implemented with zfs send/receive over netcat (nc). 
    Each child filesystem is transmitted independently to improve transmission
    efficiency in the case of network outages/errors. ie zfs send/receive does 
    not resume a transmission but restarts the transmission of a filesystem
    from the beginning. ie Failure during the backup of a filesystem composed of
    small child filesystems, will only re-transmit the data for the child
    filesystem processing, at the point in time of the network failure.

diskcheck.sh - Check the disk usage threshold and send an alert email.    

vbox_restart_pm_utils - Reboot a virtualbox guest on resume from pm-suspend to 
    resynchronize the clock on the guest host.
