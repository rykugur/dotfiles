{ ... }:
{
  flake.modules.homeManager.moonlight =
    { lib, pkgs, ... }:
    let
      mapping = "0600b7925e040000000b000017050000,Xbox One Elite 2 Controller,a:b0,b:b1,x:b2,y:b3,back:b6,guide:b8,start:b7,leftstick:b9,rightstick:b10,leftshoulder:b4,rightshoulder:b5,dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,misc1:b15,paddle1:b12,paddle2:b11,paddle3:b14,paddle4:b13,leftx:a0,lefty:a1,rightx:a3,righty:a4,lefttrigger:a2,righttrigger:a5,platform:Linux,";
    in
    {
      home.packages = [
        (pkgs.symlinkJoin {
          name = "moonlight-qt";
          paths = [ pkgs.moonlight-qt ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/moonlight \
              --set SDL_GAMECONTROLLERCONFIG ${lib.escapeShellArg mapping}
          '';
        })
      ];
    };
}
