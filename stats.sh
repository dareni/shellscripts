#!/usr/local/bin/bash
# Maintained at: git@github.com:dareni/shellscripts.git
# Use nvtop instead.

do_usage(){
   echo "Show cpu and gpu stats."
   echo
   echo "usage: stats.sh [process name]"
}

if [[ "$1" = "-h" ]]; then
   do_usage;
   exit;
fi


while true; do
 nvidia-settings -q GPUCoreTemp -q GPUUtilization | \
   grep gpu |awk '{buff=$2 $4 $5 $6 buff} END{printf buff" "}' | \
   sed -e "s/'GPUUtilization/GPUUtil/" |sed -e "s/'GPUCoreTemp/ GpuTemp/" |sed -e "s/'/:/g" |sed -e"s/, / /" |sed -e"s/. / /";

    if [ -n "$1" ]; then
      arg="-C $1"
    else
      arg="-e"
    fi
    ps $arg h -o pcpu |awk '{pcpu=pcpu + $1} END{print "CPUUtil:'$1':" pcpu"%"}';
  sleep 1;
done
