{ host, ... }:

{
  homelab.vaultwarden = {
    enable = true;
    domain = "vault.${host.domain}";
  };
}
