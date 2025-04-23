{
  arch,
  dbxRelease, 
  ...
}:

{
  virtualbox.memorySize = 4096;
  virtualbox.vmDerivationName = "dogebox";
  virtualbox.vmName = "Dogebox";
  virtualbox.vmFileName = "dogebox-${dbxRelease}-${arch}.ova";
  virtualisation.virtualbox.guest.enable = true;
}
