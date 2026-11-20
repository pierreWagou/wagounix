_:

{
  sops = {
    defaultSopsFile = ../secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      cloudflare-dns-token.mode = "0400";

      wagou-password-hash.neededForUsers = true;
      root-password-hash.neededForUsers = true;

      rbw-master-password = {
        mode = "0400";
        owner = "wagou";
      };
    };
  };
}
