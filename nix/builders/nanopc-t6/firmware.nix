{ pkgs, ... }:

let
  dogebox = import <dogebox> { inherit pkgs; };
in
{
  system.activationScripts.rk3588-firmware = ''
    for i in /etc/firmware /lib/firmware /system;
    do
      [ -L $i ] && echo "Removing old symlink $i" && rm $i
      [ -e $i ] && echo "Moving $i out of the way" && mv $i $i.`date -I`
    done
    echo "Adding new firmware symlinks"
    ln -sf ${dogebox.rk3588-firmware}/etc/firmware/ /etc/firmware
    ln -sf ${dogebox.rk3588-firmware}/lib/firmware/ /lib/firmware
    ln -sf ${dogebox.rk3588-firmware}/system/ /system
  '';
}
