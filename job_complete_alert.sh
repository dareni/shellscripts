#!/bin/bash
#Beep when the processor usage drops below a given level.

PID="$1"
LEVEL="$2"

# Check if a process name is provided as an argument
if [ -z "$PID" ]; then
  echo "Usage: job_complete_alert <pid>"
  exit 1
fi

# Monitor the CPU usage
while true; do
  # Get CPU usage
  PID_LIST=$(pstree $PID -p | grep -o "([0-9]*)" | tr -d '()' | tr '\n' ' ')
  CPU_USAGE=$(ps -h -o pcpu -p $PID_LIST | tr '\n' '+' | tr -d '[:space:]' | sed 's/.$//')
  CPU_USAGE=$(echo $CPU_USAGE | bc -l)

  # Check if the process is running
  if [ -z "$CPU_USAGE" ]; then
    echo pid $PID complete!
    beep
  elif [ $(echo $CPU_USAGE | wc -w) -gt 1 ]; then
    echo Too many processes? Did you enter the parent pid?
    break
  elif [[ 1 -eq $(echo "$CPU_USAGE<=${LEVEL:-0}" | bc -l) ]]; then
    # No cpu usage
    echo pid $PID %Usage = $CPU_USAGE
    beep
  else
    echo pid usage: $CPU_USAGE
  fi
  sleep 5
done
