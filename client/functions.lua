OpenRentalMenu = function(index)
    local MENU = {}
    local temp = Config.Locations[index]

    for k, data in pairs(temp.vehicle) do
        MENU[#MENU + 1] = {
			title = data.name,
			description = Strings.menu_rental_desc,
			arrow = true,
            icon = 'fa-solid fa-user',
            iconColor = Config.IconColor,
            metadata = {
                { label = Strings.menu_rental_md_price, value = data.price },
                { label = Strings.menu_rental_md_account, value = data.account },
                { label = Strings.menu_rental_md_type, value = data.paymentType },
                { label = Strings.menu_remtal_md_plate, value = data.plate },
            },
			onSelect = function()
                local alert
                local input

                if data.paymentType == 'instant' then
                    input = lib.inputDialog(data.name, {
                        { type = 'number', label = Strings.input_rental, description = Strings.input_rental_desc, required = true, default = 5, max = Config.MaxTime, min = 1 }
                    })

                    if not input then
                        return CORE.Bridge.notification('Error')
                    end

                    alert = lib.alertDialog({
                        header = Strings.rental_alert,
                        content = Strings.rental_alert_desc:format(data.name, input[1]*data.price, input[1]),
                        centered = true,
                        cancel = true
                    })
                else
                    alert = lib.alertDialog({
                        header = Strings.rental_alert2,
                        content = Strings.rental_alert2_desc:format(data.name, data.price),
                        centered = true,
                        cancel = true
                    })
                end

                if alert == 'cancel' then
                    return CORE.Bridge.notification(Strings.error_alert)
                end

                local DATA = lib.callback.await('zrx_rental:server:startRental', 1000, {
                    model = data.model,
                    price = data.price,
                    minute = input?[1] or 1,
                    spawnPosition = data.spawnPosition,
                    plate = data.plate,
                    paymentType = data.paymentType,
                    account = data.account
                })

                if not DATA then
                    return
                end

                StartRental(DATA)
			end,
		}
    end

    CORE.Client.CreateMenu({
        id = 'zrx_rental:mainPage',
        title = Strings.menu_rental,
    }, MENU, Config.Menu.type ~= 'menu', Config.Menu.postition)
end

StartRental = function(DATA)
    ACTIVE_RENTAL = DATA.vehicleNet
    local vehicle = NetToVeh(DATA.vehicleNet)

    HightlightVehicle(vehicle)
    SetPedIntoVehicle(cache.ped, vehicle, -1)
end

HightlightVehicle = function(vehicle)
    if not DoesEntityExist(vehicle) then
        return
    end

    CreateThread(function()
        local r, g, b = Config.IconColor:match('rgba%((%d+),%s*(%d+),%s*(%d+)')
        r, g, b = tonumber(r), tonumber(g), tonumber(b)

        SetEntityDrawOutline(vehicle, true)
        SetEntityDrawOutlineColor(r, g, b, 100)
        SetEntityDrawOutlineShader(1)
        Wait(1000)
        SetEntityDrawOutline(vehicle, false)
    end)
end