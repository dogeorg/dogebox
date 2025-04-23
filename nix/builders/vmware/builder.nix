{ dbxRelease, arch, ... }:

{
  vmware.memorySize = 4096;
  vmware.vmDerivationName = "dogebox";
  vmware.vmName = "Dogebox";
  vmware.vmFileName = "dogebox-${dbxRelease}-${arch}.vmdk";
}
