CORE = exports.zrx_utility:GetUtility()
PED_DATA, BOX_DATA, LOC_DATA, ACTIVE_RENTAL = {}, {}, {}, 0

CORE.Client.RegisterKeyMappingCommand(Config.CancelCommand, Strings.cmd_cancel_desc, Config.CancelKey, function()
    if not ACTIVE_RENTAL then
        return
    end

    local alert = lib.alertDialog({
        header = Strings.cancel_alert,
        content = Strings.cancel_alert_desc,
        centered = true,
        cancel = true
    })

    if alert == 'cancel' then
        return
    end

    TriggerServerEvent('zrx_rental:server:tryCancel', ACTIVE_RENTAL)
end)

AddEventHandler('onResourceStop', function(res)
	if GetCurrentResourceName() ~= res then return end

	for i, data in pairs(PED_DATA) do
		if DoesEntityExist(data) then
			SetPedAsNoLongerNeeded(data)
            SetEntityAsMissionEntity(data, true, true)
			DeleteEntity(data)
		end
	end
end)

CreateThread(function()
	for i, data in ipairs(Config.Locations) do
        for k, coords in pairs(data.location) do
            LOC_DATA[#LOC_DATA + 1] = {
                x = coords.x,
                y = coords.y,
                z = coords.z,
                h = coords[4],

                ped = data.ped,
                animation = data.animation
            }

            BOX_DATA[i] = exports.ox_target:addBoxZone({
                coords = vector3(coords.x, coords.y, coords.z),
                size = vector3(1, 1, 4),
                options = {
                    {
                        icon = 'fa-solid fa-briefcase',
                        iconColor = Config.IconColor,
                        label = Strings.target,
                        distance = 1.0,
                        onSelect = function()
                            OpenRentalMenu(i)
                        end,
                        canInteract = function()
                            return ACTIVE_RENTAL == 0
                        end
                    }
                }
            })

            data.blip(vector3(coords.x, coords.y, coords.z), data.name)
        end
	end

    local pedCoords, dist, entity

    while true do
		pedCoords = GetEntityCoords(cache.ped)

		for i, data in ipairs(LOC_DATA) do
			dist = #(vector3(pedCoords.x, pedCoords.y, pedCoords.z) - vector3(data.x, data.y, data.z))

			if dist <= Config.DrawDistance and not DoesEntityExist(PED_DATA[i]) then
                lib.requestAnimDict(data.animation.dict, 100)
                lib.requestModel(data.ped, 100)

				entity = CreatePed(28, data.ped, data.x, data.y, data.z, data.h, false, false)

				FreezeEntityPosition(entity, true)
				SetEntityInvincible(entity, true)
				SetBlockingOfNonTemporaryEvents(entity, true)
				TaskPlayAnim(entity, data.animation.dict, data.animation.name, 8.0, 0.0, -1, 1, 0, false, false, false)

				PED_DATA[i] = entity
			elseif dist > Config.DrawDistance and DoesEntityExist(PED_DATA[i]) then
				SetPedAsNoLongerNeeded(PED_DATA[i])
                SetEntityAsMissionEntity(PED_DATA[i], true, true)
				DeleteEntity(PED_DATA[i])
				RemoveAnimDict(data.animation.dict)

				PED_DATA[i] = nil
			end
		end

		Wait(2000)
	end
end)

lib.callback.register('zrx_rental:client:leaveVehicle', function(vehicleNet)
    ACTIVE_RENTAL = 0
    local vehicle = NetToVeh(vehicleNet)

    if not DoesEntityExist(vehicle) then
        return false
    end

    if GetVehiclePedIsIn(cache.ped, false) ~= vehicle then
        return false
    end

    TaskLeaveVehicle(cache.ped, vehicle, 0)

    Wait(2000)

    return true
end)