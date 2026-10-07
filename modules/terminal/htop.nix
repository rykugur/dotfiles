{ ... }:
{
  flake.modules.homeManager.htop =
    { ... }:
    {
      programs.htop = {
        enable = true;

        settings = {
          show_program_path = 0;
          highlight_base_name = 1;
          tree_view = 1;
          hide_kernel_threads = 1;
          hide_userland_threads = 1;
        };
      };
    };
}
