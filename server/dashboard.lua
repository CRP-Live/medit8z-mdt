-- ════════════════════════════════════════════════════════════════════
-- PHASE 2: REAL-TIME DASHBOARD SYSTEM
-- ════════════════════════════════════════════════════════════════════

local ActiveUnits = {}
local RecentCalls = {}
local ActiveWarrants = 0
local RecentArrests = {}
local ProbationList = {}

-- ════════════════════════════════════════════════════════════════════
-- Real-time Data Management
-- ════════════════════════════════════════════════════════════════════

-- Track active units
CreateThread(function()
    while true do
        -- Update active units every 5 seconds
        local players = GetPlayers()
        local tempUnits = {}
        
        for _, playerId in ipairs(players) do
            local src = tonumber(playerId)
            local Player = GetPlayer(src)
            
            if Player then
                local job, rank = GetPlayerJob(Player)
                
                -- Check if player is in a law enforcement job
                for deptName, dept in pairs(Config.Departments) do
                    if dept.enabled then
                        for _, allowedJob in ipairs(dept.jobs) do
                            local isOnDuty = IsOnDuty(src)
                            
                            if job == allowedJob and isOnDuty then
                                local callsign = 'N/A'
                                local unitStatus = '10-8'
                                
                                if Config.Framework == 'qbx_core' or Config.Framework == 'qb-core' then
                                    callsign = Player.PlayerData.metadata.callsign or 'N/A'
                                    unitStatus = Player.PlayerData.metadata.unitStatus or '10-8'
                                end
                                
                                table.insert(tempUnits, {
                                    id = src,
                                    name = GetPlayerName(playerId),
                                    callsign = callsign,
                                    status = unitStatus,
                                    department = deptName,
                                    location = GetEntityCoords(GetPlayerPed(playerId))
                                })
                                break
                            end
                        end
                    end
                end
            end
        end
        
        ActiveUnits = tempUnits
        
        -- Broadcast update to all MDT users
        TriggerClientEvent('medit8z-mdt:client:updateDashboard', -1, {
            activeUnits = #ActiveUnits,
            units = ActiveUnits
        })
        
        Wait(5000) -- Update every 5 seconds
    end
end)

-- ════════════════════════════════════════════════════════════════════
-- Recent Calls Management (3-minute retention)
-- ════════════════════════════════════════════════════════════════════
function AddRecentCall(callData)
    table.insert(RecentCalls, {
        id = #RecentCalls + 1,
        type = callData.type,
        location = callData.location,
        description = callData.description,
        timestamp = os.time(),
        units = callData.units or {}
    })
    
    -- Broadcast to all MDT users
    TriggerClientEvent('medit8z-mdt:client:newCall', -1, RecentCalls[#RecentCalls])
end

-- Clean up old calls (3-minute retention)
CreateThread(function()
    while true do
        local currentTime = os.time()
        local updated = false
        
        for i = #RecentCalls, 1, -1 do
            if currentTime - RecentCalls[i].timestamp > 180 then -- 3 minutes
                table.remove(RecentCalls, i)
                updated = true
            end
        end
        
        if updated then
            TriggerClientEvent('medit8z-mdt:client:updateDashboard', -1, {
                recentCalls = #RecentCalls
            })
        end
        
        Wait(10000) -- Check every 10 seconds
    end
end)

-- ════════════════════════════════════════════════════════════════════
-- Warrant Management
-- ════════════════════════════════════════════════════════════════════
local function LoadActiveWarrants()
    local warrants = MySQL.query.await('SELECT COUNT(*) as count FROM medit8z_mdt_warrants WHERE status = ?', {'active'})
    if warrants and warrants[1] then
        ActiveWarrants = warrants[1].count
    end
end

CreateThread(function()
    Wait(2000) -- Wait for database
    LoadActiveWarrants()
    
    -- Refresh warrants every minute
    while true do
        Wait(60000)
        LoadActiveWarrants()
        
        TriggerClientEvent('medit8z-mdt:client:updateDashboard', -1, {
            activeWarrants = ActiveWarrants
        })
    end
end)

-- ════════════════════════════════════════════════════════════════════
-- Recent Arrests Feed
-- ════════════════════════════════════════════════════════════════════
function AddRecentArrest(arrestData)
    table.insert(RecentArrests, 1, {
        id = #RecentArrests + 1,
        officer = arrestData.officer,
        suspect = arrestData.suspect,
        charges = arrestData.charges,
        timestamp = os.time()
    })
    
    -- Keep only last 10 arrests
    if #RecentArrests > 10 then
        table.remove(RecentArrests, 11)
    end
    
    -- Broadcast to all MDT users
    TriggerClientEvent('medit8z-mdt:client:newArrest', -1, RecentArrests[1])
end

-- ════════════════════════════════════════════════════════════════════
-- Probation List Management
-- ════════════════════════════════════════════════════════════════════
local function LoadProbationList()
    local probation = MySQL.query.await([[
        SELECT citizen_id, citizen_name, end_date 
        FROM medit8z_mdt_probation 
        WHERE status = 'active' 
        AND end_date > NOW()
        LIMIT 10
    ]])
    
    if probation then
        ProbationList = probation
    end
end

CreateThread(function()
    Wait(3000) -- Wait for database
    LoadProbationList()
    
    -- Refresh probation list every 5 minutes
    while true do
        Wait(300000)
        LoadProbationList()
        
        TriggerClientEvent('medit8z-mdt:client:updateProbation', -1, ProbationList)
    end
end)

-- ════════════════════════════════════════════════════════════════════
-- Dashboard Data Provider
-- ════════════════════════════════════════════════════════════════════
lib.callback.register('medit8z-mdt:server:getDashboardData', function(source)
    local hasAccess = HasMDTAccess(source)
    if not hasAccess then return nil end
    
    -- Get today's statistics
    local today = os.date("%Y-%m-%d")
    local department = GetDepartment(source)
    local todayStats = MySQL.query.await([[
        SELECT arrests, citations, reports 
        FROM medit8z_mdt_statistics 
        WHERE date = ? AND department = ?
    ]], {today, department})
    
    local stats = {
        totalArrests = 0,
        totalCitations = 0,
        totalReports = 0
    }
    
    if todayStats and todayStats[1] then
        stats.totalArrests = todayStats[1].arrests or 0
        stats.totalCitations = todayStats[1].citations or 0
        stats.totalReports = todayStats[1].reports or 0
    end
    
    return {
        activeUnits = #ActiveUnits,
        units = ActiveUnits,
        recentCalls = #RecentCalls,
        calls = RecentCalls,
        activeWarrants = ActiveWarrants,
        recentArrests = RecentArrests,
        probationList = ProbationList,
        statistics = stats
    }
end)

-- ════════════════════════════════════════════════════════════════════
-- Unit Status Management
-- ════════════════════════════════════════════════════════════════════
RegisterNetEvent('medit8z-mdt:server:updateUnitStatus', function(status)
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    
    -- Update player metadata
    if Config.Framework == 'qbx_core' or Config.Framework == 'qb-core' then
        Player.Functions.SetMetaData('unitStatus', status)
    end
    
    -- Update active units
    for _, unit in ipairs(ActiveUnits) do
        if unit.id == src then
            unit.status = status
            break
        end
    end
    
    -- Broadcast status change
    TriggerClientEvent('medit8z-mdt:client:unitStatusChanged', -1, {
        unitId = src,
        status = status,
        name = GetPlayerName(src)
    })
    
    -- Log status change
    LogMDTAction(src, 'status_change', 'unit', tostring(src), {
        newStatus = status
    })
end)

-- ════════════════════════════════════════════════════════════════════
-- Global Search System
-- ════════════════════════════════════════════════════════════════════
lib.callback.register('medit8z-mdt:server:globalSearch', function(source, query)
    local hasAccess = HasMDTAccess(source)
    if not hasAccess then return {} end
    
    local results = {
        profiles = {},
        vehicles = {},
        incidents = {},
        weapons = {}
    }
    
    -- Search profiles
    local profiles = MySQL.query.await([[
        SELECT citizen_id, first_name, last_name, phone 
        FROM medit8z_mdt_profiles 
        WHERE first_name LIKE ? OR last_name LIKE ? OR phone LIKE ?
        LIMIT 5
    ]], {'%'..query..'%', '%'..query..'%', '%'..query..'%'})
    
    if profiles then
        results.profiles = profiles
    end
    
    -- Search vehicles
    local vehicles = MySQL.query.await([[
        SELECT plate, owner_name, make, model 
        FROM medit8z_mdt_vehicles 
        WHERE plate LIKE ? OR owner_name LIKE ?
        LIMIT 5
    ]], {'%'..query..'%', '%'..query..'%'})
    
    if vehicles then
        results.vehicles = vehicles
    end
    
    -- Search incidents
    local incidents = MySQL.query.await([[
        SELECT incident_number, title, created_at 
        FROM medit8z_mdt_incidents 
        WHERE incident_number LIKE ? OR title LIKE ?
        LIMIT 5
    ]], {'%'..query..'%', '%'..query..'%'})
    
    if incidents then
        results.incidents = incidents
    end
    
    return results
end)

-- ════════════════════════════════════════════════════════════════════
-- Notification System
-- ════════════════════════════════════════════════════════════════════
function SendMDTNotification(targetId, notification)
    TriggerClientEvent('medit8z-mdt:client:receiveNotification', targetId, {
        id = math.random(100000, 999999),
        type = notification.type or 'info',
        title = notification.title,
        message = notification.message,
        timestamp = os.time(),
        actions = notification.actions or {}
    })
end

-- Send notification to all units
function BroadcastToUnits(notification)
    for _, unit in ipairs(ActiveUnits) do
        SendMDTNotification(unit.id, notification)
    end
end

-- ════════════════════════════════════════════════════════════════════
-- Panic Button
-- ════════════════════════════════════════════════════════════════════
-- ════════════════════════════════════════════════════════════════════
-- Panic Button (Enhanced with error handling)
-- ════════════════════════════════════════════════════════════════════
RegisterNetEvent('medit8z-mdt:server:panicButton', function()
    local src = source
    
    -- Add debug logging
    if Config.Debug then
        print('[MDT] Panic button triggered by source:', src)
    end
    
    local Player = GetPlayer(src)
    if not Player then 
        print('[MDT] Error: Could not get player for panic button')
        return 
    end
    
    -- Get player ped and coords safely
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        print('[MDT] Error: Invalid player ped for panic button')
        return
    end
    
    local coords = GetEntityCoords(ped)
    if not coords then
        coords = {x = 0, y = 0, z = 0}
        print('[MDT] Warning: Could not get player coords for panic button')
    end
    
    -- Add emergency call
    if AddRecentCall then
        AddRecentCall({
            type = '10-99',
            location = string.format('%.2f, %.2f', coords.x, coords.y),
            description = 'OFFICER PANIC BUTTON - ' .. GetPlayerName(src),
            units = {src}
        })
    end
    
    -- Send notification to all units
    if BroadcastToUnits then
        BroadcastToUnits({
            type = 'emergency',
            title = '10-99 OFFICER EMERGENCY',
            message = GetPlayerName(src) .. ' has activated panic button!',
            actions = {
                {label = 'Set GPS', action = 'setgps', data = coords}
            }
        })
    end
    
    -- Play alert sound for all units
    if ActiveUnits then
        for _, unit in ipairs(ActiveUnits) do
            TriggerClientEvent('medit8z-mdt:client:playAlert', unit.id, 'panic')
        end
    end
    
    -- Log the panic button activation
    if LogMDTAction then
        LogMDTAction(src, 'panic_button', 'emergency', tostring(src), {
            location = coords,
            officer = GetPlayerName(src)
        })
    end
    
    if Config.Debug then
        print('[MDT] Panic button successfully activated by', GetPlayerName(src))
    end
end)

if Config.Debug then
    RegisterCommand('testpanic', function(source, args, rawCommand)
        if source == 0 then
            print('This command must be run in-game')
            return
        end
        
        print('[MDT Debug] Testing panic button for', GetPlayerName(source))
        TriggerEvent('medit8z-mdt:server:panicButton')
    end, false)
end

if Config.Debug then
    RegisterCommand('testpanic2', function(source, args, rawCommand)
        if source == 0 then
            print('This command must be run in-game')
            return
        end
        
        print('[MDT Debug] Manual panic test for source:', source)
        
        local coords = GetEntityCoords(GetPlayerPed(source))
        
        -- Bypass GetPlayer for testing
        AddRecentCall({
            type = '10-99',
            location = string.format('%.2f, %.2f', coords.x, coords.y),
            description = 'OFFICER PANIC BUTTON - ' .. GetPlayerName(source),
            units = {source}
        })
        
        BroadcastToUnits({
            type = 'emergency',
            title = '10-99 OFFICER EMERGENCY',
            message = GetPlayerName(source) .. ' has activated panic button!',
            actions = {
                {label = 'Set GPS', action = 'setgps', data = coords}
            }
        })
        
        print('[MDT Debug] Panic button test completed')
    end, false)
end

-- ════════════════════════════════════════════════════════════════════
-- Export Functions
-- ════════════════════════════════════════════════════════════════════
function GetActiveUnits()
    return ActiveUnits
end

exports('AddRecentCall', AddRecentCall)
exports('AddRecentArrest', AddRecentArrest)
exports('SendMDTNotification', SendMDTNotification)
exports('BroadcastToUnits', BroadcastToUnits)
exports('GetActiveUnits', GetActiveUnits)

print('^2[medit8z-mdt]^7 Phase 2 Dashboard System Loaded')