fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'arca_interface'
author 'Arca'
description 'Pause (Esc) menu that replaces GTA\'s native pause menu'
version '0.1.0'

shared_scripts {
    '@arca_core/shared/import.lua',
    'config.lua',
}

client_scripts {
    'client/settings.lua',
    'client/main.lua',
    'client/native.lua',
    'client/blips.lua',
    'client/blipinfo.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'images/*.png',
}

dependencies {
    'arca_core',
}
