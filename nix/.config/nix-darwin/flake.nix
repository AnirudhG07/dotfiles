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

    outputs = inputs @ {
        self,
        nix-darwin,
        nixpkgs,
        home-manager, 
        nix-homebrew, 
        homebrew-core, 
        homebrew-cask, 
        homebrew-bundle,
        ...}:
        let
        configuration = { pkgs, config, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
            # home-manager
            users.users.anirudhgupta = {
                name = "anirudhgupta";
                home = "/Users/anirudhgupta";
            };

            nixpkgs.config.allowUnfree = true;
            homebrew = {
                enable = true;
                brews = [
                    "mas"
                    "tag"
                    "poppler"
                    "herdr"
                ];
                casks = [
                ];
                masApps = {};
                onActivation.cleanup = "zap";
            };
            programs.zsh = {
                enable = true;
                # ~/.zshrc (zinit + `compinit -C`) already owns completion init;
                # these defaults were making /etc/zshrc run a second, unflagged
                # compinit + bashcompinit + prompt-suse setup on every shell start.
                enableCompletion = false;
                enableGlobalCompInit = false;
                enableBashCompletion = false;
                promptInit = ""; # p10k replaces this
            };
        };
    in {
        # Build darwin flake using:
        # $ darwin-rebuild build --flake .#simple
        darwinConfigurations."Anirudhs-MacBook-Air" = nix-darwin.lib.darwinSystem {
            inherit inputs;
            system = "aarch64-darwin";
            modules = [
                ./modules
                configuration
                    nix-homebrew.darwinModules.nix-homebrew
                    {
                        nix-homebrew = {
                            enable = true;
                            enableRosetta = true;
                            user = "anirudhgupta";
                            autoMigrate = true;
                        };
                    }
                home-manager.darwinModules.home-manager {
                    home-manager = {
                        useGlobalPkgs = true;
                        users.anirudhgupta = {
                            programs.zsh = {
                                enable = true;
                            };
                            imports = [ ./home-manager/home.nix ];
                            home.stateVersion = "25.05";
                        };
                    };
                }
            ];
        };

        darwinPackages = self.darwinConfigurations."Anirudhs-MacBook-Air".pkgs;

        homeConfigurations.anirudhgupta = home-manager.lib.homeManagerConfiguration {
            pkgs = nixpkgs.legacyPackages."aarch64-darwin";
            modules = [ ./home-manager/home.nix ];
        };
    };
}

## Reference repos for nix configs:
# - https://github.com/amsynist/zero-darwin
# - https://github.com/uncenter/flake
