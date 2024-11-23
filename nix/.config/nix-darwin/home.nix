# home.nix
# home-manager switch 

{ config, pkgs, ... }:

{
  home.username = "anirudhgupta";
  #home.homeDirectory = ../../../;
  home.stateVersion = "25.05"; # Please read the comment before changing.

# Makes sense for user specific applications that shouldn't be available system-wide
  home.packages = [
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".zshrc".source = ../../../zsh/.zshrc;
    ".config/yazi".source = ../../../yazi/.config/yazi;
    ".p10k.zsh".source = ../../../p10k.zsh/.p10k.zsh;
    ".config/starship".source = ../../../starship/.config/starship.toml;
    ".config/borders".source = ../../../borders/.config/borders;
    ".config/nvim".source = ../../../nvim/.config/nvim;
    ".config/nix".source = ../../../nix/.config/nix;
    ".config/nix-darwin".source = ../../../nix/.config/nix-darwin;
    ".config/tmux".source = ../../../tmux/.tmux.conf;
    ".config/aerospace".source = ../../../aerospace/.config/aerospace;
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
