#!/bin/sh
# wpa_cli example script.

list_network() {
    max_net_id=`sudo wpa_cli add_network|tail -1| awk '{print $NF}'`
    i=0;
    while [ $i -le ${max_net_id} ]
    do
        #wpa_cli get_network $i ssid
        ssid=`sudo wpa_cli get_network $i ssid|tail -1`
        if [ "$ssid" = FAIL ]; then
            sudo wpa_cli remove_network $i > /dev/null
        else
            echo $i : $ssid
        fi
        i=$((i+1))
    done;
}

list_scan() {
    sudo wpa_cli scan
    sudo wpa_cli scan_results
}

select_network() {
    if [ -z $1 ]; then
        echo Specify network id to select.
        return 1;
    fi
    sudo wpa_cli select_network $1
}

status() {
    sudo wpa_cli status
}

case $1 in
    lsnet)
        list_network;;
    lsscan)
        list_scan;;
    select)
        select_network $2;;
    stat)
        status;;
    *)
        echo lsnet,lsscan,select,stat;;
esac
