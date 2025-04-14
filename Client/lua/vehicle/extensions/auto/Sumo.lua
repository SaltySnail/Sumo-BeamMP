M = {}

-- function isSumoAirSpeedHigherThan(kmh)
--     print('isSumoAirSpeedHigherThan')
--     if electrics.values.airspeed * 3.6 > kmh then
--         obj:queueGameEngineLua('onSumoAirSpeedTooHigh()')
--     end
-- end

function requestSumoAirSpeedKmh()
    -- print('requestSumoAirSpeedKmh')
    obj:queueGameEngineLua('onSumoAirSpeedKmh(' .. electrics.values.airspeed * 3.6 .. ')')
end

M.requestSumoAirSpeedKmh = requestSumoAirSpeedKmh
-- M.isSumoAirSpeedHigherThan = isSumoAirSpeedHigherThan
return M