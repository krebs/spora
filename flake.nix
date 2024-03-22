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

      spora = { config, lib, ... }: {
        imports = [
          self.nixosModules.hosts
        ];
        services.mycelium = {
          enable = true;
          openFirewall = true;
          peers = let
            hostsWithoutSelf = lib.filterAttrs (name: _: name != config.networking.hostName) self.lib.hosts;
            hostsWithIps = lib.filterAttrs (name: host: lib.hasAttr "public_endpoints" host) hostsWithoutSelf;
          in
            lib.flatten (map (host: host.public_endpoints) (lib.attrValues hostsWithIps));
        };
      };

    };
  };
}
