rec {
  username = "deck";
  homeDir = "/home/${username}";
  # Cosmetic only (not consumed by home.nix) — Steam Deck uses
  # "steamdeck"; adjust if your device reports something else.
  hostname = "steamdeck";
}
