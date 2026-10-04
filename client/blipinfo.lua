-- Blip hover cards on the pause-menu map: hovering a blip shows a panel with a
-- title, picture, info rows and a description (like GTA Online's property cards).
--
-- Works by marking blips as "mission creator" blips (the only kind GTA reports a
-- hover for) and filling the map's info column through the frontend scaleform.
--
-- Info comes from config (InterfaceConfig.BlipInfo, matched by sprite) or from any
-- resource for one specific blip:
--   exports.arca_interface:SetBlipInfo(blip, { title = 'Fleeca', description = '...',
--       image = 'fleeca.png', rows = { { 'Open', '24/7' } } })

local cfg = InterfaceConfig.BlipInfo
if not cfg or not cfg.Enabled then return end

local TXD = 'arca_interface_bi'
local perBlip = {}  -- [blip] = info set via export
local images = {}   -- [file] = texture name once loaded
local marked = {}   -- [blip] = true once flagged as hoverable

local function image(file)
    if not file then return nil end
    if images[file] ~= nil then return images[file] or nil end
    if not LoadResourceFile(GetCurrentResourceName(), 'images/' .. file) then
        print(('^3[arca_interface] blip image images/%s not found^7'):format(file))
        images[file] = false
        return nil
    end
    local name = file:gsub('%.%w+$', '')
    CreateRuntimeTextureFromImage(CreateRuntimeTxd(TXD), name, 'images/' .. file)
    images[file] = name
    return name
end

local function infoFor(blip)
    return perBlip[blip] or cfg.Sprites[GetBlipSprite(blip)]
end

---------------------------------------------------------------------
-- Frontend scaleform helpers (column 1 = the map's info panel)
---------------------------------------------------------------------
local function text(str)
    BeginTextCommandScaleformString('STRING')
    AddTextComponentSubstringPlayerName(str or '')
    EndTextCommandScaleformString()
end

local function setTitle(title, txn)
    BeginScaleformMovieMethodOnFrontend('SET_COLUMN_TITLE')
    ScaleformMovieMethodAddParamInt(1)
    text(title)
    text('')
    ScaleformMovieMethodAddParamTextureNameString(txn and TXD or '')
    ScaleformMovieMethodAddParamTextureNameString(txn or '')
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamBool(false)
    EndScaleformMovieMethod()
end

local function setRow(index, left, right)
    BeginScaleformMovieMethodOnFrontend('SET_DATA_SLOT')
    ScaleformMovieMethodAddParamInt(1)
    ScaleformMovieMethodAddParamInt(index)
    ScaleformMovieMethodAddParamInt(65)
    ScaleformMovieMethodAddParamInt(3)
    ScaleformMovieMethodAddParamInt(0) -- 0 = label / value row
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(0)
    text(left)
    text(right)
    EndScaleformMovieMethod()
end

local function setDescription(index, desc)
    BeginScaleformMovieMethodOnFrontend('SET_DATA_SLOT')
    ScaleformMovieMethodAddParamInt(1)
    ScaleformMovieMethodAddParamInt(index)
    ScaleformMovieMethodAddParamInt(65)
    ScaleformMovieMethodAddParamInt(3)
    ScaleformMovieMethodAddParamInt(1) -- 1 = text block
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(0)
    text(desc)
    EndScaleformMovieMethod()
end

local function call(method, ...)
    BeginScaleformMovieMethodOnFrontend(method)
    for _, v in ipairs({ ... }) do
        if type(v) == 'boolean' then ScaleformMovieMethodAddParamBool(v) else ScaleformMovieMethodAddParamInt(v) end
    end
    EndScaleformMovieMethod()
end

local function show(info)
    call('SET_DATA_SLOT_EMPTY', 1)
    setTitle(info.title, image(info.image))
    local i = 0
    for _, row in ipairs(info.rows or {}) do
        setRow(i, row[1], row[2])
        i = i + 1
    end
    if info.description and info.description ~= '' then setDescription(i, info.description) end
    call('DISPLAY_DATA_SLOT', 1)
    call('SHOW_COLUMN', 1, true)
end

local function hide()
    call('SHOW_COLUMN', 1, false)
    call('SET_DATA_SLOT_EMPTY', 1)
end

---------------------------------------------------------------------
-- Mark blips that have info as hoverable
---------------------------------------------------------------------
local function mark(blip)
    if marked[blip] or not DoesBlipExist(blip) then return end
    SetBlipAsMissionCreatorBlip(blip, true)
    marked[blip] = true
end

CreateThread(function()
    while true do
        for sprite in pairs(cfg.Sprites) do
            local blip = GetFirstBlipInfoId(sprite)
            while DoesBlipExist(blip) do
                mark(blip)
                blip = GetNextBlipInfoId(sprite)
            end
        end
        for blip in pairs(perBlip) do
            if DoesBlipExist(blip) then mark(blip) else perBlip[blip], marked[blip] = nil, nil end
        end
        Wait(5000)
    end
end)

---------------------------------------------------------------------
-- Hover loop
---------------------------------------------------------------------
CreateThread(function()
    local shown
    while true do
        if IsPauseMenuActive() and IsFrontendReadyForControl() then
            local hovering = IsHoveringOverMissionCreatorBlip()
            -- "New" selected blip: only returns a blip on the frame the hover starts,
            -- so remember it and keep the card up for as long as the hover lasts
            local blip = hovering and GetNewSelectedMissionCreatorBlip()
            if hovering and blip and DoesBlipExist(blip) and blip ~= shown then
                local info = infoFor(blip)
                if info then
                    TakeControlOfFrontend()
                    show(info)
                    ReleaseControlOfFrontend()
                    shown = blip
                end
            elseif not hovering and shown then
                TakeControlOfFrontend()
                hide()
                ReleaseControlOfFrontend()
                shown = nil
            end
            Wait(0)
        elseif IsPauseMenuActive() then
            Wait(0) -- frontend busy for a moment; keep whatever card is up
        else
            shown = nil
            Wait(250)
        end
    end
end)

exports('SetBlipInfo', function(blip, info)
    perBlip[blip] = info
    mark(blip)
end)

exports('ClearBlipInfo', function(blip)
    perBlip[blip] = nil
end)
