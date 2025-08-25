fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'medit8z-mdt'
author 'CRP-Live'
version '0.1.0'
description 'Advanced Mobile Data Terminal for FiveM'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/css/*.css',
    'ui/js/*.js',
    'ui/assets/**/*'
}

dependencies {
    'oxmysql',
    'ox_lib',
    'ox_inventory'
}