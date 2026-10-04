-- Re-skins GTA's own pause menu (the one the Map and GTA Settings buttons open):
-- header title, player details and picture, tab and button names, menu colours
-- and a backdrop drawn behind the menu. Same approach other pause-menu scripts use:
-- text entries, HUD colour overrides, the frontend header scaleform and script
-- drawing behind the pause menu.

local cfg = InterfaceConfig.NativeTheme
local TXD = 'arca_interface_pm' -- runtime texture dictionary for our images

local function serverName()
    return InterfaceConfig.ServerName or GetConvar('sv_projectName', '') ~= '' and GetConvar('sv_projectName', '') or 'Arca'
end

---------------------------------------------------------------------
-- Images (PNG files in images/, loaded into a runtime texture dictionary)
---------------------------------------------------------------------
local textures = {} -- [name] = true once loaded

local function loadImage(name, file)
    if not file or file == '' then return end
    if not LoadResourceFile(GetCurrentResourceName(), 'images/' .. file) then
        print(('^3[arca_interface] images/%s not found, skipping^7'):format(file))
        return
    end
    local txd = CreateRuntimeTxd(TXD)
    CreateRuntimeTextureFromImage(txd, name, 'images/' .. file)
    textures[name] = true
end

---------------------------------------------------------------------
-- Text and colours
---------------------------------------------------------------------
local function applyText()
    AddTextEntry('FE_THDR_GTAO', cfg.Title or serverName()) -- big header title
    for entry, text in pairs(cfg.Labels) do AddTextEntry(entry, text) end
end

local function applyColours()
    for index, c in pairs(cfg.Colours) do
        ReplaceHudColourWithRgba(index, c[1], c[2], c[3], c[4] or 255)
    end
end

---------------------------------------------------------------------
-- Header
---------------------------------------------------------------------
local function money(n)
    if type(n) ~= 'number' then return '' end
    local s = tostring(math.floor(n)):reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
    return '$' .. s
end

local days = { 'SUNDAY', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY' }

local function applyHeader()
    local pd = exports.arca_core:GetPlayerData() or {}
    local char = pd.charinfo or {}
    local name = char.firstname and (char.firstname .. ' ' .. (char.lastname or '')) or GetPlayerName(PlayerId())
    local streamer = GetSettingValue('streamerMode')

    -- three lines top-right: name / day + in-game time / money
    local when = ('%s %02d:%02d'):format(days[GetClockDayOfWeek() + 1], GetClockHours(), GetClockMinutes())
    local cash = cfg.ShowMoney and pd.money and ('BANK %s  CASH %s'):format(money(pd.money.bank), money(pd.money.cash)) or ''

    BeginScaleformMovieMethodOnFrontendHeader('SET_HEADING_DETAILS')
    ScaleformMovieMethodAddParamTextureNameString(streamer and 'Hidden' or name)
    ScaleformMovieMethodAddParamTextureNameString(when)
    ScaleformMovieMethodAddParamTextureNameString(cash)
    ScaleformMovieMethodAddParamBool(false)
    EndScaleformMovieMethod()

    BeginScaleformMovieMethodOnFrontendHeader('SET_HEADER_TITLE')
    ScaleformMovieMethodAddParamTextureNameString(cfg.Title or serverName())
    ScaleformMovieMethodAddParamBool(false)
    ScaleformMovieMethodAddParamTextureNameString(cfg.Subtitle or '')
    ScaleformMovieMethodAddParamBool(cfg.Subtitle ~= nil and cfg.Subtitle ~= '')
    EndScaleformMovieMethod()

    -- picture next to the name: our logo instead of the character headshot
    if textures.logo then
        BeginScaleformMovieMethodOnFrontendHeader('SET_CHAR_IMG')
        ScaleformMovieMethodAddParamTextureNameString(TXD)
        ScaleformMovieMethodAddParamTextureNameString('logo')
        ScaleformMovieMethodAddParamBool(true)
        EndScaleformMovieMethod()
    end
end

---------------------------------------------------------------------
-- Backdrop drawn behind the menu (instead of the blurred game)
---------------------------------------------------------------------
local function drawBackdrop()
    local bd = cfg.Backdrop
    SetScriptGfxDrawBehindPausemenu(true)
    if textures.backdrop then
        DrawSprite(TXD, 'backdrop', 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, bd.ImageAlpha or 255)
    end
    local c = bd.Tint
    if c then DrawRect(0.5, 0.5, 1.0, 1.0, c[1], c[2], c[3], c[4] or 200) end
    local a = bd.AccentBar
    if a then DrawRect(0.5, a.height / 2, 1.0, a.height, a.colour[1], a.colour[2], a.colour[3], a.colour[4] or 255) end
    SetScriptGfxDrawBehindPausemenu(false)
end

---------------------------------------------------------------------
-- Main loop
---------------------------------------------------------------------
CreateThread(function()
    if not cfg or not cfg.Enabled then return end
    loadImage('logo', cfg.Logo)
    loadImage('backdrop', cfg.Backdrop and cfg.Backdrop.Image)
    applyText()
    applyColours()

    local nextHeader = 0
    while true do
        if IsPauseMenuActive() then
            if cfg.Backdrop and cfg.Backdrop.Enabled then drawBackdrop() end
            -- GTA rewrites the header with its own name / Online cash after opening
            -- and when switching tabs, so keep writing ours while it's open
            if GetGameTimer() >= nextHeader then
                applyHeader()
                nextHeader = GetGameTimer() + 200
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

---------------------------------------------------------------------
-- Theme tools: try colours and labels live, then copy them into config.lua
--   /pmcolour 116 0 255 106      recolour HUD colour 116, then open the pause menu to look
--   /pmcolour 116                put HUD colour 116 back to GTA's
--   /pmlabel PM_SCR_MAP Atlas    rename a text label
---------------------------------------------------------------------
local originals = {}

RegisterCommand('pmcolour', function(_, args)
    local index = tonumber(args[1])
    if not index then return print('usage: /pmcolour <index> [r g b a]') end
    if not originals[index] then originals[index] = { GetHudColour(index) } end
    local r, g, b, a = tonumber(args[2]), tonumber(args[3]), tonumber(args[4]), tonumber(args[5])
    if r and g and b then
        ReplaceHudColourWithRgba(index, r, g, b, a or 255)
        print(('HUD colour %d -> %d %d %d %d (was %d %d %d %d)'):format(index, r, g, b, a or 255, table.unpack(originals[index])))
    else
        local o = originals[index]
        ReplaceHudColourWithRgba(index, o[1], o[2], o[3], o[4])
        print(('HUD colour %d reset'):format(index))
    end
end, false)

RegisterCommand('pmlabel', function(_, args)
    local entry = args[1]
    if not entry then return print('usage: /pmlabel <LABEL> <text>') end
    local text = table.concat(args, ' ', 2)
    AddTextEntry(entry, text)
    print(('%s -> "%s"'):format(entry, text))
end, false)
