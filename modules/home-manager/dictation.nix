{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.machshev.dictation;

  # whisper.cpp on the Intel iGPU via Vulkan. The Meteor Lake NPU isn't usable
  # here: it would need whisper.cpp built against OpenVINO, which nixpkgs
  # doesn't provide.
  voxtype = pkgs.voxtype-vulkan;

  modelName = "ggml-large-v3-turbo-q5_0.bin";
  model = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/${modelName}";
    sha256 = "1qm7zxamlvac564c3270wqqqks5wc7532q3fqi01zbfmkiq22hir";
  };

  settings = {
    state_file = "auto";

    # Recording is driven by compositor keybindings (`voxtype record toggle`)
    hotkey = {
      enabled = false;
      key = "SCROLLLOCK";
      modifiers = [];
    };

    audio = {
      device = "default";
      sample_rate = 16000;
      max_duration_secs = 300;
    };

    whisper = {
      model = "${config.xdg.dataHome}/voxtype/models/${modelName}";
      language = "en";
      translate = false;
      on_demand_loading = false;
      # Biases whisper towards the vocabulary and spelling we actually use
      initial_prompt = lib.concatStringsSep " " [
        "A Christadelphian Bible talk, in British English."
        "The ecclesia, the brethren and sisters, baptised into Christ."
        "Our Saviour's honour and favour; we realise and recognise God's judgement."
        "Yahweh, the Lord Jesus Christ, the Kingdom of God, the Abrahamic covenant."
        "Melchizedek, Nebuchadnezzar, Hezekiah, Zerubbabel, Jehoshaphat, Elisha,"
        "Ezekiel, Habakkuk, Zechariah, Thessalonians, Philippians, Deuteronomy."
      ];
    };

    output = {
      mode = "type";
      fallback_to_clipboard = true;
      type_delay_ms = 0;
      pre_type_delay_ms = 0;
      # Separate consecutive utterances
      append_text = " ";
      notification = {
        on_recording_start = true;
        on_recording_stop = false;
        on_transcription = false;
      };
    };

    status.icon_theme = "emoji";
  };
in {
  options.machshev.dictation.enable = lib.mkEnableOption "local voice dictation (voxtype)";

  config = lib.mkIf cfg.enable {
    home.packages = [voxtype];

    xdg.dataFile."voxtype/models/${modelName}".source = model;
    xdg.configFile."voxtype/config.toml".source =
      (pkgs.formats.toml {}).generate "voxtype-config.toml" settings;

    systemd.user.services.voxtype = {
      Unit = {
        Description = "Voxtype voice dictation daemon";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target" "pipewire.service"];
        X-Restart-Triggers = ["${config.xdg.configFile."voxtype/config.toml".source}"];
      };
      Service = {
        ExecStart = "${voxtype}/bin/voxtype daemon";
        Restart = "on-failure";
      };
      Install.WantedBy = ["graphical-session.target"];
    };

    wayland.windowManager.sway.config.keybindings = let
      mod = config.wayland.windowManager.sway.config.modifier;
    in
      # mkOptionDefault to merge with (not replace) the bindings in sway.nix;
      # mkForce to take over the stock dmenu binding (wofi is on Mod+x).
      lib.mkOptionDefault {
        # Press to start dictating, press again to transcribe and type the text
        "${mod}+d" = lib.mkForce "exec ${voxtype}/bin/voxtype record toggle";
        "${mod}+Shift+d" = "exec ${voxtype}/bin/voxtype record cancel";
      };
  };
}
