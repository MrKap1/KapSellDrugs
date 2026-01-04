-- ====================================
-- CLIENT.LUA - Drug Selling System
-- ====================================

local isSelling = false
local currentPed = nil
local lastSaleTime = 0

-- Constants
local TASK_GO_STRAIGHT = 1073741824
local ANIM_FLAG_UPPERBODY = 49

-- ====================================
-- MAIN COMMAND
-- ====================================
RegisterCommand(Config.Command, function()
    -- Cooldown check
    local timeSinceLastSale = GetGameTimer() - lastSaleTime
    if timeSinceLastSale < Config.SaleCooldown then
        local remaining = math.ceil((Config.SaleCooldown - timeSinceLastSale) / 1000)
        lib.notify({
            title = 'Too Soon',
            description = ('Wait %s seconds before selling again'):format(remaining),
            type = 'error'
        })
        return
    end

    if not isSelling then
        TriggerEvent('drugsale:startProcess')
    else
        if currentPed and not DoesEntityExist(currentPed) then
            StopSelling("Previous deal glitched. Resetting...")
            TriggerEvent('drugsale:startProcess')
        else
            lib.notify({title = 'Busy', description = "You're already in a deal!", type = 'error'})
        end
    end
end, false)

-- ====================================
-- SELLING PROCESS
-- ====================================
RegisterNetEvent('drugsale:startProcess')
AddEventHandler('drugsale:startProcess', function()
    local playerPed = PlayerPedId()
    
    -- Check inventory
    local availableDrug = lib.callback.await('drugsale:checkInventory', false)
    if not availableDrug then 
        lib.notify({
            title = 'No Drugs', 
            description = 'You have nothing to sell!', 
            type = 'error'
        })
        return 
    end

    isSelling = true
    LocalPlayer.state:set('invBusy', true, true)
    
    -- Spawn buyer ped
    local model = GetHashKey(Config.PedModels[math.random(#Config.PedModels)])
    lib.requestModel(model, 5000) 
    
    local spawnPos = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, Config.SpawnDistance, 0.0)
    currentPed = CreatePed(4, model, spawnPos.x, spawnPos.y, spawnPos.z, 0.0, true, false)
    
    SetNetworkIdCanMigrate(ObjToNet(currentPed), true)
    SetEntityAsMissionEntity(currentPed, true, true)
    SetBlockingOfNonTemporaryEvents(currentPed, true)
    
    TaskGoToEntity(currentPed, playerPed, -1, 1.5, 2.0, TASK_GO_STRAIGHT, 0)
    
    lib.notify({
        title = 'Buyer Approaching',
        description = 'Press ~r~[E]~s~ to cancel the deal',
        type = 'inform'
    })

    -- Main selling loop
    Citizen.CreateThread(function()
        while isSelling do
            if not DoesEntityExist(currentPed) or IsPedDeadOrDying(currentPed, true) then
                StopSelling("The buyer left or died.")
                break
            end

            -- Cancel key
            if IsControlJustPressed(0, Config.CancelKey) then
                StopSelling("You cancelled the deal.")
                break
            end

            local pCoords = GetEntityCoords(playerPed)
            local cCoords = GetEntityCoords(currentPed)
            local dist = #(pCoords - cCoords)

            -- Performance optimization: only check every frame when close
            if dist < 2.5 then
                Citizen.Wait(0)
                
                if dist < 2.0 then
                    -- Buyer reached player
                    ClearPedTasks(currentPed)
                    TaskTurnPedToFaceEntity(currentPed, playerPed, 1000)
                    TaskTurnPedToFaceEntity(playerPed, currentPed, 1000)
                    Citizen.Wait(500)
                    
                    -- Random rejection chance
                    if math.random() < Config.RejectionChance then
                        StopSelling("The buyer got cold feet and left.")
                        break
                    end
                    
                    -- Get transaction details from server
                    local dealInfo = lib.callback.await('drugsale:prepareDeal', false, availableDrug)
                    
                    if not dealInfo then
                        StopSelling("Something went wrong with the deal.")
                        break
                    end
                    
                    -- Check if player still has enough
                    local currentCount = exports.ox_inventory:GetItemCount(availableDrug)
                    if currentCount < dealInfo.amount then
                        StopSelling(("Buyer wanted %sx but you don't have enough!"):format(dealInfo.amount))
                        break
                    end
                    
                    -- Calculate sell time based on level
                    local duration = dealInfo.duration
                    
                    -- Load animation
                    local animDict = "mp_common"
                    local animName = "givetake1_a"
                    lib.requestAnimDict(animDict)
                    Citizen.Wait(100)
                    
                    -- Progress bar
                    local success = lib.progressBar({
                        duration = duration,
                        label = ('Selling %sx %s...'):format(dealInfo.amount, dealInfo.label),
                        useWhileDead = false,
                        canCancel = true,
                        disable = { move = true, car = true, combat = true, mouse = false },
                        anim = { dict = animDict, clip = animName, flag = ANIM_FLAG_UPPERBODY },
                    })

                    if success then
                        -- Complete transaction on server
                        TriggerServerEvent('drugsale:completeTransaction', dealInfo.transactionId)
                        lastSaleTime = GetGameTimer()
                        StopSelling()
                    else
                        StopSelling("You cancelled the exchange.")
                    end
                    
                    break 
                end
            else
                Citizen.Wait(250) -- Far away, check less frequently
            end
        end
    end)
end)

-- ====================================
-- CLEANUP FUNCTION
-- ====================================
function StopSelling(msg)
    isSelling = false 
    LocalPlayer.state:set('invBusy', false, true)

    if msg then 
        lib.notify({
            title = 'Deal Over',
            description = msg,
            type = 'inform'
        }) 
    end
    
    if currentPed then
        ClearPedTasksImmediately(currentPed)
        TaskWanderStandard(currentPed, 10.0, 10)
        SetPedAsNoLongerNeeded(currentPed)
        
        local pedToCleanup = currentPed
        currentPed = nil 
        
        Citizen.SetTimeout(Config.PedCleanupDelay, function()
            if DoesEntityExist(pedToCleanup) then
                DeletePed(pedToCleanup)
            end
        end)
    end
end

-- ====================================
-- STATS CHECK COMMAND
-- ====================================
RegisterCommand(Config.StatsCommand, function()
    local stats = lib.callback.await('drugsale:getStats', false)
    if stats then
        local bonusPercent = math.floor((Config.LevelRewards[stats.level] or Config.MaxLevelFallback) * 100)
        local nextLevelXP = Config.XPNeeded - stats.xp
        
        lib.alertDialog({
            header = '💊 Dealer Profile',
            content = ('**Level:** %s  \n**XP:** %s / %s (%s to next level)  \n**Price Bonus:** +%s%%  \n**Total Sales:** %s'):format(
                stats.level, 
                stats.xp, 
                Config.XPNeeded, 
                nextLevelXP,
                bonusPercent,
                stats.totalSales or 0
            ),
            centered = true,
            cancel = false
        })
    else
        lib.notify({description = "You have no dealer history yet.", type = "error"})
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if currentPed and DoesEntityExist(currentPed) then
            DeletePed(currentPed)
        end
    end
end)