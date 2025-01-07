{ pkgs, ... }: {

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
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
    go
    lua
    ncdu
    ouch
    rich-cli
    ruff
    rustup
    tldr
    television
  ];
}
