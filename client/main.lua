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

-- ════════════════════════════════════════════════════════════════════
-- ox_target Integration (for future use)
-- ════════════════════════════════════════════════════════════════════
if Config.Integration.target == 'ox_target' then
    -- Example: Add target to evidence lockers, computers, etc.
    -- This will be used in later phases
    
    -- exports.ox_target:addModel('prop_computer_01', {
    --     {
    --         name = 'mdt_computer',
    --         icon = 'fas fa-laptop',
    --         label = 'Access MDT',
    --         onSelect = function()
    --             TriggerEvent('medit8z-mdt:client:openFromComputer')
    --         end,
    --         canInteract = function(entity, distance, coords, name)
    --             return lib.callback.await('medit8z-mdt:server:checkAccess', false)
    --         end
    --     }
    -- })
end

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
-- Exports
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