if not MySQL then
    print("^1ERROR: oxmysql was not found! Make sure it is started before this script.^7")
end

local playerLevels = {}

-- Helper to get player identifier
local function getIdentifier(source)
    return GetPlayerIdentifierByType(source, 'license')
end

-- Load player data from DB
local function loadPlayerData(source)
    local identifier = getIdentifier(source)
    local result = MySQL.single.await('SELECT level, xp FROM player_drug_stats WHERE identifier = ?', {identifier})
    
    if result then
        playerLevels[source] = { level = result.level, xp = result.xp }
    else
        MySQL.insert.await('INSERT INTO player_drug_stats (identifier, level, xp) VALUES (?, ?, ?)', {identifier, 1, 0})
        playerLevels[source] = { level = 1, xp = 0 }
    end
    return playerLevels[source]
end

-- Check Inventory Callback
lib.callback.register('drugsale:checkInventory', function(source)
    if not playerLevels[source] then loadPlayerData(source) end
    
    for drugName, _ in pairs(Config.Drugs) do
        local count = exports.ox_inventory:GetItemCount(source, drugName)
        if count > 0 then return true end
    end
    return false
end)

-- Process Transaction
RegisterNetEvent('drugsale:processTransaction')
AddEventHandler('drugsale:processTransaction', function(amountToSell)
    local src = source
    local drugToSell = nil
    local amount = amountToSell or 1 

    -- Find which drug the player has enough of
    for drugName, _ in pairs(Config.Drugs) do
        local itemCount = exports.ox_inventory:GetItemCount(src, drugName)
        if itemCount >= amount then
            drugToSell = drugName
            break
        end
    end

    if drugToSell then
        local pData = playerLevels[src] or loadPlayerData(src)
        local drugData = Config.Drugs[drugToSell]

        local currentLevel = pData.level
        local bonusPercent = Config.LevelRewards[currentLevel] or Config.MaxLevelFallback
        
        local basePrice = math.random(drugData.minPrice, drugData.maxPrice)
        local priceWithBonus = math.floor(basePrice * (1 + bonusPercent))
        local finalTotalPrice = priceWithBonus * amount

        if exports.ox_inventory:RemoveItem(src, drugToSell, amount) then
            exports.ox_inventory:AddItem(src, 'money', finalTotalPrice)

            -- FIXED: XP is now flat per transaction (1 deal = Config.XPPerSale)
            local earnedXP = Config.XPPerSale 
            pData.xp = pData.xp + earnedXP

            -- Handle Level Up
            while pData.xp >= Config.XPNeeded do
                pData.level = pData.level + 1
                pData.xp = pData.xp - Config.XPNeeded
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Level Up!', 
                    description = ('You are now level %s! Bonus: %s%%'):format(pData.level, (Config.LevelRewards[pData.level] or Config.MaxLevelFallback) * 100), 
                    type = 'success'
                })
            end

            -- Notification for the sale
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Sale Complete',
                description = ('Sold %sx %s for $%s'):format(amount, drugData.label, finalTotalPrice),
                type = 'success'
            })

            -- SAVE TO DATABASE
            MySQL.update.await('UPDATE player_drug_stats SET level = ?, xp = ? WHERE identifier = ?', {
                pData.level, pData.xp, getIdentifier(src)
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Deal Failed',
            description = 'You do not have enough items to complete this deal!',
            type = 'error'
        })
    end
end)

-- Level Check Command
RegisterCommand("druglevel", function(source)
    local pData = playerLevels[source] or loadPlayerData(source)
    local currentBonus = (Config.LevelRewards[pData.level] or Config.MaxLevelFallback) * 100
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Drug Dealer Stats',
        description = ('Level: %s | XP: %s/%s\nCurrent Bonus: %s%%'):format(
            pData.level, pData.xp, Config.XPNeeded, currentBonus
        ),
        type = 'inform'
    })
end)

-- Clear RAM on leave
AddEventHandler('playerDropped', function()
    playerLevels[source] = nil
end)

-- Stats Callback
lib.callback.register('drugsale:getStats', function(source)
    return playerLevels[source] or loadPlayerData(source)
end)