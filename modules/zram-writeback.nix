{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.services.zramWriteback;
  dev = config.zramSwap.writebackDevice;
  devName = builtins.baseNameOf dev;
in
{
  options = {
    services.zramWriteback = {
      enable = lib.mkOption {
        default = false;
        type = lib.types.bool;
        description = ''
          Enable automatic writing of huge_idle pages to the zram writeback device.
        '';
      };

      idleTimeSeconds = lib.mkOption {
        default = 120;
        type = lib.types.int;
        description = ''
          The minimum number of seconds a page that need to have passed since last using a page for it to be marked as idle.
        '';
      };

      markIdleFrequencyMinutes = lib.mkOption {
        default = 1;
        type = lib.types.int;
        description = ''
          The delay on the idle marking timer in minutes.
        '';
      };

      writebackFrequencyMinutes = lib.mkOption {
        default = 1;
        type = lib.types.int;
        description = ''
          The delay on the writeback trigger timer in minutes.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = dev != null;
        message = "Cannot enable zramWriteback service if no writeback device is configured. ${dev}";
      }
    ];

    systemd.services."zram-mark-idle" = {
      enable = true;
      description = "Mark pages in ${dev} as idle";
      before = ["zram-writeback-pages.service"];
      unitConfig = {
        ConditionPathExists = "/sys/block/${devName}/idle";
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''${pkgs.bash}/bin/bash -c "echo ${builtins.toString cfg.idleTimeSeconds} > /sys/block/${devName}/idle"'';
      };
      startAt = "*:0/${builtins.toString cfg.markIdleFrequencyMinutes}";
    };

    systemd.services."zram-writeback-pages" = {
      enable = true;
      description = "Trigger writeback on ${dev}";
      after = ["zram-mark-idle.service"];
      requires = ["zram-mark-idle.service"];
      unitConfig = {
        ConditionPathExists = "/sys/block/${devName}/writeback";
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''${pkgs.bash}/bin/bash -c "echo huge_idle > /sys/block/${devName}/writeback"'';
      };
      startAt = "*:0/${builtins.toString cfg.writebackFrequencyMinutes}";
    };
  };
}
