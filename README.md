Shell Scripts
=============

A collection of usefull scripts.

diskcheck.sh - Check the disk usage threshold and send an alert email.

gstatus.sh - Find subdirectories containing git repositories and print the
    status of each repository.

jdkenv - A script to allow easy configuration of java jdk or jre environment by
    setting the PATH and JAVA_HOME from a selection of java environments. Does
    a clean up of the PATH to avoid invalid path elements.

sshd-fwscan.sh - Tail auth.log and add the host of invalid login attempts to
    the packet filter for blocking. The hosts of successful logins are not
    blocked.

vbox_restart_pm_utils - Reboot a virtualbox guest on resume from pm-suspend to
    resynchronize the clock on the guest host.

zfsDup.sh - Allow recursive duplication of filesystems to a remote host. The
    parent and child filesystem snapshot versions are verified with the remote
    destination. Implemented with zfs send/receive over ssh.
    Each child filesystem is transmitted independently to improve transmission
    efficiency in the case of network outages/errors. ie zfs send/receive does
    not resume a transmission but restarts the transmission of a filesystem
    from the beginning. ie Failure during the duplication of a filesystem
    composed of small child filesystems, will only re-transmit the data for the
    child filesystem in the process of duplicating, at the point in time of
    the network failure.
