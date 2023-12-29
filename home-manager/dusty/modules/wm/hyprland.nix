{ config, inputs, lib, ... }: {
  home.file.".config/hypr" = {

    source = ../../../../configs/hypr;
    force = true;
  };
}
