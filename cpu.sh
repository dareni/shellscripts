#!/bin/bash
echo range: `sudo cpufreq-info -l`
echo current freq: `sudo cpufreq-info -w`
LOW=`cpufreq-info -l |awk '{print $1}'`
HIGH=`cpufreq-info -l |awk '{print $2}'`
if [[ "$1" == "low" ]]; then
   echo $1
   sudo cpufreq-set -f $LOW
else
   sudo cpufreq-set -f $HIGH
fi

echo new freq: `sudo cpufreq-info -w`
