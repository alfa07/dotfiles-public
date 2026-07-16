local wezterm = require("wezterm")
local act = wezterm.action
local os = require("os")

local function active_tab(window)
	for _, t in pairs(window:tabs_with_info()) do
		if t.is_active then
			return t.tab
		end
	end
end

local function find_window_direction(window, direction)
	local wx = {}
	local p0 = window:get_position()
	local sz0 = window:get_dimensions()
	p0.x = p0.x + sz0.pixel_width / 2
	p0.y = p0.y + sz0.pixel_height / 2
	for idx, w in pairs(wezterm.mux.all_windows()) do
		if w:window_id() == window:window_id() then
			goto next
		end
		local x = 0
		local x0 = 0
		local y = 0
		local y0 = 0
		local p = w:gui_window():get_position()
		local sz = w:gui_window():get_dimensions()
		p.x = p.x + sz.pixel_width / 2
		p.y = p.y + sz.pixel_height / 2
		if direction == "Left" or direction == "Right" then
			x = p.x
			x0 = p0.x
			y = p.y
			y0 = p0.y
		elseif direction == "Up" or direction == "Down" then
			x = p.y
			x0 = p0.y
			y = p.x
			y0 = p0.x
		end
		print(string.format("win[%d] coords x0=%d x=%d y=%d y0=%d", idx, x, x0, y, y0))
		if (direction == "Left" or direction == "Up") and x <= x0 then
			wx[#wx + 1] = { x0 - x + math.abs(y - y0) * 2, w }
		elseif (direction == "Right" or direction == "Down") and x >= x0 then
			wx[#wx + 1] = { x - x0 + math.abs(y - y0) * 2, w }
		end
		::next::
	end
	table.sort(wx, function(a, b)
		return a[1] < b[1]
	end)
	if #wx > 0 then
		return wx[1][2]
	end
	return nil
end

local function get_file_name(file)
	return file:match("[^/]*$")
end

-- Nvim navigator implementation
-- The usage of NVIM_LISTEN_ADDRESS is depricated see https://github.com/neovim/neovim/pull/11009
-- see https://github.com/wez/wezterm/discussions/995
-- see https://github.com/aca/wezterm.nvim
local move_around = function(window, pane, direction_wez, direction_nvim)
	local vars = pane:get_user_vars()
	print(vars)
	local socket = vars["NVIM_LISTEN_ADDRESS"]
	local cmd = "env NVIM_LISTEN_ADDRESS=" .. socket .. " wezterm.nvim.navigator " .. direction_nvim
	print(cmd)
	local result = os.execute(cmd)
	if result then
		print("vim window")
		window:perform_action(wezterm.action({ SendString = "\x17" .. direction_nvim }), pane)
	else
		local t = pane:tab()
		if not t then
			-- Debug panes do not have tabs :(
			t = active_tab(window:mux_window())
		end
		if t:get_pane_direction(direction_wez) then
			print("wez pane")
			window:perform_action(wezterm.action({ ActivatePaneDirection = direction_wez }), pane)
		else
			print("wez window")
			local w = find_window_direction(window, direction_wez)
			if w then
				print("wez window focus")
				w:gui_window():focus()
			else
				print("unable to find window")
			end
		end
	end
end

wezterm.on("move-left", function(window, pane)
	move_around(window, pane, "Left", "h")
end)

wezterm.on("move-right", function(window, pane)
	move_around(window, pane, "Right", "l")
end)

wezterm.on("move-up", function(window, pane)
	move_around(window, pane, "Up", "k")
end)

wezterm.on("move-down", function(window, pane)
	move_around(window, pane, "Down", "j")
end)

local function window_index_from_tab_info(tab_info)
	for idx, window in pairs(wezterm.gui.gui_windows()) do
		if tab_info.window_id == window:window_id() then
			return idx -- lua indices are 1-based, but we want 0-based
		end
	end
	return 0 -- didn't find it, guess?
end

wezterm.on("format-window-title", function(tab, pane, tabs, panes, config)
	local index = window_index_from_tab_info(tab)
	return "[" .. index .. "] " .. tab.active_pane.title
end)

local function file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

wezterm.on("open-uri", function(window, pane, uri)
	print(uri)
	local start, match_end = uri:find("edit:")
	if start == 1 then
		local file_and_loc = uri:sub(match_end + 1)
		local i1 = file_and_loc:find(":")
		local file = file_and_loc:sub(1, i1 - 1)
		local loc = file_and_loc:sub(i1 + 1, file_and_loc:len())
		local i2 = loc:find(":")
		local line = loc:sub(1, i2 - 1)
		local s, e = file:find("go/src/github.com/example/project/.cargo/")
		if s == 1 then
			file = "$HOME/.cargo/" .. file:sub(e + 1)
		else
			local s, e = file:find("go/src/github.com/example/")
			if s == 1 then
				file = "$HOME/dd/" .. file:sub(e + 1)
				file = file:gsub("x86_64-unknown-linux-gnu/", "")
			end
		end
		local file_dd = "$HOME/dev/project/crates/" .. file
		if file_exists(file_dd) then
			file = file_dd
		end
		print(file, line)

		for _, p in ipairs(pane:tab():panes()) do
			print("scanning", p:pane_id())
			if p:pane_id() ~= pane:pane_id() then
				print("sending keys")
				p:send_text("\x1b")
				p:send_text(string.format(":e +%s %s\n", line, file))
				p:send_text("zz")
				return false
			end
		end
		return false
	end
end)

-- wezterm.on('update-status', function(window, pane)
--   local overrides = window:get_config_overrides() or {}
--   if window:is_focused() then
--     overrides.color_scheme = 'nordfox'
--   else
--     overrides.color_scheme = 'nightfox'
--   end
--   window:set_config_overrides(overrides)
-- end)

return {
	-- font = wezterm.font 'Fira Code',
	-- You can specify some parameters to influence the font selection;
	-- for example, this selects a Bold, Italic font variant.
	enable_tab_bar = true,
	term = "xterm-256color",
	-- font = wezterm.font('JetBrainsMono Nerd Font', { weight = 'Regular' }),
	font = wezterm.font("Iosevka Nerd Font", { weight = "Regular" }),
	font_size = 16,
	leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 },
	audible_bell = "Disabled",
	keys = {
		{
			key = "s",
			mods = "LEADER",
			action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
		},
		{
			key = "v",
			mods = "LEADER",
			action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
		},
		{
			key = "g",
			mods = "LEADER",
			action = wezterm.action.SpawnCommandInNewTab({
				args = { "lazygit" },
			}),
		},
		{
			key = "x",
			mods = "LEADER",
			action = wezterm.action.CloseCurrentPane({
				confirm = false,
			}),
		},
		{
			key = "k",
			mods = "LEADER",
			action = wezterm.action.CloseCurrentTab({
				confirm = true,
			}),
		},
		{
			key = "c",
			mods = "LEADER",
			action = act.SpawnTab("CurrentPaneDomain"),
		},
		{
			key = "r",
			mods = "CMD|SHIFT",
			action = wezterm.action.ReloadConfiguration,
		},
		{
			key = "1",
			mods = "CMD|ALT",
			action = wezterm.action.ActivateWindow(0),
		},
		{
			key = "2",
			mods = "CMD|ALT",
			action = wezterm.action.ActivateWindow(1),
		},
		{
			key = "3",
			mods = "CMD|ALT",
			action = wezterm.action.ActivateWindow(2),
		},
		{
			key = "4",
			mods = "CMD|ALT",
			action = wezterm.action.ActivateWindow(3),
		},
		{
			key = "5",
			mods = "CMD|ALT",
			action = wezterm.action.ActivateWindow(4),
		},
		{
			key = "1",
			mods = "LEADER",
			action = wezterm.action.ActivateTab(0),
		},
		{
			key = "2",
			mods = "LEADER",
			action = wezterm.action.ActivateTab(1),
		},
		{
			key = "3",
			mods = "LEADER",
			action = wezterm.action.ActivateTab(2),
		},
		{
			key = "4",
			mods = "LEADER",
			action = wezterm.action.ActivateTab(3),
		},
		{
			key = "5",
			mods = "LEADER",
			action = wezterm.action.ActivateTab(4),
		},
		{
			key = "6",
			mods = "LEADER",
			action = wezterm.action.ActivateTab(5),
		},
		{
			key = "7",
			mods = "LEADER",
			action = wezterm.action.ActivateTab(6),
		},
		{
			key = "8",
			mods = "LEADER",
			action = wezterm.action.ActivateTab(7),
		},
		{
			key = "9",
			mods = "LEADER",
			action = wezterm.action.ActivateTab(8),
		},
		{
			key = "0",
			mods = "LEADER",
			action = wezterm.action.ActivateTab(9),
		},
		{ key = "h", mods = "CTRL", action = wezterm.action({ EmitEvent = "move-left" }) },
		{ key = "l", mods = "CTRL", action = wezterm.action({ EmitEvent = "move-right" }) },
		{ key = "k", mods = "CTRL", action = wezterm.action({ EmitEvent = "move-up" }) },
		{ key = "j", mods = "CTRL", action = wezterm.action({ EmitEvent = "move-down" }) },
		{
			key = "w",
			mods = "CTRL|SHIFT|ALT",
			action = act.CloseCurrentPane({ confirm = false }),
		},
	},
	color_scheme = "Builtin Solarized Light",
	-- window_decorations = "TITLE",
	hyperlink_rules = {
		-- Linkify things that look like URLs and the host has a TLD name.
		-- Compiled-in default. Used if you don't specify any hyperlink_rules.
		{
			regex = "\\S*:\\d+:\\d+\\b",
			format = "edit:$0",
		},
		-- Make task numbers clickable
		-- The first matched regex group is captured in $1.
		{
			regex = [[\b[tT](\d+)\b]],
			format = "https://example.com/tasks/?t=$1",
		},
		-- Linkify things that look like URLs and the host has a TLD name.
		-- Compiled-in default. Used if you don't specify any hyperlink_rules.
		{
			regex = "\\b\\w+://[\\w.-]+\\.[a-z]{2,15}\\S*\\b",
			format = "$0",
		},
		-- linkify email addresses
		-- Compiled-in default. Used if you don't specify any hyperlink_rules.
		{
			regex = [[\b\w+@[\w-]+(\.[\w-]+)+\b]],
			format = "mailto:$0",
		},

		-- file:// URI
		-- Compiled-in default. Used if you don't specify any hyperlink_rules.
		{
			regex = [[\bfile://\S*\b]],
			format = "$0",
		},

		-- Linkify things that look like URLs with numeric addresses as hosts.
		-- E.g. http://127.0.0.1:8000 for a local development server,
		-- or http://192.168.1.1 for the web interface of many routers.
		{
			regex = [[\b\w+://(?:[\d]{1,3}\.){3}[\d]{1,3}\S*\b]],
			format = "$0",
		},
	},
}
