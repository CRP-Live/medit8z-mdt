local Framework = nil
local FrameworkName = Config.Framework

-- ════════════════════════════════════════════════════════════════════
-- Framework Detection & Setup
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
        else
            print('^1[medit8z-mdt]^7 No framework detected! Please install qbx_core, QB-Core or ESX')
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
    
    if Framework then
        print('^2[medit8z-mdt]^7 Framework detected: ' .. FrameworkName)
        print('^2[medit8z-mdt]^7 Using inventory: ' .. Config.Integration.inventory)
        print('^2[medit8z-mdt]^7 Using notifications: ' .. Config.Notifications.type)
    end
end)

-- ════════════════════════════════════════════════════════════════════
-- Utility Functions
-- ════════════════════════════════════════════════════════════════════
local function GetPlayer(source)
    if FrameworkName == 'qbx_core' then
        return exports.qbx_core:GetPlayer(source)
    elseif FrameworkName == 'qb-core' then
        return Framework.Functions.GetPlayer(source)
    elseif FrameworkName == 'esx' then
        return Framework.GetPlayerFromId(source)
    end
    return nil
end

local function GetPlayerJob(Player)
    if not Player then return nil, 0 end
    
    if FrameworkName == 'qbx_core' then
        return Player.PlayerData.job.name, Player.PlayerData.job.grade.level
    elseif FrameworkName == 'qb-core' then
        return Player.PlayerData.job.name, Player.PlayerData.job.grade.level
    elseif FrameworkName == 'esx' then
        return Player.job.name, Player.job.grade
    end
    return nil, 0
end

local function HasItem(source, item)
    if not Config.RequireItem then return true end
    
    -- Use ox_inventory for all frameworks when configured
    if Config.Integration.inventory == 'ox_inventory' then
        local count = exports.ox_inventory:Search(source, 'count', item)
        return count and count > 0
    end
    
    -- Fallback to framework-specific methods
    local Player = GetPlayer(source)
    if not Player then return false end
    
    if FrameworkName == 'qbx_core' or FrameworkName == 'qb-core' then
        local hasItem = Player.Functions.GetItemByName(item)
        return hasItem ~= nil
    elseif FrameworkName == 'esx' then
        local item = Player.getInventoryItem(item)
        return item and item.count > 0
    end
    return false
end

local function Notify(source, message, type)
    type = type or 'inform'
    
    if Config.Notifications.type == 'ox_lib' then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'MDT',
            description = message,
            type = type,
            position = Config.Notifications.position,
            duration = Config.Notifications.duration
        })
    elseif FrameworkName == 'qbx_core' then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'MDT',
            description = message,
            type = type
        })
    elseif FrameworkName == 'qb-core' then
        TriggerClientEvent('QBCore:Notify', source, message, type)
    elseif FrameworkName == 'esx' then
        TriggerClientEvent('esx:showNotification', source, message)
    end
end

-- ════════════════════════════════════════════════════════════════════
-- MDT Access Check
-- ════════════════════════════════════════════════════════════════════
local function CanAccessMDT(source)
    local Player = GetPlayer(source)
    if not Player then return false, nil end
    
    local job, rank = GetPlayerJob(Player)
    if not job then return false, nil end
    
    -- Check each department
    for deptName, dept in pairs(Config.Departments) do
        if dept.enabled then
            for _, allowedJob in ipairs(dept.jobs) do
                if job == allowedJob and rank >= dept.minRank then
                    return true, deptName
                end
            end
        end
    end
    
    return false, nil
end

-- ════════════════════════════════════════════════════════════════════
-- Item Usage (Tablet) - Using ox_inventory
-- ════════════════════════════════════════════════════════════════════
if Config.Integration.inventory == 'ox_inventory' then
    -- ox_inventory item usage
    exports('useTablet', function(event, item, inventory, slot, data)
        local src = inventory.id
        if not src then return end
        
        local hasAccess, department = CanAccessMDT(src)
        
        if not hasAccess then
            Notify(src, 'You don\'t have access to the MDT', 'error')
            return
        end
        
        -- Get player data
        local Player = GetPlayer(src)
        local playerData = {}
        
        if FrameworkName == 'qbx_core' then
            playerData = {
                name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                job = Player.PlayerData.job.name,
                jobLabel = Player.PlayerData.job.label,
                rank = Player.PlayerData.job.grade.level,
                rankLabel = Player.PlayerData.job.grade.name,
                department = department,
                citizenid = Player.PlayerData.citizenid,
                callsign = Player.PlayerData.metadata.callsign or 'N/A'
            }
        elseif FrameworkName == 'qb-core' then
            playerData = {
                name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                job = Player.PlayerData.job.name,
                jobLabel = Player.PlayerData.job.label,
                rank = Player.PlayerData.job.grade.level,
                rankLabel = Player.PlayerData.job.grade.name,
                department = department,
                citizenid = Player.PlayerData.citizenid,
                callsign = Player.PlayerData.metadata.callsign or 'N/A'
            }
        end
        
        -- Send to client to open MDT
        TriggerClientEvent('medit8z-mdt:client:openMDT', src, playerData, department)
        
        if Config.Debug then
            print('^2[medit8z-mdt]^7 ' .. GetPlayerName(src) .. ' opened MDT (Department: ' .. department .. ')')
        end
    end)
    
    -- Register the item with ox_inventory
    exports.ox_inventory:registerHook('useItem', function(event, item, inventory, slot, data)
        if item.name == Config.TabletItem then
            exports['medit8z-mdt']:useTablet(event, item, inventory, slot, data)
        end
    end)
    
elseif FrameworkName == 'qbx_core' then
    -- Qbox item usage (fallback if not using ox_inventory)
    exports.qbx_core:CreateUseableItem(Config.TabletItem, function(source, item)
        local src = source
        local hasAccess, department = CanAccessMDT(src)
        
        if not hasAccess then
            Notify(src, 'You don\'t have access to the MDT', 'error')
            return
        end
        
        local Player = GetPlayer(src)
        local playerData = {
            name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
            job = Player.PlayerData.job.name,
            jobLabel = Player.PlayerData.job.label,
            rank = Player.PlayerData.job.grade.level,
            rankLabel = Player.PlayerData.job.grade.name,
            department = department,
            citizenid = Player.PlayerData.citizenid,
            callsign = Player.PlayerData.metadata.callsign or 'N/A'
        }
        
        TriggerClientEvent('medit8z-mdt:client:openMDT', src, playerData, department)
        
        if Config.Debug then
            print('^2[medit8z-mdt]^7 ' .. GetPlayerName(src) .. ' opened MDT (Department: ' .. department .. ')')
        end
    end)
elseif FrameworkName == 'qb-core' then
    -- QB-Core item usage
    Framework.Functions.CreateUseableItem(Config.TabletItem, function(source, item)
        -- Similar code as above...
    end)
end

-- ════════════════════════════════════════════════════════════════════
-- Command Handler (if enabled)
-- ════════════════════════════════════════════════════════════════════
if Config.CommandEnabled then
    lib.addCommand(Config.Command, {
        help = 'Open the MDT',
        restricted = false
    }, function(source, args, raw)
        local src = source
        if src == 0 then return end -- Console cannot use MDT
        
        local hasAccess, department = CanAccessMDT(src)
        
        if not hasAccess then
            Notify(src, 'You don\'t have access to the MDT', 'error')
            return
        end
        
        -- Check for tablet item if required
        if Config.RequireItem and not HasItem(src, Config.TabletItem) then
            Notify(src, 'You need an MDT tablet to use this', 'error')
            return
        end
        
        -- Get player data
        local Player = GetPlayer(src)
        local playerData = {}
        
        if FrameworkName == 'qbx_core' or FrameworkName == 'qb-core' then
            playerData = {
                name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                job = Player.PlayerData.job.name,
                jobLabel = Player.PlayerData.job.label,
                rank = Player.PlayerData.job.grade.level,
                rankLabel = Player.PlayerData.job.grade.name,
                department = department,
                citizenid = Player.PlayerData.citizenid,
                callsign = Player.PlayerData.metadata.callsign or 'N/A'
            }
        else
            playerData = {
                name = Player.getName(),
                job = Player.job.name,
                jobLabel = Player.job.label,
                rank = Player.job.grade,
                rankLabel = Player.job.grade_label,
                department = department,
                citizenid = Player.identifier,
                callsign = Player.get('callsign') or 'N/A'
            }
        end
        
        -- Send to client to open MDT
        TriggerClientEvent('medit8z-mdt:client:openMDT', src, playerData, department)
        
        if Config.Debug then
            print('^2[medit8z-mdt]^7 ' .. GetPlayerName(src) .. ' opened MDT via command (Department: ' .. department .. ')')
        end
    end)
end

-- ════════════════════════════════════════════════════════════════════
-- Callbacks using ox_lib
-- ════════════════════════════════════════════════════════════════════
lib.callback.register('medit8z-mdt:server:checkAccess', function(source)
    local hasAccess, department = CanAccessMDT(source)
    return hasAccess, department
end)

lib.callback.register('medit8z-mdt:server:getPlayerData', function(source)
    local Player = GetPlayer(source)
    if not Player then return nil end
    
    local hasAccess, department = CanAccessMDT(source)
    if not hasAccess then return nil end
    
    if FrameworkName == 'qbx_core' or FrameworkName == 'qb-core' then
        return {
            name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
            job = Player.PlayerData.job.name,
            jobLabel = Player.PlayerData.job.label,
            rank = Player.PlayerData.job.grade.level,
            rankLabel = Player.PlayerData.job.grade.name,
            department = department,
            citizenid = Player.PlayerData.citizenid,
            callsign = Player.PlayerData.metadata.callsign or 'N/A'
        }
    end
    return nil
end)

-- ════════════════════════════════════════════════════════════════════
-- Exports for other resources
-- ════════════════════════════════════════════════════════════════════
exports('IsOnDuty', function(source)
    local Player = GetPlayer(source)
    if not Player then return false end
    
    if FrameworkName == 'qbx_core' or FrameworkName == 'qb-core' then
        return Player.PlayerData.job.onduty
    elseif FrameworkName == 'esx' then
        return true -- ESX doesn't have on-duty system by default
    end
    return false
end)

exports('GetDepartment', function(source)
    local hasAccess, department = CanAccessMDT(source)
    return department
end)

exports('HasMDTAccess', function(source)
    local hasAccess, department = CanAccessMDT(source)
    return hasAccess
end)

print('^2[medit8z-mdt]^7 Server-side loaded successfully!')