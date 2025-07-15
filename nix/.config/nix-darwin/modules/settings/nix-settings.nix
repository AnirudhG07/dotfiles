{username, ...}: {
  # Common Nix settings
  nix.settings = {
    extra-sandbox-paths = ["/tmp"]; # Extra paths to bind-mount in the sandbox
    keep-build-log = true; # Keep logs of builds
    trusted-users = ["anirudhgupta"]; # Users that have additional permissions
    experimental-features = "nix-command flakes";
  };

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
  # nix.extraOptions = ''
  #   experimental-features = nix-command flakes
  #   http-connections = 128
  #   max-substitution-jobs = 128
  # '';
  nix.optimise.automatic = true;
}
