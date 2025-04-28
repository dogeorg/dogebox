{
  arch,
  dbxRelease,
  ...
}:

{
  isoImage.isoName = "dogebox-${dbxRelease}-${arch}.iso";
  isoImage.prependToMenuLabel = "DogeboxOS (";
  isoImage.appendToMenuLabel = ")";
}
