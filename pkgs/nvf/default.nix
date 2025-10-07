{
  config,
  pkgs,
  lib,
  ...
}: {
  config.vim = {
    theme = {
      enable = true;
      name = "catppuccin";
      style = "mocha";
      transparent = false;
    };

    spellcheck.enable = true;

    lsp = {
      enable = true;

      formatOnSave = true;
      lspkind.enable = false;
      lightbulb.enable = true;
      lspsaga.enable = false;
      trouble.enable = true;
    };

    debugger = {
      nvim-dap = {
        enable = true;
        ui.enable = true;
      };
    };

    keymaps = [
      {
        key="J";
        mode = ["n"];
        action = "mzJ`z";
        desc = "Join with next line";
      }
      {
        key="<leader>pc";
        mode = ["n"];
        action = "<cmd>Ex<CR>";
        desc = "Path Explorer";
      }
    ];

   languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = true;

      nix.enable = true;
      markdown.enable = true;
      bash.enable = true;

      clang.enable = true;

      # css.enable = true; # Seems to be broken
      html.enable = true;
      sql.enable = true;

      python.enable = true;
      rust = {
        enable = true;
        crates.enable = true;
      };
      go.enable = true;
      lua.enable = true;

      dart.enable = true;
      zig.enable = true;
    };

    statusline = {
      lualine = {
        enable = true;
        theme = "catppuccin";
      };
    };

    autopairs.nvim-autopairs.enable = true;

    autocomplete = {
      nvim-cmp.enable = false;
      blink-cmp.enable = true;
    };

    filetree = {
      neo-tree = {
        enable = true;
      };
    };

    tabline = {
      nvimBufferline.enable = true;
    };

    treesitter.context.enable = true;

    binds = {
      whichKey.enable = true;
      cheatsheet.enable = true;
    };

    telescope.enable = true;

    git = {
      enable = true;
      gitsigns.enable = true;
      gitsigns.codeActions.enable = false; # throws an annoying debug message
      neogit.enable = true;
    };

    minimap = {
      minimap-vim.enable = false;
      codewindow.enable = true; # lighter, faster, and uses lua for configuration
    };

    dashboard = {
      dashboard-nvim.enable = false;
      alpha.enable = true;
    };

    notify = {
      nvim-notify.enable = true;
    };

    projects = {
      project-nvim.enable = true;
    };

    utility = {
      ccc.enable = false;
      vim-wakatime.enable = false;
      diffview-nvim.enable = true;
      yanky-nvim.enable = false;
      icon-picker.enable = false;
      surround.enable = false;
      leetcode-nvim.enable = false;
      multicursors.enable = false;
      smart-splits.enable = false;
      undotree.enable = true;
      nvim-biscuits.enable = false;

      motion = {
        hop.enable = true;
        leap.enable = true;
        precognition.enable = false;
      };
      images = {
        image-nvim.enable = false;
        img-clip.enable = false;
      };
    };

    notes = {
      neorg.enable = false;
      orgmode.enable = false;
      mind-nvim.enable = false;
      todo-comments.enable = true;
    };

    terminal = {
      toggleterm = {
        enable = true;
        lazygit.enable = true;
      };
    };

    ui = {
      borders.enable = true;
      noice.enable = true;
      colorizer.enable = true;
      modes-nvim.enable = false; # the theme looks terrible with catppuccin
      illuminate.enable = true;
      breadcrumbs = {
        enable = false;
        navbuddy.enable = false;
      };
      smartcolumn = {
        enable = true;
        setupOpts.custom_colorcolumn = {
          # this is a freeform module, it's `buftype = int;` for configuring column position
          nix = "110";
          ruby = "120";
          java = "130";
          go = ["90" "130"];
        };
      };
      fastaction.enable = true;
    };

    assistant = {
      chatgpt.enable = false;
      copilot = {
        enable = false;
        cmp.enable = false;
      };
      codecompanion-nvim.enable = false;
      avante-nvim.enable = false;
    };

    session = {
      nvim-session-manager.enable = false;
    };

    gestures = {
      gesture-nvim.enable = false;
    };

    comments = {
      comment-nvim.enable = true;
    };

    presence = {
      neocord.enable = false;
    };

  };
}
