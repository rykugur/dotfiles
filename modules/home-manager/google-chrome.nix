{ pkgs, ... }: {
  home.packages = with pkgs; [
    google-chrome
  ];

  xdg = {
    enable = true;

    mimeApps = {
      enable = true;

      defaultApplications = {
        "x-scheme-handler/http" = [ "google-chrome.desktop" ];
        "x-scheme-handler/https" = [ "google-chrome.desktop" ];
      };
    };
  };
}
