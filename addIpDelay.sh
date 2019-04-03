#FreeBSD ipfw pipe 10 config delay 100ms
tc -s qdisc

read -p "Add delay ms? n/[100]" DELAY

if [ "n" = "$DELAY" ]; then
  sudo tc qdisc del dev enp4s0 root netem
else
  if [ -z "$DELAY" ]; then
    DELAY=100
  fi
  sudo tc qdisc add dev enp4s0 root netem delay ${DELAY}ms
fi
tc -s qdisc
