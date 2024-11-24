# dotfiles

These are my dotfiles which i use in my MacOS.
I use the above configurations everyday and i just love the configurations that I have made for myself.

## Steps to download the dotfiles

The most important component is homebrew. After installing homebrew, I have configured these dotfiles to just `git clone` the repo and use GNU `stow` to directly set everything up.

## Important Tools to downloads

- Nix
- Homebrew
- Zsh + Oh-my-zsh
- Yazi
- Lazygit
- Neovim
- Tmux
- Aerospace
- starship(for yazi)
- powerlevel10k(p10k)

## Other tools you can download

- Taskwarrior
- Cheatshh
- sketchybar + borders
- Yabai + skhd

## Setup

To download this configuration, you can do it manually by copy pasting or simply run -

```bash
cd
git clone https://github.com/AnirudhG07/dotfiles
cd dotfiles
```

### With stow

While using stow, you can run -

```bash
stow zsh p10k yazi nvim tmux starship nvim aerospace # .etc
```

Then simply do the following to install all the plugins:

- open nvim with `nvim .` or `v .` and everything will automatically happen
- open Tmux and press `Cmd A + Shift I`, to downloads plugins for tmux

To start sketchybar, borders, yabai, skhd for Window tiling manager and making my Mac look Sexy, simply run respective startup commands with appropriate permissions from settings and we are done!

### With Nix

If you are using Nix, you can simply run `nix-shell` and everything will be setup for you locally. For Global configurations -

- Make sure you have nix setup.
- Run `nix-env -iA nixpkgs.stow` to install stow.
- Have Nix Darwin present.
- Then run `darwin-rebuild switch --flake .` to setup everything.
- For home-manager, follow some guidelines [here](https://nix-community.github.io/home-manager/index.xhtml#sec-install-standalone)

## Terminal Emulator

I might be changing terminal emulators here and there, so I have some of the configurations for shitty things in the "master" branch. The most important thing there is the `iTERM colorschemes` which you use (mainly 2).

To try kitty and wezterm, you can also go to `ugcl` branch to configure them, my machine was Ubuntu 22.04.

## Branches details

- `stow` is the master branch containing my MacOS configurations
- `ugcl` is the branch with all my settings in IISc UGCL Ubuntu 22.04 (cant install everything due to restricted access)
- `master` is branch full of shit and some configs which you may need or never need.
