{ host, ... }:

{
  homelab.opencloud = {
    enable = true;
    domain = "cloud.${host.domain}";
  };
}
