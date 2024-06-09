CORE = exports.zrx_utility:GetUtility()
RENTED_VEHICLES = {}

CreateThread(function()
    if Config.CheckForUpdates then
        CORE.Server.CheckVersion('zrx_rental')
    end
end)

lib.callback.register('zrx_rental:server:startRental', function(source, data)
    if not data.model or not data.price or not data.minute or not data.spawnPosition or not data.plate or not data.paymentType or not data.account then
        return Config.PunishPlayer(source, 'Tried to trigger "zrx_rental:server:startRental"')
    end

    local flag = nil
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    for k, data2 in pairs(Config.Locations) do
        for i, data3 in pairs(data2.location) do
            if #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(data3.x, data3.y, data3.z)) < 2.0 then
                flag = data2
            end

            if flag then
                break
            end
        end
    end

    if not flag then
        return Config.PunishPlayer(source, 'Tried to trigger "zrx_rental:server:startRental"')
    end

    local xPlayer = CORE.Bridge.getPlayerObject(source)

    if data.paymentType == 'instant' then
        if xPlayer.getAccount(data.account).money < data.price*data.minute then
            CORE.Bridge.notification(Strings.not_enough_money)
            return false
        end

        xPlayer.removeAccountMoney(data.account, data.price*data.minute, 'Vehicle rent')
        CORE.Bridge.notification(xPlayer.player, Strings.started_rent:format(data.price*data.minute))
    else
        if xPlayer.getAccount(data.account).money < data.price then
            CORE.Bridge.notification(Strings.not_enough_money)
            return false
        end

        CORE.Bridge.notification(xPlayer.player, Strings.started_rent2:format(data.price))
    end

    local vehicleNet, vehicle = CORE.Bridge.getVehicleObject().spawnVehicle(data.model, data.spawnPosition, data.plate)
    Wait(500)
    Config.VehicleKeys('add', xPlayer.player, data.plate)

    RENTED_VEHICLES[vehicleNet] = {
        owner = xPlayer.identifier,
        ownerSvid = xPlayer.player,
        time = data.minute,
        curTime = data.minute,
        vehicle = vehicle,
        plate = data.plate,
        toPay = data.price,
        account = data.account,
        type = data.paymentType,
        cancel = false
    }

    CreateThread(function()
        while not RENTED_VEHICLES[vehicleNet].cancel do
            Wait(60000)

            if data.paymentType == 'instant' then
                RENTED_VEHICLES[vehicleNet].curTime -= 1

                if RENTED_VEHICLES[vehicleNet].curTime <= 0 then
                    Config.VehicleKeys('remove', RENTED_VEHICLES[vehicleNet].ownerSvid, RENTED_VEHICLES[vehicleNet].plate)

                    CORE.Bridge.notification(RENTED_VEHICLES[vehicleNet].ownerSvid, Strings.ended_rent)

                    lib.callback.await('zrx_rental:client:leaveVehicle', RENTED_VEHICLES[vehicleNet].ownerSvid, vehicleNet)
                    DeleteEntity(RENTED_VEHICLES[vehicleNet].vehicle)

                    return
                end

                if Config.NotifyPlayer[RENTED_VEHICLES[vehicleNet].curTime] then
                    CORE.Bridge.notification(RENTED_VEHICLES[vehicleNet].ownerSvid, Strings.end_minute:format(RENTED_VEHICLES[vehicleNet].curTime))
                end
            else
                if xPlayer.getAccount(data.account).money < RENTED_VEHICLES[vehicleNet].toPay + data.price then
                    xPlayer.removeAccountMoney(data.account, RENTED_VEHICLES[vehicleNet].toPay, 'Vehicle rent')

                    Config.VehicleKeys('remove', RENTED_VEHICLES[vehicleNet].ownerSvid, RENTED_VEHICLES[vehicleNet].plate)

                    CORE.Bridge.notification(RENTED_VEHICLES[vehicleNet].ownerSvid, Strings.ended_rent_money:format(RENTED_VEHICLES[vehicleNet].toPay))

                    lib.callback.await('zrx_rental:client:leaveVehicle', RENTED_VEHICLES[vehicleNet].ownerSvid, vehicleNet)
                    DeleteEntity(RENTED_VEHICLES[vehicleNet].vehicle)

                    return
                end

                RENTED_VEHICLES[vehicleNet].toPay += data.price
            end
        end

        if Webhook.Links.ended:len() > 0 then
            local message = ([[
                The player ended a rented vehicle
    
                Vehicle: **%s**
                Spawnposition: **%s**
                Plate: **%s**
                Pay/m: **%s**
                Account: **0**
                Time: **%s**
                Type: **%s**
            ]]):format(data.model, data.spawnPosition, data.plate, data.price, data.account, data.minute, data.paymentType)

            CORE.Server.DiscordLog(xPlayer.player, 'RENT END', message, Webhook.Links.company)
        end

        RENTED_VEHICLES[vehicleNet] = nil
    end)

    if Webhook.Links.rent:len() > 0 then
        local message = ([[
            The player started to rent a vehicle

            Vehicle: **%s**
            Spawnposition: **%s**
            Plate: **%s**
            Pay/m: **%s**
            Account: **0**
            Time: **%s**
            Type: **%s**
        ]]):format(data.model, data.spawnPosition, data.plate, data.price, data.account, data.minute, data.paymentType)

        CORE.Server.DiscordLog(xPlayer.player, 'RENT START', message, Webhook.Links.company)
    end

    return {
        vehicleNet = vehicleNet,
    }
end)

RegisterNetEvent('zrx_rental:server:tryCancel', function(vehicleNet)
    if not RENTED_VEHICLES[vehicleNet] then
        return Config.PunishPlayer(source, 'Tried to trigger "zrx_rental:server:tryCancel"')
    end

    local xPlayer = CORE.Bridge.getPlayerObject(source)

    if RENTED_VEHICLES[vehicleNet].owner ~= xPlayer.identifier then
        return Config.PunishPlayer(xPlayer.player, 'Tried to trigger "zrx_rental:server:tryCancel"')
    end

    xPlayer.removeAccountMoney(RENTED_VEHICLES[vehicleNet].account, RENTED_VEHICLES[vehicleNet].toPay, 'Vehicle rent')

    Config.VehicleKeys('remove', RENTED_VEHICLES[vehicleNet].ownerSvid, RENTED_VEHICLES[vehicleNet].plate)

    CORE.Bridge.notification(RENTED_VEHICLES[vehicleNet].ownerSvid, Strings.ended_rent2:format(RENTED_VEHICLES[vehicleNet].toPay))

    lib.callback.await('zrx_rental:client:leaveVehicle', RENTED_VEHICLES[vehicleNet].ownerSvid, vehicleNet)
    DeleteEntity(RENTED_VEHICLES[vehicleNet].vehicle)

    RENTED_VEHICLES[vehicleNet].cancel = true
end)

AddEventHandler('onPlayerDropped', function()
    local xPlayer = CORE.Bridge.getPlayerObject(source)

    for k, data in pairs(RENTED_VEHICLES) do
        if data.owner ~= xPlayer.identifier then
            goto continue
        end

        if data.type ~= 'instant' then
            xPlayer.removeAccountMoney(data.account, data.toPay, 'Vehicle rent')
        end

        data.cancel = true

        DeleteEntity(data.vehicle)
        Config.VehicleKeys('remove', data.ownerSvid, data.plate)

        ::continue::
    end
end)

AddEventHandler('onResourceStop', function(resName)
    if GetCurrentResourceName() ~= resName then
        return
    end

    for k, data in pairs(RENTED_VEHICLES) do
        data.cancel = true

        DeleteEntity(data.vehicle)
        Config.VehicleKeys('remove', data.ownerSvid, data.plate)
    end
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function(eventData)
    local xPlayer

    for k, data in pairs(RENTED_VEHICLES) do
        if data.type ~= 'instant' then
            xPlayer = CORE.Bridge.getPlayerObject(data.ownerSvid)

            xPlayer.removeAccountMoney(data.account, data.toPay, 'Vehicle rent')
        end

        data.cancel = true

        DeleteEntity(data.vehicle)
        Config.VehicleKeys('remove', data.ownerSvid, data.plate)
    end
end)