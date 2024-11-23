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
        configuration = { pkgs, config, ... }: {
        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget

            nixpkgs.config.allowUnfree = true;

            environment.systemPackages = with pkgs; [
                neovim
                tmux
                stow
                fzf
                zoxide
                ripgrep
                fd
                bat
                eza
                gh
                lazygit
            ];

            # home-manager
            users.users.anirudhgupta = {
                name = "anirudhgupta";
                home = "/Users/anirudhgupta";
                shell = pkgs.zsh;
            };

            home-manager.users.anirudhgupta = {pkgs, ...}: {
                home.packages = [];
                programs.zsh = {
                    enable = true;
                };


            home.stateVersion = "25.05";
            };

            homebrew = {
                enable = true;
                brews = [
                    "mas"
                    "tag"
                    "starship"
                ];
                casks = [
                ];
                masApps = {
                };
                onActivation.cleanup = "zap";
            };


            system.defaults = {
                dock.autohide = true;
                loginwindow.LoginwindowText = "Hare Krsna Anirudh! Let's get some work done!";

            };
            # Necessary for using flakes on this system.
            nix.settings.experimental-features = "nix-command flakes";
            # Set Git commit hash for darwin-version.
            system.configurationRevision = self.rev or self.dirtyRev or null;

            # $ darwin-rebuild changelog
            system.stateVersion = 5;

            # The platform the configuration will be used on.

            programs.zsh.enable = true;  # default shell on catalina
            nixpkgs.hostPlatform = "aarch64-darwin";
            security.pam.enableSudoTouchIdAuth = true;
        };
    in
    {
        # Build darwin flake using:
        # $ darwin-rebuild build --flake .#simple

        darwinConfigurations."Anirudhs-MacBook-Air" = nix-darwin.lib.darwinSystem {
            system = "aarch64-darwin";
            modules = [
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
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.users.anirudhgupta = {
                        imports = [ ./home.nix ];
                    };
                }
            ];
        };

        darwinPackages = self.darwinConfigurations."Anirudhs-MacBook-Air".pkgs;
    };
}
