# arca_interface

Replaces GTA's Esc / P pause menu with an Arca menu: Home (resume, map, settings, disconnect, quit, character card), settings tabs, a keybinds list and a hand-off to GTA's own settings.

## What lives where

| Thing | Where it's changed | Why |
| --- | --- | --- |
| Arca settings (streamer mode, menu scale, ...) | This menu | Saved per player in resource KVP |
| Key bindings | GTA Settings > Key Bindings > FiveM | Every `RegisterKeyMapping` command shows up there; the Keybinds tab reads the current key back |
| Graphics, audio, controls | GTA Settings | Scripts can't change GTA's profile settings, so the menu opens GTA's settings and comes back when it closes |

The Map button also opens GTA's pause menu (on the map), since the map can't be drawn in NUI.

## Settings API

```lua
-- read
local on = exports.arca_interface:GetSetting('streamerMode')

-- react to changes
AddEventHandler('arca_interface:settingChanged', function(key, value) end)

-- add your own tab
exports.arca_interface:RegisterSettings({
    id = 'hud', label = 'HUD', icon = 'fa-solid fa-gauge',
    settings = {
        { key = 'hudSpeedUnit', label = 'Speed Unit', type = 'select', default = 'mph',
          options = { { value = 'mph', label = 'MPH' }, { value = 'kmh', label = 'KM/H' } } },
        { key = 'hudScale', label = 'HUD Scale', type = 'slider', default = 100, min = 70, max = 130, step = 5, suffix = '%' },
        { key = 'hudMoney', label = 'Show Money', type = 'toggle', default = true },
    },
})
```

Setting keys are global across resources, so prefix them with your resource.

Other exports: `Open(page?)`, `Close()`, `IsOpen()`, `SetSetting(key, value)`.

## Preview

Open `web/index.html?preview` in a browser (add `&page=interface` or `&page=keybinds` for another tab).
