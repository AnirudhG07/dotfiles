{pkgs, ...}: {
  services.jankyborders = {
    enable = true;
    package = pkgs.jankyborders;
    width = 5.0;
    active_color = "gradient(top_left=0xff0000FF,bottom_right=0xff00FF00)";
    inactive_color = "gradient(top_right=0x9992B3F5,bottom_left=0x9992B3F5)";
    hidpi = true;
    ax_focus = true;
  };
}
