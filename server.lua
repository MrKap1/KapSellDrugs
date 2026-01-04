-- ====================================
-- SERVER.LUA - Drug Selling System
-- ====================================

if not MySQL then
    print("^1[ERROR] oxmysql not found! This resource will not work.^7")
end

local playerStats = {}
local pendingTransactions = {}

-- ====================================
-- HELPER FUNCTIONS
-- ====================================
local function getIdentifier(source)
    return GetPlayerIdentifierByType(source, 'license')
end

local function loadPlayerData(source)
    local identifier = getIdentifier(source)
    if not identifier then return nil end
    
    local result = MySQL.single.await('SELECT level, xp, total_sales FROM player_drug_stats WHERE identifier = ?', {identifier})
    
    if result then
        playerStats[source] = { 
            level = result.level, 
            xp = result.xp,
            totalSales = result.total_sales or 0
        }
    else
        MySQL.insert.await('INSERT INTO player_drug_stats (identifier, level, xp, total_sales) VALUES (?, ?, ?, ?)', 
            {identifier, 1, 0, 0})
        playerStats[source] = { level = 1, xp = 0, totalSales = 0 }
    end
    
    return playerStats[source]
end

local function savePlayerData(source)
    local stats = playerStats[source]
    if not stats then return end
    
    local identifier = getIdentifier(source)
    if not identifier then return end
    
    MySQL.update.await('UPDATE player_drug_stats SET level = ?, xp = ?, total_sales = ? WHERE identifier = ?', {
        stats.level, stats.xp, stats.totalSales, identifier
    })
end

-- ====================================
-- INVENTORY CHECK CALLBACK
-- ====================================
lib.callback.register('drugsale:checkInventory', function(source)
    if not playerStats[source] then 
        loadPlayerData(source) 
    end
    
    -- Return the first drug the player has
    for drugName, _ in pairs(Config.Drugs) do
        local count = exports.ox_inventory:GetItemCount(source, drugName)
        if count > 0 then 
            return drugName 
        end
    end
    
    return false
end)

-- ====================================
-- PREPARE DEAL CALLBACK
-- ====================================
lib.callback.register('drugsale:prepareDeal', function(source, drugName)
    local stats = playerStats[source] or loadPlayerData(source)
    if not stats then return nil end
    
    local drugConfig = Config.Drugs[drugName]
    if not drugConfig then return nil end
    
    -- Generate transaction details
    local amount = math.random(drugConfig.minAmount, drugConfig.maxAmount)
    local basePrice = math.random(drugConfig.minPrice, drugConfig.maxPrice)
    local bonusMultiplier = Config.LevelRewards[stats.level] or Config.MaxLevelFallback
    local pricePerItem = math.floor(basePrice * (1 + bonusMultiplier))
    local totalPrice = pricePerItem * amount
    
    -- Calculate sell duration based on level
    local duration = Config.SellTime
    if Config.LevelSpeedsUpSales then
        duration = Config.SellTime - (stats.level * Config.SpeedBonusPerLevel)
        if duration < Config.MinimumSellTime then 
            duration = Config.MinimumSellTime 
        end
    end
    
    -- Create unique transaction ID
    local transactionId = ("%s_%s"):format(source, os.time())
    
    -- Store transaction details
    pendingTransactions[transactionId] = {
        source = source,
        drugName = drugName,
        amount = amount,
        totalPrice = totalPrice,
        timestamp = os.time()
    }
    
    return {
        transactionId = transactionId,
        amount = amount,
        label = drugConfig.label,
        totalPrice = totalPrice,
        duration = duration
    }
end)

-- ====================================
-- COMPLETE TRANSACTION
-- ====================================
RegisterNetEvent('drugsale:completeTransaction')
AddEventHandler('drugsale:completeTransaction', function(transactionId)
    local src = source
    
    -- Validate transaction exists
    local transaction = pendingTransactions[transactionId]
    if not transaction then 
        print(("^3[WARNING] Invalid transaction attempted by %s^7"):format(GetPlayerName(src)))
        return 
    end
    
    -- Validate it's the right player
    if transaction.source ~= src then
        print(("^1[SECURITY] Player %s tried to complete someone else's transaction!^7"):format(GetPlayerName(src)))
        return
    end
    
    -- Check transaction isn't too old (prevent replay attacks)
    if (os.time() - transaction.timestamp) > 60 then
        pendingTransactions[transactionId] = nil
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Deal Expired',
            description = 'Transaction took too long',
            type = 'error'
        })
        return
    end
    
    -- Validate inventory
    local currentCount = exports.ox_inventory:GetItemCount(src, transaction.drugName)
    if currentCount < transaction.amount then
        pendingTransactions[transactionId] = nil
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Deal Failed',
            description = "You don't have enough items!",
            type = 'error'
        })
        return
    end
    
    -- Remove items
    if not exports.ox_inventory:RemoveItem(src, transaction.drugName, transaction.amount) then
        pendingTransactions[transactionId] = nil
        return
    end
    
    -- Add money
    exports.ox_inventory:AddItem(src, 'money', transaction.totalPrice)
    
    -- Update stats
    local stats = playerStats[src] or loadPlayerData(src)
    stats.xp = stats.xp + Config.XPPerSale
    stats.totalSales = stats.totalSales + 1
    
    -- Check for level up
    local leveledUp = false
    while stats.xp >= Config.XPNeeded do
        stats.level = stats.level + 1
        stats.xp = stats.xp - Config.XPNeeded
        leveledUp = true
        
        local newBonus = math.floor((Config.LevelRewards[stats.level] or Config.MaxLevelFallback) * 100)
        TriggerClientEvent('ox_lib:notify', src, {
            title = '🎉 Level Up!', 
            description = ('You reached level %s!\nPrice Bonus: +%s%%'):format(stats.level, newBonus), 
            type = 'success',
            duration = 7000
        })
    end
    
    -- Save to database
    savePlayerData(src)
    
    -- Success notification
    local drugConfig = Config.Drugs[transaction.drugName]
    TriggerClientEvent('ox_lib:notify', src, {
        title = '💰 Sale Complete',
        description = ('Sold %sx %s for $%s%s'):format(
            transaction.amount, 
            drugConfig.label, 
            transaction.totalPrice,
            leveledUp and '\n+' .. Config.XPPerSale .. ' XP' or ''
        ),
        type = 'success'
    })
    
    -- Check for police alert
    if Config.PoliceAlertEnabled then
        local alertChance = Config.BasePoliceAlertChance + (stats.level * Config.AlertChancePerLevel)
        if math.random() < alertChance then
            -- Trigger your police system here
            local playerCoords = GetEntityCoords(GetPlayerPed(src))
            TriggerEvent('police:drugSaleAlert', playerCoords, src)
            
            TriggerClientEvent('ox_lib:notify', src, {
                title = '🚨 Alert',
                description = 'Someone may have seen you!',
                type = 'warning'
            })
        end
    end
    
    -- Clean up transaction
    pendingTransactions[transactionId] = nil
end)

-- ====================================
-- GET STATS CALLBACK
-- ====================================
lib.callback.register('drugsale:getStats', function(source)
    return playerStats[source] or loadPlayerData(source)
end)

-- ====================================
-- ADMIN COMMANDS
-- ====================================
RegisterCommand("resetdealerstats", function(source, args)
    if source == 0 or IsPlayerAceAllowed(source, "admin") then
        local targetId = tonumber(args[1])
        if targetId and GetPlayerName(targetId) then
            local identifier = getIdentifier(targetId)
            MySQL.update.await('UPDATE player_drug_stats SET level = 1, xp = 0, total_sales = 0 WHERE identifier = ?', {identifier})
            playerStats[targetId] = { level = 1, xp = 0, totalSales = 0 }
            
            if source > 0 then
                TriggerClientEvent('ox_lib:notify', source, {
                    description = 'Reset stats for ' .. GetPlayerName(targetId),
                    type = 'success'
                })
            end
            
            TriggerClientEvent('ox_lib:notify', targetId, {
                title = 'Stats Reset',
                description = 'Your dealer stats have been reset by an admin',
                type = 'inform'
            })
        else
            if source > 0 then
                TriggerClientEvent('ox_lib:notify', source, {
                    description = 'Invalid player ID',
                    type = 'error'
                })
            end
        end
    end
end, true)

RegisterCommand("setdealerlevel", function(source, args)
    if source == 0 or IsPlayerAceAllowed(source, "admin") then
        local targetId = tonumber(args[1])
        local newLevel = tonumber(args[2])
        
        if targetId and newLevel and GetPlayerName(targetId) then
            local stats = playerStats[targetId] or loadPlayerData(targetId)
            stats.level = newLevel
            stats.xp = 0
            savePlayerData(targetId)
            
            if source > 0 then
                TriggerClientEvent('ox_lib:notify', source, {
                    description = ('Set %s to level %s'):format(GetPlayerName(targetId), newLevel),
                    type = 'success'
                })
            end
            
            TriggerClientEvent('ox_lib:notify', targetId, {
                description = ('Your level was set to %s'):format(newLevel),
                type = 'inform'
            })
        end
    end
end, true)

-- ====================================
-- PLAYER LOADING/CLEANUP
-- ====================================
AddEventHandler('playerJoining', function()
    local src = source
    Citizen.SetTimeout(2000, function()
        loadPlayerData(src)
    end)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if playerStats[src] then
        savePlayerData(src)
        playerStats[src] = nil
    end
    
    -- Clean up any pending transactions
    for transactionId, transaction in pairs(pendingTransactions) do
        if transaction.source == src then
            pendingTransactions[transactionId] = nil
        end
    end
end)

-- Periodic cleanup of old transactions (every 5 minutes)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000) -- 5 minutes
        local currentTime = os.time()
        for transactionId, transaction in pairs(pendingTransactions) do
            if (currentTime - transaction.timestamp) > 120 then
                pendingTransactions[transactionId] = nil
            end
        end
    end
end)