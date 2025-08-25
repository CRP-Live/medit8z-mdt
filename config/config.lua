Config = {}

-- ════════════════════════════════════════════════════════════════════
-- Framework Settings
-- ════════════════════════════════════════════════════════════════════
Config.Framework = 'qbx_core' -- 'qbx_core', 'qb-core', 'esx', 'auto'
Config.Mysql = 'oxmysql' -- Always use oxmysql with qbx_core

-- ════════════════════════════════════════════════════════════════════
-- MDT Access Settings
-- ════════════════════════════════════════════════════════════════════
Config.TabletItem = 'mdt_tablet' -- Item required to open MDT
Config.RequireItem = true -- Require the tablet item to open MDT
Config.CommandEnabled = false -- Allow /mdt command as backup
Config.Command = 'mdt' -- Command to open MDT (if enabled)

-- ════════════════════════════════════════════════════════════════════
-- Department Configuration
-- ════════════════════════════════════════════════════════════════════
Config.Departments = {
    -- Police Department
    Police = {
        enabled = true,
        jobs = {'police', 'lspd', 'bcso', 'sasp', 'sheriff', 'trooper', 'ranger'},
        minRank = 0, -- Minimum rank required to access MDT
        maxRank = 10, -- Maximum rank (for chief/commissioner features)
        features = {
            dashboard = true,
            profiles = true,
            incidents = true,
            reports = true,
            warrants = true,
            bolos = true,
            dmv = true,
            weapons = true,
            cameras = true,
            staffLogs = true,
            towing = true,
            sops = true,
            roster = true
        },
        callsign = {
            enabled = true,
            format = "###", -- Format: # = number, A = letter
            prefix = "" -- Optional prefix (e.g., "LSPD-")
        }
    },
    
    -- Emergency Medical Services
    EMS = {
        enabled = true,
        jobs = {'ambulance', 'ems', 'doctor', 'medical', 'fire'},
        minRank = 0,
        maxRank = 10,
        features = {
            dashboard = true,
            profiles = true,
            medical = true,
            reports = true,
            icu = true,
            roster = true,
            sops = true,
            staffLogs = true,
            towing = true
        },
        callsign = {
            enabled = true,
            format = "M##",
            prefix = ""
        }
    },
    
    -- Department of Justice
    DOJ = {
        enabled = true,
        jobs = {'judge', 'lawyer', 'attorney', 'da', 'public_defender'},
        minRank = 0,
        maxRank = 10,
        features = {
            warrants = true, -- Approve/Deny warrants
            arrests = true, -- View arrest records
            incidents = true, -- Read-only access
            evidence = true, -- Read-only access
            weapons = true, -- View weapon registrations
            court = true, -- Court scheduling
            sentencing = true -- Sentencing records
        }
    },
    
    -- Towing Services
    Towing = {
        enabled = true,
        jobs = {'tow', 'mechanic', 'towing', 'impound'},
        minRank = 0,
        maxRank = 5,
        features = {
            dashboard = true,
            requests = true,
            impound = true,
            billing = true,
            reports = true,
            roster = true,
            sops = true,
            staffLogs = true
        },
        companies = { -- Different towing companies
            ['tow'] = {
                name = "Los Santos Towing",
                color = "#FFA500"
            },
            ['mechanic'] = {
                name = "LS Customs Towing",
                color = "#FF6B6B"
            }
        }
    }
}

-- ════════════════════════════════════════════════════════════════════
-- UI Settings
-- ════════════════════════════════════════════════════════════════════
Config.UI = {
    scale = 0.8, -- UI Scale (0.5 - 1.0)
    theme = 'dark', -- 'dark' or 'light'
    blurBackground = true, -- Blur game when MDT is open
    playSound = true, -- Play sound when opening/closing
    useAnimation = true, -- Use tablet animation when MDT is open
    animationSpeed = 300, -- Animation speed in ms
}

-- ════════════════════════════════════════════════════════════════════
-- Keybinds
-- ════════════════════════════════════════════════════════════════════
Config.Keybinds = {
    close = 'ESCAPE', -- Key to close MDT
    submit = 'ENTER', -- Key to submit forms
    switchTab = 'TAB', -- Key to switch tabs
}

-- ════════════════════════════════════════════════════════════════════
-- Performance Settings
-- ════════════════════════════════════════════════════════════════════
Config.Performance = {
    cacheTime = 300, -- Cache time in seconds
    maxSearchResults = 50, -- Maximum search results
    pagination = 20, -- Items per page
    autoSaveInterval = 30, -- Auto-save interval in seconds
    refreshInterval = 5, -- Dashboard refresh interval in seconds
}

-- ════════════════════════════════════════════════════════════════════
-- Database Settings
-- ════════════════════════════════════════════════════════════════════
Config.Database = {
    tables = {
        profiles = 'medit8z_mdt_profiles',
        incidents = 'medit8z_mdt_incidents',
        reports = 'medit8z_mdt_reports',
        warrants = 'medit8z_mdt_warrants',
        bolos = 'medit8z_mdt_bolos',
        vehicles = 'medit8z_mdt_vehicles',
        weapons = 'medit8z_mdt_weapons',
        evidence = 'medit8z_mdt_evidence',
        logs = 'medit8z_mdt_logs',
        towing = 'medit8z_mdt_towing',
        medical = 'medit8z_mdt_medical',
        court = 'medit8z_mdt_court'
    }
}

-- ════════════════════════════════════════════════════════════════════
-- Webhook Settings (Discord Logging)
-- ════════════════════════════════════════════════════════════════════
Config.Webhooks = {
    enabled = false, -- Enable Discord webhook logging
    urls = {
        general = "", -- General MDT actions
        warrants = "", -- Warrant creation/approval
        arrests = "", -- Arrest logging
        evidence = "", -- Evidence management
        admin = "" -- Admin actions (deletions, etc.)
    }
}

-- ════════════════════════════════════════════════════════════════════
-- Debug Settings
-- ════════════════════════════════════════════════════════════════════
Config.Debug = true -- Enable debug prints (disable in production)

-- ════════════════════════════════════════════════════════════════════
-- Integration Settings
-- ════════════════════════════════════════════════════════════════════
Config.Integration = {
    target = 'ox_target', -- Target system for interactions
    lib = 'ox_lib', -- Library for notifications, menus, etc.
    inventory = 'ox_inventory', -- Inventory resource for item checks
    phone = 'lb-phone', -- Phone resource for notifications
    screenshot = 'screenshot-basic', -- Screenshot resource for evidence
    garage = 'custom', -- Custom garage system (will need exports)
    banking = 'qbx_banking', -- Banking resource for fines
    housing = 'qs-housing', -- Housing resource for property data
}

-- ════════════════════════════════════════════════════════════════════
-- Language Settings
-- ════════════════════════════════════════════════════════════════════
Config.Locale = 'en' -- Language setting

-- ════════════════════════════════════════════════════════════════════
-- Notification Settings
-- ════════════════════════════════════════════════════════════════════
Config.Notifications = {
    type = 'ox_lib', -- 'ox_lib', 'qb-core', 'esx', 'custom'
    position = 'top-right', -- For ox_lib notifications
    duration = 3000, -- Duration in ms
}

-- ════════════════════════════════════════════════════════════════════
-- Custom Integration Exports
-- ════════════════════════════════════════════════════════════════════
Config.CustomExports = {
    -- Define your custom garage exports here
    garage = {
        getVehicles = 'your_garage:getPlayerVehicles', -- Export to get player vehicles
        getVehicleByPlate = 'your_garage:getVehicleByPlate', -- Export to get vehicle by plate
        setImpounded = 'your_garage:setImpounded', -- Export to impound vehicle
        isImpounded = 'your_garage:isImpounded' -- Export to check impound status
    },
    -- qs-housing exports
    housing = {
        getPlayerHouses = 'qs-housing:GetPlayerHouses', -- Get player properties
        getHouseByCoords = 'qs-housing:GetClosestHouse', -- Get house at location
        hasKeys = 'qs-housing:HasKeys' -- Check if player has keys
    }
}

-- Export for other resources
exports('GetConfig', function()
    return Config
end)