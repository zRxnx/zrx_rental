Config = {}

--| Discord Webhook in 'configuration/webhook.lua'
Config.CheckForUpdates = true --| Check for updates?
Config.IconColor  = 'rgba(173, 216, 230, 1)' --| rgba format
Config.MaxTime = 60 --| in minutes
Config.DrawDistance = 20 --| gta units

Config.CancelCommand = 'cancelrental' --| Only for pay for minute rental type
Config.CancelKey = 'F1' --| Only for pay for minute rental type

Config.Menu = {
    type = 'context', --| context or menu
    postition = 'top-left' --| top-left, top-right, bottom-left or bottom-right
}

Config.NotifyPlayer = { --| these minutes triggers a notify to warn the player that the rental ends in x minutes | only for instant type
    [30] = true,
    [15] = true,
    [10] = true,
    [5] = true,
    [3] = true,
    [2] = true,
    [1] = true,
}

Config.Locations = {
    {
        name = 'Rent Bicycle', --| Name of dealer
        ped = `a_m_m_og_boss_01`, --| Ped

        animation = { --| Animation to play
            dict = 'mini@strip_club@idles@bouncer@base',
            name = 'base'
        },

        location = {
            vector4(371.5898, -1068.7001, 29.4780, 82.6891),
            vector4(358.8593, -1070.0785, 29.5484, 89.2290)
        },

        blip = function(coords, text) --| Change it if you know what you are doing
            local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

            SetBlipSprite(blip, 38)
            SetBlipColour(blip, 0)
            SetBlipScale(blip, 0.5)
            SetBlipAlpha(blip, 255)
            SetBlipAsShortRange(blip, false)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(text)
            EndTextCommandSetBlipName(blip)

            return blip
        end,

        vehicle = {
            {
                name = 'BMX', --| display name
                model = `bmx`, --| spawn model
                plate = 'ZRXNX', --| plate
                price = 100, --| Price per minute
                account = 'bank', --| bank, money
                paymentType = 'instant', --| instant or minute
                spawnPosition = vector4(365.8633, -1065.6132, 29.3454, 305.4672)
            },

            {
                name = 'Adder', --| display name
                model = `adder`, --| spawn model
                plate = 'ZRXNX', --| plate
                price = 80, --| Price per minute
                account = 'bank', --| bank, money
                paymentType = 'instant', --| instant or minute
                spawnPosition = vector4(372.4389, -1063.1327, 29.2816, 343.6638)
            },

            {
                name = 'Tyrant', --| display name
                model = `tyrant`, --| spawn model
                plate = 'ZRXNX', --| plate
                price = 80, --| Price per minute
                account = 'bank', --| bank, money
                paymentType = 'minute', --| instant or minute
                spawnPosition = vector4(372.4389, -1063.1327, 29.2816, 343.6638)
            }
        }
    }
}

--| Place here your punish actions
Config.PunishPlayer = function(player, reason)
    if not IsDuplicityVersion() then return end
    if Webhook.Links.punish:len() > 0 then
        local message = ([[
            The player got punished

            Reason: **%s**
        ]]):format(reason)

        CORE.Server.DiscordLog(player, 'Punish', message, Webhook.Links.punish)
    end

    DropPlayer(player, reason)
end

--| Add here your add/remove key export
Config.VehicleKeys = function(action, player, plate)
    if IsDuplicityVersion() then
        if action == 'add' then
            exports.zrx_carlock:giveKey(player, plate)
        elseif action == 'remove' then
            exports.zrx_carlock:removeKey(player, plate)
        end
    else
        if action == 'add' then
            exports.zrx_carlock:giveKey(plate)
        elseif action == 'remove' then
            exports.zrx_carlock:removeKey(plate)
        end
    end
end