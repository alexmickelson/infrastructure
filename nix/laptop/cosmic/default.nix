{
  imports = [ ./system.nix ];

  home-manager.users.alex.imports = [
    ./home.nix
    ./gestures.nix
  ];
}
