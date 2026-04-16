{ host, ... }:

{
  users.users.${host.username} = {
    name = host.username;
    home = host.homeDir;
  };
}
