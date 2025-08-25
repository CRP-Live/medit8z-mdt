local Framework = nil
local FrameworkName = Config.Framework

-- ════════════════════════════════════════════════════════════════════
-- Framework Detection & Setup
-- ════════════════════════════════════════════════════════════════════
-- At the top of server/main.lua, fix the framework detection
CreateThread(function()
    Wait(100) -- Small delay to ensure resources are loaded
    
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
    
    -- Debug print to verify
    if Config.Debug then
        print('^2[medit8z-mdt]^7 Framework initialized:', FrameworkName)
        print('^2[medit8z-mdt]^7 Framework object exists:', Framework ~= nil)
    end
end)

-- Fix the GetPlayer function
function GetPlayer(source)
    if not source or source == 0 then return nil end
    
    if FrameworkName == 'qbx_core' then
        return exports.qbx_core:GetPlayer(source)
    elseif FrameworkName == 'qb-core' then
        if Framework and Framework.Functions then
            return Framework.Functions.GetPlayer(source)
        end
    elseif FrameworkName == 'esx' then
        if Framework then
            return Framework.GetPlayerFromId(source)
        end
    end
    
    -- Debug if player not found
    if Config.Debug then
        print('^1[MDT Debug]^7 GetPlayer failed for source:', source, 'Framework:', FrameworkName)
    end
    
    return nil
end

-- ════════════════════════════════════════════════════════════════════
-- Utility Functions
-- ════════════════════════════════════════════════════════════════════
function GetPlayer(source)
    if FrameworkName == 'qbx_core' then
        return exports.qbx_core:GetPlayer(source)
    elseif FrameworkName == 'qb-core' then
        return Framework.Functions.GetPlayer(source)
    elseif FrameworkName == 'esx' then
        return Framework.GetPlayerFromId(source)
    end
    return nil
end

function GetPlayerJob(Player)
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

local function GetPlayerData(source)
    local Player = GetPlayer(source)
    if not Player then return nil end
    
    local hasAccess, department = CanAccessMDT(source)
    if not hasAccess then return nil end
    
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
    elseif FrameworkName == 'esx' then
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
    
    return playerData
end

local function HasItem(source, item)
    if not Config.RequireItem then return true end
    
    if Config.Integration.inventory == 'ox_inventory' then
        local count = exports.ox_inventory:Search(source, 'count', item)
        return count and count > 0
    end
    
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
function CanAccessMDT(source)
    local Player = GetPlayer(source)
    if not Player then return false, nil end
    
    local job, rank = GetPlayerJob(Player)
    if not job then return false, nil end
    
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
-- Open MDT Function
-- ════════════════════════════════════════════════════════════════════
local function OpenMDTForPlayer(src)
    local hasAccess, department = CanAccessMDT(src)
    
    if not hasAccess then
        Notify(src, 'You don\'t have access to the MDT', 'error')
        return
    end
    
    local playerData = GetPlayerData(src)
    if not playerData then
        Notify(src, 'Failed to load player data', 'error')
        return
    end
    
    TriggerClientEvent('medit8z-mdt:client:openMDT', src, playerData, department)
    
    if Config.Debug then
        print('^2[medit8z-mdt]^7 ' .. GetPlayerName(src) .. ' opened MDT (Department: ' .. department .. ')')
    end
end

-- ════════════════════════════════════════════════════════════════════
-- ox_inventory Integration (Simplified)
-- ════════════════════════════════════════════════════════════════════
function SetupMDTItem()
    if Config.Integration.inventory == 'ox_inventory' then
        Wait(1000)
        
        -- Simple event-based approach for ox_inventory
        print('^2[medit8z-mdt]^7 Waiting for ox_inventory item usage...')
        
    elseif FrameworkName == 'qbx_core' then
        exports.qbx_core:CreateUseableItem(Config.TabletItem, function(source, item)
            OpenMDTForPlayer(source)
        end)
    elseif FrameworkName == 'qb-core' then
        Framework.Functions.CreateUseableItem(Config.TabletItem, function(source, item)
            OpenMDTForPlayer(source)
        end)
    elseif FrameworkName == 'esx' then
        Framework.RegisterUsableItem(Config.TabletItem, function(source)
            OpenMDTForPlayer(source)
        end)
    end
end

-- ════════════════════════════════════════════════════════════════════
-- ox_inventory Event Handler (Primary method for ox_inventory)
-- ════════════════════════════════════════════════════════════════════
AddEventHandler('ox_inventory:usedItem', function(playerId, name, slotId, metadata)
    if name == 'mdt_tablet' then
        local hasAccess, department = CanAccessMDT(playerId)
        if hasAccess then
            local playerData = GetPlayerData(playerId)
            if playerData then
                TriggerClientEvent('medit8z-mdt:client:openMDT', playerId, playerData, department)
                if Config.Debug then
                    print('^2[medit8z-mdt]^7 MDT opened via ox_inventory for player: ' .. GetPlayerName(playerId))
                end
            else
                Notify(playerId, 'Failed to load player data', 'error')
            end
        else
            Notify(playerId, 'You don\'t have access to the MDT', 'error')
        end
    end
end)

-- ════════════════════════════════════════════════════════════════════
-- Command Handler
-- ════════════════════════════════════════════════════════════════════
if Config.CommandEnabled then
    lib.addCommand(Config.Command, {
        help = 'Open the MDT',
        restricted = false
    }, function(source, args, raw)
        local src = source
        if src == 0 then return end
        
        if Config.RequireItem and not HasItem(src, Config.TabletItem) then
            Notify(src, 'You need an MDT tablet to use this', 'error')
            return
        end
        
        OpenMDTForPlayer(src)
    end)
end

-- ════════════════════════════════════════════════════════════════════
-- Callbacks
-- ════════════════════════════════════════════════════════════════════
lib.callback.register('medit8z-mdt:server:checkAccess', function(source)
    local hasAccess, department = CanAccessMDT(source)
    return hasAccess, department
end)

lib.callback.register('medit8z-mdt:server:getPlayerData', function(source)
    return GetPlayerData(source)
end)

lib.callback.register('medit8z-mdt:server:getDashboardStats', function(source)
    local hasAccess = CanAccessMDT(source)
    if not hasAccess then return {} end
    
    return {
        activeUnits = 0,
        recentCalls = 0,
        activeWarrants = 0
    }
end)

lib.callback.register('medit8z-mdt:server:searchProfiles', function(source, query)
    local hasAccess = CanAccessMDT(source)
    if not hasAccess then return {} end
    
    if not query or query == "" then return {} end
    
    -- Search the players table directly
    local searchTerm = '%' .. query .. '%'
    
    local results = MySQL.query.await([[
        SELECT 
            citizenid,
            license,
            name,
            charinfo,
            job,
            money
        FROM players 
        WHERE 
            citizenid LIKE ? OR
            license LIKE ? OR
            name LIKE ? OR
            charinfo LIKE ?
        LIMIT 20
    ]], {searchTerm, searchTerm, searchTerm, searchTerm})
    
    if not results then return {} end
    
    -- Parse and format the results
    local formattedResults = {}
    for i = 1, #results do
        local player = results[i]
        local charinfo = json.decode(player.charinfo or '{}')
        local job = json.decode(player.job or '{}')
        local name = json.decode(player.name or '{}')
        
        table.insert(formattedResults, {
            citizenid = player.citizenid,
            firstname = charinfo.firstname or 'Unknown',
            lastname = charinfo.lastname or 'Unknown',
            fullname = (charinfo.firstname or 'Unknown') .. ' ' .. (charinfo.lastname or 'Unknown'),
            phone = charinfo.phone or 'N/A',
            dob = charinfo.birthdate or 'N/A',
            job = job.label or 'Unemployed',
            accountname = name or 'N/A'
        })
    end
    
    return formattedResults
end)

-- Add this new callback for getting full profile details
lib.callback.register('medit8z-mdt:server:getProfile', function(source, citizenid)
    local hasAccess = CanAccessMDT(source)
    if not hasAccess then return nil end
    
    -- Get basic player data
    local playerData = MySQL.query.await([[
        SELECT * FROM players WHERE citizenid = ?
    ]], {citizenid})
    
    if not playerData or not playerData[1] then
        return nil
    end
    
    local player = playerData[1]
    local charinfo = json.decode(player.charinfo or '{}')
    local job = json.decode(player.job or '{}')
    
    -- Check if MDT profile exists
    local mdtProfile = MySQL.query.await([[
        SELECT * FROM medit8z_mdt_profiles WHERE citizen_id = ?
    ]], {citizenid})
    
    local profile = {
        -- Basic info from players table
        citizenid = player.citizenid,
        firstname = charinfo.firstname or 'Unknown',
        lastname = charinfo.lastname or 'Unknown',
        dob = charinfo.birthdate or 'N/A',
        gender = charinfo.gender == 0 and 'Male' or 'Female',
        phone = charinfo.phone or 'N/A',
        job = job.label or 'Unemployed',
        
        -- MDT specific info (if exists)
        notes = '',
        flags = {},
        fingerprint = '',
        dna = '',
        photo = '',
        warnings = 0,
        arrests = 0
    }
    
    -- If MDT profile exists, add that data
    if mdtProfile and mdtProfile[1] then
        local mdt = mdtProfile[1]
        profile.notes = mdt.notes or ''
        profile.flags = json.decode(mdt.flags or '[]')
        profile.fingerprint = mdt.fingerprint or ''
        profile.dna = mdt.dna or ''
        profile.photo = mdt.photo or ''
    else
        -- Create MDT profile if it doesn't exist
        MySQL.insert.await([[
            INSERT INTO medit8z_mdt_profiles 
            (citizen_id, first_name, last_name, dob, gender, phone) 
            VALUES (?, ?, ?, ?, ?, ?)
        ]], {
            citizenid,
            charinfo.firstname or 'Unknown',
            charinfo.lastname or 'Unknown',
            charinfo.birthdate,
            charinfo.gender == 0 and 'Male' or 'Female',
            charinfo.phone
        })
    end
    
    return profile
end)

-- Update profile notes/flags (MDT specific data)
lib.callback.register('medit8z-mdt:server:updateProfile', function(source, citizenid, data)
    local hasAccess = CanAccessMDT(source)
    if not hasAccess then return false end
    
    -- Check if profile exists
    local exists = MySQL.query.await([[
        SELECT id FROM medit8z_mdt_profiles WHERE citizen_id = ?
    ]], {citizenid})
    
    if exists and exists[1] then
        -- Update existing profile
        MySQL.update.await([[
            UPDATE medit8z_mdt_profiles 
            SET notes = ?, flags = ?, updated_at = NOW()
            WHERE citizen_id = ?
        ]], {
            data.notes or '',
            json.encode(data.flags or {}),
            citizenid
        })
    else
        -- Get player info for new profile
        local playerData = MySQL.query.await([[
            SELECT charinfo FROM players WHERE citizenid = ?
        ]], {citizenid})
        
        if playerData and playerData[1] then
            local charinfo = json.decode(playerData[1].charinfo or '{}')
            
            -- Create new profile
            MySQL.insert.await([[
                INSERT INTO medit8z_mdt_profiles 
                (citizen_id, first_name, last_name, notes, flags) 
                VALUES (?, ?, ?, ?, ?)
            ]], {
                citizenid,
                charinfo.firstname or 'Unknown',
                charinfo.lastname or 'Unknown',
                data.notes or '',
                json.encode(data.flags or {})
            })
        end
    end
    
    -- Log the action
    LogMDTAction(source, 'profile_update', 'profile', citizenid, data)
    
    return true
end)

-- ════════════════════════════════════════════════════════════════════
-- Database Initialization
-- ════════════════════════════════════════════════════════════════════
CreateThread(function()
    Wait(2000)
    
    local success = MySQL.query.await('SELECT 1 FROM medit8z_mdt_profiles LIMIT 1')
    if success == nil then
        print('^3[medit8z-mdt]^7 Database tables not found! Please run install.sql')
    else
        print('^2[medit8z-mdt]^7 Database tables verified')
    end
end)

-- ════════════════════════════════════════════════════════════════════
-- Global Export Functions
-- ════════════════════════════════════════════════════════════════════
function IsOnDuty(source)
    local Player = GetPlayer(source)
    if not Player then return false end
    
    if FrameworkName == 'qbx_core' or FrameworkName == 'qb-core' then
        return Player.PlayerData.job.onduty
    elseif FrameworkName == 'esx' then
        return true
    end
    return false
end

function GetDepartment(source)
    local hasAccess, department = CanAccessMDT(source)
    return department
end

function HasMDTAccess(source)
    local hasAccess, department = CanAccessMDT(source)
    return hasAccess
end

-- Register exports
exports('IsOnDuty', IsOnDuty)
exports('GetDepartment', GetDepartment)
exports('HasMDTAccess', HasMDTAccess)
exports('GetPlayer', GetPlayer)
exports('GetPlayerJob', GetPlayerJob)

-- ════════════════════════════════════════════════════════════════════
-- Debug Commands (Remove in production)
-- ════════════════════════════════════════════════════════════════════
if Config.Debug then
    RegisterCommand('mdtcheck', function(source)
        if source == 0 then
            print('This command must be run in-game')
            return
        end
        local hasAccess, department = CanAccessMDT(source)
        print('^3[MDT Debug]^7 Player: ' .. GetPlayerName(source))
        print('^3[MDT Debug]^7 Has Access: ' .. tostring(hasAccess))
        print('^3[MDT Debug]^7 Department: ' .. tostring(department))
        
        local Player = GetPlayer(source)
        if Player then
            local job, rank = GetPlayerJob(Player)
            print('^3[MDT Debug]^7 Job: ' .. tostring(job) .. ' Rank: ' .. tostring(rank))
        end
    end, false)
    
    RegisterCommand('mdtforce', function(source)
        if source == 0 then
            print('This command must be run in-game')
            return
        end
        TriggerClientEvent('medit8z-mdt:client:openMDT', source, {
            name = 'Test User',
            job = 'police',
            jobLabel = 'Police',
            rank = 5,
            rankLabel = 'Sergeant',
            department = 'Police',
            citizenid = 'TEST123',
            callsign = '123'
        }, 'Police')
        print('^2[MDT Debug]^7 Force opened MDT for ' .. GetPlayerName(source))
    end, false)
    
    RegisterCommand('givemdttablet', function(source, args)
        if source == 0 then
            print('This command must be run in-game')
            return
        end
        
        if Config.Integration.inventory == 'ox_inventory' then
            exports.ox_inventory:AddItem(source, 'mdt_tablet', 1)
            Notify(source, 'You received an MDT Tablet', 'success')
        else
            print('This command only works with ox_inventory')
        end
    end, false)
end

-- Add this command to set callsign
RegisterCommand('callsign', function(source, args, rawCommand)
    if source == 0 then return end
    
    local Player = GetPlayer(source)
    if not Player then return end
    
    local newCallsign = args[1]
    if not newCallsign then
        Notify(source, 'Usage: /callsign [number]', 'error')
        return
    end
    
    -- Set callsign based on framework
    if FrameworkName == 'qbx_core' or FrameworkName == 'qb-core' then
        Player.Functions.SetMetaData('callsign', newCallsign)
    elseif FrameworkName == 'esx' then
        Player.set('callsign', newCallsign)
    end
    
    Notify(source, 'Callsign set to: ' .. newCallsign, 'success')
end, false)

print('^2[medit8z-mdt]^7 Server-side loaded successfully!')