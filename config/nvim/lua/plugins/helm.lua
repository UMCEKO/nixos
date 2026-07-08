return {
  -- 1. The Syntax & Filetype Plugin
  -- This forces proper highlighting for {{ .Values }} and detects "helm" filetype
  {
    "towolf/vim-helm",
    event = "BufReadPre",
  },

  -- 2. The LSP Configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- The Helm Language Server
        -- It provides completion for {{ .Values... }} and k8s resources
        helm_ls = {
          settings = {
            ["helm-ls"] = {
              yamlls = {
                path = "yaml-language-server",
              },
            },
          },
        },
        -- The Standard YAML Server
        -- We configure it to IGNORE helm files so it doesn't report errors on templates
        yamlls = {
          filetypes = { "yaml", "yaml.docker-compose" }, -- Removed "helm"
        },
      },
      setup = {
        -- Advanced: Ensure yamlls doesn't attach to helm files if filetypes overlap
        yamlls = function(_, opts)
          opts.filetypes = { "yaml", "yaml.docker-compose" }
        end,
      },
    },
  },

  -- 3. Treesitter support for the weird Go-Template-inside-YAML syntax
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "helm" })
      end
    end,
  },
}
