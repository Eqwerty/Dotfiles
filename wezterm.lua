local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux

local config = wezterm.config_builder()

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

local TAB_COLORS = {
    { id = 'default', label = 'Default', fg = '#8B949E', active = '#59616B' },
    { id = 'blue', label = 'Blue', fg = '#58A6FF', active = '#3978B8' },
    { id = 'purple', label = 'Purple', fg = '#A371F7', active = '#704CA8' },
    { id = 'green', label = 'Green', fg = '#56D364', active = '#3F984A' },
    { id = 'yellow', label = 'Yellow', fg = '#F2CC60', active = '#B89542' },
    { id = 'orange', label = 'Orange', fg = '#F0883E', active = '#B85C24' },
    { id = 'red', label = 'Red', fg = '#F85149', active = '#A83B35' },
    { id = 'cyan', label = 'Cyan', fg = '#39C5CF', active = '#2D858C' },
    { id = 'pink', label = 'Pink', fg = '#EC4899', active = '#A8326B' },
}

local TAB_COLOR_BY_ID = {}
local tab_color_choices = {}

for _, color in ipairs(TAB_COLORS) do
    TAB_COLOR_BY_ID[color.id] = color
    table.insert(tab_color_choices, { id = color.id, label = color.label })
end

local function tab_color_key(tab_id)
    return 'tab_color_' .. tostring(tab_id)
end

local function refresh_tab_bar(pane)
    wezterm.GLOBAL.tab_bar_refresh = not wezterm.GLOBAL.tab_bar_refresh

    local value = wezterm.GLOBAL.tab_bar_refresh and 'MQ==' or 'MA=='

    pane:inject_output('\x1b]1337;SetUserVar=TAB_BAR_REFRESH=' .. value .. '\x07')
end

local function set_tab_color(tab, pane, color_id)
    if not TAB_COLOR_BY_ID[color_id] then
        return
    end

    wezterm.GLOBAL[tab_color_key(tab:tab_id())] =
        color_id == 'default' and '' or color_id

    refresh_tab_bar(pane)
end

local function get_tab_color(tab_id)
    local color_id = wezterm.GLOBAL[tab_color_key(tab_id)]

    if not color_id or color_id == '' then
        return nil
    end

    return color_id
end

local SESSION_DIR = wezterm.home_dir .. '/.local/state/wezterm'
local SESSION_FILE = SESSION_DIR .. '/session.json'

local function get_pane_cwd(pane)
    local cwd = pane:get_current_working_dir()

    if cwd and cwd.scheme == 'file' then
        return cwd.file_path
    end

    return nil
end

local SPLIT_AXES = {
    { direction = 'Right', start = 'left', size = 'width' },
    { direction = 'Bottom', start = 'top', size = 'height' },
}

local function extent(panes, axis)
    local first, last = math.huge, 0

    for _, p in ipairs(panes) do
        first = math.min(first, p[axis.start])
        last = math.max(last, p[axis.start] + p[axis.size])
    end

    return last - first
end

local function find_split(panes, axis)
    for _, candidate in ipairs(panes) do
        local cut = candidate[axis.start] + candidate[axis.size]
        local first, second = {}, {}
        local valid = true

        for _, p in ipairs(panes) do
            if p[axis.start] + p[axis.size] <= cut then
                table.insert(first, p)
            elseif p[axis.start] >= cut then
                table.insert(second, p)
            else
                valid = false
                break
            end
        end

        if valid and #first > 0 and #second > 0 then
            return first, second
        end
    end

    return nil
end

local function build_pane_tree(panes)
    if #panes == 1 then
        return {
            cwd = get_pane_cwd(panes[1].pane),
            active = panes[1].is_active or nil,
        }
    end

    for _, axis in ipairs(SPLIT_AXES) do
        local first, second = find_split(panes, axis)

        if first then
            return {
                direction = axis.direction,
                size = extent(second, axis) / extent(panes, axis),
                first = build_pane_tree(first),
                second = build_pane_tree(second),
            }
        end
    end

    for _, p in ipairs(panes) do
        if p.is_active then
            return build_pane_tree { p }
        end
    end

    return build_pane_tree { panes[1] }
end

local function get_pane_layout(tab)
    local was_zoomed = tab:set_zoomed(false)
    local layout = build_pane_tree(tab:panes_with_info())

    if was_zoomed then
        tab:set_zoomed(true)
    end

    return layout, was_zoomed
end

local function tab_uid_key(tab)
    return 'tab_uid_' .. tostring(tab:tab_id())
end

local function get_tab_uid(tab)
    return wezterm.GLOBAL[tab_uid_key(tab)]
end

local function set_tab_uid(tab, uid)
    wezterm.GLOBAL[tab_uid_key(tab)] = uid
end

local function ensure_tab_uid(tab)
    local uid = get_tab_uid(tab)

    if not uid then
        local counter = (wezterm.GLOBAL.tab_uid_counter or 0) + 1
        wezterm.GLOBAL.tab_uid_counter = counter

        uid = string.format('%x-%x', os.time(), counter)
        set_tab_uid(tab, uid)
    end

    return uid
end

local function save_session()
    local session = {
        version = 1,
        windows = {},
    }
    local tab_count = 0

    for _, window in ipairs(mux.all_windows()) do
        local window_info = { tabs = {} }
        local active_tab_id = window:active_tab():tab_id()

        for index, tab in ipairs(window:tabs()) do
            local pane = tab:active_pane()
            local layout, zoomed = get_pane_layout(tab)

            table.insert(window_info.tabs, {
                title = tab:get_title(),
                cwd = pane and get_pane_cwd(pane) or nil,
                color = get_tab_color(tab:tab_id()),
                id = ensure_tab_uid(tab),
                panes = layout,
                zoomed = zoomed or nil,
            })

            if tab:tab_id() == active_tab_id then
                window_info.active_tab = index
            end

            tab_count = tab_count + 1
        end

        table.insert(session.windows, window_info)
    end

    wezterm.run_child_process { 'mkdir', '-p', SESSION_DIR }

    local tmp_file = SESSION_FILE .. '.tmp'
    local file, err = io.open(tmp_file, 'w')

    if not file then
        return nil, tostring(err)
    end

    local written, write_err = file:write(wezterm.json_encode(session))
    file:close()

    if not written then
        os.remove(tmp_file)
        return nil, tostring(write_err)
    end

    local renamed, rename_err = os.rename(tmp_file, SESSION_FILE)

    if not renamed then
        return nil, tostring(rename_err)
    end

    return tab_count
end

local function read_session()
    local file = io.open(SESSION_FILE, 'r')

    if not file then
        return nil
    end

    local contents = file:read('*a')
    file:close()

    local ok, session = pcall(wezterm.json_parse, contents)

    if not ok or type(session) ~= 'table' then
        return nil
    end

    return session
end

local function is_directory(path)
    return pcall(wezterm.read_dir, path)
end

local function resolve_cwd(cwd)
    if not cwd or cwd == '' then
        return nil, nil
    end

    if not is_directory(cwd) then
        return wezterm.home_dir, cwd
    end

    return cwd, nil
end

local function warn_missing_folder(pane, missing_cwd)
    pane:inject_output(
        '\r\n\x1b[33mwezterm-session: folder no longer exists:\r\n  '
            .. missing_cwd
            .. '\x1b[0m\r\n\r\n'
    )
end

local function first_leaf(node)
    while node.direction do
        node = node.first
    end

    return node
end

local function pane_leaves(node, leaves)
    leaves = leaves or {}

    if node.direction then
        pane_leaves(node.first, leaves)
        pane_leaves(node.second, leaves)
    else
        table.insert(leaves, node)
    end

    return leaves
end

local function restore_panes(node, pane)
    if not node.direction then
        return node.active and pane or nil
    end

    local cwd, missing_cwd = resolve_cwd(first_leaf(node.second).cwd)
    local new_pane = pane:split {
        direction = node.direction,
        size = node.size,
        cwd = cwd,
    }

    if missing_cwd then
        warn_missing_folder(new_pane, missing_cwd)
    end

    local active_first = restore_panes(node.first, pane)
    local active_second = restore_panes(node.second, new_pane)

    return active_first or active_second
end

local function restore_tab(tab, pane, saved_tab, layout, missing_cwd)
    if saved_tab.title and saved_tab.title ~= '' then
        tab:set_title(saved_tab.title)
    end

    if saved_tab.color and saved_tab.color ~= '' then
        set_tab_color(tab, pane, saved_tab.color)
    end

    if missing_cwd then
        warn_missing_folder(pane, missing_cwd)
    end

    local active_pane = restore_panes(layout, pane)

    if active_pane then
        active_pane:activate()
    end

    if saved_tab.zoomed then
        tab:set_zoomed(true)
    end
end

local function tab_key(title, color, cwd)
    return (title or '') .. '\0' .. (color or '') .. '\0' .. (cwd or '')
end

local function open_tabs_by_key()
    local tabs_by_key = {}

    for _, window in ipairs(mux.all_windows()) do
        for _, tab in ipairs(window:tabs()) do
            local pane = tab:active_pane()
            local key = tab_key(
                tab:get_title(),
                get_tab_color(tab:tab_id()),
                pane and get_pane_cwd(pane) or nil
            )

            tabs_by_key[key] = tabs_by_key[key] or {}
            table.insert(tabs_by_key[key], tab)
        end
    end

    return tabs_by_key
end

local function saved_tab_key(saved_tab)
    return tab_key(
        saved_tab.title,
        saved_tab.color,
        (resolve_cwd(saved_tab.cwd))
    )
end

local function open_tabs_by_uid()
    local tabs_by_uid = {}

    for _, window in ipairs(mux.all_windows()) do
        for _, tab in ipairs(window:tabs()) do
            local uid = get_tab_uid(tab)

            if uid then
                tabs_by_uid[uid] = tab
            end
        end
    end

    return tabs_by_uid
end

local function open_tabs()
    return { by_uid = open_tabs_by_uid(), by_key = open_tabs_by_key() }
end

local function find_open_tab(saved_tab, open)
    if saved_tab.id then
        return open.by_uid[saved_tab.id]
    end

    local matches = open.by_key[saved_tab_key(saved_tab)]

    if matches and #matches > 0 then
        return table.remove(matches, 1)
    end

    return nil
end

local function load_session(gui_window)
    local session = read_session()

    if not session or not session.windows then
        return nil
    end

    local open = open_tabs()
    local tab_count = 0

    for window_index, saved_window in ipairs(session.windows) do
        local mux_window = nil
        local window_tabs = {}

        if window_index == 1 then
            mux_window = gui_window:mux_window()
        end

        for index, saved_tab in ipairs(saved_window.tabs or {}) do
            local layout = saved_tab.panes or { cwd = saved_tab.cwd }
            local open_tab = find_open_tab(saved_tab, open)

            if open_tab then
                window_tabs[index] = open_tab
            else
                local cwd, missing_cwd = resolve_cwd(first_leaf(layout).cwd)
                local options = { cwd = cwd }
                local tab, pane

                if mux_window then
                    tab, pane = mux_window:spawn_tab(options)
                else
                    tab, pane, mux_window = mux.spawn_window(options)
                end

                restore_tab(tab, pane, saved_tab, layout, missing_cwd)

                if saved_tab.id then
                    set_tab_uid(tab, saved_tab.id)
                end
                window_tabs[index] = tab
                tab_count = tab_count + 1
            end
        end

        local active_tab = window_tabs[saved_window.active_tab]

        if active_tab then
            active_tab:activate()
        end
    end

    return tab_count
end

local function unopened_saved_tabs()
    local session = read_session()
    local unopened = {}

    if not session or not session.windows then
        return unopened
    end

    local open = open_tabs()

    for _, saved_window in ipairs(session.windows) do
        for _, saved_tab in ipairs(saved_window.tabs or {}) do
            if not find_open_tab(saved_tab, open) then
                table.insert(unopened, saved_tab)
            end
        end
    end

    return unopened
end

local function saved_tab_label(saved_tab)
    if saved_tab.title and saved_tab.title ~= '' then
        return saved_tab.title
    end

    return (saved_tab.cwd or ''):match('([^/]+)/?$') or '~'
end

local function show_status(window, text, color)
    local id = (wezterm.GLOBAL.session_status_id or 0) + 1
    wezterm.GLOBAL.session_status_id = id

    window:set_right_status(wezterm.format {
        { Foreground = { Color = color } },
        { Text = ' ' .. text .. '  ' },
    })

    wezterm.time.call_after(3, function()
        if wezterm.GLOBAL.session_status_id == id then
            window:set_right_status('')
        end
    end)
end

local function do_save(window)
    local tab_count, err = save_session()

    if tab_count then
        show_status(
            window,
            '✓ Session saved (' .. tab_count .. ' tabs)',
            TAB_COLOR_BY_ID.green.fg
        )
    else
        wezterm.log_error('Could not save session: ' .. err)
        show_status(window, '✗ Could not save session', TAB_COLOR_BY_ID.red.fg)
    end
end

local save_session_action = wezterm.action_callback(function(window, pane)
    local unopened = unopened_saved_tabs()

    if #unopened == 0 then
        do_save(window)
        return
    end

    local home_pattern = '^' .. wezterm.home_dir:gsub('%p', '%%%0')
    local name_width = 0

    for _, saved_tab in ipairs(unopened) do
        name_width = math.max(name_width, #saved_tab_label(saved_tab))
    end

    local lines = {
        { Foreground = { Color = TAB_COLOR_BY_ID.yellow.fg } },
        {
            Text = #unopened
                .. ' saved tab(s) are not open and will be lost:\n\n',
        },
    }

    for _, saved_tab in ipairs(unopened) do
        local color = (TAB_COLOR_BY_ID[saved_tab.color] or TAB_COLOR_BY_ID.default).fg
        local name = saved_tab_label(saved_tab)
        local folders = {}

        for _, leaf in ipairs(pane_leaves(saved_tab.panes or { cwd = saved_tab.cwd })) do
            table.insert(folders, ((leaf.cwd or '~'):gsub(home_pattern, '~')))
        end

        table.insert(lines, { Foreground = { Color = color } })
        table.insert(lines, { Text = '  ● ' })
        table.insert(lines, { Foreground = { Color = '#F0F6FC' } })
        table.insert(lines, { Text = name .. string.rep(' ', name_width - #name) })
        table.insert(lines, { Foreground = { Color = TAB_COLOR_BY_ID.default.fg } })

        for index, folder in ipairs(folders) do
            if index > 1 then
                table.insert(lines, { Text = string.rep(' ', name_width + 4) })
            end

            table.insert(lines, { Text = '  ' .. folder .. '\n' })
        end
    end

    table.insert(lines, { Foreground = { Color = TAB_COLOR_BY_ID.default.fg } })
    table.insert(lines, {
        Text = '\nType y and press Enter to save anyway; Enter or Esc cancels.',
    })

    window:perform_action(
        act.PromptInputLine {
            description = wezterm.format(lines),

            action = wezterm.action_callback(function(window, pane, line)
                if line and line:lower():match('^%s*y') then
                    do_save(window)
                else
                    show_status(window, 'Save cancelled', TAB_COLOR_BY_ID.default.fg)
                end
            end),
        },
        pane
    )
end)

local load_session_action = wezterm.action_callback(function(window, pane)
    load_session(window)
end)

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
    choices = tab_color_choices,
    fuzzy = false,

    action = wezterm.action_callback(function(window, pane, id, label)
        if id then
            set_tab_color(window:active_tab(), pane, id)
        end
    end),
}

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
        {
            brief = 'Save session',
            action = save_session_action,
        },
        {
            brief = 'Load session',
            action = load_session_action,
        },
    }
end)

wezterm.on(
    'format-tab-title',
    function(tab, tabs, panes, config, hover, max_width)
        local color_id = get_tab_color(tab.tab_id)
        local color = TAB_COLOR_BY_ID[color_id] or TAB_COLOR_BY_ID.default

        local bg
        local fg

        if tab.is_active then
            bg = color.active
            fg = '#FFFFFF'
        elseif color_id and TAB_COLOR_BY_ID[color_id] then
            bg = '#0D1117'
            fg = color.fg
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

config.keys = {
    {
        key = 'Backspace',
        mods = 'OPT',
        action = act.SendString '\x1b\x7f',
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
        key = 'UpArrow',
        mods = 'CMD|SHIFT',
        action = act.MoveTabRelative(-1),
    },
    {
        key = 'DownArrow',
        mods = 'CMD|SHIFT',
        action = act.MoveTabRelative(1),
    },
    {
        key = 'd',
        mods = 'CMD',
        action = act.SplitHorizontal { domain = 'CurrentPaneDomain' },
    },
    {
        key = 'd',
        mods = 'CMD|SHIFT',
        action = act.SplitVertical { domain = 'CurrentPaneDomain' },
    },
    {
        key = 'LeftArrow',
        mods = 'CTRL|CMD|SHIFT',
        action = act.AdjustPaneSize { 'Left', 5 },
    },
    {
        key = 'RightArrow',
        mods = 'CTRL|CMD|SHIFT',
        action = act.AdjustPaneSize { 'Right', 5 },
    },
    {
        key = 'UpArrow',
        mods = 'CTRL|CMD|SHIFT',
        action = act.AdjustPaneSize { 'Up', 5 },
    },
    {
        key = 'DownArrow',
        mods = 'CTRL|CMD|SHIFT',
        action = act.AdjustPaneSize { 'Down', 5 },
    },
    {
        key = 'w',
        mods = 'CMD',
        action = act.CloseCurrentPane { confirm = true },
    },
    {
        key = 's',
        mods = 'CMD',
        action = save_session_action,
    },
    {
        key = 'l',
        mods = 'CMD',
        action = load_session_action,
    },
}

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

wezterm.on('gui-startup', function(cmd)
    local _, _, window = wezterm.mux.spawn_window(cmd or {})
    window:gui_window():maximize()
end)

return config

