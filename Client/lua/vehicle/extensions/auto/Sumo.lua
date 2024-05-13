M = {}

function isSumoAirSpeedHigherThan(kmh)
    print('isSumoAirSpeedHigherThan')
    if electrics.values.airspeed * 3.6 > kmh then
        obj:queueGameEngineLua('onSumoAirSpeedTooHigh()')
    end
end

M.isSumoAirSpeedHigherThan = isSumoAirSpeedHigherThan
return M