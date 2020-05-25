--[[
Press ESCAPE to go into normal mode, in this mode you can move around using the "modal+" keybindings
you find at the bottom of this file. Press I to go back to insert mode. While this plugin is inspired
by vim, this is not a vim emulator, it only has the most basic movement functions that vim does.

Additionally, it also has easy-motion inspired functionality. In normal mode, press S to start the
easy-motion functionality, then select wherever you want to go to. With the combination of this with
all the other keys you should be able to edit text without moving your hand away from the keyboard!
]]--

local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"
local DocView = require "core.docview"
local style = require "core.style"
local config = require "core.config"
local common = require "core.common"
local translate = require "core.doc.translate"

local mode = "insert"
local in_easy_motion = false
local first_easy_motion_key_pressed = false
local first_key = ""
local easy_motion_lines = {}
local separated_words = {}
local has_autoindent = system.get_file_info("data/plugins/autoindent.lua") or system.get_file_info("data/user/plugins/autoindent.lua")
local easy_motion_color_1 = { common.color "#FFA94D" }
local easy_motion_color_2 = { common.color "#f7c95c" }

local function dv()
  return core.active_view
end

local function doc()
  return core.active_view.doc
end

local function append_line_if_last_line(line)
  if line >= #doc().lines then
    doc():insert(line, math.huge, "\n")
  end
end

local activate_easy_motion = function()
  local dv = core.active_view
  if not dv:is(DocView) then return end
  in_easy_motion = true
  local min, max = dv:get_visible_line_range()
  local lines = dv.doc.lines
  local current_line, current_col = dv.doc:get_selection()
  easy_motion_lines = {}
  separated_words = {}

  local pivot_inserted = false
  local total_words = 0
  local keys = {"a", "s", "d", "f", "g", "h", "j", "k", "l", "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "z", "x", "c", "v", "b", "n", "m"}
  local l, m = 1, 1
  for i = min, max do
    for j, symbol, k, word in lines[i]:gmatch("()([%s%p]*)()([%w%p%c%S]+)") do
      table.insert(separated_words, {line = i, col = j, text = symbol})
      for a, tail in word:gmatch("(.)(.*)") do
        local t = {line = i, col = k, head = a, tail = tail, key_1 = keys[l], key_2 = keys[m]}
        table.insert(separated_words, t)
        m = m + 1
        if m > #keys then
          m = 1
          l = l + 1
        end
      end
    end
  end

  for _, word in ipairs(separated_words) do
    if not easy_motion_lines[word.line] then
      easy_motion_lines[word.line] = {}
    end
    if word.head then
      table.insert(easy_motion_lines[word.line], {col = word.col, text = word.key_1, type = easy_motion_color_1})
      table.insert(easy_motion_lines[word.line], {col = word.col+1, text = word.key_2, type = easy_motion_color_2})
      if #word.tail > 1 then
        table.insert(easy_motion_lines[word.line], {col = word.col+2, text = word.tail:sub(2, #word.tail), type = style.syntax.comment})
      end
    else
      table.insert(easy_motion_lines[word.line], {col = word.col, text = word.text, type = style.syntax.comment})
    end
  end
end

local press_first_easy_motion_key = function(key)
  local dv = core.active_view
  if not dv:is(DocView) then return end
  first_easy_motion_key_pressed = true
  first_key = key
  local min, max = dv:get_visible_line_range()
  local black = { common.color "#000000" }
  easy_motion_lines = {}

  for _, word in ipairs(separated_words) do
    if not easy_motion_lines[word.line] then
      easy_motion_lines[word.line] = {}
    end
    if word.head then
      if word.key_1 == key then
        table.insert(easy_motion_lines[word.line], {col = word.col, text = word.key_2, type = black, bg = easy_motion_color_2})
        table.insert(easy_motion_lines[word.line], {col = word.col+1, text = word.tail, type = style.syntax.comment})
      else
        table.insert(easy_motion_lines[word.line], {col = word.col, text = word.head .. word.tail, type = style.syntax.comment})
      end
    else
      table.insert(easy_motion_lines[word.line], {col = word.col, text = word.text, type = style.syntax.comment})
    end
  end
end

local modkey_map = {
  ["left ctrl"]   = "ctrl",
  ["right ctrl"]  = "ctrl",
  ["left shift"]  = "shift",
  ["right shift"] = "shift",
  ["left alt"]    = "alt",
  ["right alt"]   = "altgr",
}

local modkeys = { "ctrl", "alt", "altgr", "shift" }

local function key_to_stroke(k)
  local stroke = ""
  for _, mk in ipairs(modkeys) do
    if keymap.modkeys[mk] then
      stroke = stroke .. mk .. "+"
    end
  end
  return stroke .. k
end

function keymap.on_key_pressed(k)
  local mk = modkey_map[k]
  if mk then
    keymap.modkeys[mk] = true
    -- work-around for windows where `altgr` is treated as `ctrl+alt`
    if mk == "altgr" then
      keymap.modkeys["ctrl"] = false
    end
  else
    local stroke = key_to_stroke(k)
    local commands
    if mode == "insert" then
      commands = keymap.map[stroke]
    elseif mode == "movement" then
      commands = keymap.map["modal+" .. stroke]
    end

    if in_easy_motion then
      if first_easy_motion_key_pressed then
        for _, word in ipairs(separated_words) do
          if word.key_2 == k and word.key_1 == first_key then
            core.active_view.doc:set_selection(word.line, word.col)
          end
        end
        in_easy_motion = false
        first_easy_motion_key_pressed = false
        first_key = ""
        easy_motion_lines = {}
        separated_words = {}
      else
        press_first_easy_motion_key(k)
      end
    else
      if commands then
        for _, cmd in ipairs(commands) do
          local performed = command.perform(cmd)
          if performed then break end
        end
        -- change to movement mode on escape after performing its normal functions
        if k == "escape" then
          mode = "movement"
          in_easy_motion = false
        end
        return true
      end
    end
    -- we don't want to perform any action when a command isn't found in movement mode
    if mode == "movement" then
      if k == "escape" then -- work-around for also using escape to get out ot easy-motion
        in_easy_motion = false
      end
      return true
    end
  end
  return false
end

local draw_line_body = DocView.draw_line_body

function DocView:draw_line_body(idx, x, y)
  local line, col = self.doc:get_selection()
  draw_line_body(self, idx, x, y)

  if mode == "movement" then
    if line == idx and core.active_view == self
    and system.window_has_focus() then
      local lh = self:get_line_height()
      local x1 = x + self:get_col_x_offset(line, col)
      local w = self:get_font():get_width(" ")
      renderer.draw_rect(x1, y, w, lh, style.caret)
    end
  end
end

local draw_line_text = DocView.draw_line_text

function DocView:draw_line_text(idx, x, y)
  if in_easy_motion then
    local tx, ty = x, y + self:get_line_text_y_offset()
    local font = self:get_font()
    if easy_motion_lines[idx] then
      for _, word in ipairs(easy_motion_lines[idx]) do
        if word.bg then
          renderer.draw_rect(tx, ty, self:get_font():get_width(word.text), self:get_line_height(), word.bg)
        end
        tx = renderer.draw_text(font, word.text, tx, ty, word.type)
      end
    else
      for _, type, text in self.doc.highlighter:each_token(idx) do
        local color = style.syntax[type]
        tx = renderer.draw_text(font, text, tx, ty, color)
      end
    end
  else
    draw_line_text(self, idx, x, y)
  end
end

command.add(nil, {
  ["modalediting:switch-to-movement-mode"] = function()
    mode = "movement"
  end,

  ["modalediting:switch-to-insert-mode"] = function()
    mode = "insert"
  end,

  ["modalediting:easy-motion"] = activate_easy_motion,

  ["modalediting:insert-at-start-of-line"] = function()
    mode = "insert"
    command.perform("doc:move-to-start-of-line")
  end,

  ["modalediting:insert-at-end-of-line"] = function()
    mode = "insert"
    command.perform("doc:move-to-end-of-line")
  end,

  ["modalediting:insert-at-next-char"] = function()
    mode = "insert"
    local line, col = doc():get_selection()
    local next_line, next_col = translate.next_char(doc(), line, col)
    if line ~= next_line then
      doc():move_to(translate.end_of_line, dv())
    else
      if doc():has_selection() then
        local _, _, line, col = doc():get_selection(true)
        doc():set_selection(line, col)
      else
        doc():move_to(translate.next_char)
      end
    end
  end,

  ["modalediting:insert-on-newline-below"] = function()
    mode = "insert"
    if has_autoindent then
      command.perform("autoindent:newline-below")
    else
      command.perform("doc:newline-below")
    end
  end,

  ["modalediting:insert-on-newline-above"] = function()
    mode = "insert"
    command.perform("doc:newline-above")
  end,

  ["modalediting:delete-line"] = function()
    if doc():has_selection() then
      local text = doc():get_text(doc():get_selection())
      system.set_clipboard(text)
      doc():delete_to(0)
    else
      local line, col = doc():get_selection()
      doc():move_to(translate.start_of_line, dv())
      doc():select_to(translate.end_of_line, dv())
      if doc():has_selection() then
        local text = doc():get_text(doc():get_selection())
        system.set_clipboard(text)
        doc():delete_to(0)
      end
      local line1, col1, line2 = doc():get_selection(true)
      append_line_if_last_line(line2)
      doc():remove(line1, 1, line2 + 1, 1)
      doc():set_selection(line1, col1)
    end
  end,

  ["modalediting:delete-to-end-of-line"] = function()
    if doc():has_selection() then
      local text = doc():get_text(doc():get_selection())
      system.set_clipboard(text)
      doc():delete_to(0)
    else
      doc():select_to(translate.end_of_line, dv())
      if doc():has_selection() then
        local text = doc():get_text(doc():get_selection())
        system.set_clipboard(text)
        doc():delete_to(0)
      end
    end
  end,

  ["modalediting:delete-word"] = function()
    if doc():has_selection() then
      local text = doc():get_text(doc():get_selection())
      system.set_clipboard(text)
      doc():delete_to(0)
    else
      doc():select_to(translate.next_word_boundary, dv())
      if doc():has_selection() then
        local text = doc():get_text(doc():get_selection())
        system.set_clipboard(text)
        doc():delete_to(0)
      end
    end
  end,

  ["modalediting:delete-char"] = function()
    if doc():has_selection() then
      local text = doc():get_text(doc():get_selection())
      system.set_clipboard(text)
      doc():delete_to(0)
    else
      doc():select_to(translate.next_char, dv())
      if doc():has_selection() then
        local text = doc():get_text(doc():get_selection())
        system.set_clipboard(text)
        doc():delete_to(0)
      end
    end
  end,

  ["modalediting:paste"] = function()
    local line, col = doc():get_selection()
    local indent = doc().lines[line]:match("^[\t ]*")
    doc():insert(line, math.huge, "\n")
    doc():set_selection(line + 1, math.huge)
    doc():text_input(indent .. system.get_clipboard():gsub("\r", ""))
  end,

  ["modalediting:copy"] = function()
    if doc():has_selection() then
      local text = doc():get_text(doc():get_selection())
      system.set_clipboard(text)
      local line, col = doc():get_selection()
      doc():move_to(function() return line, col end, dv())
    else
      local line, col = doc():get_selection()
      doc():move_to(translate.start_of_line, dv())
      doc():move_to(translate.next_word_boundary, dv())
      doc():select_to(translate.end_of_line, dv())
      if doc():has_selection() then
        local text = doc():get_text(doc():get_selection())
        system.set_clipboard(text)
      end
      doc():move_to(function() return line, col end, dv())
    end
  end,

  ["modalediting:find"] = function()
    mode = "insert"
    command.perform("find-replace:find")
  end,

  ["modalediting:replace"] = function()
    mode = "insert"
    command.perform("find-replace:replace")
  end,

  ["modalediting:go-to-line"] = function()
    mode = "insert"
    command.perform("doc:go-to-line")
  end,

  ["modalediting:close"] = function()
    mode = "insert"
    command.perform("root:close")
  end,

  ["modalediting:end-of-line"] = function()
    if doc():has_selection() then
      doc():select_to(translate.end_of_line, dv())
    else
      command.perform("doc:move-to-end-of-line")
    end
  end,

  ["modalediting:command-finder"] = function()
    mode = "insert"
    command.perform("core:command-finder")
  end,

  ["modalediting:file-finder"] = function()
    mode = "insert"
    command.perform("core:file-finder")
  end,

  ["modalediting:open-file"] = function()
    mode = "insert"
    command.perform("core:open-file")
  end,

  ["modalediting:new-doc"] = function()
    mode = "insert"
    command.perform("core:new-doc")
  end,

  ["modalediting:indent"] = function()
    if doc():has_selection() then
      local line, col = doc():get_selection()
      local line1, col1, line2, col2 = doc():get_selection(true)
      for i = line1, line2 do
        doc():move_to(function() return i, 1 end, dv())
        doc():move_to(translate.start_of_line, dv())
        command.perform("doc:indent")
      end
      doc():move_to(function() return line, col end, dv())
    else
      local line, col = doc():get_selection()
      doc():move_to(translate.start_of_line, dv())
      command.perform("doc:indent")
      doc():move_to(function() return line, col end, dv())
    end
  end,
})

keymap.add {
  ["modal+s"] = "modalediting:easy-motion",
  ["modal+ctrl+s"] = "doc:save",
  ["modal+ctrl+shift+p"] = "modalediting:command-finder",
  ["modal+ctrl+p"] = "modalediting:file-finder",
  ["modal+ctrl+o"] = "modalediting:open-file",
  ["modal+ctrl+n"] = "modalediting:new-doc",
  ["modal+alt+return"] = "core:toggle-fullscreen",

  ["modal+alt+shift+j"] = "root:split-left",
  ["modal+alt+shift+l"] = "root:split-right",
  ["modal+alt+shift+i"] = "root:split-up",
  ["modal+alt+shift+k"] = "root:split-down",
  ["modal+alt+j"] = "root:switch-to-left",
  ["modal+alt+l"] = "root:switch-to-right",
  ["modal+alt+i"] = "root:switch-to-up",
  ["modal+alt+k"] = "root:switch-to-down",

  ["modal+ctrl+w"] = "modalediting:close",
  ["modal+ctrl+l"] = "root:switch-to-next-tab",
  ["modal+ctrl+h"] = "root:switch-to-previous-tab",
  ["modal+alt+1"] = "root:switch-to-tab-1",
  ["modal+alt+2"] = "root:switch-to-tab-2",
  ["modal+alt+3"] = "root:switch-to-tab-3",
  ["modal+alt+4"] = "root:switch-to-tab-4",
  ["modal+alt+5"] = "root:switch-to-tab-5",
  ["modal+alt+6"] = "root:switch-to-tab-6",
  ["modal+alt+7"] = "root:switch-to-tab-7",
  ["modal+alt+8"] = "root:switch-to-tab-8",
  ["modal+alt+9"] = "root:switch-to-tab-9",

  ["modal+ctrl+f"] = "modalediting:find",
  ["modal+r"] = "modalediting:replace",
  ["modal+n"] = "find-replace:repeat-find",
  ["modal+shift+n"] = "find-replace:previous-find",
  ["modal+g"] = "modalediting:go-to-line",

  ["modal+k"] = "doc:move-to-previous-line",
  ["modal+j"] = "doc:move-to-next-line",
  ["modal+h"] = "doc:move-to-previous-char",
  ["modal+backspace"] = "doc:move-to-previous-char",
  ["modal+l"] = "doc:move-to-next-char",
  ["modal+w"] = "doc:move-to-next-word-boundary",
  ["modal+b"] = "doc:move-to-previous-word-boundary",
  ["modal+0"] = "doc:move-to-start-of-line",
  ["modal+shift+4"] = "modalediting:end-of-line",
  ["modal+["] = "doc:move-to-previous-start-of-block",
  ["modal+]"] = "doc:move-to-next-start-of-block",
  ["modal+ctrl+u"] = "doc:move-to-previous-page",
  ["modal+ctrl+d"] = "doc:move-to-next-page",
  ["modal+shift+k"] = "doc:select-to-previous-line",
  ["modal+shift+j"] = "doc:select-to-next-line",
  ["modal+shift+h"] = "doc:select-to-previous-char",
  ["modal+shift+backspace"] = "doc:select-to-previous-char",
  ["modal+shift+l"] = "doc:select-to-next-char",
  ["modal+shift+w"] = "doc:select-to-next-word-boundary",
  ["modal+shift+b"] = "doc:select-to-previous-word-boundary",
  ["modal+shift+0"] = "doc:select-to-start-of-line",
  ["modal+shift+["] = "doc:select-to-previous-start-of-block",
  ["modal+shift+]"] = "doc:select-to-next-start-of-block",

  ["modal+i"] = "modalediting:switch-to-insert-mode",
  ["modal+shift+i"] = "modalediting:insert-at-start-of-line",
  ["modal+a"] = "modalediting:insert-at-next-char",
  ["modal+shift+a"] = "modalediting:insert-at-end-of-line",
  ["modal+o"] = "modalediting:insert-on-newline-below",
  ["modal+shift+o"] = "modalediting:insert-on-newline-above",

  ["modal+ctrl+j"] = "doc:join-lines",
  ["modal+u"] = "doc:undo",
  ["modal+ctrl+r"] = "doc:redo",
  ["modal+tab"] = "modalediting:indent",
  ["modal+shift+tab"] = "doc:unindent",
  ["modal+shift+."] = "modalediting:indent",
  ["modal+shift+,"] = "doc:unindent",
  ["modal+p"] = "modalediting:paste",
  ["modal+y"] = "modalediting:copy",
  ["modal+d"] = "modalediting:delete-line",
  ["modal+e"] = "modalediting:delete-to-end-of-line",
  ["modal+q"] = "modalediting:delete-word",
  ["modal+x"] = "modalediting:delete-char",
  ["modal+ctrl+\\"] = "treeview:toggle",
}
