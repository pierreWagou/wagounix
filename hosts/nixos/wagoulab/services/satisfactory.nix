_:

{
  virtualisation.quadlet.containers.satisfactory = {
    containerConfig = {
      image = "wolveix/satisfactory-server:latest";
      noNewPrivileges = true;
      healthCmd = "none";
      networks = [ "host" ];
      volumes = [ "/var/lib/satisfactory:/config" ];
      environments = {
        MAXPLAYERS = "4";
        PUID = "1000";
        PGID = "1000";
        STEAMBETA = "false";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/satisfactory 0755 root root -"
  ];
}
