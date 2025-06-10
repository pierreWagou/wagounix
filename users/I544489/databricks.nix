{ ... }: {

  home.file.".databrickscfg".text = ''
    [test]
    host  = https://adb-2486274436240795.15.azuredatabricks.net
    # token = ${{secrets.token}}
    cluster_id = 1030-140138-ftzepock
  ''
}