local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()

-- ============================================================
-- State
-- ============================================================

-- Colors assigned to individual tabs.
local tab_colors = {}


-- ============================================================
-- Appearance
-- ============================================================

config.font_size = 17.0

config.default_cursor_style = 'BlinkingBlock'
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

config.window_frame = {
    font_size = 14.0,
}

config.colors = {
    foreground = '#C9D1D9',
    background = '#000000',

    cursor_bg = '#C9D1D9',
    cursor_fg = '#151D29',
    cursor_border = '#C9D1D9',

    selection_bg = '#2D4A63',
    selection_fg = '#F0F6FC',

    ansi = {
        '#484F58',
        '#C12F25',
        '#41BE52',
        '#F5B924',
        '#58A6FF',
        '#7F5DB0',
        '#3D797D',
        '#B1BAC4',
    },

    brights = {
        '#6E7681',
        '#DE5B52',
        '#67CB74',
        '#F0D76C',
        '#79C0FF',
        '#c346c7',
        '#3EABB3',
        '#F0F6FC',
    },
}

config.ui_key_cap_rendering = 'AppleSymbols'

config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false


-- ============================================================
-- Tab colors
-- ============================================================

local tab_color_options = {
    { label = 'Default', id = 'default' },
    { label = 'Blue',    id = 'blue' },
    { label = 'Purple',  id = 'purple' },
    { label = 'Green',   id = 'green' },
    { label = 'Yellow',  id = 'yellow' },
    { label = 'Orange',  id = 'orange' },
    { label = 'Red',     id = 'red' },
    { label = 'Cyan',    id = 'cyan' },
    { label = 'Gray',    id = 'gray' },
}

local tab_color_values = {
    default = nil,

    -- Match the ANSI shell colors above.
    blue    = '#58A6FF',
    purple  = '#7F5DB0',
    green   = '#41BE52',
    yellow  = '#F5B924',
    orange  = '#D18616',
    red     = '#C12F25',
    cyan    = '#3D797D',
    gray    = '#6E7681',
}


-- ============================================================
-- Helpers
-- ============================================================

local function get_tab_title(tab)
    local title = tab.tab_title

    if not title or title == '' then
        title = tab.active_pane.title
    end

    -- Hide the zero-width character used by refresh_tab_bar().
    return title:gsub('\u{200B}', '')
end


local function refresh_tab_bar(tab)
    local current_title = tab:get_title()

    if not current_title or current_title == '' then
        current_title = tab:active_pane():get_title()
    end

    -- Add an invisible character to force WezTerm to recompute
    -- format-tab-title, then restore the original title.
    tab:set_title(current_title .. '\u{200B}')

    wezterm.time.call_after(0, function()
        tab:set_title(current_title)
    end)
end


local function set_tab_color(window, color_id)
    local tab = window:active_tab()
    local tab_id = tab:tab_id()

    tab_colors[tab_id] = tab_color_values[color_id]

    refresh_tab_bar(tab)
end


-- ============================================================
-- Rename tab action
-- ============================================================

local rename_tab_action = act.PromptInputLine {
    description = 'New tab name:',

    action = wezterm.action_callback(function(window, pane, line)
        if line then
            window:active_tab():set_title(line)
        end
    end),
}


-- ============================================================
-- Select tab color action
-- ============================================================

local select_tab_color_action = act.InputSelector {
    title = 'Select tab color',
    choices = tab_color_options,
    fuzzy = false,

    action = wezterm.action_callback(function(window, pane, id, label)
        if id then
            set_tab_color(window, id)
        end
    end),
}


-- ============================================================
-- Command Palette
-- ============================================================

wezterm.on('augment-command-palette', function(window, pane)
    return {
        {
            brief = 'Rename current tab',
            action = rename_tab_action,
        },

        {
            brief = 'Select tab color',
            action = select_tab_color_action,
        },
    }
end)


-- ============================================================
-- Tab appearance
-- ============================================================

wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
    local bg = tab_colors[tab.tab_id]

    if not bg then
        if tab.is_active then
            bg = '#21262D'
        elseif hover then
            bg = '#161B22'
        else
            bg = '#0D1117'
        end
    end

    local fg = tab.is_active and '#F0F6FC' or '#8B949E'
    local title = get_tab_title(tab)

    return {
        { Background = { Color = bg } },
        { Foreground = { Color = fg } },
        { Text = '  ' .. title .. '  ' },
    }
end)


-- ============================================================
-- Keyboard shortcuts
-- ============================================================

config.keys = {

    -- Rename current tab
    -- Cmd + Shift + R
    {
        key = 'r',
        mods = 'CMD|SHIFT',
        action = rename_tab_action,
    },

    -- Select tab color
    -- Cmd + Shift + E
    {
        key = 'e',
        mods = 'CMD|SHIFT',
        action = select_tab_color_action,
    },

    -- Open Command Palette
    -- Cmd + Shift + P
    {
        key = 'p',
        mods = 'CMD|SHIFT',
        action = act.ActivateCommandPalette,
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

    -- Right-click:
    --   With selection    -> copy and clear selection
    --   Without selection -> paste
    {
        event = { Down = { streak = 1, button = 'Right' } },
        mods = 'NONE',

        action = wezterm.action_callback(function(window, pane)
            local selection = window:get_selection_text_for_pane(pane)

            if selection ~= '' then
                window:perform_action(
                    act.CopyTo 'Clipboard',
                    pane
                )

                window:perform_action(
                    act.ClearSelection,
                    pane
                )
            else
                window:perform_action(
                    act.PasteFrom 'Clipboard',
                    pane
                )
            end
        end),
    },
}


return config
