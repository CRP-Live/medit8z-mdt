-- ════════════════════════════════════════════════════════════════════
-- PHASE 2: SERVER UTILITY FUNCTIONS
-- ════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════
-- Logging Functions
-- ════════════════════════════════════════════════════════════════════
function LogMDTAction(userId, action, targetType, targetId, details)
    MySQL.insert([[
        INSERT INTO medit8z_mdt_logs (user_id, user_name, action, target_type, target_id, details) 
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {
        userId,
        GetPlayerName(userId) or 'System',
        action,
        targetType,
        targetId,
        json.encode(details or {})
    })
    
    -- Also log to activity feed for dashboard
    LogActivity(action, userId, targetType, targetId, details)
end

function LogActivity(type, userId, targetType, targetId, metadata)
    MySQL.insert([[
        INSERT INTO medit8z_mdt_activity (type, action, user_id, user_name, target_type, target_id, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        type,
        'created', -- Default action
        userId,
        GetPlayerName(userId) or 'System',
        targetType,
        targetId,
        json.encode(metadata or {})
    })
end

-- ════════════════════════════════════════════════════════════════════
-- Discord Webhook Logging
-- ════════════════════════════════════════════════════════════════════
function SendWebhook(webhookType, title, description, color, fields)
    if not Config.Webhooks.enabled then return end
    
    local webhook = Config.Webhooks.urls[webhookType]
    if not webhook or webhook == "" then return end
    
    local embed = {
        {
            title = title,
            description = description,
            color = color or 3447003,
            fields = fields or {},
            footer = {
                text = "MDT System | " .. os.date("%Y-%m-%d %H:%M:%S")
            }
        }
    }
    
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
        username = "MDT System",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- ════════════════════════════════════════════════════════════════════
-- Statistics Tracking
-- ════════════════════════════════════════════════════════════════════
function UpdateDailyStatistics(department, statType, increment)
    increment = increment or 1
    local today = os.date("%Y-%m-%d")
    
    -- Check if record exists for today
    local existing = MySQL.query.await([[
        SELECT id FROM medit8z_mdt_statistics 
        WHERE date = ? AND department = ?
    ]], {today, department})
    
    if existing and existing[1] then
        -- Update existing record
        MySQL.update.await(string.format([[
            UPDATE medit8z_mdt_statistics 
            SET %s = %s + ? 
            WHERE date = ? AND department = ?
        ]], statType, statType), {increment, today, department})
    else
        -- Create new record
        MySQL.insert.await(string.format([[
            INSERT INTO medit8z_mdt_statistics (date, department, %s) 
            VALUES (?, ?, ?)
        ]], statType), {today, department, increment})
    end
end

-- ════════════════════════════════════════════════════════════════════
-- Utility Helpers
-- ════════════════════════════════════════════════════════════════════
function GenerateUniqueId(prefix)
    local timestamp = os.time()
    local random = math.random(1000, 9999)
    return string.format("%s-%d-%d", prefix, timestamp, random)
end

function FormatDateTime(timestamp)
    if not timestamp then return "N/A" end
    return os.date("%Y-%m-%d %H:%M:%S", timestamp)
end

function GetTimeDifference(startTime, endTime)
    endTime = endTime or os.time()
    local diff = endTime - startTime
    
    if diff < 60 then
        return diff .. " seconds"
    elseif diff < 3600 then
        return math.floor(diff / 60) .. " minutes"
    elseif diff < 86400 then
        return math.floor(diff / 3600) .. " hours"
    else
        return math.floor(diff / 86400) .. " days"
    end
end

-- ════════════════════════════════════════════════════════════════════
-- Data Validation
-- ════════════════════════════════════════════════════════════════════
function ValidateInput(input, inputType)
    if not input then return false end
    
    if inputType == 'citizenid' then
        return string.match(input, "^[A-Z0-9]+$") ~= nil
    elseif inputType == 'phone' then
        return string.match(input, "^%d%d%d%-?%d%d%d%d$") ~= nil
    elseif inputType == 'plate' then
        return string.match(input, "^[A-Z0-9 ]+$") ~= nil
    elseif inputType == 'name' then
        return string.len(input) >= 2 and string.len(input) <= 50
    end
    
    return true
end

-- ════════════════════════════════════════════════════════════════════
-- Permission Checking
-- ════════════════════════════════════════════════════════════════════
function HasPermission(source, permission)
    local Player = exports['medit8z-mdt']:GetPlayer(source)
    if not Player then return false end
    
    local job, rank = exports['medit8z-mdt']:GetPlayerJob(Player)
    
    -- Check MDT access
    local hasAccess = exports['medit8z-mdt']:HasMDTAccess(source)
    local department = exports['medit8z-mdt']:GetDepartment(source)
    
    if not hasAccess then return false end
    
    -- Check department-specific permissions
    local deptConfig = Config.Departments[department]
    if not deptConfig then return false end
    
    -- Check if feature is enabled for department
    if deptConfig.features and deptConfig.features[permission] == false then
        return false
    end
    
    -- Check rank requirements for specific permissions
    local rankRequirements = {
        deleteReports = 3,
        approveWarrants = 5,
        modifyRoster = 7,
        systemAdmin = 10
    }
    
    if rankRequirements[permission] and rank < rankRequirements[permission] then
        return false
    end
    
    return true
end

-- ════════════════════════════════════════════════════════════════════
-- Notification Queue Management
-- ════════════════════════════════════════════════════════════════════
local NotificationQueue = {}

function QueueNotification(targetId, notification)
    if not NotificationQueue[targetId] then
        NotificationQueue[targetId] = {}
    end
    
    table.insert(NotificationQueue[targetId], notification)
    
    -- Store in database for persistence
    MySQL.insert.await([[
        INSERT INTO medit8z_mdt_notifications 
        (recipient_id, type, title, message, data) 
        VALUES (?, ?, ?, ?, ?)
    ]], {
        targetId,
        notification.type,
        notification.title,
        notification.message,
        json.encode(notification.data or {})
    })
end

function GetQueuedNotifications(playerId)
    local notifications = NotificationQueue[playerId] or {}
    NotificationQueue[playerId] = {} -- Clear queue after retrieval
    
    -- Also get unread from database
    local dbNotifications = MySQL.query.await([[
        SELECT * FROM medit8z_mdt_notifications 
        WHERE recipient_id = ? AND read = 0 
        ORDER BY created_at DESC LIMIT 10
    ]], {playerId})
    
    if dbNotifications then
        for _, notif in ipairs(dbNotifications) do
            table.insert(notifications, {
                id = notif.id,
                type = notif.type,
                title = notif.title,
                message = notif.message,
                data = json.decode(notif.data or '{}'),
                timestamp = notif.created_at
            })
        end
        
        -- Mark as read
        MySQL.update.await([[
            UPDATE medit8z_mdt_notifications 
            SET read = 1 
            WHERE recipient_id = ? AND read = 0
        ]], {playerId})
    end
    
    return notifications
end

-- ════════════════════════════════════════════════════════════════════
-- Export Utility Functions
-- ════════════════════════════════════════════════════════════════════
exports('LogMDTAction', LogMDTAction)
exports('SendWebhook', SendWebhook)
exports('UpdateDailyStatistics', UpdateDailyStatistics)
exports('GenerateUniqueId', GenerateUniqueId)
exports('ValidateInput', ValidateInput)
exports('HasPermission', HasPermission)
exports('QueueNotification', QueueNotification)
exports('GetQueuedNotifications', GetQueuedNotifications)

print('^2[medit8z-mdt]^7 Phase 2 Utilities Loaded')