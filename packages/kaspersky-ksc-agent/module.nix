{ defaultPackage }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.kasperskyKscAgent;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  registration = {
    inherit (cfg)
      server
      port
      sslPort
      useSsl
      groupName
      gatewayMode
      gatewayAddress
      ;
  };
  registrationHash = builtins.hashString "sha256" (builtins.toJSON registration);
  registrationStamp = pkgs.writeText "kaspersky-ksc-agent-registration" registrationHash;

  optionalArg = condition: argument: lib.optionals condition [ argument ];
  registrationArgs = [
    "-regserver"
    "-pkgver"
    "16.3.0.1207"
    "-server"
    cfg.server
    "-port"
    (toString cfg.port)
    "-sslport"
    (toString cfg.sslPort)
    "-usessl"
    (if cfg.useSsl then "1" else "0")
    "-gwmode"
    (toString cfg.gatewayMode)
    "-eula_accepted"
    "1"
    "-tl"
    "4"
    "-tf"
    "/var/log/kaspersky/klnagent64/registration.log"
  ]
  ++ optionalArg (cfg.groupName != null) "-groupname"
  ++ optionalArg (cfg.groupName != null) cfg.groupName
  ++ optionalArg (cfg.gatewayAddress != null) "-gwaddress"
  ++ optionalArg (cfg.gatewayAddress != null) cfg.gatewayAddress;

  registerAgent = pkgs.writeShellScript "kaspersky-ksc-agent-register" ''
    set -eu
    stamp=/var/opt/kaspersky/klnagent/1103/.nixos-registration

    if cmp -s ${registrationStamp} "$stamp"; then
      exit 0
    fi

    set +e
    ${cfg.package}/opt/kaspersky/klnagent64/sbin/klnagent ${lib.escapeShellArgs registrationArgs}
    rc=$?
    set -e

    # The vendor installer treats 0, 1 and 2 as successful registration.
    if [ "$rc" -gt 2 ]; then
      echo "Kaspersky Network Agent registration failed with exit code $rc" >&2
      exit "$rc"
    fi

    install -m 0600 ${registrationStamp} "$stamp"
  '';
in
{
  options.services.kasperskyKscAgent = {
    enable = mkEnableOption "Kaspersky Security Center Network Agent";

    package = mkOption {
      type = types.package;
      default = defaultPackage;
      defaultText = lib.literalExpression "the package exposing this module";
      description = "Kaspersky Network Agent package to use.";
    };

    server = mkOption {
      type = types.str;
      example = "ksc.example.org";
      description = "DNS name or IP address of the Kaspersky Administration Server.";
    };

    port = mkOption {
      type = types.port;
      default = 14000;
      description = "Non-TLS Administration Server port.";
    };

    sslPort = mkOption {
      type = types.port;
      default = 13000;
      description = "TLS Administration Server port.";
    };

    useSsl = mkOption {
      type = types.bool;
      default = true;
      description = "Use TLS when connecting to the Administration Server.";
    };

    groupName = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "NixOS workstations";
      description = "Administration group in which to place this device.";
    };

    gatewayMode = mkOption {
      type = types.ints.between 0 2;
      default = 1;
      description = "Connection gateway mode accepted by the vendor agent (0, 1 or 2).";
    };

    gatewayAddress = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "gateway.example.org";
      description = "Connection gateway address, when one is used.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.gatewayMode == 1 || cfg.gatewayAddress != null;
        message = "services.kasperskyKscAgent.gatewayAddress must be set for the selected gateway mode";
      }
    ];

    environment.systemPackages = [ cfg.package ];

    systemd.tmpfiles.rules = [
      "d /opt/kaspersky 0755 root root -"
      "L+ /opt/kaspersky/klnagent64 - - - - ${cfg.package}/opt/kaspersky/klnagent64"
      "d /etc/opt/kaspersky/klnagent 0755 root root -"
      "d /var/opt/kaspersky 0755 root root -"
      "d /var/opt/kaspersky/tmp 0755 root root -"
      "d /var/opt/kaspersky/klnagent 0755 root root -"
      "d /var/opt/kaspersky/klnagent/1103 0750 root root -"
      "d /var/log/kaspersky 0755 root root -"
      "d /var/log/kaspersky/klnagent64 0750 root root -"
    ];

    systemd.services.kaspersky-ksc-agent = {
      description = "Kaspersky Security Center Network Agent";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [
        "network-online.target"
        "systemd-tmpfiles-setup.service"
      ];

      path = with pkgs; [
        coreutils
        findutils
        gnugrep
        gnused
        iproute2
        lshw
        procps
        util-linux
      ];

      environment = {
        UV_USE_IO_URING = "0";
        SSS_LOCKFREE = "NO";
        SASL_PATH = "/opt/kaspersky/klnagent64/lib/sasl2-plugins";
        KLCS_CUSTOM_JEARENAS_DISABLE = "1";
        MALLOC_CONF = "tcache:false";
        KLCSAK_TEMP_PATH = "/var/opt/kaspersky/tmp";
      };

      serviceConfig = {
        Type = "simple";
        ExecStartPre = registerAgent;
        # Apply the vendor allocator only to the agent itself.  Putting
        # LD_PRELOAD in the unit environment would also inject it into the
        # registration shell and all of its helper programs.
        ExecStart = "${pkgs.coreutils}/bin/env LD_PRELOAD=/opt/kaspersky/klnagent64/lib/libjemalloc.so.2 ${cfg.package}/opt/kaspersky/klnagent64/sbin/klnagent -d -from_wd";
        WorkingDirectory = "/opt/kaspersky/klnagent64/sbin";
        Restart = "on-failure";
        RestartSec = 5;
        TimeoutStopSec = 30;
        KillMode = "process";
        LimitNOFILE = "32768:131072";
      };
    };
  };
}
