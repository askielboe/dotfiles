return {
  "echasnovski/mini.ai",
  opts = {
    custom_textobjects = {
      e = { -- Word with case and underscores
        {
          "%u[%l%d]+%f[^%l%d]", -- CamelCase words
          "%f[%S][%l%d]+%f[^%l%d]", -- after non-whitespace
          "%f[%P][%l%d]+%f[^%l%d]", -- after non-punctuation
          "^[%l%d]+%f[^%l%d]", -- start of line
          "%f[%u][%u]+%f[^%u]", -- UPPER_CASED_WORDS
        },
        "^().*()$",
      },
    },
  },
}
