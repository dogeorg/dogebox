{ ... }:

{
  system.activationScripts.buildType = {
    text = ''
      echo "default" > /opt/build-type
    '';
  };
}
