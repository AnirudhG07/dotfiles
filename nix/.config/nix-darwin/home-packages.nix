{ pkgs, ... }: {

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    # Desktop apps
    aerospace
    obsidian

    # CLI tools
    _7zz
    aria2
    btop
    chafa
    coreutils
    delta
    fabric-ai
    ffmpeg
    glow
    ncdu
    ouch
    rich-cli
    ruff
    rustup
    tldr
    ueberzugpp

    # languages
    go
    lua
    lean4
    ## Rust

  ];
}
