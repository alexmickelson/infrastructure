# Swaps the 3- and 4-finger touchpad swipes, which kwin compiles in and does
# not expose as configuration:
#   3-finger up/down   -> Overview / Grid View (was 4-finger)
#   4-finger up/down   -> vertical workspace switching (was 3-finger)
# Horizontal swipes are left to kwin (workspace switching on both 3 and 4
# fingers already). While an InputActions gesture is active the plugin blocks
# the built-in kwin gestures, so the swapped-away built-ins do not fire.
# Actions are discrete plasma_shortcut invocations — workspace switching jumps
# without kwin's realtime slide animation.
# Live-reload edits: `inputactions config reload`.
{
  ...
}:
{
  xdg.configFile."inputactions/config.yaml".text = ''
    # 45° tolerance so sloppy swipes don't get cancelled and leak kwin's
    # built-in gestures (see InputActions discussion #85); disables diagonals.
    # 0.9.0.0 null-derefs in TouchpadTriggerHandler::touchMotion on evdev-replayed
    # touch ids and segfaults the compositor; swipes come from kwin's libinput
    # events, so the evdev backend is not needed for them.
    device_rules:
      - conditions: $touchpad
        handle_evdev_events: false
        swipe:
          angle_tolerance: 45

    touchpad:
      gestures:
        - type: swipe
          fingers: 3
          direction: up
          actions:
            - on: begin
              plasma_shortcut: kwin,Overview

        # - type: swipe
        #   fingers: 3
        #   direction: down
        #   actions:
        #     - on: begin
        #       plasma_shortcut: kwin,Grid View

        - type: swipe
          fingers: 4
          direction: up
          actions:
            - on: end
              plasma_shortcut: kwin,Switch One Desktop Down

        - type: swipe
          fingers: 4
          direction: down
          actions:
            - on: end
              plasma_shortcut: kwin,Switch One Desktop Up
  '';
}
