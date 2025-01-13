{ pkgs, ... }: {

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    # Core Utils
    tmux
    fzf
    zoxide
    ripgrep
    fd
    bat
    eza
    imagemagick
    direnv

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
    tldr # Too Long; Didn't Read
    ueberzugpp # image previewer
    television # Better fzf
    krabby # Pokemons

    # languages
    ## Python
    python313
    uv # package manager
    ruff # python linter

    go
    lua
    ## Lean4
    elan
    ## Rust
    rustup # rust toolchain manager
    ];
}
