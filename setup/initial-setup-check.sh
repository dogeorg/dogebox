#!/run/current-system/sw/bin/bash

# For package 'dogebox-initial-setup' ?
# use ${pkg.xx} paths if so

WIRED=enp0s3

SYSTEMCTL=/run/current-system/sw/bin/systemctl
IFCONFIG=/run/current-system/sw/bin/ifconfig
DNSMASQ=/run/current-system/sw/bin/dnsmasq
IFPLUGD=/run/current-system/sw/bin/ifplugd
PKILL=/run/current-system/sw/bin/pkill

if ls /media/*/RECOVERY.txt 2>&1 >/dev/null; then
  echo "RECOVERY.txt found, entering initial setup/recovery mode:"

  if $SYSTEMCTL is-active --quiet dhcpcd; then
    echo "Stopping dhcpcd . . ."
    $SYSTEMCTL stop dhcpcd
  fi

  echo "Reconfiguring enp0s3 . . ."
  $IFCONFIG $WIRED 10.0.0.69 netmask 255.255.0.0

  $PKILL dnsmasq
  echo "Starting dnsmasq . . ."
  $DNSMASQ --enable-dbus -C -i $WIRED /etc/nixos/setup/dnsmasq.conf

  $IFPLUGD -i $WIRED -r /etc/nixos/setup/interface-check.sh
else
  echo "No RECOVERY.txt, this is a normal boot."
fi
