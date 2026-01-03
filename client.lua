local isSelling = false
local currentPed = nil

-- REGISTER THE COMMAND
RegisterCommand(Config.Command, function()
    if not isSelling then
        TriggerEvent('drugsale:startProcess')
    else
        if currentPed and not DoesEntityExist(currentPed) then
            StopSelling("Previous deal glitched. Resetting...")
            TriggerEvent('drugsale:startProcess')
        else
            lib.notify({description = "You are already in a deal!", type = 'error'})
        end
    end
end, false)

RegisterNetEvent('drugsale:startProcess')
AddEventHandler('drugsale:startProcess', function()
    local playerPed = PlayerPedId()
    
    local hasDrug = lib.callback.await('drugsale:checkInventory', false)
    if not hasDrug then 
        lib.notify({title = 'No Drugs', description = 'You have nothing to sell!', type = 'error'})
        isSelling = false 
        return 
    end

    isSelling = true
    
    local model = GetHashKey(Config.PedModels[math.random(#Config.PedModels)])
    lib.requestModel(model, 5000) 
    
    local spawnPos = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, Config.SpawnDistance, 0.0)
    currentPed = CreatePed(4, model, spawnPos.x, spawnPos.y, spawnPos.z, 0.0, true, false)
    
    SetNetworkIdCanMigrate(ObjToNet(currentPed), true)
    SetEntityAsMissionEntity(currentPed, true, true)
    
    TaskGoToEntity(currentPed, playerPed, -1, 1.2, 1.2, 1073741824, 0)
    lib.notify({description = "A buyer is approaching. Press [E] to cancel.", type = 'inform'})

    Citizen.CreateThread(function()
        while isSelling do
            Citizen.Wait(0) 
            
            if not DoesEntityExist(currentPed) or IsPedDeadOrDying(currentPed) then
                StopSelling("The buyer left or died.")
                break
            end

            -- Cancel while approaching
            if IsControlJustPressed(0, Config.CancelKey) then
                StopSelling("You cancelled the deal.")
                break
            end

            local pCoords = GetEntityCoords(PlayerPedId())
            local cCoords = GetEntityCoords(currentPed)
            local dist = #(pCoords - cCoords)

            if dist < 2.0 then
                ClearPedTasks(currentPed)
                TaskTurnPedToFaceEntity(currentPed, PlayerPedId(), 1000)
                TaskTurnPedToFaceEntity(PlayerPedId(), currentPed, 1000)
                
                local drugName = "weed_og-kush" 
                local drugConf = Config.Drugs[drugName]
                local randomAmount = math.random(drugConf.minAmount, drugConf.maxAmount)
                local stats = lib.callback.await('drugsale:getStats', false)
                local currentCount = exports.ox_inventory:GetItemCount(drugName)

                if currentCount < randomAmount then
                    StopSelling("Buyer wanted "..randomAmount.."x, but you don't have enough!")
                    break
                end

                local duration = Config.SellTime
                if Config.LevelSpeedsUpSales and stats then
                    duration = Config.SellTime - (stats.level * (Config.SpeedBonusPerLevel or 0))
                    if duration < (Config.MinimumSellTime or 1000) then duration = Config.MinimumSellTime end
                end

                local animDict = "mp_common_miss"
                local animName = "low_fives"
                lib.requestAnimDict(animDict)
                Citizen.Wait(500) 

                -- FIX: Create a watcher thread to listen for 'E' during the Progress Bar
                Citizen.CreateThread(function()
                    while lib.progressActive() do
                        Citizen.Wait(0)
                        if IsControlJustPressed(0, Config.CancelKey) then
                            lib.cancelProgress() -- This forces the progress bar to fail
                        end
                    end
                end)

                -- PROGRESS BAR
                local success = lib.progressBar({
                    duration = duration,
                    label = ('Exchanging %sx %s...'):format(randomAmount, drugConf.label),
                    useWhileDead = false,
                    canCancel = true, 
                    disable = { move = true, car = true, combat = true },
                    anim = { dict = animDict, clip = animName, flag = 49 },
                })

                if success then
                    TriggerServerEvent('drugsale:processTransaction', randomAmount)
                    StopSelling()
                else
                    StopSelling("You cancelled the exchange.")
                end
                
                break 
            end
        end
    end)
end)

function StopSelling(msg)
    isSelling = false 
    LocalPlayer.state:set('invBusy', false, true)

    if msg then lib.notify({description = msg}) end
    
    if currentPed then
        ClearPedTasksImmediately(currentPed)
        TaskWanderStandard(currentPed, 10.0, 10)
        SetPedAsNoLongerNeeded(currentPed)
        
        local pedToCleanup = currentPed
        currentPed = nil 
        
        Citizen.SetTimeout(10000, function()
            if DoesEntityExist(pedToCleanup) then
                DeletePed(pedToCleanup)
            end
        end)
    end
end

RegisterCommand("checklevel", function()
    local stats = lib.callback.await('drugsale:getStats', false)
    if stats then
        local bonusPercent = (Config.LevelRewards[stats.level] or Config.MaxLevelFallback) * 100
        lib.alertDialog({
            header = 'Your Dealer Profile',
            content = ('**Current Level:** %s  \n**Total XP:** %s / %s  \n**Price Bonus:** %s%%'):format(
                stats.level, stats.xp, Config.XPNeeded, math.floor(bonusPercent)
            ),
            centered = true,
            cancel = false
        })
    else
        lib.notify({description = "You have no history yet.", type = "error"})
    end
end)