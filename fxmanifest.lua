fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'medit8z-mdt'
author 'CRP-Live'
version '0.2.0'
description 'Advanced Mobile Data Terminal for FiveM - Phase 2'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/nui.lua',
    'client/callbacks.lua'  -- Add this line
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/dashboard.lua',
    'server/utils.lua'
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

-- Client-side exports
exports {
    'mdt_tablet',  -- ox_inventory item export (MUST BE FIRST)
    'IsOpen',
    'GetDepartment',
    'OpenMDT',
    'CloseMDT',
    'TriggerPanicButton',
    'SetUnitStatus'
}

-- Server-side exports
server_exports {
    'useMDTTablet',  -- Alternative ox_inventory server export
    'AddRecentCall',
    'AddRecentArrest',
    'SendMDTNotification',
    'BroadcastToUnits',
    'GetActiveUnits',
    'IsOnDuty',
    'HasMDTAccess',
    'GetPlayer',
    'GetPlayerJob',
    'LogMDTAction',
    'SendWebhook',
    'UpdateDailyStatistics',
    'GenerateUniqueId',
    'ValidateInput',
    'HasPermission',
    'QueueNotification',
    'GetQueuedNotifications'
}