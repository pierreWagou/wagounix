{
  config,
  pkgs,
  ...
}:

let
  # Custom pinentry script for rbw — reads the master password from a sops-decrypted file.
  # Speaks the Assuan pinentry protocol: responds to GETPIN with the password.
  # This enables zero-touch rbw unlock on the headless server.
  pinentry-rbw-sops = pkgs.writeShellScript "pinentry-rbw-sops" ''
    SECRET_FILE="${config.sops.secrets.rbw-master-password.path}"

    while IFS= read -r cmd; do
      case "$cmd" in
        GETPIN)
          if [ -f "$SECRET_FILE" ]; then
            password=$(cat "$SECRET_FILE")
            echo "D $password"
            echo "OK"
          else
            echo "ERR 83886179 No secret file found"
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
  # Make the pinentry script available at a stable path for the rbw config
  environment.etc."rbw/pinentry-sops".source = pinentry-rbw-sops;
}
