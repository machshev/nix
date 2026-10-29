{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}: let
  cfg = config.machshev.dictation;

  # whisper.cpp on the Intel iGPU via Vulkan.
  voxtypeVulkan = pkgs.voxtype-vulkan;

  # The same, plus the OpenVINO GenAI Whisper engine (Intel NPU), so one binary
  # can run either engine and `--engine` picks between them at runtime. The
  # openvino-whisper feature needs voxtype >= 1.1, hence unstable.
  voxtypeOpenvino = (pkgs-unstable.voxtype.override {vulkanSupport = true;}).overrideAttrs (old: {
    # buildRustPackage copies buildFeatures into these when it's called, so
    # overriding buildFeatures alone doesn't reach cargo.
    cargoBuildFeatures = old.cargoBuildFeatures ++ ["openvino-whisper"];
    cargoCheckFeatures = old.cargoCheckFeatures ++ ["openvino-whisper"];

    # Clean paragraph breaks from a spoken "new paragraph" (see [text] below),
    # stop streaming falling behind when inference outlasts its interval, and
    # type rather than discard what is still being transcribed at stop
    patches = (old.patches or []) ++ [./voxtype-streaming-fixes.patch];

    # nixpkgs swaps voxtype's openvino-genai git fork for the crates.io
    # release, which lacks WhisperPipeline::with_properties. That only passed
    # CACHE_DIR; the NPU driver keeps its own compiled-blob cache anyway.
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace src/transcribe/openvino_whisper.rs \
          --replace-fail \
            'WhisperPipeline::with_properties(&self.model_path, device, props)' \
            '{ let _ = props; WhisperPipeline::new(&self.model_path, device) }'
      '';

    postFixup =
      (old.postFixup or "")
      + ''
        # The NPU plugin dlopens libze_loader.so.1, and the NPU driver its
        # libnpu_driver_compiler.so (installed beside it), by bare name
        wrapProgram $out/bin/voxtype \
          --prefix LD_LIBRARY_PATH : ${pkgs-unstable.level-zero}/lib:/run/opengl-driver/lib \
          --set VOXTYPE_OPENVINO_DIR ${pkgs-unstable.openvino-genai}/lib \
          --set OPENVINO_TOKENIZERS_PATH_GENAI ${pkgs-unstable.openvino-tokenizers}/lib/libopenvino_tokenizers.so
      '';
  });

  voxtype =
    if cfg.openvino.enable
    then voxtypeOpenvino
    else voxtypeVulkan;

  modelName = "ggml-large-v3-turbo-q5_0.bin";
  model = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/${modelName}";
    sha256 = "1qm7zxamlvac564c3270wqqqks5wc7532q3fqi01zbfmkiq22hir";
  };

  # OpenVINO IR export of the same large-v3-turbo model, for a like-for-like
  # comparison. Only the files voxtype's WhisperPipeline loads.
  openvinoModel = let
    repo = "OpenVINO/whisper-large-v3-turbo-int8-ov";
    rev = "b568445dd5dc8c695bde596f8acbb4694fd6ba64";
    files = {
      "openvino_encoder_model.xml" = "0w70djx00b6zplvja23apk518v97xhvlf77143h8xb58sd73swb0";
      "openvino_encoder_model.bin" = "0590a8f35f96d57801c55990028d917821ac721026e34b7f3f59d7561fc908e6";
      "openvino_decoder_model.xml" = "0irhy02amq4dkcsnbczkz8i5h01n6iv4c3zkpa2by30wpyprzc5f";
      "openvino_decoder_model.bin" = "c064991cbafc4381567d29972b7013dc24026de9c326d03eb1e6e4fc44aa959f";
      "openvino_tokenizer.xml" = "14zdzv4s78222wrzbx60wgrfq5qia34gpk6bsawp6iympbkh98yb";
      "openvino_tokenizer.bin" = "adfa3d9a2920d0f314121270a960ab331ec0f05838544bb8ecaaa422282a6fd4";
      "openvino_detokenizer.xml" = "0mnwm7dvj6kn8y7xmdsm4hxzk7w13ndsjj3rdfs721sby4a6l43f";
      "openvino_detokenizer.bin" = "f2b3c47825a1089525ff65c0c8e49271e1dee69a401a04fc827ac2de5b7766e4";
      "tokenizer.json" = "06yzg30j76xqgbpy7sc9rfp3s0g03fq4dy6yprvi8vkikq6g66sw";
      "config.json" = "11la7s5fp2a4wb69mcssvhgsjnaspq481bmb8b5i5as7fl4jrndz";
      "generation_config.json" = "1d3ppm4746w122yplbam1dlbc6lwj6nalhri20dbkwwa8p5gq5s6";
      "preprocessor_config.json" = "16fldc96ydy9c77p71nmcpi2vdg0djjnsxprxa698fqn7s6z2k35";
    };
  in
    pkgs.linkFarm "whisper-large-v3-turbo-int8-ov" (lib.mapAttrs (name: sha256:
      pkgs.fetchurl {
        url = "https://huggingface.co/${repo}/resolve/${rev}/${name}";
        inherit sha256;
      })
    files);

  # voxtype's "subtle" sound theme, regenerated with a softer completion sound.
  # Streaming plays no stop sound, only "complete" once the text is typed, and
  # upstream's is a full-volume 900->1100 Hz step with a click at the jump;
  # here it's a smooth sweep at half volume. 0.49 matches upstream's amplitude.
  feedbackTheme =
    pkgs.runCommand "voxtype-sounds" {nativeBuildInputs = [pkgs.sox];} ''
      mkdir $out && cd $out
      tone() { sox -n -r 44100 -b 16 -c 1 "$1" synth "$2" sine "$3" fade t "$4" 0 "$4" vol "$5"; }
      tone start.wav    0.05 1200     0.01  0.49
      tone stop.wav     0.05 800      0.01  0.49
      tone complete.wav 0.06 900-1100 0.015 0.25
      tone cancel.wav   0.04 600      0.008 0.49
      tone error.wav    0.1  400-300  0.015 0.49
    '';

  # One config per spoken language: the OpenVINO engine takes a single fixed
  # language, and only whisper's honours voxtype's --language override.
  mkSettings = language:
    {
      engine = cfg.engine;
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
        # Turn other audio down while dictating
        duck_media = true;
        # Beep when recording starts and stops
        feedback = {
          enabled = true;
          theme = "${feedbackTheme}";
        };
      };

      whisper = {
        model = "${config.xdg.dataHome}/voxtype/models/${modelName}";
        inherit language;
        translate = false;
        on_demand_loading = false;
        inherit (cfg) streaming;
      };

      output = {
        mode = "type";
        fallback_to_clipboard = true;
        type_delay_ms = 0;
        pre_type_delay_ms = 0;
        # Separate consecutive utterances
        append_text = " ";
        notification = {
          # Waybar shows recording state instead
          on_recording_start = false;
          on_recording_stop = false;
          on_transcription = false;
        };
      };

      status.icon_theme = "emoji";

      # Reject recordings with no speech (e.g. a dead mic) rather than let
      # Whisper hallucinate "you" from silence
      vad.enabled = true;

      # nixpkgs builds no OSD frontend, so the daemon only logs failures
      osd.enabled = false;
    }
    // lib.optionalAttrs cfg.openvino.enable {
      openvino = {
        model = "${openvinoModel}";
        inherit (cfg.openvino) device;
        inherit language;
        translate = false;
        on_demand_loading = false;
        inherit (cfg) streaming;
      };

      # Say "new paragraph" to start one. Only the patched 1.1 build tidies
      # the punctuation Whisper puts around it.
      text.replacements = {
        "new paragraph" = "\n\n";
        "פסקה חדשה" = "\n\n";
      };

      # Streamed text is typed as committed segments rather than partials:
      # same timing, but only segments get the [text] replacements.
      streaming.type_partials = false;
    };

  defaultLanguage = builtins.head cfg.languages;
  mkConfig = language:
    (pkgs.formats.toml {}).generate "voxtype-config-${language}.toml" (mkSettings language);

  # The daemon runs whichever engine and language `voxtype-engine` and
  # `voxtype-language` last selected, falling back to the configured defaults.
  stateDir = "${config.xdg.stateHome}/voxtype";
  daemon = pkgs.writeShellScript "voxtype-daemon" ''
    engine=$(cat ${stateDir}/engine 2>/dev/null || true)
    language=$(cat ${stateDir}/language 2>/dev/null || echo ${defaultLanguage})
    config=${config.xdg.configHome}/voxtype/config-$language.toml
    [ -e "$config" ] || config=${config.xdg.configHome}/voxtype/config.toml
    exec ${voxtype}/bin/voxtype --config "$config" ''${engine:+--engine "$engine"} daemon
  '';

  # `<name> [value|default]`: show, set or clear the daemon's choice of <name>
  mkSwitch = name: values: default:
    pkgs.writeShellScriptBin "voxtype-${name}" ''
      set -eu
      state=${stateDir}/${name}
      case "''${1-}" in
        "")
          cat "$state" 2>/dev/null || echo "${default} (default)"
          exit 0
          ;;
        ${lib.concatStringsSep " | " values})
          mkdir -p ${stateDir}
          echo "$1" > "$state"
          ;;
        default)
          rm -f "$state"
          ;;
        *)
          echo "usage: voxtype-${name} [${lib.concatStringsSep "|" values}|default]" >&2
          exit 1
          ;;
      esac
      systemctl --user restart voxtype.service
    '';
  voxtypeEngine = mkSwitch "engine" ["whisper" "openvino"] cfg.engine;
  voxtypeLanguage = mkSwitch "language" cfg.languages defaultLanguage;
in {
  options.machshev.dictation = {
    enable = lib.mkEnableOption "local voice dictation (voxtype)";

    engine = lib.mkOption {
      type = lib.types.enum ["whisper" "openvino"];
      default = "whisper";
      description = ''
        Engine the daemon starts with: "whisper" (whisper.cpp on the iGPU via
        Vulkan) or "openvino" (OpenVINO GenAI, by default on the Intel NPU).
        `voxtype-engine` switches it at runtime.
      '';
    };

    languages = lib.mkOption {
      type = lib.types.nonEmptyListOf lib.types.str;
      default = ["en"];
      example = ["en" "he"];
      description = ''
        Whisper language codes to dictate in; the first is the default.
        `voxtype-language` switches between them at runtime.
      '';
    };

    streaming = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Type text while still recording: the rolling buffer is re-transcribed
        every interval and words are typed once two passes agree, rather than
        all at once when recording stops. Needs voxtype >= 1.1, which only
        `openvino.enable` builds here.
      '';
    };

    openvino = {
      enable = lib.mkEnableOption ''
        the OpenVINO Whisper engine alongside whisper.cpp. The host also needs
        `hardware.cpu.intel.npu.enable` to use the NPU'';

      device = lib.mkOption {
        type = lib.types.enum ["NPU" "GPU" "CPU" "AUTO"];
        default = "NPU";
        description = "OpenVINO inference device.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.engine == "openvino" -> cfg.openvino.enable;
        message = "machshev.dictation.engine = \"openvino\" requires machshev.dictation.openvino.enable";
      }
      {
        assertion = cfg.streaming -> cfg.openvino.enable;
        message = "machshev.dictation.streaming requires machshev.dictation.openvino.enable (voxtype >= 1.1)";
      }
    ];

    home.packages = [voxtype] ++ lib.optionals cfg.openvino.enable [voxtypeEngine voxtypeLanguage];

    xdg.dataFile."voxtype/models/${modelName}".source = model;
    xdg.configFile =
      {
        # What the voxtype CLI reads by default
        "voxtype/config.toml".source = mkConfig defaultLanguage;
      }
      // lib.listToAttrs (map (l: lib.nameValuePair "voxtype/config-${l}.toml" {source = mkConfig l;}) cfg.languages);

    systemd.user.services.voxtype = {
      Unit = {
        Description = "Voxtype voice dictation daemon";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target" "pipewire.service"];
        X-Restart-Triggers = map (l: "${mkConfig l}") cfg.languages;
      };
      Service = {
        ExecStart =
          if cfg.openvino.enable
          then "${daemon}"
          else "${voxtype}/bin/voxtype daemon";
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
