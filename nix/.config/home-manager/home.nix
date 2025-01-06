# home.nix
# home-manager switch 

{ config, pkgs, ... }:

{
    imports = [
        ./home-packages.nix
    ];

    home.username = "anirudhgupta";
    home.homeDirectory = "/home/anirudhgupta";
    home.stateVersion = "25.05"; # Please read the comment before changing.

        # Makes sense for user specific applications that shouldn't be available system-wide
    home.packages = with pkgs; [
        zsh
        git
        neovim
        yazi
        tmux
        bat
        gh
        fzf
        ripgrep
        fd
        # Add more packages as needed
    ];

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    home.file = {
    #".zshrc".source = /dotfiles/zsh/.zshrc;
    #".config/yazi".source = ../../../yazi/.config/yazi;
    #".p10k.zsh".source = ../../../p10k.zsh/.p10k.zsh;
    #".config/starship.toml".source = ../../../starship/.config/starship.toml;
    #".config/borders".source = ../../../borders/.config/borders;
    #".config/nvim".source = ../../../nvim/.config/nvim;
    #".config/nix".source = ../../../nix/.config/nix;
    #".config/nix-darwin".source = ../../../nix/.config/nix-darwin;
    #".config/aerospace".source = ../../../aerospace/.config/aerospace;
    #".tmux.conf".source = ../../../tmux/.tmux.conf;
    #".config/aerospace".source = ../../../aerospace/.config/aerospace;
    # ".config/yabai".source = "../../../yabai;
    # ".config/ghostty".source = "../../../ghostty;
    # ".config/sketchybar".source = "../../../sketchybar;
    # ".config/skhd".source = "../../../skhd;
    };

    home.sessionVariables = {
    };

    home.sessionPath = [
        "/run/current-system/sw/bin"
            "$HOME/.nix-profile/bin"
    ];
    programs.home-manager.enable = true;

    programs = {
        direnv = {
            enable = true;
                nix-direnv.enable = true;
        };

    };
}
