M = {}

-- function isSumoAirSpeedHigherThan(kmh)
--     print('isSumoAirSpeedHigherThan')
--     if electrics.values.airspeed * 3.6 > kmh then
--         obj:queueGameEngineLua('onSumoAirSpeedTooHigh()')
--     end
-- end
local gameRunning = false
local function setSumoGameRunning(isGameRunning)
    print('setSumoGameRunning called')
    gameRunning = isGameRunning
end

function requestSumoAirSpeedKmh()
    -- print('requestSumoAirSpeedKmh')
    obj:queueGameEngineLua('onSumoAirSpeedKmh(' .. electrics.values.airspeed * 3.6 .. ')')
end

local ogStartRecovering = recovery.startRecovering
recovery.startRecovering = function(useAltMode) -- overwrite in-game function to disable rewinding during rounds
    if gameRunning then 
        recovery.recoverInPlace() -- don't allow for rewinds when gameIsRunning 
        return 
    end
    ogStartRecovering(useAltMode)
end

M.setSumoGameRunning = setSumoGameRunning
M.requestSumoAirSpeedKmh = requestSumoAirSpeedKmh
-- M.isSumoAirSpeedHigherThan = isSumoAirSpeedHigherThan
return M
