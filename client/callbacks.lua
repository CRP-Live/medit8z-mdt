-- ════════════════════════════════════════════════════════════════════
-- PHASE 2: NUI CALLBACKS FIX
-- ════════════════════════════════════════════════════════════════════

-- Dashboard Data
RegisterNUICallback('getDashboardData', function(data, cb)
    local dashboardData = lib.callback.await('medit8z-mdt:server:getDashboardData', false)
    cb(dashboardData or {})
end)

-- Global Search
RegisterNUICallback('globalSearch', function(data, cb)
    local results = lib.callback.await('medit8z-mdt:server:globalSearch', false, data.query)
    cb(results or {})
end)

-- Panic Button
RegisterNUICallback('panicButton', function(data, cb)
    -- CRITICAL: Call cb() immediately to prevent freeze
    cb('ok')
    
    -- Then trigger the server event
    TriggerServerEvent('medit8z-mdt:server:panicButton')
    
    lib.notify({
        title = 'PANIC BUTTON',
        description = 'Emergency signal sent to all units!',
        type = 'error',
        duration = 5000
    })
end)

-- GPS Setting
RegisterNUICallback('setGPS', function(data, cb)
    if data.coords then
        SetNewWaypoint(data.coords.x, data.coords.y)
        lib.notify({
            title = 'MDT',
            description = 'GPS waypoint set',
            type = 'success'
        })
    end
    cb('ok')
end)

-- Sound Player
RegisterNUICallback('playSound', function(data, cb)
    if data.sound == 'notification' then
        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    elseif data.sound == 'error' then
        PlaySoundFrontend(-1, "ERROR", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    elseif data.sound == 'success' then
        PlaySoundFrontend(-1, "SUCCESS", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
    cb('ok')
end)

-- Status Update
RegisterNUICallback('updateStatus', function(data, cb)
    if data.status then
        TriggerServerEvent('medit8z-mdt:server:updateUnitStatus', data.status)
        
        lib.notify({
            title = 'MDT',
            description = 'Status updated to ' .. data.status,
            type = 'success'
        })
    end
    cb('ok')
end)

print('[medit8z-mdt] NUI Callbacks registered')