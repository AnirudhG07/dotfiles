{...}: {
    system = {
        keyboard.enableKeyMapping = true;
        # keyboard.remapCapsLockToEscape = true;

        defaults = {
            loginwindow.LoginwindowText = "Hare Krsna Anirudh! Let's get some work done!";
            dock = {
                autohide = true;
            };
        };

        # $ darwin-rebuild changelog
        stateVersion = 5;
        primaryUser = "anirudhgupta";
    };

    # Touch ID for sudo. nix owns /etc/pam.d/sudo_local; setup.sh's `fingerprint` module sees that and stays out.
    security.pam.services.sudo_local.touchIdAuth = true;
    # pam_reattach: without it Touch ID falls back to the password inside tmux / herdr terminals
    security.pam.services.sudo_local.reattach = true;
}
