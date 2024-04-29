{ ... }: {
  home.file = {
    ".drirc" = {
      text = ''
        <application name="Star Citizen" executable="StarCitizen.exe" >
          <option name="dual_color_blend_by_location" value="true" />
        </application>
      '';
    };
  };
}
