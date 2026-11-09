vim.o.termguicolors = true
vim.g.colors_name = "matugen"

local c = {
	bg = "#{{colors.background.default.hex_stripped}}",
	fg = "#{{colors.on_background.default.hex_stripped}}",
	muted = "#{{colors.on_surface_variant.default.hex_stripped}}",
	line = "#{{colors.outline_variant.default.hex_stripped}}",
	surface = "#{{colors.surface_container.default.hex_stripped}}",
	surface_low = "#{{colors.surface_container_low.default.hex_stripped}}",
	surface_high = "#{{colors.surface_container_high.default.hex_stripped}}",
	primary = "#{{colors.primary.default.hex_stripped}}",
	primary_container = "#{{colors.primary_container.default.hex_stripped}}",
	on_primary_container = "#{{colors.on_primary_container.default.hex_stripped}}",
	secondary = "#{{colors.secondary.default.hex_stripped}}",
	tertiary = "#{{colors.tertiary.default.hex_stripped}}",
	tertiary_container = "#{{colors.tertiary_container.default.hex_stripped}}",
	error = "#{{colors.error.default.hex_stripped}}",
	ter_sat = {{colors.tertiary.default.saturation}},
	ter_light = {{colors.tertiary.default.lightness}},
	ter_cont_light = {{colors.tertiary_container.default.lightness}},
	err_light = {{colors.error.default.lightness}},
}

local function hsl(h, s, l)
	s, l = s / 100, l / 100
	local a = s * math.min(l, 1 - l)
	local function f(n)
		local k = (n + h / 30) % 12
		return l - a * math.max(math.min(k - 3, 9 - k, 1), -1)
	end
	return string.format("#%02x%02x%02x", f(0) * 255, f(8) * 255, f(4) * 255)
end

local git_green = hsl(140, c.ter_sat, c.ter_light)
local git_green_dim = hsl(140, c.ter_sat, math.min(c.ter_cont_light, 20))
local git_red = hsl(8, c.ter_sat, c.err_light)
local git_red_dim = hsl(8, c.ter_sat, math.min(c.ter_cont_light, 30))

local hi = function(name, spec)
	vim.api.nvim_set_hl(0, name, spec)
end

hi("Normal", { fg = c.fg, bg = c.bg })
hi("NormalFloat", { fg = c.fg, bg = c.surface })
hi("FloatBorder", { fg = c.line, bg = c.surface })
hi("FloatTitle", { fg = c.primary, bg = c.surface, bold = true })
hi("CursorLine", { bg = c.surface_low })
hi("CursorColumn", { bg = c.surface_low })
hi("LineNr", { fg = c.line })
hi("CursorLineNr", { fg = c.primary, bold = true })
hi("Visual", { bg = c.surface_high })
hi("Search", { bg = c.tertiary_container, fg = c.fg })
hi("IncSearch", { bg = c.primary, fg = c.bg })
hi("Substitute", { bg = c.primary_container, fg = c.on_primary_container })
hi("MatchParen", { bg = c.primary_container, fg = c.on_primary_container, bold = true })
hi("VertSplit", { fg = c.line })
hi("WinSeparator", { fg = c.line })
hi("NonText", { fg = c.line })
hi("Whitespace", { fg = c.line })
hi("Comment", { fg = c.muted, italic = true })
hi("Constant", { fg = c.tertiary })
hi("Number", { fg = c.tertiary })
hi("Boolean", { fg = c.tertiary })
hi("String", { fg = c.tertiary })
hi("Character", { fg = c.tertiary })
hi("Identifier", { fg = c.fg })
hi("Function", { fg = c.primary })
hi("Keyword", { fg = c.primary, bold = true })
hi("Statement", { fg = c.primary })
hi("Operator", { fg = c.muted })
hi("PreProc", { fg = c.secondary })
hi("Include", { fg = c.secondary })
hi("Type", { fg = c.secondary })
hi("Special", { fg = c.tertiary })
hi("Title", { fg = c.primary, bold = true })
hi("Directory", { fg = c.primary })
hi("Pmenu", { fg = c.fg, bg = c.surface })
hi("PmenuSel", { fg = c.on_primary_container, bg = c.primary_container, bold = true })
hi("PmenuSbar", { bg = c.surface })
hi("PmenuThumb", { bg = c.line })
hi("StatusLine", { fg = c.fg, bg = c.surface })
hi("StatusLineNC", { fg = c.muted, bg = c.surface_low })
hi("TabLine", { fg = c.muted, bg = c.surface_low })
hi("TabLineSel", { fg = c.fg, bg = c.surface_high })
hi("TabLineFill", { bg = c.bg })
hi("Folded", { fg = c.muted, bg = c.surface_low })
hi("FoldColumn", { fg = c.line })
hi("SignColumn", { bg = c.bg })
hi("ErrorMsg", { fg = c.fg, bg = c.error, bold = true })
hi("WarningMsg", { fg = c.tertiary })
hi("Error", { fg = c.error })
hi("Todo", { fg = c.primary, bold = true })
hi("Underlined", { fg = c.primary, underline = true })
hi("DiffAdd", { bg = git_green_dim, fg = git_green })
hi("DiffChange", { bg = c.surface_high })
hi("DiffDelete", { bg = git_red_dim, fg = git_red })
hi("DiffText", { bg = c.tertiary_container, fg = c.fg, bold = true })
hi("Added", { fg = git_green })
hi("Removed", { fg = git_red })
hi("Changed", { fg = c.tertiary })
hi("GitSignsAdd", { fg = git_green })
hi("GitSignsChange", { fg = c.tertiary })
hi("GitSignsDelete", { fg = git_red })
hi("@diff.plus", { link = "Added" })
hi("@diff.minus", { link = "Removed" })
hi("@diff.delta", { link = "Changed" })
hi("DiagnosticError", { fg = c.error })
hi("DiagnosticWarn", { fg = c.tertiary })
hi("DiagnosticInfo", { fg = c.secondary })
hi("DiagnosticHint", { fg = c.muted })
hi("DiagnosticUnderlineError", { undercurl = true, sp = c.error })
hi("DiagnosticUnderlineWarn", { undercurl = true, sp = c.tertiary })
hi("DiagnosticUnderlineInfo", { undercurl = true, sp = c.secondary })
hi("DiagnosticUnderlineHint", { undercurl = true, sp = c.muted })

hi("@comment", { link = "Comment" })
hi("@keyword", { link = "Keyword" })
hi("@function", { link = "Function" })
hi("@string", { link = "String" })
hi("@number", { link = "Number" })
hi("@type", { link = "Type" })
hi("@variable", { link = "Identifier" })
hi("@parameter", { fg = c.muted })
hi("@property", { fg = c.secondary })
hi("@operator", { link = "Operator" })
hi("@punctuation.bracket", { fg = c.muted })
hi("@constant", { link = "Constant" })
hi("Diagnostic", { link = "DiagnosticError" })

hi("TermCursor", { fg = c.bg, bg = c.fg })
hi("TermCursorNC", { bg = c.muted })

vim.g.terminal_color_0 = c.line
vim.g.terminal_color_8 = c.muted
vim.g.terminal_color_1 = c.error
vim.g.terminal_color_9 = c.error
vim.g.terminal_color_2 = git_green
vim.g.terminal_color_10 = git_green
vim.g.terminal_color_3 = c.tertiary
vim.g.terminal_color_11 = c.tertiary
vim.g.terminal_color_4 = c.secondary
vim.g.terminal_color_12 = c.secondary
vim.g.terminal_color_5 = c.tertiary
vim.g.terminal_color_13 = c.tertiary
vim.g.terminal_color_6 = c.primary
vim.g.terminal_color_14 = c.primary
vim.g.terminal_color_15 = c.fg
