-- Pane navigation, matching Ghostty.
rex.bind("ctrl+cmd+j", "pane.focus", { direction = "down" })
rex.bind("ctrl+cmd+h", "pane.focus", { direction = "left" })
rex.bind("ctrl+cmd+k", "pane.focus", { direction = "up" })
rex.bind("ctrl+cmd+l", "pane.focus", { direction = "right" })

-- Rex measures resize amounts in percent, not Ghostty's terminal cells.
rex.bind("ctrl+alt+cmd+j", "pane.resize", { direction = "down", amount = 5 })
rex.bind("ctrl+alt+cmd+h", "pane.resize", { direction = "left", amount = 5 })
rex.bind("ctrl+alt+cmd+k", "pane.resize", { direction = "up", amount = 5 })
rex.bind("ctrl+alt+cmd+l", "pane.resize", { direction = "right", amount = 5 })

-- Keep these layout-specific characters available with Option acting as Alt.
for key, text in pairs({
  -- Hax distinguishes newline (LF) from submit (CR).
  ["shift+enter"] = "\n",
  ["alt+8"] = "[",
  ["alt+9"] = "]",
  ["alt+shift+7"] = "\\",
  ["alt+shift+8"] = "{",
  ["alt+shift+9"] = "}",
  ["alt+[BracketRight]"] = "~", -- Danish ¨ key; Rex requires a physical binding.
  ["alt+'"] = "@",
  ["alt+i"] = "|",
}) do
  rex.bind(key, function(ctx, ev)
    local _, err = rex.block.call("com.superlogical.terminal", "write", {
      block_id = ctx.block_id,
      data = text,
    })
    if err ~= nil then error(err, 0) end
    return true
  end)
end
