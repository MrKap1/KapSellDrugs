Config = {}
Config.Command = "selldrugs"
Config.CancelKey = 38 -- "E"

-- Ped Spawning
Config.SpawnDistance = 15.0 
Config.PedModels = { "a_m_y_stbla_02", "a_m_y_soucent_01", "g_m_y_famdnf_01" }

-- Leveling System
Config.XPPerSale = 1
Config.XPNeeded = 100

Config.SellTime = 10000 -- Base time in milliseconds (5 seconds)

-- OPTIONAL: If true, higher levels sell faster
Config.LevelSpeedsUpSales = true 
Config.SpeedBonusPerLevel = 100 -- Each level subtracts 100ms from the time
Config.MinimumSellTime = 1000   -- The fastest a deal can ever be (2 seconds)

-- Define specific bonus per level reached
-- 0.00 = 0% | 0.10 = 10% | 0.25 = 25%, etc.
Config.LevelRewards = {
    [1] = 0.00,  -- Starter
    [2] = 0.10,  -- Associate
    [3] = 0.20,  -- Dealer
    [4] = 0.35,  -- Hustler
    [5] = 0.50,  -- Kingpin
    [6] = 0.60,  -- Street Boss
    [7] = 0.70,
    [8] = 0.80,
    [9] = 0.90,
    [10] = 1.00, -- Double Money (100% bonus)
    [11] = 1.05,
    [12] = 1.10,
    [13] = 1.15,
    [14] = 1.20,
    [15] = 1.30, -- Veteran Dealer
    [16] = 1.35,
    [17] = 1.40,
    [18] = 1.45,
    [19] = 1.50,
    [20] = 1.65, -- Underworld Mogul
    [21] = 1.70,
    [22] = 1.75,
    [23] = 1.80,
    [24] = 1.90,
    [25] = 2.00  -- Triple Money (200% bonus)
}

-- Make sure to update this fallback so Level 26+ keeps the 200% bonus
Config.MaxLevelFallback = 2.00

Config.Drugs = {
    ["weed_og-kush"] = { 
        label = "Bag of Weed", 
        minPrice = 50, 
        maxPrice = 100,
        minAmount = 1, -- MINIMUM amount the ped will ask for
        maxAmount = 5  -- MAXIMUM amount the ped will ask for
    }
}