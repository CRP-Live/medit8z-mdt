-- ════════════════════════════════════════════════════════════════════
-- PHASE 2: CLIENT NUI HANDLERS
-- ════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════
-- Check if MDT is open (exported from main.lua)
-- ════════════════════════════════════════════════════════════════════
local function IsMDTOpen()
    return exports['medit8z-mdt']:IsOpen()
end

-- ════════════════════════════════════════════════════════════════════
-- Real-time Update Events
-- ════════════════════════════════════════════════════════════════════
RegisterNetEvent('medit8z-mdt:client:updateDashboard', function(data)
    if not IsMDTOpen() then return end
    
    SendNUIMessage({
        action = 'updateDashboard',
        data = data
    })
end)

RegisterNetEvent('medit8z-mdt:client:newCall', function(call)
    if not IsMDTOpen() then return end
    
    SendNUIMessage({
        action = 'newCall',
        call = call
    })
end)

RegisterNetEvent('medit8z-mdt:client:newArrest', function(arrest)
    if not IsMDTOpen() then return end
    
    SendNUIMessage({
        action = 'newArrest',
        arrest = arrest
    })
end)

RegisterNetEvent('medit8z-mdt:client:unitStatusChanged', function(unit)
    if not IsMDTOpen() then return end
    
    SendNUIMessage({
        action = 'unitStatusChanged',
        unit = unit
    })
end)

RegisterNetEvent('medit8z-mdt:client:updateProbation', function(list)
    if not IsMDTOpen() then return end
    
    SendNUIMessage({
        action = 'updateProbation',
        list = list
    })
end)

-- ════════════════════════════════════════════════════════════════════
-- Notification System
-- ════════════════════════════════════════════════════════════════════
RegisterNetEvent('medit8z-mdt:client:receiveNotification', function(notification)
    if not IsMDTOpen() then 
        -- Store notification for when MDT opens
        -- Or show a game notification
        lib.notify({
            title = 'MDT: ' .. notification.title,
            description = notification.message,
            type = notification.type or 'inform',
            duration = 5000
        })
        return
    end
    
    SendNUIMessage({
        action = 'receiveNotification',
        notification = notification
    })
end)

-- ════════════════════════════════════════════════════════════════════
-- Alert System
-- ════════════════════════════════════════════════════════════════════
RegisterNetEvent('medit8z-mdt:client:playAlert', function(alertType)
    if alertType == 'panic' then
        -- Play panic button sound
        PlaySoundFrontend(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", true)
        
        -- Flash screen red briefly
        CreateThread(function()
            for i = 1, 3 do
                SetTimecycleModifier("hud_def_blur")
                SetTimecycleModifierStrength(1.0)
                Wait(100)
                ClearTimecycleModifier()
                Wait(100)
            end
        end)
    elseif alertType == 'call' then
        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
    
    if IsMDTOpen() then
        SendNUIMessage({
            action = 'playAlert',
            type = alertType
        })
    end
end)

-- ════════════════════════════════════════════════════════════════════
-- NUI Callbacks for Phase 2 Features
-- ════════════════════════════════════════════════════════════════════
RegisterNUICallback('getDashboardData', function(data, cb)
    local dashboardData = lib.callback.await('medit8z-mdt:server:getDashboardData', false)
    cb(dashboardData or {})
end)

RegisterNUICallback('globalSearch', function(data, cb)
    local results = lib.callback.await('medit8z-mdt:server:globalSearch', false, data.query)
    cb(results or {})
end)

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

-- ════════════════════════════════════════════════════════════════════
-- Panic Button Handler
-- ════════════════════════════════════════════════════════════════════

RegisterNUICallback('panicButton', function(data, cb)
    TriggerServerEvent('medit8z-mdt:server:panicButton')
    
    lib.notify({
        title = 'PANIC BUTTON',
        description = 'Emergency signal sent to all units!',
        type = 'error',
        duration = 5000
    })
    
    cb('ok')
end)

RegisterNUICallback('getDashboardData', function(data, cb)
    local dashboardData = lib.callback.await('medit8z-mdt:server:getDashboardData', false)
    cb(dashboardData or {})
end)

-- ════════════════════════════════════════════════════════════════════
-- Unit Status Update
-- ════════════════════════════════════════════════════════════════════
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

-- ════════════════════════════════════════════════════════════════════
-- Profile/Vehicle/Incident Quick Open
-- ════════════════════════════════════════════════════════════════════
RegisterNUICallback('openProfile', function(data, cb)
    -- Will be implemented in Phase 3
    print('[MDT] Opening profile:', data.citizenId)
    cb('ok')
end)

RegisterNUICallback('openVehicle', function(data, cb)
    -- Will be implemented in Phase 8
    print('[MDT] Opening vehicle:', data.plate)
    cb('ok')
end)

RegisterNUICallback('openIncident', function(data, cb)
    -- Will be implemented in Phase 4
    print('[MDT] Opening incident:', data.incidentNumber)
    cb('ok')
end)

-- ════════════════════════════════════════════════════════════════════
-- Export Functions for Other Resources
-- ════════════════════════════════════════════════════════════════════
exports('TriggerPanicButton', function()
    if IsMDTOpen() then
        TriggerServerEvent('medit8z-mdt:server:panicButton')
    end
end)

exports('SetUnitStatus', function(status)
    if IsMDTOpen() then
        TriggerServerEvent('medit8z-mdt:server:updateUnitStatus', status)
    end
end)

print('[medit8z-mdt] Phase 2 NUI handlers loaded')