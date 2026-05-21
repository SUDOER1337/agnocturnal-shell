{
  config,
  lib,
  ...
}:
let
  cfg = config.services.agnoctural-shell;
in
{
  options.services.agnoctural-shell = {
    enable = lib.mkEnableOption "Noctalia shell systemd service";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The agnoctural-shell package to use";
    };

    target = lib.mkOption {
      type = lib.types.str;
      default = "graphical-session.target";
      example = "hyprland-session.target";
      description = "The systemd target for the agnoctural-shell service.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [
      ''
        Running agnoctural-shell as a systemd service has been deprecated!
        See https://github.com/SUDOER1337/agnocturnal-shell/getting-started/nixos/#running-the-shell for details.
      ''
    ];
    systemd.user.services.agnoctural-shell = {
      description = "Noctalia Shell - Wayland desktop shell";
      documentation = [ "https://github.com/SUDOER1337/agnocturnal-shell" ];
      after = [ cfg.target ];
      partOf = [ cfg.target ];
      wantedBy = [ cfg.target ];
      restartTriggers = [ cfg.package ];

      environment = {
        PATH = lib.mkForce null;
      };

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
      };
    };

    environment.systemPackages = [ cfg.package ];
  };
}
