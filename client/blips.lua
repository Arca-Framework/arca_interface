-- Map legend theming: groups every resource's blips under our own headings in the
-- pause-menu map legend, and can restyle them (colour / scale), matched by sprite.
-- Blips are created by other resources at any time, so this re-checks every few seconds.

local cfg = InterfaceConfig.MapLegend
if not cfg or not cfg.Enabled then return end

local bySprite = {} -- [sprite] = { category = id, style = {...} }

for _, cat in ipairs(cfg.Categories) do
    AddTextEntry(('BLIP_CAT_%d'):format(cat.id), cat.label) -- heading shown in the legend
    for _, sprite in ipairs(cat.sprites) do
        bySprite[sprite] = { category = cat.id }
    end
end
for sprite, style in pairs(cfg.Styles or {}) do
    bySprite[sprite] = bySprite[sprite] or {}
    bySprite[sprite].style = style
end

local done = {} -- [blip handle] = true once styled

local function apply(blip, rule)
    if rule.category then SetBlipCategory(blip, rule.category) end
    local s = rule.style
    if s then
        if s.colour then SetBlipColour(blip, s.colour) end
        if s.scale then SetBlipScale(blip, s.scale + 0.0) end
        if s.sprite then SetBlipSprite(blip, s.sprite) end
        if s.display then SetBlipDisplay(blip, s.display) end
    end
end

CreateThread(function()
    while true do
        local seen = {}
        for sprite, rule in pairs(bySprite) do
            local blip = GetFirstBlipInfoId(sprite)
            while DoesBlipExist(blip) do
                seen[blip] = true
                if not done[blip] then
                    apply(blip, rule)
                    done[blip] = true
                end
                blip = GetNextBlipInfoId(sprite)
            end
        end
        for blip in pairs(done) do
            if not seen[blip] then done[blip] = nil end -- removed, handle may be reused
        end
        Wait(cfg.Interval or 5000)
    end
end)
