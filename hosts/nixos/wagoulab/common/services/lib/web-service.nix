{ config, host }:

let
  qNetworks = config.virtualisation.quadlet.networks;
in
{
  mkWebService =
    {
      name,
      image,
      subdomain ? null,
      port ? null,
      exposeViaTraefik ? true,
      networks ? null,
      extraNetworks ? [ ],
      env ? { },
      volumes ? [ ],
      environmentFiles ? [ ],
      publishPorts ? [ ],
      devices ? [ ],
      addGroups ? [ ],
      addCapabilities ? [ ],
      dns ? [ ],
      addHosts ? [ ],
      exec ? null,
      shmSize ? null,
      healthCmd ? null,
      dataDirs ? [ ],
      dataDirsMode ? "0755 root root",
      extraLabels ? { },
      unitConfig ? { },
      serviceConfig ? { },
    }:
    let
      allNetworks = (if networks == null then [ qNetworks.proxy.ref ] else networks) ++ extraNetworks;
      traefikLabels =
        if exposeViaTraefik then
          (
            assert subdomain != null && port != null;
            {
              "traefik.enable" = "true";
              "traefik.http.routers.${name}.rule" = "Host(`${subdomain}.${host.domain}`)";
              "traefik.http.routers.${name}.entrypoints" = "websecure";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.middlewares" = "secure-headers@file";
              "traefik.http.services.${name}.loadbalancer.server.port" = toString port;
            }
          )
        else
          { };
    in
    {
      containerConfig = {
        inherit
          image
          volumes
          environmentFiles
          publishPorts
          devices
          addGroups
          addCapabilities
          dns
          addHosts
          ;
        environments = env;
        noNewPrivileges = true;
        networks = allNetworks;
        labels = traefikLabels // extraLabels;
      }
      // (if exec == null then { } else { inherit exec; })
      // (if shmSize == null then { } else { inherit shmSize; })
      // (if healthCmd == null then { } else { inherit healthCmd; });

      tmpfilesRules = map (dir: "d ${dir} ${dataDirsMode} -") dataDirs;

      inherit unitConfig serviceConfig;
    };

  mkPostgres =
    {
      name,
      image,
      db ? null,
      user ? null,
      passwordEnvFile ? null,
      dataDir ? "/var/lib/${name}",
      dataDirMode ? "0755 root root",
      networks,
      shmSize ? null,
      initdbArgs ? null,
      extraEnv ? { },
      extraTmpfilesRules ? [ ],
      unitConfig ? { },
      serviceConfig ? { },
    }:
    {
      containerConfig = {
        inherit image;
        noNewPrivileges = true;
        inherit networks;
        volumes = [ "${dataDir}:/var/lib/postgresql/data" ];
        environments =
          { }
          // (if db == null then { } else { POSTGRES_DB = db; })
          // (if user == null then { } else { POSTGRES_USER = user; })
          // (if initdbArgs == null then { } else { POSTGRES_INITDB_ARGS = initdbArgs; })
          // extraEnv;
        environmentFiles = if passwordEnvFile == null then [ ] else [ passwordEnvFile ];
      }
      // (if shmSize == null then { } else { inherit shmSize; });

      tmpfilesRules = [ "d ${dataDir} ${dataDirMode} -" ] ++ extraTmpfilesRules;

      inherit unitConfig serviceConfig;
    };

  mkValkey =
    {
      name,
      image ? host.valkeyImage,
      dataDir ? "/var/lib/${name}",
      dataDirMode ? "0755 root root",
      networks,
      persist ? true,
      extraEnv ? { },
      environmentFiles ? [ ],
      extraTmpfilesRules ? [ ],
      unitConfig ? { },
      serviceConfig ? { },
    }:
    {
      containerConfig = {
        inherit image environmentFiles;
        noNewPrivileges = true;
        inherit networks;
        volumes = if dataDir == null then [ ] else [ "${dataDir}:/data" ];
        environments = extraEnv;
      }
      // (
        if persist then
          {
            exec = [
              "--save"
              "60"
              "1"
              "--loglevel"
              "warning"
            ];
          }
        else
          { }
      );

      tmpfilesRules =
        (if dataDir == null then [ ] else [ "d ${dataDir} ${dataDirMode} -" ]) ++ extraTmpfilesRules;

      inherit unitConfig serviceConfig;
    };
}
