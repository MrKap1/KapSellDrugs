-- ====================================
-- CONFIG.LUA - Drug Selling System
-- ====================================

Config = {}

-- ====================================
-- COMMANDS
-- ====================================
Config.Command = "selldrugs"          -- Command to start selling
Config.StatsCommand = "dealerstats"   -- Command to check your stats
Config.CancelKey = 38                 -- "E" key to cancel deals

-- ====================================
-- COOLDOWN & TIMING
-- ====================================
Config.SaleCooldown = 30000           -- 30 seconds between sales (in milliseconds)
Config.SellTime = 8000                -- Base time for progress bar (8 seconds)
Config.MinimumSellTime = 2000         -- Fastest possible sell time (2 seconds)
Config.PedCleanupDelay = 15000        -- How long until ped is deleted after deal (15 seconds)

-- ====================================
-- PED SPAWNING
-- ====================================
Config.SpawnDistance = 15.0           -- How far away the buyer spawns
Config.RejectionChance = 0.15         -- 15% chance buyer rejects the deal

-- Different ped models for variety
Config.PedModels = { 
    "a_m_y_stbla_02",     -- Street guy
    "a_m_y_soucent_01",   -- South Central
    "g_m_y_famdnf_01",    -- Gang member
    "a_m_y_skater_01",    -- Skater
    "a_m_y_downtown_01",  -- Downtown guy
    "a_f_y_tourist_01",   -- Tourist
    "a_m_y_mexthug_01"    -- Mexican thug
}

-- ====================================
-- LEVELING SYSTEM
-- ====================================
Config.XPPerSale = 1                  -- Flat XP gained per successful sale
Config.XPNeeded = 100                 -- XP needed to level up

-- OPTIONAL: Speed bonus for higher levels
Config.LevelSpeedsUpSales = true      -- Enable faster sales as you level up
Config.SpeedBonusPerLevel = 150       -- Each level reduces time by 150ms

-- ====================================
-- POLICE ALERTS (Optional)
-- ====================================
Config.PoliceAlertEnabled = true      -- Enable random police alerts
Config.BasePoliceAlertChance = 0.05   -- 5% base chance
Config.AlertChancePerLevel = 0.005    -- +0.5% per level (level 10 = 10% chance)

-- ====================================
-- PRICE BONUSES PER LEVEL
-- ====================================
-- Format: [level] = bonus multiplier
-- 0.00 = 0% bonus (normal price)
-- 0.50 = 50% bonus (1.5x price)
-- 1.00 = 100% bonus (2x price)

Config.LevelRewards = {
    [1]  = 0.00,   -- Rookie
    [2]  = 0.05,   -- +5%
    [3]  = 0.10,   -- +10%
    [4]  = 0.15,   -- +15%
    [5]  = 0.25,   -- +25% (Quarter Hustler)
    [6]  = 0.30,   -- +30%
    [7]  = 0.35,   -- +35%
    [8]  = 0.40,   -- +40%
    [9]  = 0.45,   -- +45%
    [10] = 0.60,   -- +60% (Street Boss)
    [11] = 0.65,   -- +65%
    [12] = 0.70,   -- +70%
    [13] = 0.75,   -- +75%
    [14] = 0.80,   -- +80%
    [15] = 0.90,   -- +90% (Kingpin)
    [16] = 0.95,   -- +95%
    [17] = 1.00,   -- +100% (Double money!)
    [18] = 1.10,   -- +110%
    [19] = 1.20,   -- +120%
    [20] = 1.40,   -- +140% (Cartel Boss)
    [21] = 1.50,   -- +150%
    [22] = 1.60,   -- +160%
    [23] = 1.70,   -- +170%
    [24] = 1.80,   -- +180%
    [25] = 2.00,   -- +200% (Triple money!)
    [26] = 2.20,   -- +220%
    [27] = 2.40,   -- +240%
    [28] = 2.60,   -- +260%
    [29] = 2.80,   -- +280%
    [30] = 3.00,   -- +300% (Legendary Dealer)
}

-- Fallback for levels beyond your defined rewards
Config.MaxLevelFallback = 3.00        -- Players level 30+ get 300% bonus

-- ====================================
-- DRUG CONFIGURATIONS
-- ====================================
-- Add as many drugs as you want!
-- Format:
-- ["item_name"] = {
--     label = "Display Name",
--     minPrice = minimum price per item,
--     maxPrice = maximum price per item,
--     minAmount = minimum quantity buyer wants,
--     maxAmount = maximum quantity buyer wants
-- }

Config.Drugs = {
    ["weed_og-kush"] = { 
        label = "OG Kush", 
        minPrice = 40, 
        maxPrice = 80,
        minAmount = 1, 
        maxAmount = 5
    },
    
    ["weed_white-widow"] = { 
        label = "White Widow", 
        minPrice = 50, 
        maxPrice = 90,
        minAmount = 1, 
        maxAmount = 4
    },
    
    ["cocaine"] = { 
        label = "Cocaine", 
        minPrice = 100, 
        maxPrice = 200,
        minAmount = 1, 
        maxAmount = 3
    },
    
    ["meth"] = { 
        label = "Methamphetamine", 
        minPrice = 150, 
        maxPrice = 300,
        minAmount = 1, 
        maxAmount = 2
    },
    
    -- Add more drugs here following the same format
}