{ host, ... }:

{
  homelab.home-assistant = {
    enable = true;
    domain = "home.${host.domain}";
  };
}
