{ dbxRelease, arch, ... }:

{
  vm.imageName = "dogebox-${dbxRelease}-${arch}.vmdk";
}
