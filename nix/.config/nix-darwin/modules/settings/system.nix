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

    security.pam.services.sudo_local.touchIdAuth = true;
}
