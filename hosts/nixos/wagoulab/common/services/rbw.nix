{
  config,
  pkgs,
  ...
}:

let
  pinentry-rbw-sops = pkgs.writeShellScript "pinentry-rbw-sops" ''
    set -euo pipefail
    SECRET_FILE="${config.sops.secrets.rbw-master-password.path}"

    while IFS= read -r cmd; do
      case "$cmd" in
        GETPIN)
          if [ -f "$SECRET_FILE" ]; then
            password=$(cat "$SECRET_FILE")
            echo "D $password"
            echo "OK"
          else
            echo "ERR 83886179 No secret file found" # Assuan error: no secret file found
          fi
          ;;
        BYE)
          echo "OK closing connection"
          exit 0
          ;;
        *)
          echo "OK"
          ;;
      esac
    done
  '';
in
{
  environment.etc."rbw/pinentry-sops".source = pinentry-rbw-sops;
}
