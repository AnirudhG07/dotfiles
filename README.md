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
- powerlevel10k(p10k)

## Other tools you can download

- Taskwarrior
- Cheatshh
- sketchybar + borders
- Yabai + skhd

## Setup

One command, on a fresh macOS or Linux box (with or without sudo). It clones this repo to `~/dotfiles`
and asks what to set up — see it at <https://anirudhg07.github.io/dotfiles/>:

```bash
curl -fsSL https://anirudhg07.github.io/dotfiles/setup.sh -o setup.sh
bash setup.sh              # interactive;  --all | --only core,nvim,shell | --dry-run
```

Or by hand:

```bash
cd
git clone https://github.com/AnirudhG07/dotfiles
cd dotfiles
```

### With stow

While using stow, you can run -

```bash
stow zsh p10k yazi nvim tmux nvim aerospace # .etc
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

I might be changing terminal emulators here and there; older configs (the `iTERM colorschemes` I mainly use, kitty, wezterm) live in the `archive/master` tag.

To try kitty and wezterm on Linux, see the `archive/ugcl` tag (that machine was Ubuntu 22.04).

## Branches

- `main` is the only branch: macOS (zsh) and Linux configs, including `bash/` for Linux machines without
  sudo — `setup.sh` picks zsh on macOS and on Linux with sudo, bash + oh-my-bash otherwise.
- The old `ugcl` (IISc UGCL Ubuntu, bash) and `master` (older experiments: iTerm2 colorschemes, kitty,
  wezterm, …) branches are kept as the tags `archive/ugcl` and `archive/master`.
