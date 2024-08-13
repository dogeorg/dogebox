#!/run/current-system/sw/bin/bash

# For package 'dogebox-initial-setup' ?
# use ${pkg.xx} paths if so
# TODO : have this process be reversable when setup is done
#          - stopping dnsmasq
#          - stopping ifplugd
#          - dhcpcd should be started by new network config
#            if it was selected

SYSTEMCTL=/run/current-system/sw/bin/systemctl
IFCONFIG=/run/current-system/sw/bin/ifconfig
DNSMASQ=/run/current-system/sw/bin/dnsmasq
IFPLUGD=/run/current-system/sw/bin/ifplugd
PKILL=/run/current-system/sw/bin/pkill

echo "Stopping dnsmasq . . ."
$PKILL dnsmasq
echo "Stopping ifplugd . . ."
$IFPLUGD -k
