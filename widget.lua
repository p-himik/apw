-- Copyright 2013 mokasin
-- This file is part of the Awesome Pulseaudio Widget (APW).
--
-- APW is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- APW is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with APW. If not, see <http://www.gnu.org/licenses/>.

local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local beautiful = require("beautiful")
local pulseaudio = require("apw4.pulseaudio")

local pulsewidget = { mt = {} }
local p = pulseaudio:Create()

local function _update()
    if pulsewidget.progressbar then
        pulsewidget.progressbar:set_value(p.Volume)
        if p.Mute then
            pulsewidget.progressbar:set_color(pulsewidget.color_mute)
            pulsewidget.progressbar:set_background_color(pulsewidget.color_bg_mute)
        else
            pulsewidget.progressbar:set_color(pulsewidget.color)
            pulsewidget.progressbar:set_background_color(pulsewidget.color_bg)
        end
    end
    if pulsewidget.textbox then
        pulsewidget.textbox:set_text('' .. p.Perc)
    end
end

function pulsewidget.up(step)
    step = step or 0.05
    p:SetVolume(p.Volume + step)
    _update()
end

function pulsewidget.down(step)
    step = step or 0.05
    p:SetVolume(p.Volume - step)
    _update()
end

function pulsewidget.togglemute()
    p:ToggleMute()
    _update()
end

function pulsewidget.update()
    p:UpdateState()
    _update()
end

local tooltip

function pulsewidget:hide_tooltip()
    if tooltip ~= nil then
        naughty.destroy(tooltip)
        tooltip = nil
    end
end

function pulsewidget:show_tooltip()
    if tooltip then
        naughty.destroy(tooltip)
    end
    tooltip = naughty.notify({
        preset = fs_notification_preset,
        text = self.tooltip(),
        font = 'monospace',
        timeout = 0,
        screen = mouse.screen,
    })
end

local function _tooltip()
    local volumes = io.popen("pacmd list-sinks | grep -i 'volume: f' | awk '{print $5}'")
    local vol = {}
    for v in volumes:lines() do
        table.insert(vol, v)
    end
    volumes:close()

    local names = io.popen("pacmd list-sinks | grep -i 'device.description' | awk -F' = ' '{print $2}' | tr -d '\"'")
    local nm = {}
    for v in names:lines() do
        table.insert(nm, v)
    end
    names:close()

    local mutes = io.popen("pacmd list-sinks | grep -i 'muted' ")
    local mu = {}
    for v in mutes:lines() do
        table.insert(mu, v)
    end
    mutes:close()

    local max_nm_len = 0
    for _, nm in pairs(nm) do
        max_nm_len = math.max(max_nm_len, nm:len())
    end

    local result = ""
    for i, k in pairs(vol) do
        result = result .. string.format('%-' .. max_nm_len .. 's\t%s%s', nm[i], k, mu[i]) .. '\n'
    end
    return result:sub(1, -2)  -- removing the last \n
end

local function _attach_tooltip(widget)
    widget:connect_signal('mouse::enter', function() pulsewidget:show_tooltip() end)
    widget:connect_signal('mouse::leave', function() pulsewidget:hide_tooltip() end)
end

local function _assign_buttons(widget, buttons)
    local buttons_table = {}
    for button, fn in pairs(buttons) do
        buttons_table = awful.util.table.join(buttons_table, awful.button({}, button, fn))
    end
    widget:buttons(buttons_table)
end

-- initialize
local function new(args)
    -- Configuration variables
    args = args or {}

    pulsewidget.color = args.color or beautiful.apw_fg_color or "#888888" --'#698f1e' -- foreground color of progessbar'#1a4b5c'
    pulsewidget.color_bg = args.color_bg or beautiful.apw_bg_color or "#343434" --'#33450f' -- background color'#0F1419'--
    pulsewidget.color_mute = args.color_mute or beautiful.apw_mute_fg_color or '#be2a15' -- foreground color when muted
    pulsewidget.color_bg_mute = args.color_bg_mute or beautiful.apw_mute_bg_color or pulsewidget.color_bg --'#532a15' -- background color when muted
    local buttons = args.buttons or {
        [1] = pulsewidget.togglemute,
        [3] = function() awful.spawn.with_shell('pavucontrol') end,
        [4] = function () pulsewidget.up() end,
        [5] = function() pulsewidget.down() end
    }

    if args.tooltip == false then
        pulsewidget.tooltip = nil
    elseif args.tooltip == nil or args.tooltip == true then
        pulsewidget.tooltip = _tooltip
    else
        pulsewidget.tooltip = args.tooltip
    end

    if args.textbox == false then
        pulsewidget.textbox = nil
    elseif args.textbox == nil or args.textbox == true then
        pulsewidget.textbox = wibox.widget.textbox("vol")
    else
        pulsewidget.textbox = args.textbox
    end
    if pulsewidget.textbox then
        _assign_buttons(pulsewidget.textbox, buttons)
        if pulsewidget.tooltip then
            _attach_tooltip(pulsewidget.textbox)
        end
    end

    if args.progressbar == false then
        pulsewidget.progressbar = nil
    elseif args.progressbar == nil or args.progressbar == true then
        pulsewidget.progressbar = wibox.widget.progressbar()
    else
        pulsewidget.progressbar = args.progressbar
    end
    if pulsewidget.progressbar then
        _assign_buttons(pulsewidget.progressbar, buttons)
        if pulsewidget.tooltip then
            _attach_tooltip(pulsewidget.progressbar)
        end
    end

    pulsewidget.update()

    return {
        progressbar = wibox.widget {
            widget = pulsewidget.progressbar,
            max_value = 1,
            min_value = 0,
            forced_width = 100
        },
        textbox = pulsewidget.textbox,
        update = pulsewidget.update,
        up = pulsewidget.up,
        down = pulsewidget.down,
        togglemute = pulsewidget.togglemute
    }
end

function pulsewidget.mt:__call(...)
    return new(...)
end

return setmetatable(pulsewidget, pulsewidget.mt)
