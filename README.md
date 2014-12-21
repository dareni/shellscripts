Shell Scripts
=============

A collection of usefull scripts.

jdkenv - A script to allow easy configuration of java jdk or jre environment by
    setting the PATH and JAVA_HOME from a selection of java environments. Does
    a clean up of the PATH to avoid invalid path elements. 

zfsBup.sh - Allow recursive backup of zfs filesystems to a remote host. The 
    parent and child filesystem snapshot versions are verified with the remote
    destination. Implemented with zfs send/receive over netcat (nc). 
    Each child filesystem is transmitted independently to improve transmission
    efficiency in the case of network outages/errors. ie zfs send/receive does 
    not resume a transmission but restarts the transmission of a filesystem
    from the beginning. ie Failure during the backup of a filesystem composed of
    small child filesystems will only retransmit the data for the child
    filesystem processing at the point in time of the network failure.

    
