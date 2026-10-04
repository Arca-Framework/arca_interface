InterfaceConfig = {}

-- Shown in the menu header. nil = use the server's sv_projectName convar.
InterfaceConfig.ServerName = nil

-- Links shown on the landing page (leave a value empty to hide its button)
InterfaceConfig.Links = {
    discord = '',
    website = '',
}

-- GTA's own pause menu, opened from our menu for things scripts can't change
-- (graphics, audio, controller, rebinding keys). The third value is the tab
-- highlighted when it opens: -1 = the menu's default tab.
InterfaceConfig.Native = {
    Map      = { menu = 'FE_MENU_VERSION_MP_PAUSE', tab = -1 },
    Settings = { menu = 'FE_MENU_VERSION_MP_PAUSE', tab = -1 },
}

-- true = don't replace Esc / P at all; players get GTA's own pause menu, re-skinned
-- with NativeTheme below. false = Esc / P open the Arca menu.
InterfaceConfig.UseNativeMenu = false

-- Re-skin of GTA's own pause menu (shown for the Map and GTA Settings, or always
-- when UseNativeMenu = true).
InterfaceConfig.NativeTheme = {
    Enabled = true,
    Title = nil,            -- big header title; nil = server name
    Subtitle = '',          -- small line under the title ('' to hide; it sits close to the tabs)
    ShowMoney = true,       -- cash / bank next to the character name in the header

    -- PNG in arca_interface/images/ shown instead of the character headshot
    -- (square, e.g. 256x256). nil = keep the headshot.
    Logo = nil,

    -- drawn behind the menu, over the blurred game
    Backdrop = {
        Enabled = true,
        Image = nil,                     -- PNG in images/ stretched full screen (e.g. 1920x1080), or nil
        ImageAlpha = 255,
        Tint = { 6, 10, 9, 170 },        -- colour laid over the game / image; nil for none
        AccentBar = { height = 0.004, colour = { 0, 255, 106, 255 } }, -- thin line along the top; nil for none
    },

    -- GTA text labels -> your text. Add any other label you want renamed.
    Labels = {
        PM_SCR_MAP  = 'MAP',
        PM_SCR_INF  = 'INFO',
        PM_SCR_STA  = 'STATS',
        PM_SCR_SET  = 'SETTINGS',
        PM_SCR_GAL  = 'GALLERY',
        PM_SCR_RPL  = 'EDITOR',
        PM_PANE_LEAVE = 'Disconnect',
        PM_PANE_QUIT  = 'Quit Game',
        PM_PANE_CFX   = 'FiveM',
    },

    -- HUD colour index -> { r, g, b, a }. These indexes are the ones pause-menu
    -- re-skins usually change: 116 = tab / highlight colour, 117 = menu background,
    -- 142 = waypoint & selection accent. Remove a line to keep GTA's colour.
    Colours = {
        [116] = { 0, 255, 106, 255 },
        [117] = { 10, 14, 17, 200 },
        [142] = { 0, 255, 106, 255 },
    },
}

-- Map legend (the list on the right of the pause-menu map). Blips are grouped
-- under these headings by their icon (sprite), whatever resource made them.
-- Names come from each resource's own config (shops: arca_inventory, banks:
-- arca_bank, barber / clothing / tattoo / surgeon: illenium-appearance).
InterfaceConfig.MapLegend = {
    Enabled = true,
    Categories = {   -- id must be 10 or higher (lower ids are GTA's own)
        { id = 10, label = 'Shops',      sprites = { 52, 402, 521, 110 } },  -- 24/7, hardware, Digital Den, Ammu-Nation
        { id = 11, label = 'Banks',      sprites = { 108 } },                -- Fleeca, Blaine County, Pacific Standard
        { id = 12, label = 'Appearance', sprites = { 366, 71, 75, 102 } },   -- clothing, barber, tattoo, plastic surgeon
    },
    -- optional restyle by sprite: colour (blip colour id), scale, sprite (swap the icon)
    Styles = {
        [108] = { colour = 2, scale = 0.7 },
    },
}

-- Hover cards on the pause-menu map: hovering a blip shows this info.
-- Matched by blip icon (sprite). image = PNG in arca_interface/images/ (optional,
-- landscape ~ 512x256). Resources can also set info for one specific blip with
-- exports.arca_interface:SetBlipInfo(blip, { title, description, image, rows }).
InterfaceConfig.BlipInfo = {
    Enabled = true,
    Sprites = {
        [52]  = { title = '24/7 Supermarket', description = 'Food, drinks and everyday supplies.', rows = { { 'Open', '24/7' } } },
        [402] = { title = 'Hardware Store', description = 'Tools, repair kits and supplies.', rows = { { 'Open', '24/7' } } },
        [521] = { title = 'Digital Den', description = 'Phones, phone chips and electronics.', rows = { { 'Open', '24/7' } } },
        [110] = { title = 'Ammu-Nation', description = 'Weapons and ammo. A weapon licence is required.', rows = { { 'Licence', 'Required' } } },
        [108] = { title = 'Bank', description = 'Deposit, withdraw and manage your accounts and cards at the teller.', rows = { { 'Services', 'Accounts, cards' } } },
        [73]  = { title = 'Clothing Store', description = 'Change your outfit and save outfits.' },
        [366] = { title = 'Clothing Store', description = 'Change your outfit and save outfits.' },
        [71]  = { title = 'Barber', description = 'Haircuts, beards and makeup.' },
        [75]  = { title = 'Tattoo Shop', description = 'Get inked, or have tattoos removed.' },
        [102] = { title = 'Plastic Surgeon', description = 'Change your face and features.' },
    },
}

-- Key bindings listed in the Keybinds tab. These are RegisterKeyMapping commands;
-- players rebind them in GTA Settings > Key Bindings > FiveM, and the new key
-- shows up here automatically.
InterfaceConfig.Keybinds = {
    { category = 'General',   command = 'inventory',     label = 'Open inventory' },
    { category = 'General',   command = 'phone',         label = 'Open phone' },
    { category = 'General',   command = '+arca_target',  label = 'Target (third eye)' },
    { category = 'General',   command = '+arca_radial',  label = 'Radial menu' },
    { category = 'Weapons',   command = '+arca_reload',  label = 'Load ammo into weapon' },
    { category = 'Hotbar',    command = 'hotbar1',       label = 'Hotbar slot 1' },
    { category = 'Hotbar',    command = 'hotbar2',       label = 'Hotbar slot 2' },
    { category = 'Hotbar',    command = 'hotbar3',       label = 'Hotbar slot 3' },
    { category = 'Hotbar',    command = 'hotbar4',       label = 'Hotbar slot 4' },
    { category = 'Hotbar',    command = 'hotbar5',       label = 'Hotbar slot 5' },
}

-- Settings saved per player (on their PC) and readable by any resource:
--   exports.arca_interface:GetSetting('streamerMode')
--   AddEventHandler('arca_interface:settingChanged', function(key, value) end)
-- Other resources can add their own categories with exports.arca_interface:RegisterSettings.
--
-- types: toggle (default true/false), select (options = { {value, label} }),
--        slider (min, max, step, suffix)
-- profile = 'name' makes a row control GTA's own setting (the profile_<name> console
-- variable) instead of an Arca one. Those are saved in the player's GTA settings,
-- and a row whose setting doesn't exist in their game is left out.
-- Defaults on GTA rows are what "Restore to Default" sets: GTA's stock values.
InterfaceConfig.Settings = {
    {
        id = 'display', label = 'Display', icon = 'fa-solid fa-display',
        settings = {
            { key = 'gta_gamma', profile = 'gamma', label = 'Brightness', type = 'slider', default = 15, min = 0, max = 30, step = 1,
              description = 'Overall game brightness.' },
            { key = 'gta_safezone', profile = 'safezoneSize', label = 'Safe Zone Size', type = 'slider', default = 0, min = 0, max = 10, step = 1,
              description = 'Moves the HUD and minimap in from the edges of the screen.' },
            { key = 'gta_hud', profile = 'displayHud', label = 'Show HUD', type = 'toggle', default = true,
              description = 'GTA\'s own HUD elements.' },
            { key = 'gta_gps', profile = 'displayGps', label = 'GPS Route', type = 'toggle', default = true,
              description = 'Draws the route to your waypoint on the minimap.' },
            { key = 'gta_bigradar', profile = 'bigRadar', label = 'Expanded Radar', type = 'toggle', default = false,
              description = 'Uses the bigger minimap.' },
            { key = 'gta_radarnames', profile = 'bigRadarNames', label = 'Radar Street Names', type = 'toggle', default = false,
              description = 'Shows street names on the expanded minimap.' },
            { key = 'gta_subtitles', profile = 'subtitles', label = 'Subtitles', type = 'toggle', default = true,
              description = 'Subtitles for game dialogue.' },
            { key = 'gta_units', profile = 'measurementSystem', label = 'Measurement System', type = 'select', default = 0,
              options = { { value = 0, label = 'Imperial' }, { value = 1, label = 'Metric' } },
              description = 'Units GTA uses for distances.' },
            { key = 'gta_reticule', profile = 'reticule', label = 'Reticle', type = 'toggle', default = true,
              description = 'The aiming dot in the middle of the screen.' },
            { key = 'gta_reticulesize', profile = 'reticuleSize', label = 'Reticle Size', type = 'slider', default = 0, min = 0, max = 10, step = 1,
              description = 'Size of the aiming reticle.' },
        },
    },
    {
        id = 'audio', label = 'Audio', icon = 'fa-solid fa-volume-high',
        settings = {
            { key = 'gta_sfx', profile = 'sfxVolume', label = 'SFX Volume', type = 'slider', default = 10, min = 0, max = 10, step = 1,
              description = 'Gunshots, engines, footsteps and other game sounds.' },
            { key = 'gta_music', profile = 'musicVolume', label = 'Music Volume', type = 'slider', default = 10, min = 0, max = 10, step = 1,
              description = 'Radio and score music.' },
            { key = 'gta_musicmp', profile = 'musicVolumeInMp', label = 'Music Volume (Online)', type = 'slider', default = 10, min = 0, max = 10, step = 1,
              description = 'Music volume while in a multiplayer session (this server).' },
            { key = 'gta_mutefocus', profile = 'audioMuteOnFocusLoss', label = 'Mute When Tabbed Out', type = 'toggle', default = false,
              description = 'Silences the game while it isn\'t the active window.' },
        },
    },
    {
        id = 'camera', label = 'Camera', icon = 'fa-solid fa-video',
        settings = {
            { key = 'gta_fov', profile = 'fpsFieldOfView', label = 'First Person FOV', type = 'slider', default = 5, min = 0, max = 10, step = 1,
              description = 'Field of view in first person.' },
            { key = 'gta_headbob', profile = 'fpsHeadbob', label = 'First Person Head Bob', type = 'toggle', default = true,
              description = 'Camera sway while walking and running in first person.' },
            { key = 'gta_fpsragdoll', profile = 'fpsRagdoll', label = 'First Person Ragdoll', type = 'toggle', default = true,
              description = 'Stays in first person when you ragdoll.' },
            { key = 'gta_fpscover', profile = 'fpsThirdPersonCover', label = 'Third Person in Cover', type = 'toggle', default = false,
              description = 'Switches to third person when taking cover.' },
            { key = 'gta_hood', profile = 'hoodCamera', label = 'Hood Camera', type = 'toggle', default = false,
              description = 'Adds the bonnet view to the vehicle camera cycle.' },
            { key = 'gta_cinshoot', profile = 'cinematicShooting', label = 'Cinematic Shooting', type = 'toggle', default = false,
              description = 'Slow-motion cinematic camera during drive-bys.' },
        },
    },
    {
        id = 'controls', label = 'Controls', icon = 'fa-solid fa-computer-mouse',
        settings = {
            { key = 'gta_invertmouse', profile = 'invertMouse', label = 'Invert Mouse', type = 'toggle', default = false,
              description = 'Inverts vertical mouse look on foot.' },
            { key = 'gta_toggleaim', profile = 'kbmToggleAim', label = 'Toggle Aim', type = 'toggle', default = false,
              description = 'Right-click once to aim instead of holding it.' },
            { key = 'gta_drivebyalt', profile = 'alternateDriveby', label = 'Alternate Drive-by', type = 'toggle', default = false,
              description = 'Drive-by aiming without holding the aim button.' },
            { key = 'gta_mousedrive', profile = 'mouseDrive', label = 'Mouse Steering', type = 'toggle', default = false,
              description = 'Steer vehicles with the mouse.' },
            { key = 'gta_mousefly', profile = 'mouseFly', label = 'Mouse Flying', type = 'toggle', default = false,
              description = 'Fly aircraft with the mouse.' },
        },
    },
    {
        id = 'gameplay', label = 'Gameplay', icon = 'fa-solid fa-person-running',
        settings = {
            { key = 'streamerMode', label = 'Streamer Mode', type = 'toggle', default = false,
              description = 'Hides your server ID and character name on the pause menu so they don\'t show up on stream.' },
            { key = 'idleCamera', label = 'Idle Camera', type = 'toggle', default = false,
              description = 'GTA\'s cinematic camera that kicks in when you stand still for a while.' },
        },
    },
    {
        id = 'interface', label = 'Interface', icon = 'fa-solid fa-palette',
        settings = {
            { key = 'uiScale', label = 'Menu Scale', type = 'slider', default = 100, min = 80, max = 120, step = 5, suffix = '%',
              description = 'Size of this pause menu.' },
            { key = 'menuBlur', label = 'Background Blur', type = 'toggle', default = true,
              description = 'Blurs the game behind the pause menu.' },
            { key = 'clock', label = 'Clock Format', type = 'select', default = '24h',
              options = { { value = '24h', label = '24 Hour' }, { value = '12h', label = '12 Hour' } },
              description = 'How times are shown on the pause menu.' },
        },
    },
}
