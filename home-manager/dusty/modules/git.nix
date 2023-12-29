{ inputs
, lib
, config
, ...
}: {
  programs.git = {
    enable = true;
    userName = "Dusty";
    userEmail = "rollhax@gmail.com";
  };
}
