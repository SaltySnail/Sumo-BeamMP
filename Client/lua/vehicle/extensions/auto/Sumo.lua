M = {}

local gameRunning = false
local tryResettingTime = 0
local resetDelay = 0

local function setSumoGameRunning(isGameRunning)
    print('setSumoGameRunning called ' .. tostring(gameRunning))
    gameRunning = isGameRunning
end

local function setTryResettingTime(time)
    tryResettingTime = time 
    if tryResettingTime < resetDelay then return end
    recovery.recoverInPlace() -- don't allow for rewinds when gameIsRunning 
    obj:queueGameEngineLua('Sumo.onSumoStopResetting()')
end

local function setResetDelay(time)
    resetDelay = time
end

local function requestSumoAirSpeedKmh()
    -- print('requestSumoAirSpeedKmh')
    obj:queueGameEngineLua('Sumo.onSumoAirSpeedKmh(' .. electrics.values.airspeed * 3.6 .. ')')
end

local ogStartRecovering = recovery.startRecovering
recovery.startRecovering = function(useAltMode) -- overwrite in-game function to disable rewinding during rounds
    if gameRunning then 
        if tryResettingTime == 0 then
            obj:queueGameEngineLua('Sumo.onSumoStartResetting()')
            return
        end
        return 
    end
    ogStartRecovering(useAltMode)
end

local ogStopRecovering = recovery.stopRecovering
recovery.stopRecovering = function() -- overwrite in-game function to add reset delay functionality
    if gameRunning then
        tryResettingTime = 0
        obj:queueGameEngineLua('Sumo.onSumoStopResetting()')
    end
    ogStopRecovering()
end

M.setSumoGameRunning = setSumoGameRunning
M.requestSumoAirSpeedKmh = requestSumoAirSpeedKmh
M.setTryResettingTime = setTryResettingTime
M.setResetDelay = setResetDelay
-- M.isSumoAirSpeedHigherThan = isSumoAirSpeedHigherThan
return M
