{ pkgs, lib, config, ... }:

let
  cfg = config.customFish;
in {
  options.customFish = {
    # Opt-in: only enable if the relevant tools are installed on this machine

    bluetuiAliases = lib.mkEnableOption "bluetui/jellyfin-tui shell aliases";

    dotnetPackage = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Enable dotnet env vars and PATH entries. Set to the desired SDK package (e.g. pkgs.dotnetCorePackages.sdk_8_0).";
    };

    bitwardenSshAgent = lib.mkEnableOption "Bitwarden SSH agent (sets SSH_AUTH_SOCK)";
  };

  config = {
    programs.fish = {
      enable = true;
      shellInit = lib.concatStringsSep "\n" (lib.filter (s: s != "") [

        # https://gist.github.com/thomd/7667642
        ''
          export LS_COLORS=':di=95'

          function commit
            git add --all
            git commit -m "$argv"
            for remote in (git remote)
              git pull $remote
              git push $remote
            end
          end

          # have ctrl+backspace delete previous word
          bind \e\[3\;5~ kill-word
          # have ctrl+delete delete following word
          bind \b  backward-kill-word
          set -U fish_user_paths ~/.local/bin ~/bin ~/.dotnet ~/.dotnet/tools $fish_user_paths
          set fish_pager_color_selected_background --background='00399c'

          export VISUAL=vim
          export EDITOR="$VISUAL"

          set -x LIBVIRT_DEFAULT_URI qemu:///system
          set -x TERM xterm-256color

          if test -f "$HOME/.cargo/env.fish"
            source "$HOME/.cargo/env.fish"
          end
        ''

        (lib.optionalString cfg.bluetuiAliases ''
          alias blue="bluetui"
          alias jelly="jellyfin-tui"
        '')


        (lib.optionalString (cfg.dotnetPackage != null) ''
          export DOTNET_WATCH_RESTART_ON_RUDE_EDIT=1
          export DOTNET_CLI_TELEMETRY_OPTOUT=1
          export DOTNET_ROOT=${cfg.dotnetPackage}
        '')

        (lib.optionalString cfg.bitwardenSshAgent ''
          export SSH_AUTH_SOCK=$HOME/.bitwarden-ssh-agent.sock
        '')

      ]);
    };
  };
}
