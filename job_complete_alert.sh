#!/bin/bash
#Beep when the processor usage drops to zero.

PID="$1"

# Check if a process name is provided as an argument
if [ -z "$PID" ]; then
  echo "Usage: job_complete_alert <pid>"
  exit 1
fi

# Monitor the CPU usage
while true; do
  # Get CPU usage
  CPU_USAGE=$(ps --cumulative -h -o pcpu -p $PID | tr -d '[:space:]')
  BC=$(ps -h -o pcpu --ppid $PID | tr '\n' '+' | tr -d '[:space:]' | sed 's/.$//')
  CPU_USAGE=$(echo ${BC:-0}"+"${CPU_USAGE:-0} | bc -l)
  # Check if the process is running
  if [ -z "$CPU_USAGE" ]; then
    echo pid $PID complete!
    beep
  elif [ $(echo $CPU_USAGE | wc -w) -gt 1 ]; then
    echo Too many processes? Did you enter the parent pid?
    break
  elif [[ 1 -eq $(echo "$CPU_USAGE==0" | bc -l) ]]; then
    # No cpu usage
    echo pid $PID %Usage = $CPU_USAGE
    beep
  else
    echo pid usage: $CPU_USAGE
  fi
  sleep 5
done
