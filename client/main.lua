-- Replaces GTA's Esc / P pause menu with our own NUI menu.
-- GTA's menu is still reachable from ours for the Map and for GTA's own settings.

local isOpen = false
local nativeOpen = false   -- we opened GTA's pause menu on purpose
local lastNuiFocus = 0     -- last time another resource had NUI focus
local serverInfo

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
local function keyFor(command)
    -- key-mapped commands are looked up by the joaat hash of the command, high bit set
    local label = GetControlInstructionalButton(0, joaat(command) | 0x80000000, true)
    if not label or label == '' then return nil end
    return (label:gsub('^t_', ''):gsub('^b_', ''))
end

local function keybindsForNui()
    local list = {}
    for _, kb in ipairs(InterfaceConfig.Keybinds) do
        list[#list + 1] = { category = kb.category, label = kb.label, command = kb.command, key = keyFor(kb.command) }
    end
    return list
end

local function playerForNui()
    local pd = exports.arca_core:GetPlayerData() or {}
    local char = pd.charinfo or {}
    local job = pd.job or {}
    local grade = type(job.grade) == 'table' and job.grade.name or nil
    return {
        id = GetPlayerServerId(PlayerId()),
        name = (char.firstname and (char.firstname .. ' ' .. (char.lastname or ''))) or GetPlayerName(PlayerId()),
        citizenid = pd.citizenid,
        job = job.label and (grade and (job.label .. ' - ' .. grade) or job.label) or nil,
        cash = pd.money and pd.money.cash,
        bank = pd.money and pd.money.bank,
    }
end

---------------------------------------------------------------------
-- Open / close
---------------------------------------------------------------------
local function open(page)
    if isOpen then return end
    isOpen = true
    serverInfo = Arca.Callback.Await('arca_interface:info') or serverInfo or {}
    if not isOpen then return end -- closed again while we waited
    if GetSettingValue('menuBlur') then TriggerScreenblurFadeIn(150) end
    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    SendNUIMessage({ action = 'open', data = {
        page = page,
        server = { name = InterfaceConfig.ServerName or serverInfo.name, players = serverInfo.players, maxPlayers = serverInfo.maxPlayers },
        links = InterfaceConfig.Links,
        player = playerForNui(),
        settings = SettingsForNui(),
        keybinds = keybindsForNui(),
        hud = GetResourceState('arca_hud') == 'started',
    } })
    SetNuiFocus(true, true)
end

local function close()
    if not isOpen then return end
    isOpen = false
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
    TriggerScreenblurFadeOut(150)
    PlaySoundFrontend(-1, 'BACK', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end

---Opens GTA's own pause menu, then brings our menu back when it closes
local function openNative(which)
    local cfg = InterfaceConfig.Native[which]
    if not cfg then return end
    close()
    nativeOpen = true
    ActivateFrontendMenu(joaat(cfg.menu), false, cfg.tab)
    CreateThread(function()
        local started = GetGameTimer()
        while not IsPauseMenuActive() and GetGameTimer() - started < 1000 do Wait(0) end
        while IsPauseMenuActive() do Wait(0) end
        nativeOpen = false
        Wait(100)
        open(which == 'Settings' and 'game' or nil)
    end)
end

exports('Open', open)
exports('Close', close)
exports('IsOpen', function() return isOpen end)

---------------------------------------------------------------------
-- Pause key takeover
---------------------------------------------------------------------
CreateThread(function()
    while true do
        -- includes our own menu, so the Esc that closes it doesn't reopen it on key-up
        if IsNuiFocused() then lastNuiFocus = GetGameTimer() end

        if not nativeOpen and not InterfaceConfig.UseNativeMenu then
            DisableControlAction(0, 199, true) -- P
            DisableControlAction(0, 200, true) -- Esc

            -- something else opened GTA's pause menu (or a key slipped through): swap it for ours
            if IsPauseMenuActive() and not isOpen then
                SetFrontendActive(false)
                open()
            elseif not isOpen and (IsDisabledControlJustReleased(0, 199) or IsDisabledControlJustReleased(0, 200)) then
                -- ignore the Esc that just closed another resource's UI (inventory, phone, ...)
                if GetGameTimer() - lastNuiFocus > 250 and not IsNuiFocused() then open() end
            end
        end
        Wait(0)
    end
end)

---------------------------------------------------------------------
-- NUI callbacks
---------------------------------------------------------------------
RegisterNUICallback('close', function(_, cb) cb(1) close() end)

RegisterNUICallback('map', function(_, cb) cb(1) openNative('Map') end)
RegisterNUICallback('gameSettings', function(_, cb) cb(1) openNative('Settings') end)

RegisterNUICallback('hud', function(_, cb)
    cb(1)
    if GetResourceState('arca_hud') ~= 'started' then return end
    close()
    exports.arca_hud:OpenHudMenu()
end)

RegisterNUICallback('apply', function(data, cb)
    local changed = type(data.values) == 'table' and data.values or {}
    local failed = {}
    for key, value in pairs(changed) do
        if not SetSettingValue(key, value) then failed[#failed + 1] = key end
    end
    cb({ settings = SettingsForNui(), failed = failed })
    PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end)

RegisterNUICallback('sound', function(data, cb)
    cb(1)
    local sounds = { move = 'NAV_UP_DOWN', change = 'NAV_LEFT_RIGHT', select = 'SELECT', back = 'BACK' }
    if sounds[data.name] then PlaySoundFrontend(-1, sounds[data.name], 'HUD_FRONTEND_DEFAULT_SOUNDSET', true) end
end)

RegisterNUICallback('switchCharacter', function(_, cb)
    cb(1)
    close()
    TriggerServerEvent('arca_interface:switchCharacter')
end)

RegisterNUICallback('disconnect', function(_, cb)
    cb(1)
    close()
    TriggerServerEvent('arca_interface:disconnect')
end)

RegisterNUICallback('quit', function(_, cb)
    cb(1)
    close()
    ExecuteCommand('quit')
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and isOpen then
        SetNuiFocus(false, false)
        TriggerScreenblurFadeOut(0)
    end
end)
