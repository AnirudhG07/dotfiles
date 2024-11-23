# home.nix
# home-manager switch 

{ config, pkgs, ... }:

{
  home.username = "anirudhgupta";
  home.homeDirectory = "/Users/anirudhgupta";
  home.stateVersion = "25.05"; # Please read the comment before changing.

# Makes sense for user specific applications that shouldn't be available system-wide
  home.packages = [
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".zshrc".source = "${config.home.homeDirectory}/dotfiles/zsh/.zshrc";
    #".config/yazi".source = "${config.home.homeDirectory}/dotfiles/yazi";
    #".p10k.zsh".source = "${config.home.homeDirectory}/dotfiles/p10k.zsh";
    #".config/starship".source = "${config.home.homeDirectory}/dotfiles/starship;
    #".config/borders".source = "${config.home.homeDirectory}/dotfiles/borders;
    #".config/nvim".source = "${config.home.homeDirectory}/dotfiles/nvim;
    #".config/nix".source = "${config.home.homeDirectory}/dotfiles/nix;
    #".config/nix-darwin".source = "${config.home.homeDirectory}/dotfiles/nix-darwin;"
    #".config/tmux".source = "${config.home.homeDirectory}/dotfiles/tmux;
    #".config/aerospace".source = "${config.home.homeDirectory}/dotfiles/aerospace;
    # ".config/yabai".source = "${config.home.homeDirectory}/dotfiles/yabai;
    # ".config/ghostty".source = "${config.home.homeDirectory}/dotfiles/ghostty;
    # ".config/sketchybar".source = "${config.home.homeDirectory}/dotfiles/sketchybar;
    # ".config/skhd".source = "${config.home.homeDirectory}/dotfiles/skhd;
  };

  home.sessionVariables = {
  };

  home.sessionPath = [
    "/run/current-system/sw/bin"
      "$HOME/.nix-profile/bin"
  ];
  programs.home-manager.enable = true;
  programs.zsh = {
    enable = true;
    initExtra = ''
      # Add any additional configurations here
      export PATH=/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH
      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi
    '';
  };
}
