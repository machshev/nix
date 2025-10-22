{pkgs, ...}: {
  config.vim = {
    theme = {
      enable = true;
      name = "tokyonight";
      style = "night";
      transparent = false;
    };

    spellcheck.enable = true;

    options = {
      wrap = false;

      expandtab = true;
      smarttab = true;
      shiftround = true;
      shiftwidth = 4;
      tabstop = 4;
      softtabstop = 4;

      cursorline = true;
      inccommand = "split";

      scrolloff = 10;
      signcolumn = "yes";

      updatetime = 250;

      colorcolumn = "80";

      hlsearch = true;
      incsearch = true;

      number = true;
      relativenumber = true;

      textwidth = 80;
      smartindent = false; # Use treesitter
      autoindent = false; # Use treesitter
      breakindent = true;

      ignorecase = true;
      smartcase = true;

      splitright = true;
      splitbelow = true;

      clipboard = "unnamedplus";

      swapfile = false;
      backup = false;
      undofile = true;
    };

    lsp = {
      enable = true;

      inlayHints.enable = true;
      formatOnSave = true;
      lspkind.enable = true;
      lightbulb.enable = true;
      lspsaga.enable = false;
      trouble.enable = true;

      servers = {
        "*" = {
          root_markers = [".git"];
          capabilities = {
            textDocument = {
              semanticTokens = {
                multilineTokenSupport = true;
              };
            };
          };
        };
        "typos_lsp" = {};
        "rust-analyser" = {
          root_markers = [".git" "cargo.toml"];
          filetypes = ["rust"];
        };
        "ruff" = {
          root_markers = [".git" "pyproject.toml" "setup.py"];
          filetypes = ["python"];
        };
        "pyright" = {
          root_markers = [".git" "pyproject.toml" "setup.py"];
          filetypes = ["python"];
        };
        #"pyrefly" = {
        #  root_markers = [".git" "pyproject.toml" "setup.py"];
        #  filetypes = ["python"];
        #};
        "ty" = {
          root_markers = [".git" "pyproject.toml" "setup.py"];
          filetypes = ["python"];
        };
      };

      mappings = {
        previousDiagnostic = "[d";
        nextDiagnostic = "]d";
      };
    };

    debugger = {
      nvim-dap = {
        enable = true;
        ui.enable = true;
      };
    };

    keymaps = [
      {
        key = "J";
        mode = ["n"];
        action = "mzJ`z";
        desc = "Join with next line";
      }
      {
        key = "<leader>pc";
        mode = ["n"];
        action = "<cmd>Ex<CR>";
        desc = "Path Explorer";
      }
      {
        key = "<leader>fF";
        mode = ["n"];
        action = "<cmd>Telescope find_files hidden=true no_ignore=true<CR>";
        desc = "";
      }
    ];

    telescope = {
      enable = true;
      mappings = {
        liveGrep = "<leader><leader>";
      };
      setupOpts = {
        vimgrep_arguments = [
          "${pkgs.ripgrep}/bin/rg"
          "--color=never"
          "--no-heading"
          "--with-filename"
          "--line-number"
          "--column"
          "--smart-case"
          "--no-ignore"
          "-u"
        ];
        layout_config = {
          horizontal = {
            prompt_position = "bottom";
          };
        };
        extensions = ["fzf"];
      };
    };

    languages = {
      enableFormat = true;
      enableTreesitter = true;
      enableExtraDiagnostics = true;

      nix = {
        enable = true;
        lsp.server = "nixd";
      };

      markdown = {
        enable = true;
        format.enable = false;
      };
      bash.enable = true;
      yaml.enable = true;

      assembly.enable = true;
      clang.enable = true;

      # css.enable = true; # Seems to be broken
      html.enable = true;
      php.enable = true;
      sql.enable = true;

      python = {
        enable = true;
        lsp.enable = false; # use `lsp.servers` instead
        format.type = "ruff";
      };
      rust = {
        enable = true;
        crates.enable = true;
      };
      go.enable = true;
      lua.enable = true;

      dart.enable = true;
      zig.enable = true;
      terraform.enable = true;
    };

    # Disable the built-in lualine module to avoid conflicts with custom plugin
    # below
    statusline.lualine.enable = false;

    autopairs.nvim-autopairs.enable = true;

    autocomplete = {
      nvim-cmp.enable = false;
      blink-cmp = {
        enable = true;
      };
    };

    formatter.conform-nvim = {
      enable = true;
      setupOpts = {
        formatters_by_ft = {
          go = ["goimports" "gofmt"];
          lua = ["stylua"];
          sh = ["shfmt"];
          rust = ["rustfmt"];
          css = ["biome"];
          html = ["biome"];
          json = ["biome"];
          nix = ["nix_fmt"];
          yaml = ["prettier"];
          graphql = ["prettier"];
          python = ["ruff_format"];
          javascript = ["biome" "eslint_d"];
          typescript = ["biome" "eslint_d"];
          javascriptreact = ["biome" "eslint_d"];
          typescriptreact = ["biome" "eslint_d"];
        };
      };
    };

    filetree = {
      neo-tree = {
        enable = true;
      };
    };

    tabline = {
      #nvimBufferline.enable = true;
    };

    treesitter = {
      context.enable = true;
      highlight.enable = true;
      indent.enable = true;
      grammars = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        jq
        dockerfile
        markdown
        markdown_inline
        mermaid
        regex
        toml
        udev
        verilog
        typescript
      ];
    };

    binds = {
      whichKey.enable = true;
      cheatsheet.enable = true;
    };

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
      modes-nvim.enable = false; # default colors don't work with theme
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
          python = ["88" "100"];
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

    # Add lualine as a custom plugin
    extraPlugins = {
      lualine = {
        package = "lualine-nvim";
        setup = ''
          local custom_opts = {
            options = {
              icons_enabled = true,
              section_separators = ''',
              component_separators = ''',
            }
          }

          local custom_theme = require 'lualine.themes.tokyonight'
          custom_theme.inactive.c.bg = '#101010'
          custom_theme.normal.c.bg = '#101010'

          custom_opts["options"]["theme"] = custom_theme
          require('lualine').setup(custom_opts)
        '';
      };
    };

    extraPackages = [pkgs.pyright pkgs.ruff pkgs.ty];
  };
}
