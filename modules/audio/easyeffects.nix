{ ... }:
{
  flake.modules.homeManager.easyeffects =
    { pkgs, ... }:
    let
      rnnoise-marathon = pkgs.fetchurl {
        url = "https://github.com/GregorR/rnnoise-models/raw/master/marathon-prescription-2018-08-29/mp.rnnn";
        sha256 = "sha256-ToSkSKS6+TeZKq9NEMglgAfsXSQhm2ZH39X7S1Y60jE=";
      };
    in
    {
      services.easyeffects.enable = true;
      home.file.".local/share/easyeffects/input/rnnoise.json".text = builtins.toJSON {
        input = {
          blocklist = [ ];
          plugins_order = [ "rnnoise#0" ];
          "rnnoise#0" = {
            bypass = false;
            enable-vad = true;
            input-gain = 0.0;
            model-path = "${rnnoise-marathon}";
            output-gain = 0.0;
            release = 20.0;
            vad-thres = 90.0;
            wet = 0.0;
          };
        };
      };
    };
}
