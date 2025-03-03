{
  description = "ripper";

  inputs = {
    # 1.23.2 release
    go-nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    go-nixpkgs,
    flake-utils,
  }: let
    nixosModule = {
      config,
      lib,
      pkgs,
      ...
    }: {
      options.services.ripper = {
        enable = lib.mkEnableOption "ripper";
        command = lib.mkOption {
          type = lib.types.str;
          default = "''whipper cd rip --offset 6 --cover-art complete --working-directory /mnt/process''";
          description = "Command to execute on CD insert";
        };
        user = lib.mkOption {
          type = lib.types.str;
          default = "ripper";
          description = "The user under which ripper runs.";
        };

        group = lib.mkOption {
          type = lib.types.str;
          default = "ripper";
          description = "The group under which ripper runs.";
        };
      };

      config = lib.mkIf config.services.ripper.enable {
        users.users = lib.optionalAttrs (config.services.ripper.user == "ripper") {
          ripper = {
            home = "/var/lib/ripper";
            createHome = true;
            uid = config.ids.uids.ripper;
            group = config.services.ripper.group;
          };
        };

        users.groups = lib.optionalAttrs (config.services.ripper.group == "ripper") {
          ripper = {
            gid = config.ids.gids.ripper;
          };
        };

        systemd.services.ripper = {
          description = "ripper";
          wantedBy = ["network.target"];
          path = [pkgs.whipper];
          serviceConfig = {
            ExecStart = "${self.packages.${pkgs.system}.default}/bin/ripper ${config.services.ripper.command}";
            Restart = "always";
            Type = "simple";
            User = config.services.ripper.user;
            Group = config.services.ripper.group;
            UMask = "0027";
          };
        };
      };
    };
  in
    (flake-utils.lib.eachDefaultSystem (system: let
      gopkg = go-nixpkgs.legacyPackages.${system};
    in {
      packages.default = gopkg.buildGoModule {
        pname = "ripper";
        version = "0.2.0";
        src = ./.;
        vendorHash = null;
      };

      apps.default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/ripper";
      };

      devShell = gopkg.mkShell {
        buildInputs = with gopkg; [go];
      };
    }))
    // {
      nixosModules.default = nixosModule;
    };
}
