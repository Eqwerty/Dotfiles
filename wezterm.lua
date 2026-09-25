local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()

-- Appearance

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


-- Tab colors

local tab_color_options = {
    { label = 'Default', id = 'default' },
    { label = 'Blue', id = 'blue' },
    { label = 'Purple', id = 'purple' },
    { label = 'Green', id = 'green' },
    { label = 'Yellow', id = 'yellow' },
    { label = 'Orange', id = 'orange' },
    { label = 'Red', id = 'red' },
    { label = 'Cyan', id = 'cyan' },
    { label = 'Pink', id = 'pink' },
}

local tab_color_values = {
    default = '#8B949E',
    blue = '#58A6FF',
    purple = '#A371F7',
    green = '#56D364',
    yellow = '#F2CC60',
    orange = '#DBAB79',
    red = '#F85149',
    cyan = '#39C5CF',
    pink = '#EC4899',
}

local tab_active_color_values = {
    default = '#59616B',
    blue = '#3978B8',
    purple = '#704CA8',
    green = '#3F984A',
    yellow = '#B89542',
    orange = '#A66B3A',
    red = '#A83B35',
    cyan = '#2D858C',
    pink = '#A8326B',
}


-- Tab color persistence

local TAB_COLOR_USER_VAR = 'WEZTERM_TAB_COLOR'

local tab_color_encoded_values = {
    default = '',
    blue = 'Ymx1ZQ==',
    purple = 'cHVycGxl',
    green = 'Z3JlZW4=',
    yellow = 'eWVsbG93',
    orange = 'b3Jhbmdl',
    red = 'cmVk',
    cyan = 'Y3lhbg==',
    pink = 'cGluaw==',
}

local function set_tab_color(window, pane, color_id)
    local encoded_value = tab_color_encoded_values[color_id]

    if encoded_value == nil then
        return
    end

    pane:inject_output(
        '\x1b]1337;SetUserVar='
            .. TAB_COLOR_USER_VAR
            .. '='
            .. encoded_value
            .. '\x07'
    )
end

local function get_tab_color(tab)
    local user_vars = tab.active_pane.user_vars

    if not user_vars then
        return nil
    end

    local color_id = user_vars[TAB_COLOR_USER_VAR]

    if not color_id or color_id == '' then
        return nil
    end

    return color_id
end


-- Tab actions

local rename_tab_action = act.PromptInputLine {
    description = 'New tab name:',

    action = wezterm.action_callback(function(window, pane, line)
        if line then
            window:active_tab():set_title(line)
        end
    end),
}

local select_tab_color_action = act.InputSelector {
    title = 'Select tab color',
    choices = tab_color_options,
    fuzzy = false,

    action = wezterm.action_callback(function(window, pane, id, label)
        if id then
            set_tab_color(window, pane, id)
        end
    end),
}


-- Command palette

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


-- Tab appearance

wezterm.on(
    'format-tab-title',
    function(tab, tabs, panes, config, hover, max_width)
        local color_id = get_tab_color(tab)

        local bg
        local fg

        if tab.is_active then
            bg = tab_active_color_values[color_id] or '#59616B'
            fg = '#FFFFFF'
        elseif color_id and tab_color_values[color_id] then
            bg = '#0D1117'
            fg = tab_color_values[color_id]
        elseif hover then
            bg = '#21262D'
            fg = '#C9D1D9'
        else
            bg = '#21262D'
            fg = '#8B949E'
        end

        local title = tab.tab_title

        if not title or title == '' then
            title = tab.active_pane.title
        end

        return {
            { Background = { Color = bg } },
            { Foreground = { Color = fg } },
            { Text = '  ' .. title .. '  ' },
        }
    end
)


-- Keyboard shortcuts

config.keys = {
    -- macOS-style "delete previous word".
    -- WezTerm sends Ctrl+W to Vim, which deletes the previous word
    -- while staying in Insert mode.
    {
        key = 'Backspace',
        mods = 'OPT',
        action = act.SendKey {
            key = 'w',
            mods = 'CTRL',
        },
    },

    {
        key = 'r',
        mods = 'CMD|SHIFT',
        action = rename_tab_action,
    },
    {
        key = 'e',
        mods = 'CMD|SHIFT',
        action = select_tab_color_action,
    },
    {
        key = 'p',
        mods = 'CMD|SHIFT',
        action = act.ActivateCommandPalette,
    },
    {
        key = 'LeftArrow',
        mods = 'CMD|SHIFT',
        action = act.ActivateTabRelative(-1),
    },
    {
        key = 'RightArrow',
        mods = 'CMD|SHIFT',
        action = act.ActivateTabRelative(1),
    },
    {
        key = 'LeftArrow',
        mods = 'CTRL|SHIFT',
        action = act.MoveTabRelative(-1),
    },
    {
        key = 'RightArrow',
        mods = 'CTRL|SHIFT',
        action = act.MoveTabRelative(1),
    },
}


-- Mouse shortcuts

config.mouse_bindings = {
    {
        event = {
            Down = {
                streak = 1,
                button = 'Right',
            },
        },
        mods = 'NONE',

        action = wezterm.action_callback(function(window, pane)
            local selection = window:get_selection_text_for_pane(pane)

            if selection ~= '' then
                window:perform_action(act.CopyTo 'Clipboard', pane)
                window:perform_action(act.ClearSelection, pane)
            else
                window:perform_action(act.PasteFrom 'Clipboard', pane)
            end
        end),
    },
}


-- Start maximized on macOS

wezterm.on('gui-startup', function(cmd)
    local _, _, window = wezterm.mux.spawn_window(cmd or {})
    window:gui_window():maximize()
end)


return config
