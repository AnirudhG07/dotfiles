{
    description = "Anirudh Gupta's Nix-darwin System Flake";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        nix-darwin.url = "github:LnL7/nix-darwin";
        nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

        homebrew-core = {
            url = "github:homebrew/homebrew-core";
            flake = false;
        };
        homebrew-cask = {
            url = "github:homebrew/homebrew-cask";
            flake = false;
        };
        homebrew-bundle = {
            url = "github:homebrew/homebrew-bundle";
            flake = false;
        };
    };

    outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, nix-homebrew, homebrew-core, homebrew-cask, homebrew-bundle, ...}:
        let
          system = "x86_64-linux";
          pkgs = nixpkgs.legacyPackages.${system};

        configuration = { pkgs, config, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget

            nixpkgs.config.allowUnfree = true;

            environment.systemPackages = with pkgs; [
                neovim
                stow
                gh
                lazygit
            ];

            # home-manager
            users.users.anirudhgupta = {
                name = "anirudhgupta";
                home = "/home/anirudhgupta";
                shell = pkgs.zsh;
            };

            homebrew = {
                enable = true;
                brews = [
                    "starship"
                ];
                casks = [
                ];
            };


            # Necessary for using flakes on this system.
            nix.settings.experimental-features = "nix-command flakes";
            # Set Git commit hash for darwin-version.
            system.configurationRevision = self.rev or self.dirtyRev or null;

            # $ darwin-rebuild changelog
            system.stateVersion = 5;

            # The platform the configuration will be used on.

            programs.zsh = {
                enable = true;
            };
        };
    in {
      homeConfigurations."anirudhgupta" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        # Specify your home configuration modules here, for example,
        # the path to your home.nix.
        modules = [ ./home.nix ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
      };
    };
}
