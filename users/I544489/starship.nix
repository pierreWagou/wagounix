{pkgs, ...}: {

  programs.starship = {
    enable = true;
    # enableZshIntegration = true;
    # settings = {
#       format = "[](yellow)$os$username[](yellow bg:peach)$directory[](peach bg:red)$git_branch$git_status[](red)$fill$status$python[](pink bg:mauve)$time[](mauve)
# $character";
#       character.format = ''
#         [❯ ](bold mauve)
#       '';
#       os = {
#         style = "bg:yellow";
#         format = "[🦖]($style)";
#         disabled = false;
#       };
#       directory = {
#         style = "bg:peach crust";
#         before_repo_root_style	= "bg:peach crust";
#         repo_root_style = "bg:peach bold crust";
#         read_only_style = "bg:peach crust";
#         format = "[ $path]($style)";
#         repo_root_format = "[$before_root_path]($before_repo_root_style)[$repo_root]($repo_root_style)[$path]($style)";
#         truncation_length = 3;
#         truncation_symbol = "…/";
#         substitutions = {
#           "Documents" = " 󰈙 ";
#           "Downloads" = "  ";
#           "Music" = "  ";
#           "Pictures" = "  ";
#           "Repositories/sap" = "  ";
#           "Repositories/wagou" = "  ";
#           "Videos" = "  ";
#         };
#       };
#       git_branch = {
#         symbol = "";
#         style = "bg:red bold crust";
#         format = "[ $symbol $branch]($style)";
#       };
#       git_status = {
#         style = "bg:red bold crust";
#         format = "[ $all_status$ahead_behind]($style)";
#       };
#       status = {
#         symbol = "💩";
#         success_symbol = "👌";
#         format = "[$symbol]($style) ";
#         disabled = false;
#       };
#       python = {
#         style = "bg:pink bold crust";
#         format = "[  $virtualenv]($style)";
#       };
#       time = {
#         disabled = false;
#         time_format = "%R";
#         style = "bg:mauve bold crust";
#         format = "[  $time]($style)";
#       };
    # };
  };

}

