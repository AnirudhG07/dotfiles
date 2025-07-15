{pkgs, ...}: {
  environment = {
    shells = with pkgs; [bash zsh];
    systemPackages = with pkgs; [
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
