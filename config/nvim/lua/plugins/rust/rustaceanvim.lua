return {
  "mrcjkb/rustaceanvim",
  version = vim.fn.has("nvim-0.10.0") == 0 and "^4" or false,
  ft = { "rust" },
  opts = {
    server = {
      on_attach = function(client, bufnr)
        -- Only set keymaps for Rust files
        if vim.bo[bufnr].filetype == "rust" then
          vim.keymap.set("n", "<leader>cR", function()
            vim.cmd.RustLsp("codeAction")
          end, { desc = "Code Action", buffer = bufnr })
          vim.keymap.set("n", "<leader>dr", function()
            vim.cmd.RustLsp("debuggables")
          end, { desc = "Rust Debuggables", buffer = bufnr })
        end
      end,
      default_settings = {
        -- rust-analyzer language server configuration
        ["rust-analyzer"] = {
          cargo = {
            allFeatures = true,
            loadOutDirsFromCheck = true,
            buildScripts = {
              enable = true,
            },
          },
          completion = {
            autoimport = {
              enable = true,
            },
          },
          imports = {
            granularity = {
              group = "module",
            },
            prefix = "self",
          },
          -- Add clippy lints for Rust if using rust-analyzer
          checkOnSave = {
            command = "check", -- or "clippy"
          },
          -- Enable diagnostics if using rust-analyzer
          diagnostics = {
            enable = true,
          },
          procMacro = {
            enable = true,
            ignored = {
              ["napi-derive"] = { "napi" },
              ["async-recursion"] = { "async_recursion" },
            },
          },
          files = {
            excludeDirs = {
              ".direnv",
              ".git",
              ".github",
              ".gitlab",
              "bin",
              "node_modules",
              "target",
              "venv",
              ".venv",
            },
          },
        },
      },
    },
  },
  config = function(_, opts)
    -- Check if rust-analyzer is available before setting up
    if vim.fn.executable("rust-analyzer") == 0 then
      LazyVim.error(
        "**rust-analyzer** not found in PATH, please install it.\nhttps://rust-analyzer.github.io/",
        { title = "rustaceanvim" }
      )
      return
    end

    if LazyVim.has("mason.nvim") then
      local mason_registry = require("mason-registry")
      if mason_registry.is_installed("codelldb") then
        local package_path = mason_registry.get_package("codelldb"):get_install_path()
        local codelldb = package_path .. "/extension/adapter/codelldb"
        local library_path = package_path .. "/extension/lldb/lib/liblldb.dylib"
        local uname = io.popen("uname"):read("*l")
        if uname == "Linux" then
          library_path = package_path .. "/extension/lldb/lib/liblldb.so"
        end
        opts.dap = {
          adapter = require("rustaceanvim.config").get_codelldb_adapter(codelldb, library_path),
        }
      end
    end

    vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})
  end,
}
