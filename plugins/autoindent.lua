local core = require "core"
local command = require "core.command"
local config = require "core.config"
local keymap = require "core.keymap"

config.autoindent_triggers = {
  "{%s*\n", "%(%s*\n", "%f[[]%[%s*\n", "%[%[%s*\n", "=%s*\n", ":%s*\n",
  "^#if.*\n", "^#else.*\n", "%f[%w]do%s*\n", "%f[%w]then%s*\n",
  "%f[%w]else%s*\n", "%f[%w]repeat%s*\n", "%f[%w]function.*%)%s*\n", "^%s*<([^/][^%s>]*)[^>]*>%s*\n",
}

local function indent_size(doc, line)
  local text = doc.lines[line] or ""
  local s, e = text:find("^[\t ]*")
  return e - s
end

command.add("core.docview", {
  ["autoindent:newline"] = function()
    command.perform("doc:newline")

    local doc = core.active_view.doc
    local line, col = doc:get_selection()
    local text = doc.lines[line - 1]

    for _, ptn in pairs(config.autoindent_triggers) do
      local s, _, str = text:find(ptn)
      if s then
        command.perform("doc:indent")
      end
    end
  end,

  ["autoindent:newline-below"] = function()
    command.perform("doc:newline-below")

    local doc = core.active_view.doc
    local line, col = doc:get_selection()
    local text = doc.lines[line - 1]

    for _, ptn in pairs(config.autoindent_triggers) do
      local s, _, str = text:find(ptn)
      if s then
        command.perform("doc:indent")
      end
    end
  end,
})

keymap.add {
  ["return"] = { "command:submit", "autoindent:newline" }
}
