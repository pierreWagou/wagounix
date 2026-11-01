_:

{
  sops = {
    defaultSopsFile = ../secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      # Shared Cloudflare DNS token (Traefik ACME + Stalwart ACME).
      cloudflare-dns-token.mode = "0400";

      # Host-level secrets
      wagou-password-hash.neededForUsers = true;
      root-password-hash.neededForUsers = true;

      # rbw master password — used by custom pinentry for zero-touch vault unlock
      rbw-master-password = {
        mode = "0400";
        owner = "wagou";
      };
    };
  };
}
