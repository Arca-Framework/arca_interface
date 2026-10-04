-- Per-player settings, saved on the player's PC (resource KVP).
-- Categories come from config.lua plus anything other resources add with RegisterSettings.

local KVP_KEY = 'arca_interface:settings'

local categories = {} -- ordered list of { id, label, icon, settings = { ... } }
local byKey = {}      -- [key] = setting definition
local values = {}     -- [key] = current value

local saved = json.decode(GetResourceKvpString(KVP_KEY) or '{}') or {}

local function valid(def, value)
    if def.type == 'toggle' then return type(value) == 'boolean' end
    if def.type == 'slider' then return type(value) == 'number' and value >= def.min and value <= def.max end
    if def.type == 'select' then
        for _, opt in ipairs(def.options) do
            if opt.value == value then return true end
        end
    end
    return false
end

---------------------------------------------------------------------
-- GTA profile settings (def.profile = 'sfxVolume' -> the profile_sfxVolume convar).
-- These live in GTA's own settings. Scripts can read them, but FiveM denies
-- scripts the profile_ commands ("Access denied"), so they're shown read-only
-- and the player changes them in GTA's settings menu.
---------------------------------------------------------------------
local function readProfile(def)
    local raw = GetConvarInt('profile_' .. def.profile, -1)
    if raw < 0 then return nil end
    if def.type == 'toggle' then return raw ~= 0 end
    return raw
end

local function addCategory(cat, owner)
    local rows = {}
    for _, def in ipairs(cat.settings) do
        if byKey[def.key] then
            print(('^3[arca_interface] setting "%s" registered twice, ignoring the second^7'):format(def.key))
        elseif def.profile and readProfile(def) == nil then
            -- this game build doesn't have that profile setting; leave it out
        else
            def.owner = owner
            byKey[def.key] = def
            rows[#rows + 1] = def
            if not def.profile then
                local s = saved[def.key]
                values[def.key] = (s ~= nil and valid(def, s)) and s or def.default
            end
        end
    end
    cat.settings = rows
    if #rows > 0 then categories[#categories + 1] = cat end
end

for _, cat in ipairs(InterfaceConfig.Settings) do addCategory(cat, GetCurrentResourceName()) end

local function save()
    local data = {}
    for k, v in pairs(values) do
        if byKey[k] and not byKey[k].profile then data[k] = v end
    end
    SetResourceKvp(KVP_KEY, json.encode(data))
end

---Sets a value, saves it and tells every resource. Returns false if the value isn't allowed
---or (for GTA settings) the game didn't accept it.
function SetSettingValue(key, value)
    local def = byKey[key]
    if not def or not valid(def, value) then return false end
    if GetSettingValue(key) == value then return true end
    if def.profile then return false end -- read-only, see readProfile
    values[key] = value
    save()
    TriggerEvent('arca_interface:settingChanged', key, value)
    return true
end

---Everything the NUI needs to draw the settings tabs
function SettingsForNui()
    local list = {}
    for _, cat in ipairs(categories) do
        local rows = {}
        for _, def in ipairs(cat.settings) do
            if byKey[def.key] == def then
                rows[#rows + 1] = {
                    key = def.key, label = def.label, type = def.type, description = def.description,
                    default = def.default, options = def.options, min = def.min, max = def.max,
                    step = def.step, suffix = def.suffix, value = GetSettingValue(def.key),
                    gta = def.profile ~= nil,
                }
            end
        end
        list[#list + 1] = { id = cat.id, label = cat.label, icon = cat.icon, settings = rows }
    end
    return list
end

function GetSettingValue(key)
    local def = byKey[key]
    if def and def.profile then return readProfile(def) end
    return values[key]
end

---------------------------------------------------------------------
-- Exports
---------------------------------------------------------------------
exports('GetSetting', GetSettingValue)
exports('SetSetting', SetSettingValue)

---Adds a settings category to the pause menu.
---exports.arca_interface:RegisterSettings({ id = 'hud', label = 'HUD', icon = 'fa-solid fa-gauge', settings = { ... } })
exports('RegisterSettings', function(cat)
    local owner = GetInvokingResource() or GetCurrentResourceName()
    for i = #categories, 1, -1 do
        if categories[i].id == cat.id then table.remove(categories, i) end
    end
    addCategory(cat, owner)
end)

-- drop categories from resources that stop
AddEventHandler('onClientResourceStop', function(res)
    for i = #categories, 1, -1 do
        local cat = categories[i]
        local def = cat.settings[1]
        if def and def.owner == res then
            for _, d in ipairs(cat.settings) do byKey[d.key] = nil end
            table.remove(categories, i)
        end
    end
end)

---------------------------------------------------------------------
-- Built-in settings that this resource applies itself
---------------------------------------------------------------------
local function applyIdleCamera()
    DisableIdleCamera(not values.idleCamera)
end

AddEventHandler('arca_interface:settingChanged', function(key)
    if key == 'idleCamera' then applyIdleCamera() end
end)

CreateThread(function()
    applyIdleCamera()
    -- the vehicle idle camera ignores DisableIdleCamera, so keep resetting its timer
    while true do
        if not values.idleCamera then InvalidateIdleCam() InvalidateVehicleIdleCam() end
        Wait(10000)
    end
end)
