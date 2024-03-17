{
  description = "spora network";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  {
    lib = {
      hosts = nixpkgs.lib.mapAttrs' (file: _:
        let
          name = nixpkgs.lib.removeSuffix ".json" file;
        in
          nixpkgs.lib.nameValuePair name ((nixpkgs.lib.importJSON ./hosts/${file}) // { inherit name; })
      ) (builtins.readDir ./hosts);
    };
    nixosModules = {

      hosts = {
        networking.extraHosts = nixpkgs.lib.concatMapStringsSep "\n" (host:
          "${host.address} ${host.name}.s"
        ) (nixpkgs.lib.attrValues self.lib.hosts);
      };

      mycelium = { config, lib, pkgs, ... }: let
        cfg = config.services.mycelium;
      in {
        options.services.mycelium = {
          enable = lib.mkEnableOption "mycelium network";
          peers = lib.mkOption {
            type = lib.types.listOf lib.types.str; # TODO ip-address type
            description = "List of peers to connect to";
          };
          keyFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = ''
              optional path to a keyFile, if unset the default location (/var/lib/mycelium/key) will be used
              If this key does not exist, it will be generated
            '';
          };
          openFirewall = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Open the firewall for mycelium";
          };
          package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.mycelium;
            description = "The mycelium package to use";
          };
        };
        config = lib.mkIf cfg.enable {
          networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall [ 9651 ];
          networking.firewall.allowedUDPPorts = lib.optionals cfg.openFirewall [ 9650 9651 ];

          systemd.services.mycelium = {
            description = "Mycelium network";
            wantedBy = [ "multi-user.target" ];
            restartTriggers = [
              cfg.keyFile
            ];

            serviceConfig = {
              ExecStart = lib.concatStringsSep " " (lib.flatten [
                (lib.getExe cfg.package)
                (lib.optionals (cfg.keyFile != null) "--key-file ${cfg.keyFile}")
                "--tun-name" "myc"
                "--peers" cfg.peers
                "--debug"
              ]);
              Restart = "always";
              RestartSec = 2;
              StateDirectory = "mycelium";

              # TODO: Hardening
            };
          };
        };
      };

      spora = { lib, ... }: {
        imports = [
          self.nixosModules.mycelium
          self.nixosModules.hosts
        ];
        services.mycelium = {
          enable = true;
          openFirewall = true;
          peers = let
            hostsWithIps = lib.filterAttrs (name: host: lib.hasAttr "public_endpoints" host) self.lib.hosts;
          in
            lib.flatten (map (host: host.public_endpoints) (lib.attrValues hostsWithIps));
        };
      };

    };
  };
}
