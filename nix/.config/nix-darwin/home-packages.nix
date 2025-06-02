{ pkgs, ... }: {

  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    ## CORE Utilities
    neovim
    tmux
    zoxide
    ripgrep
    fd
    bat
    eza
    imagemagick
    direnv

    # Desktop apps
    aerospace
    obsidian

    # CLI tools
    _7zz 
    aria2 # wget replacement
    btop # Better top
    chafa # For terminal image preview
    coreutils # GNU core utilities
    delta # Git diff viewer
    fabric-ai # terminal AI utility
    ffmpeg # image/video processing
    glow # markdown viewer
    ncdu # disk usage analyzer
    ouch # archive manager
    rich-cli # rich previewing
    rustup # rust toolchain manager
    tldr # Too Long; Didn't Read
    ueberzugpp # image previewer
    television # Better fzf
    krabby # Pokemons
    lazydocker # Docker from CLI

    # languages
    ## Python
    python313
    python313Packages.pip
    uv # package manager
    ruff # python linter

    ## Rust
    rustup

    go
    lua
    ## Lean4
    elan
    ## Rust

  ];
}
