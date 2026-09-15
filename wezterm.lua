local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()

-- ============================================================
-- Appearance
-- ============================================================

config.font_size = 17.0

config.colors = {
    foreground = '#C9D1D9',
    background = '#000000',

    cursor_bg = '#C9D1D9',
    cursor_fg = '#151D29',

    -- Soft blue-gray selection that fits the rest of the palette
    selection_bg = '#2D4A63',
    selection_fg = '#F0F6FC',

    ansi = {
        '#484F58', -- black
        '#C12F25', -- red
        '#41BE52', -- green
        '#F5B924', -- yellow
        '#58A6FF', -- blue
        '#7F5DB0', -- purple
        '#3D797D', -- cyan
        '#B1BAC4', -- white
    },

    brights = {
        '#6E7681', -- bright black
        '#DE5B52', -- bright red
        '#67CB74', -- bright green
        '#F0D76C', -- bright yellow
        '#79C0FF', -- bright blue
        '#c346c7', -- bright purple
        '#3EABB3', -- bright cyan
        '#F0F6FC', -- bright white
    },
}

-- Use macOS symbols when WezTerm displays keyboard shortcuts
config.ui_key_cap_rendering = 'AppleSymbols'

-- Tabs
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false


-- ============================================================
-- Command Palette
-- ============================================================

-- Add "Rename current tab" to the Command Palette
wezterm.on('augment-command-palette', function(window, pane)
    return {
        {
            brief = 'Rename current tab',

            action = act.PromptInputLine {
                description = 'New tab name:',

                action = wezterm.action_callback(function(window, pane, line)
                    if line then
                        window:active_tab():set_title(line)
                    end
                end),
            },
        },
    }
end)


-- ============================================================
-- Keyboard shortcuts
-- ============================================================

config.keys = {

    -- Rename current tab
    -- Ctrl + Shift + R
    {
        key = 'r',
        mods = 'CTRL|SHIFT',

        action = act.PromptInputLine {
            description = 'New tab name:',

            action = wezterm.action_callback(function(window, pane, line)
                if line then
                    window:active_tab():set_title(line)
                end
            end),
        },
    },

    -- Focus previous tab
    -- Cmd + Shift + Left
    {
        key = 'LeftArrow',
        mods = 'CMD|SHIFT',
        action = act.ActivateTabRelative(-1),
    },

    -- Focus next tab
    -- Cmd + Shift + Right
    {
        key = 'RightArrow',
        mods = 'CMD|SHIFT',
        action = act.ActivateTabRelative(1),
    },

    -- Move current tab to the left
    -- Ctrl + Shift + Left
    {
        key = 'LeftArrow',
        mods = 'CTRL|SHIFT',
        action = act.MoveTabRelative(-1),
    },

    -- Move current tab to the right
    -- Ctrl + Shift + Right
    {
        key = 'RightArrow',
        mods = 'CTRL|SHIFT',
        action = act.MoveTabRelative(1),
    },
}

-- ============================================================
-- Mouse shortcuts
-- ============================================================

config.mouse_bindings = {
    -- Right-click copies the current selection
    {
        event = { Down = { streak = 1, button = 'Right' } },
        mods = 'NONE',
        action = act.CompleteSelection 'ClipboardAndPrimarySelection',
    },
}

return config
