{ host, ... }:

{
  users.users.${host.username} = {
    home = host.homeDir;
  };
}
