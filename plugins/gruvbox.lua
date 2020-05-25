-- Place this file in data/user/colors and call require "user.colors.gruvbox" in data/user/init.lua

local style = require "core.style"
local common = require "core.common"

style.background = { common.color "#282828" }
style.background2 = { common.color "#1d2021" }
style.background3 = { common.color "#1d2021" }
style.text = { common.color "#ebdbb2" }
style.caret = { common.color "#fe8019" }
style.accent = { common.color "#ffd152" }
style.dim = { common.color "#665c54" }
style.divider = { common.color "#282828" }
style.selection = { common.color "#3c3836" }
style.line_number = { common.color "#504945" }
style.line_number2 = { common.color "#7c6f64" }
style.line_highlight = { common.color "#504945" }
style.scrollbar = { common.color "#504945" }
style.scrollbar2 = { common.color "#32302f" }

style.syntax["normal"] = { common.color "#ebdbb2" }
style.syntax["symbol"] = { common.color "#efdab9" }
style.syntax["comment"] = { common.color "#928374" }
style.syntax["keyword"] = { common.color "#fb4934" }
style.syntax["keyword2"] = { common.color "#fabd2f" }
style.syntax["number"] = { common.color "#d3869b" }
style.syntax["literal"] = { common.color "#d3869b" }
style.syntax["string"] = { common.color "#b8bb26" }
style.syntax["operator"] = { common.color "#ebdbb2" }
style.syntax["function"] = { common.color "#83a598" }
