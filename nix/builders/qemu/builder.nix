{
  arch,
  dbxRelease,
  ...
}:

{
  virtualisation.diskSize = 8192;
  system.build.qcow2 = {
    imageName = "dogebox-${dbxRelease}-${arch}.qcow2";
  };
}
