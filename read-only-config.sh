#!/bin/sh
# Remove sd card writes by linking to tmpfs files.
# Logic for fake-hwclock updates.
#
# sudo cp ~/bin/shellscripts/read-only-config.sh /etc/systemd/system
# sudo cp ~/bin/shellscripts/read-only-config.service /etc/systemd/system
# sudo cp ~/bin/shellscripts/read-only-config_stop.service /etc/systemd/system
# systemctl enable read-only-config.service read-only-config_stop.service

CLOCK_SAVE=/var/tmp/WRITE_CLK

startup() {
  rm -f $CLOCK_SAVE

  touch /tmp/plymouth-boot-duration
  if [ ! -L /var/lib/plymouth/boot-duration ]; then
    ln -sf /tmp/plymouth-boot-duration /var/lib/plymouth/boot-duration
  fi

  #The existence of a link for random-seed and clock is enough to disable writes.
  if [ ! -L /var/lib/systemd/random-seed ]; then
    ln -sf /tmp/random-seed /var/lib/systemd/random-seed
  fi

  if [ ! -L /var/lib/systemd/clock ]; then
    ln -sf /tmp/clock /var/lib/systemd/clock
    chown systemd-timesync:systemd-timesync /var/lib/systemd/clock
  fi

  touch /tmp/dhcpdcd-eth0.lease
  if [ ! -L /var/lib/dhcpcd5/dhcpcd-eth0.lease ]; then
    ln -sf /tmp/dhcpdcd-eth0.lease /var/lib/dhcpcd5/dhcpcd-eth0.lease
  fi

  touch /tmp/resolv.conf
  if [ ! -L /etc/resolv.conf ]; then
    ln -sf /tmp/resolv.conf /etc/resolv.conf
  fi

  #touch /tmp/fake-hwclock.data
  #if [ ! -L /etc/fake-hwclock.data ]; then
  #  ln -sf /tmp/fake-hwclock.data /etc/fake-hwclock.data
  #fi
}

shutdown() {
  if [ -f $CLOCKSAVE ]; then
    mount -o remount,rw /
    fake-hwclock save
    mount -o remount,ro /
  fi
}

case "${1:-}" in
  stop|reload|restart|force-reload)
    shutdown ;;

  start)
    startup ;;

  *)
    echo "Usage: ${0:-} {start|stop|status|restart|reload|force-reload}" >&2
    exit 1
    ;;
esac
