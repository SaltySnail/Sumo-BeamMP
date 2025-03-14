local M = {}

local floor = math.floor
local mod = math.fmod
local rand = math.random

local gamestate = {players = {}, settings = {}}

--blocked inputs when dead
local blockedInputActionsOnDeath = 			{'slower_motion','faster_motion','toggle_slow_motion','modify_vehicle','vehicle_selector','saveHome','loadHome', 'reset_all_physics','toggleTraffic', "recover_vehicle", "recover_vehicle_alt", "recover_to_last_road", "reload_vehicle", "reload_all_vehicles", "parts_selector", "dropPlayerAtCamera", "nodegrabberRender",'reset_physics','dropPlayerAtCameraNoReset'} 
local blockedInputActionsOnRound = 			{'slower_motion','faster_motion','toggle_slow_motion','modify_vehicle','vehicle_selector','saveHome','loadHome', 'reset_all_physics','toggleTraffic', 					 "recover_vehicle_alt", "recover_to_last_road", "reload_vehicle", "reload_all_vehicles", "parts_selector", "dropPlayerAtCamera", "nodegrabberRender",'reset_physics','dropPlayerAtCameraNoReset'} 
local blockedInputActionsOnSpeedOrCircle = 	{'slower_motion','faster_motion','toggle_slow_motion','modify_vehicle','vehicle_selector','saveHome','loadHome', 'reset_all_physics','toggleTraffic', "recover_vehicle", "recover_vehicle_alt", "recover_to_last_road", "reload_vehicle", "reload_all_vehicles", "parts_selector", "dropPlayerAtCamera", "nodegrabberRender",'reset_physics','dropPlayerAtCameraNoReset'} 

local colors = {["Red"] = {255,50,50,255},["LightBlue"] = {50,50,160,255},["Green"] = {50,255,50,255},["Yellow"] = {200,200,25,255},["Purple"] = {150,50,195,255}}
local mapData = {}
local isPlayerInCircle = false

local currentArena = ""
local currentLevel = ""
local lastCreatedGoalID = 1

local defaultRedFadeDistance = 20

local goalPrefabActive = false
local goalPrefabPath
local goalPrefabName
local goalPrefabObj
local goalLocation

local obstaclesPrefabActive = false
local obstaclesPrefabPath
local obstaclesPrefabName
local obstaclesPrefabObj

local debugSphereColorTriggered = ColorF(0,1,0,1)
local debugSphereColorNeutral = ColorF(1,0,0,1)
local debugView = false

local newArena = {}
newArena.goals = {}
newArena.spawnLocations = {}

local triggersThatPlayerIsIn = 0

local logTag = "Sumo"

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
end

function seconds_to_days_hours_minutes_seconds(total_seconds) --modified code from https://stackoverflow.com/questions/45364628/lua-4-script-to-convert-seconds-elapsed-to-days-hours-minutes-seconds
    local time_minutes  = floor(mod(total_seconds, 3600) / 60)
    local time_seconds  = floor(mod(total_seconds, 60))
    if (time_seconds < 10) and time_minutes > 0 then
        time_seconds = "0" .. time_seconds
    end
	if time_minutes > 0 then
    	return time_minutes .. ":" .. time_seconds
	else
    	return time_seconds
	end
end

function distance(vec1, vec2)
	return math.sqrt((vec2.x-vec1.x)^2 + (vec2.y-vec1.y)^2 + (vec2.z-vec1.z)^2)
end

function angle2D(vec1, vec2) --in degrees, because I thought it would be less conversions
	-- if vec1 == nil or vec2 == nil then return end
	local angle = math.atan2( vec1.y - vec2.y, vec2.x - vec1.x)
	return angle * (180 / math.pi)
end

function resetSumoCarColors(data)
	if data then
		local vehicle = data
		if vehicle then
			if vehicle.originalColor then
				vehicle.color = vehicle.originalColor
			end
			if vehicle.originalcolorPalette0 then
				vehicle.colorPalette0 = vehicle.originalcolorPalette0
			end
			if vehicle.originalcolorPalette1 then
				vehicle.colorPalette1 = vehicle.originalcolorPalette1
			end
		end
	else
		for k,serverVehicle in pairs(MPVehicleGE.getVehicles()) do
			local ID = serverVehicle.gameVehicleID
			local vehicle = be:getObjectByID(ID)
			if vehicle then
				if serverVehicle.originalColor then
					vehicle.color = serverVehicle.originalColor
				end
				if serverVehicle.originalcolorPalette0 then
					vehicle.colorPalette0 = serverVehicle.originalcolorPalette0
				end
				if serverVehicle.originalcolorPalette1 then
					vehicle.colorPalette1 = serverVehicle.originalcolorPalette1
				end
			end
		end
	end
	scenetree["PostEffectCombinePassObject"]:setField("enableBlueShift", 0,0)
	scenetree["PostEffectCombinePassObject"]:setField("blueShiftColor", 0,"0 0 0")


	--core_input_actionFilter.addAction(0, 'vehicleTeleporting', false)
	--core_input_actionFilter.addAction(0, 'vehicleMenues', false)
	--core_input_actionFilter.addAction(0, 'freeCam', false)
	--core_input_actionFilter.addAction(0, 'resetPhysics', false)
end

function receiveSumoGameState(data)
	local data = jsonDecode(data)
	-- if not gamestate.gameRunning and data.gameRunning then
	-- 	for k,vehicle in pairs(MPVehicleGE.getVehicles()) do
	-- 		local ID = vehicle.gameVehicleID
	-- 		local veh = be:getObjectByID(ID)
	-- 		if veh then
	-- 			vehicle.originalColor = be:getObjectByID(ID).color
	-- 			vehicle.originalcolorPalette0 = be:getObjectByID(ID).colorPalette0
	-- 			vehicle.originalcolorPalette1 = be:getObjectByID(ID).colorPalette1
	-- 		end
	-- 	end
	-- end
	print("receiveSumoGameState called: " .. dump(data))
	gamestate = data
end

function mergeSumoTable(table,gamestateTable)
	if gamestateTable == nil then gamestateTable = {} end
	for variableName,value in pairs(table) do
		if type(value) == "table" then
			mergeSumoTable(value,gamestateTable[variableName])
		elseif value == "remove" then
			gamestateTable[variableName] = nil
		else
			gamestateTable[variableName] = value
		end
	end
end

function allowSumoResets(data)
	extensions.core_input_actionFilter.setGroup('sumo', data)
	extensions.core_input_actionFilter.addAction(0, 'sumo', false)
	print('allowSumoResets called')
end

function disallowSumoResets(data)
	extensions.core_input_actionFilter.setGroup('sumo', data)
	extensions.core_input_actionFilter.addAction(0, 'sumo', true)
	print('disallowSumoResets called')
end

function spawnSumoGoal(filepath, offset, rotation) 
	goalPrefabActive = true
	goalPrefabPath   = filepath
	goalPrefabName   = string.gsub(filepath, "(.*/)(.*)", "%2"):sub(1, -13)
	local goalNumber = tonumber(string.match(goalPrefabName, "%d+"))
	goalPrefabPath = "art/goal.prefab.json"
	local offsetString = '0 0 0'
	local rotationString = '0 0 1'
	local scaleString = '1 1 1'
	print(currentArena .. " " .. goalNumber)
	if mapData.arenaData[currentArena].goals[goalNumber] then
		offsetString = "" .. mapData.arenaData[currentArena].goals[goalNumber].x .. " " .. mapData.arenaData[currentArena].goals[goalNumber].y .. " " .. mapData.arenaData[currentArena].goals[goalNumber].z
		goalLocation = {}
		goalLocation = mapData.arenaData[currentArena].goals[goalNumber]
		local rot = {rx = mapData.arenaData[currentArena].goals[goalNumber].rx, ry = mapData.arenaData[currentArena].goals[goalNumber].ry, rz = mapData.arenaData[currentArena].goals[goalNumber].rz}
		rot = quatFromEuler(rot.rx, rot.ry, rot.rz)
		rotationString = rot.x .. " " .. rot.y .. " " .. rot.z .. " " .. rot.w
	end
	if offset then
		offsetString = "" .. offset.x .. " " .. offset.y .. " " .. offset.z
	end
	if rotation then
		rotationString = "" .. rotation.x .. " " .. rotation.y .. " " .. rotation.z
	end
	if gamestate.goalScale then
		scaleString = "" .. gamestate.goalScale .. " " .. gamestate.goalScale .. " 1" --.. gamestate.goalScale
	end
	goalPrefabObj    = spawnPrefab(goalPrefabName, goalPrefabPath,  offsetString, rotationString, scaleString)
	
	local newObj = createObject('TSStatic')
	if offset then
		newObj:setPosition(vec3(offset.x, offset.y, offset.z))
	elseif mapData.arenaData[currentArena].goals[goalNumber] then
		newObj:setPosition(vec3(mapData.arenaData[currentArena].goals[goalNumber].x, mapData.arenaData[currentArena].goals[goalNumber].y, mapData.arenaData[currentArena].goals[goalNumber].z))
	else
		newObj:setPosition(vec3(0,0,0))
	end
	newObj:setField('rotation', 0, rotationString)
	newObj:setField('shapeName', 0, "/art/safezone_marker.dae")
	print("goalScale: " .. 3.900 * (tonumber(gamestate.goalScale) or 1) .. " " .. 2.100 * (tonumber(gamestate.goalScale) or 1) .. " " .. 5.300)
	newObj.scale = vec3(3.900 * (tonumber(gamestate.goalScale) or 1), 2.100 * (tonumber(gamestate.goalScale) or 1), 5.300)
	newObj.useInstanceRenderData = true
	newObj:setField('instanceColor', 0, string.format("%g %g %g %g", 0,0.183,0.684,1))
	newObj:setField('instanceColor1', 0, string.format("%g %g %g %g", 0.961126566,0.961126566,0.961126566,1))
	newObj:setField('collisionType', 0, "Collision Mesh")
	newObj:setField('decalType', 0, "Collision Mesh")
	newObj.canSave = true
	newObj:registerObject(goalPrefabName .. "TSStatic")
	scenetree.MissionGroup:addObject(newObj)
end

function onSumoCreateGoal()
	local currentVehID = be:getPlayerVehicleID(0)
	local veh = be:getObjectByID(currentVehID)
	if not veh then return end
	local pos = veh:getPosition()
	local rot = veh:getRotation()
	rot = rot:toEuler()
	removeSumoPrefabs("goal")
	-- rot = rot * (180/math.pi) --convert to degrees so people can read it in the json file
	local upVec = veh:getDirectionVectorUp()
	if upVec.z > 50 and upVec.z < 60 then
		pos.z = pos.z - 11
	end
	spawnSumoGoal("art/goal" .. #newArena.goals .. ".prefab.json", pos)
	table.insert(newArena.goals, {x = pos.x, y = pos.y, z = pos.z, rx = rot.x, ry = rot.y, rz = rot.z})
end

function onSumoCreateSpawn()
	local currentVehID = be:getPlayerVehicleID(0)
	local veh = be:getObjectByID(currentVehID)
	if not veh then return end
	vehPos = veh:getPosition()
	vehRot = veh:getDirectionVector()
	table.insert(newArena.spawnLocations, {x = vehPos.x, y = vehPos.y, z = vehPos.z, rx = vehRot.x * (180/math.pi),  ry = vehRot.y * (180/math.pi),  rz = vehRot.z * (180/math.pi)})
	print(dump(newArena.spawnLocations))
end

function spawnSumoObstacles(filepath) 
	print(filepath)
	obstaclesPrefabActive = true
	obstaclesPrefabPath   = filepath
	obstaclesPrefabName   = string.gsub(obstaclesPrefabPath, "(.*/)(.*)", "%2"):sub(1, -13)
	obstaclesPrefabObj    = spawnPrefab(obstaclesPrefabName, obstaclesPrefabPath, '0 0 0', '0 0 1', '1 1 1')
	be:reloadStaticCollision(true)
	disallowSumoResets(blockedInputActionsOnSpeedOrCircle)
end

function removeSumoPrefabs(type)
	print( "removeSumoPrefabs(" .. type .. ") Called" )
	if type == "goal" and goalPrefabActive then 
		
		for _, objectName in pairs(scenetree.getAllObjects()) do
			if objectName:find("^goal%d*TSStatic$") then 
				scenetree.findObject(objectName):delete()
			end
			if objectName:find("^goal%d*$") then 
				scenetree.findObject(objectName):delete()
			end
		end
		-- print( "Removing: " .. goalPrefabName)
		goalPrefabActive = false
	elseif type == "all" then
		if goalPrefabActive then
			removePrefab(goalPrefabName)
			-- print( "Removing: " .. goalPrefabName)
			goalPrefabActive = false
		end
		if obstaclesPrefabActive then
			removePrefab(obstaclesPrefabName)
			-- print( "Removing: " .. obstaclesPrefabName)
			obstaclesPrefabActive = false
			be:reloadStaticCollision(true)
		end
		local prefabPath = ""
		local levelName = core_levels.getLevelName(getMissionFilename())
		local goals = "1"
		print( "Removing everything in; Map: " .. levelName .. " and Arena: " .. currentArena)
		-- print( "mapData: " .. dump(mapData))
		local levelData = {}
		levelData = mapData.arenaData
		-- print( "levelData: " .. dump(levelData))
		local arenaData = {}
		arenaData = levelData[currentArena]
		-- print( "arenaData (" .. currentArena .. "): " .. dump(arenaData))
		goals = #arenaData["goals"]
		for goalID=1,tonumber(goals) do
			prefabPath = "goal" .. goalID
			-- print( "Removing: " .. prefabPath)
			removePrefab(prefabPath)
		end
		for _, objectName in pairs(scenetree.getAllObjects()) do
			if objectName:find("^goal%d*TSStatic$") then 
				scenetree.findObject(objectName):delete()
			end
		end
	end
	triggersThatPlayerIsIn = 0
end

function teleportToSumoArena()
	print("teleportToSumoArena Called")
	for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
		-- local veh = be:getObjectByID(be:getPlayerVehicleID(0))
		print("veh:" .. vehID .." : " .. dump(vehData))
		local veh = be:getObjectByID(vehID)
		if not veh then return end --Should not be called but just to be safe
		local arenaData = mapData.arenaData[currentArena]
		local chosenLocation = rand(1, #arenaData.spawnLocations)
		if arenaData.spawnLocations[chosenLocation] then
			-- print(dump(quatFromEuler(arenaData.spawnLocations[chosenLocation].rx, arenaData.spawnLocations[chosenLocation].ry, arenaData.spawnLocations[chosenLocation].rz)))
			local q = quatFromEuler(math.rad(arenaData.spawnLocations[chosenLocation].rx), math.rad(arenaData.spawnLocations[chosenLocation].ry), math.rad(arenaData.spawnLocations[chosenLocation].rz))
			veh:setPositionRotation(arenaData.spawnLocations[chosenLocation].x, arenaData.spawnLocations[chosenLocation].y, arenaData.spawnLocations[chosenLocation].z, q.x, q.y, q.z, q.w)
		end
		veh:queueLuaCommand("recovery.startRecovering()")
		veh:queueLuaCommand("recovery.stopRecovering()")
	end
end

function onSumoGameEnd()
	core_gamestate.setGameState('scenario', 'multiplayer', 'multiplayer') --reset the app layout
	allowSumoResets(blockedInputActionsOnRound)
	allowSumoResets(blockedInputActionsOnSpeedOrCircle)
	allowSumoResets(blockedInputActionsOnDeath)
	goalScale = 1
	goalLocation = nil
	removeSumoPrefabs("all")
end

-- Function to explode a car by its vehicle ID
function explodeSumoCar(vehID)
	for vid, veh in activeVehiclesIterator() do
		if vid == tonumber(vehID) then
			veh:queueLuaCommand("fire.explodeVehicle()")
			veh:queueLuaCommand("fire.igniteVehicle()")
			veh:queueLuaCommand("beamstate.breakAllBreakgroups()")
			for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
				print(vid .. " " .. vehID)
				if vid == vehID then
					-- disallowSumoResets(blockedInputActionsOnDeath)
					local vehicle = MPVehicleGE.getVehicleByGameID(vid)
					if TriggerServerEvent and vehicle and vehicle.ownerName then
						TriggerServerEvent("onSumoPlayerExplode", vehicle.ownerName) 
					end
				end
			end
		end
	end
end

function onSumoTrigger(data)
    if data == "null" then return end
	-- if data.event ~= "enter" then return end
    local trigger = data.triggerName
	local isLocalVehicle = false
    -- if MPVehicleGE.isOwn(data.subjectID) == true then
	if string.find(trigger, "^goalTrigger%d*$") then	
		if data.event == "enter" then
			for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
				if vehID == data.subjectID then
					-- if TriggerServerEvent then TriggerServerEvent("unmarkSumoVehicleToExplode", data.subjectID) end
					triggersThatPlayerIsIn = triggersThatPlayerIsIn + 1
					disallowSumoResets(blockedInputActionsOnSpeedOrCircle)
					isLocalVehicle = true
					break
				end
			end
			if isLocalVehicle then
				for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
					-- mark player to not explode
					if TriggerServerEvent then TriggerServerEvent("unmarkSumoVehicleToExplode", vehID) end
					isPlayerInCircle = true
				end
			end
			-- print( "Unmarked " .. data.subjectID .. " for exploding")
		elseif data.event == "exit" then
			for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
				if vehID == data.subjectID then
					triggersThatPlayerIsIn = triggersThatPlayerIsIn - 1
					if triggersThatPlayerIsIn <= 0 then
						-- if TriggerServerEvent then TriggerServerEvent("markSumoVehicleToExplode",  data.subjectID) end
						allowSumoResets(blockedInputActionsOnSpeedOrCircle) 
						isLocalVehicle = true
						break
					end
				end
			end
			if isLocalVehicle then
				for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
					if TriggerServerEvent then TriggerServerEvent("markSumoVehicleToExplode",  vehID) end
					isPlayerInCircle = false
				end
			end
			-- print( "Marked " .. data.subjectID .. " for exploding")
			--mark player to explode
		-- else
		-- 	if TriggerServerEvent then TriggerServerEvent("unmarkSumoVehicleToExplode", data.subjectID) end
		end
	elseif string.find(trigger, "outOfBoundTrigger") then
		--explode player
		for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
			if vehID == data.subjectID then
				-- if TriggerServerEvent then TriggerServerEvent("markSumoVehicleToExplode",  data.subjectID) end
				-- allowSumoResets(blockedInputActionsOnSpeedOrCircle) --removed this because players might spawn back on the platform, which ruins it for others
				isLocalVehicle = true
				break
			end
		end
		if isLocalVehicle then
			for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
				explodeSumoCar(vehID)
				if TriggerServerEvent then TriggerServerEvent("markSumoVehicleToExplode", vehID) end
			end
		end
		-- print( "outOfBoundTrigger was triggered")
	end
    -- end
	-- print( "trigger data: " .. dump(data))
end

function onReverseGravityTrigger(data)
	for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
		if vehID == data.subjectID then
			if data.event == "enter" then
				ogCamName = core_camera.getActiveCamName(0)
				if ogCamName ~= "chase" and ogCamName ~= "onboard_hood" and ogCamName ~= "driver" then
					core_camera.setBySlotId(0, 6) --this isn't always chase TODO: figure out how to call it by name
				core_camera.resetCamera(0)
				end
				core_environment.setGravity(9.81)
			elseif data.event == "exit" then
				if ogCamName ~= "chase" and ogCamName ~= "onboard_hood" and ogCamName ~= "driver" then
					core_camera.setBySlotId(0, 1)
					core_camera.resetCamera(0)
					ogCamName = ""
				end
				core_environment.setGravity(-9.81)
			end
			local veh = be:getObjectByID(data.subjectID)
			local upVector = veh:getDirectionVectorUp() * (180/math.pi)
			--print(dump(upVector))
			if upVector.z > 25 and upVector.z < 90 then --no clue on why the vector up z coordinate is ~57 (west coast is slanted confirmed)
				local pos = veh:getPosition()
				local rot = veh:getRotation()
				rot = rot:toEuler() * (180/math.pi)
				--print(dump(rot))
				rot.y = rot.y + 180
				rot = rot * (math.pi/180)
				--print("Rot is now: " ..  dump(rot))
				rot = quatFromEuler(rot.x, rot.y, rot.z)
				veh:setPosRot(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, rot.w)
			end
		end
	end
end

-- function requestSumoLevelName()
--   currentLevel = core_levels.getLevelName(getMissionFilename())
--   if TriggerServerEvent then TriggerServerEvent("setSumoLevelName", currentLevel) end
-- --   if TriggerServerEvent then TriggerServerEvent("markSumoVehicleToExplode", currentVehID) end
-- end

function setSumoCurrentArena(arena)
	currentArena = arena
end

function requestSumoArenaNames()
	-- local levelName = core_levels.getLevelName(getMissionFilename())
	print("requestSumoArenaNames called: ")
	-- if mapData and TriggerServerEvent then TriggerServerEvent("setSumoArenaNames", mapData.arenas) end
	if mapData then TriggerServerEvent("setSumoArenaNames", mapData.arenas) end
end

-- function requestSumoLevels()
-- 	if TriggerServerEvent then TriggerServerEvent("setSumoLevels", mapData.levels) end
-- end

function requestSumoGoalCount()
	local levelName = core_levels.getLevelName(getMissionFilename())	
	local goals = "1"
	print( "mapData: " .. dump(mapData))	
	local levelData = {}
	levelData = mapData.arenaData
	print( "levelData: " .. dump(levelData))
	local arenaData = {}
	arenaData = levelData[currentArena]
	if not arenaData then return end
	print( "arenaData (" .. currentArena .. "): " .. dump(arenaData))
	goals = #arenaData["goals"]
	print( "There are " .. goals .. " goals in " .. levelName .. ", " .. currentArena)
	if TriggerServerEvent then TriggerServerEvent("setSumoGoalCount", goals) end
end

function updateSumoGameState(data)
	print('updateSumoGameState called: ' .. data)
	mergeSumoTable(jsonDecode(data),gamestate)

	local time = 0

	if gamestate.time then time = gamestate.time-1 end
	-- for playerName, player in pairs(gamestate.players) do
	-- 	if player.resetTimerActive then
	-- 		if player.resetTimer > 0 then
	-- 			player.resetTimer = player.resetTimer - 1
	-- 		else
	-- 			player.resetTimerActive = false
	-- 			extensions.core_input_actionFilter.setGroup('sumo', blockedInputActionsOnDeath)
	-- 			extensions.core_input_actionFilter.addAction(0, 'sumo', false)	
	-- 		end
	-- 	end
	-- end

	local txt = ""
	if gamestate.randomVehicles and time and time == -28 then 
		spawnSumoRandomVehicle()
		core_gamestate.setGameState('scenario', 'sumo', 'scenario')
	end
	if not gamestate.randomVehicles and time and time == -8 then 
		core_gamestate.setGameState('scenario', 'sumo', 'scenario')
	end
	if time and time < 0 then
		be:queueAllObjectLua("controller.setFreeze(1)")
		-- for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
		-- 	local veh = be:getObjectByID(vehID)
		-- 	veh:queueLuaCommand('controller.setFreeze(1)')
		-- end
		disallowSumoResets(blockedInputActionsOnDeath)
	end
	if time and time == 0 then 
		guihooks.trigger('sumoStartTimer', 30)
		be:queueAllObjectLua("controller.setFreeze(0)")
		-- for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
		-- 	local veh = be:getObjectByID(vehID)
		-- 	veh:queueLuaCommand('controller.setFreeze(0)')
		-- end
		disallowSumoResets(blockedInputActionsOnRound)
	end
	if time and time <= 0 and time > -4 then
		guihooks.trigger('sumoCountdown', math.abs(time))
		if time < 0 then
			Engine.Audio.playOnce('AudioGui', "/art/sound/countdownTick", {volume = 50})
		else
			Engine.Audio.playOnce('AudioGui', "/art/sound/countdownGO", {volume = 40})
		end
	end
	if time and time == 1 then
		guihooks.trigger('sumoClearCountdown', 0)
	end


	if time and time < 0 then
		txt = "Game starts in "..math.abs(time).." seconds"
		
		-- for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
		-- 	-- local veh = be:getObjectByID(be:getPlayerVehicleID(0))
		-- 	-- print("veh:" .. vehID .." : " .. dump(vehData))
		-- 	local veh = be:getObjectByID(vehID)
		if TriggerServerEvent then TriggerServerEvent("markSumoVehicleToExplode", be:getPlayerVehicleID(0)) end --TODO: change the be:getPlayerVehicleID to MPVehicleGE.getOwnMap stuff 
		-- end
	elseif gamestate.gameRunning and not gamestate.gameEnding and time or gamestate.endtime and (gamestate.endtime - time) > 9 then
		local timeLeft = seconds_to_days_hours_minutes_seconds(gamestate.roundLength - time)
		txt = "Sumo Time Left: ".. timeLeft --game is still going
		
		if time % 30 == 0 then
			guihooks.trigger('sumoSyncTimer', 30);
		end
		if time and time > 0 and time % 30 >= 24 and time % 30 <= 29 then
			guihooks.trigger('sumoAnimateCircleSize', 30)
			if gamestate.safezoneEndAlarm then
				Engine.Audio.playOnce('AudioGui', "/art/sound/timerTick", {volume = 5})
			end
		end
		if not isPlayerInCircle then
			allowSumoResets(blockedInputActionsOnSpeedOrCircle) --TODO: check if this is really a good way to handle this, it might cancel the other inputblocking 			for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
			disallowSumoResets(blockedInputActionsOnRound)
			for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
			-- local veh = be:getObjectByID(be:getPlayerVehicleID(0))
				-- print("veh:" .. vehID .." : " .. dump(vehData))
				local veh = be:getObjectByID(vehID)
				veh:queueLuaCommand("isSumoAirSpeedHigherThan(20)")
			end
		end
	elseif time and gamestate.endtime and (gamestate.endtime - time) < 7 then
		local timeLeft = gamestate.endtime - time
		txt = "Sumo Colors reset in "..math.abs(timeLeft-1).." seconds" --game ended
		
		guihooks.trigger('sumoRemoveTimer', 0)
	end
	if txt ~= "" then
		guihooks.message({txt = txt}, 1, "Sumo.time")
	end
	-- if uiMessages.showMSGYouScored then
	-- 	if gamestate.time >= uiMessages.showMSGYouScoredEndTime then
	-- 	uiMessages.showMSGYouScored = false
	-- 	uiMessages.showMSGYouScoredEndTime = 0
	-- 	end
	-- end
	-- for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
	-- 	-- local veh = be:getObjectByID(be:getPlayerVehicleID(0))
	-- 	print("veh:" .. vehID .." : " .. dump(vehData))
	-- 	local veh = be:getObjectByID(vehID)
	-- 	if veh:electrics.value.airspeed * 3.6 > 30 then
	-- 		disallowSumoResets(blockedInputActionsOnSpeedOrCircle)
	-- 		break
	-- 	end
	-- end

	-- if gamestate.gameEnded then
	-- 	resetSumoCarColors()
	-- end
end

function requestSumoGameState()
	if TriggerServerEvent then TriggerServerEvent("requestSumoGameState","nil") end
end

-- function onVehicleSwitched(oldID,ID)
-- 	local currentOwnerName = MPConfig.getNickname()
-- 	if ID and MPVehicleGE.getVehicleByGameID(ID) then
-- 		currentOwnerName = MPVehicleGE.getVehicleByGameID(ID).ownerName
-- 	end
-- end

local distancecolor = -1

-- function SumoNametags(ownerName,player,vehicle) --draws flag SumoNametags on people
-- 	-- if player and player.hasFlag == true then
-- 	-- 	local veh = be:getObjectByID(vehicle.gameVehicleID)
-- 	-- 	if veh then
-- 	-- 		local vehPos = veh:getPosition()
-- 	-- 		local posOffset = vec3(0,0,2)
-- 	-- 		debugDrawer:drawTextAdvanced(vehPos+posOffset, String("Flag"), ColorF(1,1,1,1), true, false, ColorI(50,50,200,255))
-- 	-- 	end
-- 	-- end
-- end

-- function onVehicleResetted(gameVehicleID)
-- 	print( "OnVehicleResetted called")
-- 	if MPVehicleGE then
-- 		if MPVehicleGE.isOwn(gameVehicleID) then
-- 			local veh = be:getObjectByID(gameVehicleID)
-- 			if veh then
-- 				if not gamestate.players[veh.ownerName].allowedResets then
-- 					local txt = ""
-- 					txt = "You can reset in " .. gamestate.players[veh.ownerName].resetTimer .. "seconds"
-- 					gamestate.players[veh.ownerName].resetTimerActive = true
-- 					guihooks.message({txt = txt}, 1, "nil")
-- 				end
-- 			end
-- 		end
-- 	end
-- end

function sumoColor(player,vehicle,team,dt)
	local teamColor
	if gamestate.teams and player.team then
		teamColor = colors[player.team]
	end
	-- if player.hasFlag == true then
		if not vehicle.transition or not vehicle.colortimer then
			vehicle.transition = 1
			vehicle.colortimer = 1.6
		end
		local veh = be:getObjectByID(vehicle.gameVehicleID)
		if veh then
			if not vehicle.originalColor then
				vehicle.originalColor = veh.color
			end
			if not vehicle.originalcolorPalette0 then
				vehicle.originalcolorPalette0 = veh.colorPalette0
			end
			if not vehicle.originalcolorPalette1 then
				vehicle.originalcolorPalette1 = veh.colorPalette1
			end

			if not gamestate.gameEnding or (gamestate.endtime - gamestate.time) > 1 then
				local transition = vehicle.transition
				local colortimer = vehicle.colortimer
				local color = 0.6 - (1*((1+math.sin(colortimer))/2)*0.2)
				local colorfade = (1*((1+math.sin(colortimer))/2))*math.max(0.6,transition)
				local bluefade = 1 -((1*((1+math.sin(colortimer))/2))*(math.max(0.6,transition)))
				local teamColorfade = 1 -((1*((1+math.sin(colortimer))/2))*(math.max(0.6,transition)))
				if gamestate.settings and not gamestate.settings.ColorPulse then
					color = 0.6
					colorfade = transition
					bluefade = 1 - transition
				end

				if teamColor then
					veh.color = ColorF((teamColor[1] * teamColorfade) / 255, (teamColor[2] * teamColorfade) / 255, (teamColor[3] * teamColorfade) / 255, vehicle.originalColor.w):asLinear4F()
					veh.colorPalette0 = ColorF((teamColor[1] * teamColorfade) / 255,(teamColor[2] * teamColorfade) / 255, (teamColor[3] * teamColorfade) / 255, vehicle.originalcolorPalette0.w):asLinear4F()
					veh.colorPalette1 = ColorF((teamColor[1] * teamColorfade) / 255,(teamColor[2] * teamColorfade) / 255, (teamColor[3] * teamColorfade) / 255, vehicle.originalcolorPalette1.w):asLinear4F()
				else
					veh.color = ColorF(vehicle.originalColor.x*colorfade, vehicle.originalColor.y*colorfade, (vehicle.originalColor.z*colorfade) + (color*bluefade), vehicle.originalColor.w):asLinear4F()
					veh.colorPalette0 = ColorF(vehicle.originalcolorPalette0.x*colorfade, vehicle.originalcolorPalette0.y*colorfade, (vehicle.originalcolorPalette0.z*colorfade) + (color*bluefade), vehicle.originalcolorPalette0.w):asLinear4F()
					veh.colorPalette1 = ColorF(vehicle.originalcolorPalette1.x*colorfade, vehicle.originalcolorPalette1.y*colorfade, (vehicle.originalcolorPalette1.z*colorfade) + (color*bluefade), vehicle.originalcolorPalette1.w):asLinear4F()
				end
				vehicle.colortimer = colortimer + (dt*2.6)
				if transition > 0 then
					vehicle.transition = math.max(0,tFransition - dt)
				end

				vehicle.color = color
				vehicle.colorfade = colorfade
				vehicle.bluefade = bluefade
			elseif (gamestate.endtime - gamestate.time) <= 1 then
				local transition = vehicle.transition
				local color = vehicle.color or 0
				local colorfade = vehicle.colorfade or 1
				local bluefade = vehicle.bluefade or 0
			
				veh.color = ColorF(vehicle.originalColor.x*colorfade, vehicle.originalColor.y*colorfade , (vehicle.originalColor.z*colorfade) + (color*bluefade), vehicle.originalColor.w):asLinear4F()
				veh.colorPalette0 = ColorF(vehicle.originalcolorPalette0.x*colorfade, vehicle.originalcolorPalette0.y*colorfade, (vehicle.originalcolorPalette0.z*colorfade) + (color*bluefade), vehicle.originalcolorPalette0.w):asLinear4F()
				veh.colorPalette1 = ColorF(vehicle.originalcolorPalette1.x*colorfade, vehicle.originalcolorPalette1.y*colorfade, (vehicle.originalcolorPalette1.z*colorfade) + (color*bluefade), vehicle.originalcolorPalette1.w):asLinear4F()
			
				vehicle.colorfade = math.min(1,colorfade + dt)
				vehicle.bluefade = math.max(0,bluefade - dt)
				vehicle.colortimer = 1.6
				if transition < 1 then
					vehicle.transition = math.min(1,transition + dt)
				end
			end
		end
	-- end
end

local vecX = vec3(1,0,0)
local vecY = vec3(0,1,0)
local vecZ = vec3(0,0,1)

function onPreRender(dt)
	if not gamestate.gameRunning then return end
	if goalLocation and goalPrefabActive then
		debugDrawer:drawTextAdvanced(goalLocation, "Safezone", ColorF(1,1,1,1), true, false, ColorI(20,20,255,255))
	end
	local pos, rot, scl
	local zVec, yVec, xVec
	for _, objectName in pairs(scenetree.getAllObjects()) do --TODO: move this to when a goal is created
		-- print(objectName)
		if string.find(objectName, "^goal%d*TSStatic") then 
			goalObj = scenetree.findObject(objectName)
			-- goalObj.getField("ID")
			pos, rot, scl = goalObj:getPosition(), quat(goalObj:getRotation()), goalObj:getScale()
      		zVec, yVec, xVec = rot*vecZ*scl.z, rot*vecY*scl.y, rot*vecX*scl.x
			-- print(dump(goalObj) .. " " .. dump(pos))
		end
	end
	if not goalObj or not pos or not xVec or not yVec or not zVec then return end
	if not be:getPlayerVehicle(0) then return end
	local playerVehicle = be:getPlayerVehicle(0)
	local bb1 = playerVehicle:getSpawnWorldOOBB()
	xVec = xVec * 1.5 --make the hitbox of the safezone the same size as the visual safezone
	yVec = yVec * 3
	zVec = zVec * 2
	local isInsideSafezone = overlapsOBB_OBB(bb1:getCenter(), bb1:getAxis(0) * bb1:getHalfExtents().x, bb1:getAxis(1) * bb1:getHalfExtents().y, bb1:getAxis(2) * bb1:getHalfExtents().z, pos, xVec, yVec, zVec)

	if playerVehicle.isInsideSafezone ~= isInsideSafezone then
		playerVehicle.isInsideSafezone = isInsideSafezone
		if isInsideSafezone then
			if debugView then
				debugDrawer:drawSphere(pos, 0.1, debugSphereColorTriggered)
				debugDrawer:drawSphere(pos + xVec, 0.1, debugSphereColorTriggered)
				debugDrawer:drawSphere(pos + yVec, 0.1, debugSphereColorTriggered)
				debugDrawer:drawSphere(pos + zVec, 0.1, debugSphereColorTriggered)
			end
			trigger = {}
			trigger.event = "enter"
			trigger.triggerName = "goalTrigger0"
			trigger.subjectID = playerVehicle:getID()
			onSumoTrigger(trigger)
		else
			if debugView then
				debugDrawer:drawSphere(pos, 0.1, debugSphereColorNeutral)
				debugDrawer:drawSphere(pos + xVec, 0.1, debugSphereColorNeutral)
				debugDrawer:drawSphere(pos + yVec, 0.1, debugSphereColorNeutral)
				debugDrawer:drawSphere(pos + zVec, 0.1, debugSphereColorNeutral)
			end
			trigger = {}
			trigger.event = "exit"
			trigger.triggerName = "goalTrigger0"
			trigger.subjectID = playerVehicle:getID()
			onSumoTrigger(trigger)
		end
	end

	-- local currentVehID = be:getPlayerVehicleID(0)
	-- local currentOwnerName = MPConfig.getNickname()
	-- if currentVehID and MPVehicleGE.getVehicleByGameID(currentVehID) then
	-- 	currentOwnerName = MPVehicleGE.getVehicleByGameID(currentVehID).ownerName
	-- end

	-- resetSumoCarColors()
	-- print( "onPreRender called")

	-- local closestOpponent = 100000000

	-- for k,vehicle in pairs(MPVehicleGE.getVehicles()) do
	-- 	if gamestate.players then
	-- 		local player = gamestate.players[vehicle.ownerName]
	-- 		if player and currentOwnerName and vehicle then
	-- 			-- SumoNametags(currentOwnerName,player,vehicle)
	-- 			-- sumoColor(player,vehicle,gamestate.players[vehicle.ownerName].team,dt)
	-- 			if gamestate.players[currentOwnerName] and currentVehID and gamestate.players[currentOwnerName].hasFlag and not gamestate.players[vehicle.ownerName].hasFlag and currentVehID ~= vehicle.gameVehicleID then
	-- 				local myVeh = be:getObjectByID(currentVehID)
	-- 				local veh = be:getObjectByID(vehicle.gameVehicleID)				
	-- 				if veh and myVeh then
	-- 					if not gamestate.players[vehicle.ownerName].hasFlag and gamestate.players[vehicle.ownerName].team ~= gamestate.players[currentOwnername].team then
	-- 						local distance = distance(myVeh:getPosition(),veh:getPosition())
	-- 						if distance < closestOpponent then
	-- 							closestOpponent = distance
	-- 						end
	-- 					end
	-- 				end
	-- 			end
	-- 			if gamestate.teams then
	-- 				local veh = be:getObjectByID(vehicle.gameVehicleID)	
	-- 				local vehPos = veh:getPosition()
	-- 				local posOffset = vec3(0,0,1.5)
	-- 				-- debugDrawer:drawTextAdvanced(vehPos + posOffset, String("Team " .. gamestate.players[vehicle.ownerName].team), ColorF(1,1,1,1), true, false, ColorI(colors[gamestate.players[vehicle.ownerName].team][1], colors[gamestate.players[vehicle.ownerName].team][2], colors[gamestate.players[vehicle.ownerName].team][3], colors[gamestate.players[vehicle.ownerName].team][4]))
	-- 			end
	-- 		end
	-- 	end
	-- end
end

function onResetGameplay(id)
	-- print( "onResetGameplay called")
end

function onExtensionUnloaded()
	-- resetSumoCarColors()
end

function onSumoVehicleSpawned(vehID)

end

function onSumoVehicleDeleted(vehID)

end

function onSumoAirSpeedTooHigh()
	print('onSumoAirSpeedTooHigh called')
	disallowSumoResets(blockedInputActionsOnSpeedOrCircle)
end

function setSumoArenasData(contents)
	print("setSumoArenasData called")
	print(contents)
	mapData.arenaData = jsonDecode(contents)
end

function onSumoSaveArena(name)
	newArena.name = name
	TriggerServerEvent("sumoSaveArena", jsonEncode(newArena))
end

function spawnSumoRandomVehicle()
	
	local chosenConfig = ''
	
	local numVehicles = #core_vehicles.getModelList(true).models
	local chosenModel = core_vehicles.getModelList(true).models[math.random(1,numVehicles)]
	
	-- Choose a single vehicle model
	-- Reroll away undesired results
	while (chosenModel.Type == 'Prop' or 
			chosenModel.Type == 'Trailer' or
			chosenModel.Type == 'Automation' or
			chosenModel.Type == 'Truck') do
		chosenModel = core_vehicles.getModelList(true).models[math.random(1,numVehicles)]
	end 
	
	local allConfigs = core_vehicles.getConfigList(true)
	local modelConfigs = {}
	
	-- Build a list of configs for the chosen model
	for i,v in pairs(allConfigs.configs) do
		if (v.model_key == chosenModel.key) then
			table.insert(modelConfigs, {key = v.key, name = v.Name})
		end
	end

	-- Randomly choose a config
	if (#modelConfigs == 0) then ui_message("No configs found for "..chosenModel.Name)
	else chosenConfig = modelConfigs[math.random(1,#modelConfigs)]
	end

	-- Spawn the vehicle
	core_vehicles.replaceVehicle(chosenModel.key, {config = chosenConfig.key})
	ui_message('Spawned: '..chosenConfig.name)

	--Create a log for examining spawn frequencies
	--print("Fairmode: "..chosenModel.key)
end

if MPGameNetwork then AddEventHandler("resetSumoCarColors", resetSumoCarColors) end
if MPGameNetwork then AddEventHandler("spawnSumoGoal", spawnSumoGoal) end
if MPGameNetwork then AddEventHandler("onSumoCreateGoal", onSumoCreateGoal) end
if MPGameNetwork then AddEventHandler("spawnSumoObstacles", spawnSumoObstacles) end
if MPGameNetwork then AddEventHandler("removeSumoPrefabs", removeSumoPrefabs) end 
if MPGameNetwork then AddEventHandler("setSumoCurrentArena", setSumoCurrentArena) end
if MPGameNetwork then AddEventHandler("requestSumoLevelName", requestSumoLevelName) end 
if MPGameNetwork then AddEventHandler("requestSumoArenaNames", requestSumoArenaNames) end
if MPGameNetwork then AddEventHandler("requestSumoLevels", requestSumoLevels) end
if MPGameNetwork then AddEventHandler("requestSumoGoalCount", requestSumoGoalCount) end
if MPGameNetwork then AddEventHandler("receiveSumoGameState", receiveSumoGameState) end
if MPGameNetwork then AddEventHandler("requestSumoGameState", requestSumoGameState) end
if MPGameNetwork then AddEventHandler("updateSumoGameState", updateSumoGameState) end
if MPGameNetwork then AddEventHandler("allowSumoResets", allowSumoResets) end
if MPGameNetwork then AddEventHandler("disallowSumoResets", disallowSumoResets) end
if MPGameNetwork then AddEventHandler("explodeSumoCar", explodeSumoCar) end
if MPGameNetwork then AddEventHandler("onSumoGameEnd", onSumoGameEnd) end
if MPGameNetwork then AddEventHandler("teleportToSumoArena", teleportToSumoArena) end
if MPGameNetwork then AddEventHandler("onSumoTrigger", onSumoTrigger) end
if MPGameNetwork then AddEventHandler("onReverseGravityTrigger", onReverseGravityTrigger) end
if MPGameNetwork then AddEventHandler("onSumoAirSpeedTooHigh", onSumoAirSpeedTooHigh) end
if MPGameNetwork then AddEventHandler("setSumoArenasData", setSumoArenasData) end
if MPGameNetwork then AddEventHandler("onSumoSaveArena", onSumoSaveArena) end
if MPGameNetwork then AddEventHandler("onSumoCreateSpawn", onSumoCreateSpawn) end
if MPGameNetwork then AddEventHandler("spawnSumoRandomVehicle", spawnSumoRandomVehicle) end

-- if MPGameNetwork then AddEventHandler("onSumoVehicleSpawned", onSumoVehicleSpawned) end
-- if MPGameNetwork then AddEventHandler("onSumoVehicleDeleted", onSumoVehicleDeleted) end

-- if MPGameNetwork then AddEventHandler("onSumoFlagTrigger", onSumoFlagTrigger) end
-- if MPGameNetwork then AddEventHandler("onSumoGoalTrigger", onSumoGoalTrigger) end

M.requestSumoGameState = requestSumoGameState
M.receiveSumoGameState = receiveSumoGameState
M.updateSumoGameState = updateSumoGameState
M.requestSumoLevelName = requestSumoLevelName
M.requestSumoArenaNames = requestSumoArenaNames
M.requestSumoLevels = requestSumoLevels
M.requestSumoGoalCount = requestSumoGoalCount
M.onPreRender = onPreRender
-- M.onVehicleSwitched = onVehicleSwitched
M.resetSumoCarColors = resetSumoCarColors
M.spawnFlag = spawnFlag
M.spawnSumoGoal = spawnSumoGoal
M.onSumoCreateGoal = onSumoCreateGoal
M.spawnSumoObstacles = spawnSumoObstacles
M.removeSumoPrefabs = removeSumoPrefabs
M.setSumoCurrentArena = setSumoCurrentArena
M.onExtensionUnloaded = onExtensionUnloaded
M.onResetGameplay = onResetGameplay
M.allowSumoResets = allowSumoResets
M.disallowSumoResets = disallowSumoResets
-- M.onVehicleResetted = onVehicleResetted
-- M.onSumoFlagTrigger = onSumoFlagTrigger
-- M.onSumoGoalTrigger = onSumoGoalTrigger
M.explodeSumoCar = explodeSumoCar
M.onSumoTrigger = onSumoTrigger
M.onSumoGameEnd = onSumoGameEnd
M.teleportToSumoArena = teleportToSumoArena
M.onSumoAirSpeedTooHigh = onSumoAirSpeedTooHigh
M.setSumoArenasData = setSumoArenasData
M.onSumoSaveArena = onSumoSaveArena
M.onSumoCreateSpawn = onSumoCreateSpawn
M.onReverseGravityTrigger = onReverseGravityTrigger
M.spawnSumoRandomVehicle = spawnSumoRandomVehicle
-- M.onSumoVehicleSpawned = onSumoVehicleSpawned
-- M.onSumoVehicleDeleted = onSumoVehicleDeleted
return M