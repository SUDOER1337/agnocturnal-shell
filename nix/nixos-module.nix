{ lib, pkgs, ... }:

{
  options.services.agnoctural-shell = {
    enable = lib.mkEnableOption "agnoctural-shell";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The agnoctural-shell package to use";
    };
  };

  config = lib.mkIf config.services.agnoctural-shell.enable {
    environment.systemPackages = [ config.services.agnoctural-shell.package ];
  };
}
