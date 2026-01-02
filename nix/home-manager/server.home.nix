{ pkgs, ... }:
{
    home.packages = with pkgs; [
        vscode-fhs
        opencode
        quickemu
        tree
        kubernetes-helm
    ];
}