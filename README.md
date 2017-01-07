Awesome Pulseaudio Widget
=========================

Fork of [APW](http://github.com/seniorivn/apw) with percentages ![](http://i.imgur.com/5VR2kFr.png)
and support for Awesome 4.0

Awesome Pulseaudio Widget (APW) is a little widget for
[Awesome WM](http://awesome.naquadah.org/), using the awful progressbar widget,
to display default's sink volume and control Pulseaudio.

It's compatible with Awesome 4.0.

Get it
------

```sh
cd $XDG_CONFIG_HOME/awesome/
git clone https://github.com/p-himik/apw4.git
```

Use it
------

Just put these line to the appropriate places in
*$XDG_CONFIG_HOME/awesome/rc.lua*.

```lua
-- Load the widget.
local APW = require("apw4/widget")

-- This must go after beautiful.init(...)
local apw = APW()

-- The layout of widgets has to be configured in your rc.lua
-- Somewhere where you create your wibars
{ -- Right widgets on the top wibar
    layout = wibox.layout.fixed.horizontal,
    wibox.widget {
        forced_width = 40,
        widget = apw.progressbar
    },
    mykeyboardlayout,
    wibox.widget.systray(),
    mytextclock,
    s.mylayoutbox,
},

-- Configure the hotkeys.
awful.key({ }, "XF86AudioRaiseVolume",  apw.up),
awful.key({ }, "XF86AudioLowerVolume",  apw.down),
awful.key({ }, "XF86AudioMute",         apw.togglemute),

```

Customize it
------------

### Theme

*Important:* `beautiful.init` must be called before you call APW() for
theming to work.

Just add these variables to your Beautiful theme.lua file and set them
to whatever colors or gradients you wish:

```lua
--{{{ APW
theme.apw_fg_color = {type = 'linear', from = {0, 0}, to={40,0},
	stops={{0, "#CC8888"}, {.4, "#88CC88"}, {.8, "#8888CC"}}}
theme.apw_bg_color = "#333333"
theme.apw_mute_fg_color = "#CC9393"
theme.apw_mute_bg_color = "#663333"
--}}}

```

Mixer
----

Right-clicking the widget launches a mixer.  By default this is `pavucontrol`,
but you can customize it by providing an optional `buttons` argument to APW:

```lua
local APW = require("apw/widget")
local apw = APW{
    buttons = {
        [1] = pulsewidget.togglemute,
        [3] = function() awful.spawn.with_shell('pavucontrol') end,
        [4] = function () pulsewidget.up() end,
        [5] = function() pulsewidget.down() end
    }
}
```

### Tip
You could update the widget periodically if you'd like. In case, the volume is
changed from somewhere else.

```lua
apw_timer = timer({ timeout = 0.5 }) -- set update interval in s
apw_timer:connect_signal("timeout", apw.update)
apw_timer:start()
```

Contributing
------------
Just fork it and file a pull request. I'll look into it.

