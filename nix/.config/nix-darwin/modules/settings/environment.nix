{pkgs, ...}: {
  environment = {
    shells = with pkgs; [bash zsh];
    systemPackages = with pkgs; [
        git
        neovim
        fzf
        stow
        gh
        lazygit
        tmux
        zoxide
        ripgrep
        fd
        bat
        eza
        # direnv
    ];
  };
}
