local Framework = nil
local FrameworkName = Config.Framework
local MDTOpen = false
local PlayerData = {}
local Department = nil

-- ════════════════════════════════════════════════════════════════════
-- Framework Detection
-- ════════════════════════════════════════════════════════════════════
CreateThread(function()
    if Config.Framework == 'auto' then
        if GetResourceState('qbx_core') == 'started' then
            Framework = exports.qbx_core
            FrameworkName = 'qbx_core'
        elseif GetResourceState('qb-core') == 'started' then
            Framework = exports['qb-core']:GetCoreObject()
            FrameworkName = 'qb-core'
        elseif GetResourceState('es_extended') == 'started' then
            Framework = exports['es_extended']:getSharedObject()
            FrameworkName = 'esx'
        end
    elseif Config.Framework == 'qbx_core' then
        Framework = exports.qbx_core
        FrameworkName = 'qbx_core'
    elseif Config.Framework == 'qb-core' then
        Framework = exports['qb-core']:GetCoreObject()
        FrameworkName = 'qb-core'
    elseif Config.Framework == 'esx' then
        Framework = exports['es_extended']:getSharedObject()
        FrameworkName = 'esx'
    end
    
    if Config.Debug then
        print('[medit8z-mdt] Client-side loaded with framework: ' .. (FrameworkName or 'none'))
    end
end)

-- ════════════════════════════════════════════════════════════════════
-- Notification Function
-- ════════════════════════════════════════════════════════════════════
local function Notify(message, type)
    type = type or 'inform'
    
    if Config.Notifications.type == 'ox_lib' then
        lib.notify({
            title = 'MDT',
            description = message,
            type = type,
            position = Config.Notifications.position,
            duration = Config.Notifications.duration
        })
    elseif FrameworkName == 'qbx_core' then
        -- Qbox uses ox_lib by default
        lib.notify({
            title = 'MDT',
            description = message,
            type = type
        })
    elseif FrameworkName == 'qb-core' then
        TriggerEvent('QBCore:Notify', message, type)
    elseif FrameworkName == 'esx' then
        exports['es_extended']:ShowNotification(message)
    end
end

-- ════════════════════════════════════════════════════════════════════
-- MDT Open/Close Functions
-- ════════════════════════════════════════════════════════════════════
local function OpenMDT(playerData, department)
    if MDTOpen then return end
    
    MDTOpen = true
    PlayerData = playerData
    Department = department
    
    -- Set NUI Focus
    SetNuiFocus(true, true)
    
    -- Optional: Blur background
    if Config.UI.blurBackground then
        TriggerScreenblurFadeIn(250)
    end
    
    -- Send data to NUI
    SendNUIMessage({
        action = 'open',
        playerData = playerData,
        department = department,
        config = {
            departments = Config.Departments,
            ui = Config.UI,
            locale = Config.Locale
        }
    })
    
    -- Play sound if enabled
    if Config.UI.playSound then
        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
    
    -- Trigger tablet animation (optional)
    if Config.UI.useAnimation then
        RequestAnimDict("amb@code_human_in_bus_passenger_idles@female@tablet@base")
        while not HasAnimDictLoaded("amb@code_human_in_bus_passenger_idles@female@tablet@base") do
            Wait(0)
        end
        TaskPlayAnim(PlayerPedId(), "amb@code_human_in_bus_passenger_idles@female@tablet@base", "base", 8.0, -8.0, -1, 49, 0, false, false, false)
    end
    
    if Config.Debug then
        print('[medit8z-mdt] Opening MDT for department: ' .. department)
    end
end

local function CloseMDT()
    if not MDTOpen then return end
    
    MDTOpen = false
    
    -- Remove NUI Focus
    SetNuiFocus(false, false)
    
    -- Remove blur
    if Config.UI.blurBackground then
        TriggerScreenblurFadeOut(250)
    end
    
    -- Send close message to NUI
    SendNUIMessage({
        action = 'close'
    })
    
    -- Play sound if enabled
    if Config.UI.playSound then
        PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
    
    -- Stop tablet animation
    if Config.UI.useAnimation then
        ClearPedTasks(PlayerPedId())
    end
    
    if Config.Debug then
        print('[medit8z-mdt] MDT Closed')
    end
end

-- ════════════════════════════════════════════════════════════════════
-- ox_inventory Client Export
-- This is what ox_inventory is looking for
-- ════════════════════════════════════════════════════════════════════
exports('mdt_tablet', function(data, slot)
    -- Request MDT access from server
    local hasAccess, department = lib.callback.await('medit8z-mdt:server:checkAccess', false)
    if hasAccess then
        local playerData = lib.callback.await('medit8z-mdt:server:getPlayerData', false)
        if playerData then
            OpenMDT(playerData, department)
        else
            Notify('Failed to load player data', 'error')
        end
    else
        Notify('You don\'t have access to the MDT', 'error')
    end
end)

-- ════════════════════════════════════════════════════════════════════
-- Event Handlers
-- ════════════════════════════════════════════════════════════════════
RegisterNetEvent('medit8z-mdt:client:openMDT', function(playerData, department)
    OpenMDT(playerData, department)
end)

RegisterNetEvent('medit8z-mdt:client:closeMDT', function()
    CloseMDT()
end)

-- ════════════════════════════════════════════════════════════════════
-- NUI Callbacks
-- ════════════════════════════════════════════════════════════════════
RegisterNUICallback('close', function(data, cb)
    CloseMDT()
    cb('ok')
end)

RegisterNUICallback('loaded', function(data, cb)
    if Config.Debug then
        print('[medit8z-mdt] NUI Loaded Successfully')
    end
    cb('ok')
end)

RegisterNUICallback('error', function(data, cb)
    print('^1[medit8z-mdt] NUI Error:^7 ' .. (data.error or 'Unknown error'))
    cb('ok')
end)

RegisterNUICallback('getDashboardStats', function(data, cb)
    local stats = lib.callback.await('medit8z-mdt:server:getDashboardStats', false)
    cb(stats or {})
end)

RegisterNUICallback('searchProfiles', function(data, cb)
    local results = lib.callback.await('medit8z-mdt:server:searchProfiles', false, data.query)
    cb(results or {})
end)

-- ════════════════════════════════════════════════════════════════════
-- Keyboard Controls
-- ════════════════════════════════════════════════════════════════════
CreateThread(function()
    while true do
        if MDTOpen then
            -- ESC key to close
            if IsControlJustPressed(0, 322) or IsControlJustPressed(0, 177) then
                CloseMDT()
            end
            
            -- Disable other controls while MDT is open
            DisableControlAction(0, 1, true) -- Mouse look
            DisableControlAction(0, 2, true) -- Mouse look
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 47, true) -- Weapon
            DisableControlAction(0, 58, true) -- Weapon
            DisableControlAction(0, 140, true) -- Melee
            DisableControlAction(0, 141, true) -- Melee
            DisableControlAction(0, 142, true) -- Melee
            DisableControlAction(0, 143, true) -- Melee
            DisableControlAction(0, 263, true) -- Melee
            DisableControlAction(0, 264, true) -- Melee
            DisableControlAction(0, 257, true) -- Attack 2
        end
        Wait(0)
    end
end)

-- ════════════════════════════════════════════════════════════════════
-- Resource Cleanup
-- ════════════════════════════════════════════════════════════════════
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if MDTOpen then
        CloseMDT()
    end
end)

-- ════════════════════════════════════════════════════════════════════
-- Additional Exports for external use
-- ════════════════════════════════════════════════════════════════════
exports('IsOpen', function()
    return MDTOpen
end)

exports('GetDepartment', function()
    return Department
end)

exports('OpenMDT', function()
    local hasAccess, department = lib.callback.await('medit8z-mdt:server:checkAccess', false)
    if hasAccess then
        local playerData = lib.callback.await('medit8z-mdt:server:getPlayerData', false)
        if playerData then
            OpenMDT(playerData, department)
        end
    else
        Notify('You don\'t have access to the MDT', 'error')
    end
end)

exports('CloseMDT', function()
    CloseMDT()
end)

-- ════════════════════════════════════════════════════════════════════
-- ADD THIS TO THE BOTTOM OF client/main.lua
-- Complete fix for closing issues and cursor problems
-- ════════════════════════════════════════════════════════════════════

-- Debug Commands for Testing
if Config.Debug then
    -- Force close MDT and clear cursor
    RegisterCommand('mdtfixcursor', function()
        MDTOpen = false
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({ action = 'close' })
        
        if Config.UI.blurBackground then
            TriggerScreenblurFadeOut(250)
        end
        
        if Config.UI.useAnimation then
            ClearPedTasks(PlayerPedId())
        end
        
        print('^2[MDT Debug]^7 Force closed MDT and cleared cursor')
    end, false)
    
    -- Check MDT state
    RegisterCommand('mdtstate', function()
        print('^3[MDT Debug]^7 ════════════════════')
        print('^3[MDT Debug]^7 Is Open: ' .. tostring(MDTOpen))
        print('^3[MDT Debug]^7 NUI Focus: ' .. tostring(IsNuiFocusKeeping()))
        print('^3[MDT Debug]^7 NUI Has Focus: ' .. tostring(IsNuiFocus()))
        print('^3[MDT Debug]^7 Department: ' .. tostring(Department))
        print('^3[MDT Debug]^7 ════════════════════')
    end, false)
    
    -- Emergency reset
    RegisterCommand('mdtreset', function()
        -- Force close everything
        MDTOpen = false
        Department = nil
        PlayerData = {}
        
        -- Clear all UI states
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({ action = 'close' })
        
        -- Clear effects
        if Config.UI.blurBackground then
            TriggerScreenblurFadeOut(0)
            ClearTimecycleModifier()
        end
        
        -- Clear animations
        ClearPedTasks(PlayerPedId())
        
        print('^2[MDT Debug]^7 MDT completely reset')
    end, false)
end

-- Monitor for stuck cursor (failsafe)
CreateThread(function()
    while true do
        Wait(1000)
        -- We just rely on MDTOpen state
        -- If cursor gets stuck, use /mdtfixcursor
    end
end)

-- Ensure proper cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Force clear everything
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'close' })
    
    if Config.UI.blurBackground then
        TriggerScreenblurFadeOut(0)
        ClearTimecycleModifier()
    end
    
    ClearPedTasks(PlayerPedId())
end)

print('^2[medit8z-mdt]^7 Closing fix loaded - Use /mdtfixcursor if cursor gets stuck')