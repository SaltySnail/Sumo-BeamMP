local M = {}

local floor = math.floor
local mod = math.fmod
local rand = math.random

local gamestate = {players = {}, settings = {}}

--blocked inputs when dead
local blockedInputActionsOnRound = 			{'slower_motion','faster_motion','toggle_slow_motion','modify_vehicle','vehicle_selector','saveHome','loadHome', 'reset_all_physics','toggleTraffic', 					 "recover_vehicle_alt", "recover_to_last_road", "reload_vehicle", "reload_all_vehicles", "parts_selector", "dropPlayerAtCamera", "nodegrabberRender",'reset_physics','dropPlayerAtCameraNoReset',"forceField", "funBoom", "funBreak", "funExtinguish", "funFire", "funHinges", "funTires", "funRandomTire", "latchesOpen", "latchesClose","toggleWalkingMode","photomode","toggleTrackBuilder","toggleBigMap","toggleRadialMenuSandbox", "toggleRadialMenuPlayerVehicle", "toggleRadialMenuFavorites", "toggleRadialMenuMulti","appedit","pause"}
local allInputActions = 					{'slower_motion','faster_motion','toggle_slow_motion','modify_vehicle','vehicle_selector','saveHome','loadHome', 'reset_all_physics','toggleTraffic', "recover_vehicle", "recover_vehicle_alt", "recover_to_last_road", "reload_vehicle", "reload_all_vehicles", "parts_selector", "dropPlayerAtCamera", "nodegrabberRender",'reset_physics','dropPlayerAtCameraNoReset',"forceField", "funBoom", "funBreak", "funExtinguish", "funFire", "funHinges", "funTires", "funRandomTire", "latchesOpen", "latchesClose","toggleWalkingMode","photomode","toggleTrackBuilder","toggleBigMap","toggleRadialMenuSandbox", "toggleRadialMenuPlayerVehicle", "toggleRadialMenuFavorites", "toggleRadialMenuMulti","appedit","pause"}

local colors = {["Red"] = {255,50,50,255},["LightBlue"] = {50,50,160,255},["Green"] = {50,255,50,255},["Yellow"] = {200,200,25,255},["Purple"] = {150,50,195,255}}
local mapData = {}
local isPlayerInCircle = false
local isPlayerBelowSpeedLimit = false
local isPlayerDead = false
local isPlayerInReverseGravity = false
local reverseGravitySubjectId = 0 -- may be unnecessary

local currentArena = ""
local currentLevel = ""
local lastCreatedGoalID = 1

local defaultRedFadeDistance = 20

local goalPrefabActive = false
local goalPrefabPath
local goalPrefabName
local goalPrefabObj
local goalLocation
local goalPos
local goalVecX
local goalVecY
local goalVecZ
local vecX = vec3(1,0,0)
local vecY = vec3(0,1,0)
local vecZ = vec3(0,0,1)

local obstaclesPrefabActive = false
local spawnedObstaclePrefabs = {}

local debugSphereColorTriggered = ColorF(0,1,0,1)
local debugSphereColorNeutral = ColorF(1,0,0,1)
local debugView = false

local teleported = false

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
	-- print('allowSumoResets called')
end

function disallowSumoResets(data)
	extensions.core_input_actionFilter.setGroup('sumo', data)
	extensions.core_input_actionFilter.addAction(0, 'sumo', true)
	-- print('disallowSumoResets called')
end

function spawnSumoGoal(filepath, offset, rotation) 
	goalPrefabActive = true
	goalPrefabPath   = filepath
	goalPrefabName   = string.gsub(filepath, "(.*/)(.*)", "%2"):sub(1, -13)
	local goalNumber = tonumber(string.match(goalPrefabName, "%d+"))
	if 		goalNumber
		and mapData.arenaData
		and mapData.arenaData[currentArena]
		and mapData.arenaData[currentArena].goals
		and goalNumber > #mapData.arenaData[currentArena].goals then
			goalNumber = #mapData.arenaData[currentArena].goals		
			--if goal number is greater than amount of goals on the client side, just spawn the last goal
	end
	goalPrefabPath = "art/goal.prefab.json"
	local offsetString = '0 0 0'
	local rotationString = '0 0 1'
	local scaleString = '1 1 1'
	print("Spawning goal: " .. currentArena .. " " .. goalNumber)
	if 		mapData.arenaData 
		and mapData.arenaData[currentArena] 
		and mapData.arenaData[currentArena].goals 
		and mapData.arenaData[currentArena].goals[goalNumber] then
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
	elseif 		mapData.arenaData
			and mapData.arenaData[currentArena]
			and mapData.arenaData[currentArena].goals
			and mapData.arenaData[currentArena].goals[goalNumber] then
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
	
	-- set position for checking the trigger
	local rot, scl
	goalPos, rot, scl = newObj:getPosition(), quat(newObj:getRotation()), newObj:getScale()
	goalVecZ, goalVecY, goalVecX = rot*vecZ*scl.z, rot*vecY*scl.y, rot*vecX*scl.x
	goalVecX = goalVecX * 1.5 --make the hitbox of the safezone the same size as the visual safezone
	goalVecY = goalVecY * 3
	goalVecZ = goalVecZ * 2
end

function onSumoCreateGoal()
	local currentVehID = be:getPlayerVehicleID(0)
	local veh = be:getObjectByID(currentVehID)
	if not veh then return end
	local pos = veh:getPosition()
	local rot = veh:getRotation()
	rot = rot:toEuler()
	-- removeSumoPrefabs("goal")
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

function onSumoRemoveSpawns()
	if newArena.spawnLocations then
		newArena.spawnLocations = {}
	end
end
-- for _, file in ipairs(FS:findFiles("art/CastleIslands/", "*", 0, true, false)) do print(file) end
function spawnSumoObstacles(filepath)
	-- Find and spawn all prefab files in the specified directory
	for _, file in ipairs(FS:findFiles(filepath, "*", 0, true, false)) do
		if file:match("%.prefab%.json$") or file:match("%.json$") then
			print("Spawning prefab: " .. file)
			local prefabName = string.gsub(file, "(.*/)(.*)", "%2"):sub(1, -13)
			local prefabObj = spawnPrefab(prefabName, file, '0 0 0', '0 0 1', '1 1 1')
			table.insert(spawnedObstaclePrefabs, prefabName)
		end
	end
	obstaclesPrefabActive = true
	be:reloadStaticCollision(true)
	print("Spawned prefabs: " .. dump(spawnedObstaclePrefabs))
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
		goalVecX, goalVecY, goalVecZ = nil, nil, nil
		-- print( "Removing: " .. goalPrefabName)
		goalPrefabActive = false
	elseif type == "all" then
		if goalPrefabActive then
			removePrefab(goalPrefabName)
			-- print( "Removing: " .. goalPrefabName)
			goalPrefabActive = false
		end
		if obstaclesPrefabActive then
			for _, prefabName in ipairs(spawnedObstaclePrefabs) do
				removePrefab(prefabName)
				print( "Removing: " .. prefabName)
			end
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
		if arenaData 
			and arenaData.goals then
			goals = #arenaData.goals
		else
			goals = 1
		end
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
			teleported = true
		end
		veh:queueLuaCommand("recovery.startRecovering()")
		veh:queueLuaCommand("recovery.stopRecovering()")
	end
end

--[[         this function comes from spawn.lua in beamng's lua folder. I need this to pick a valid spawn point but not spawn the default vehicle.
pickSpawnPoint s responsible for finding a valid spawn point for a player and camera
@param spawnName string represent player or camera spawn point
]]
local function pickSpawnPoint(spawnName)
	local playerSP,spawnPointName
	local defaultSpawnPoint = setSpawnpoint.loadDefaultSpawnpoint()
	local spawnDefaultGroups = {"CameraSpawnPoints", "PlayerSpawnPoints", "PlayerDropPoints"}
	if defaultSpawnPoint then
	  local spawnPoint = scenetree.findObject(defaultSpawnPoint)
	  if spawnPoint then
		return spawnPoint
	  else
		log('W', logTag, 'No SpawnPointName in mission file vehicle spawn in the default position')
	  end
	end
	--Walk through the groups until we find a valid object
	for i,v in pairs(spawnDefaultGroups) do
	  if scenetree.findObject(spawnDefaultGroups[i]) then
		local spawngroupPoint = scenetree.findObject(spawnDefaultGroups[i]):getRandom()
		if not spawngroupPoint then
		  break
		end
		local sgPpointID = scenetree.findObjectById(spawngroupPoint:getId())
		if not sgPpointID then
		  break
		end
		return sgPpointID
	  end
	end
  
	--[[ ensuring backward compability with mods
	]]
	local dps = scenetree.findObject("DefaultPlayerSpawnSphere")
	if dps then
	  return scenetree.findObjectById(dps.obj:getId())
	end
  
	--[[Didn't find a spawn point by looking for the groups so let's return the
	 "default" SpawnSphere First create it if it doesn't already exist
	]]
	playerSP = createObject('SpawnSphere')
	if not playerSP then
	  log('E', logTag, 'could not create playerSP')
	  return
	end
	playerSP.dataBlock = scenetree.findObject('SpawnSphereMarker')
	if spawnName == "player" then
	  playerSP.spawnClass = "BeamNGVehicle"
	  playerSP.spawnDatablock = "default_vehicle"
	  spawnPointName = "DefaultPlayerSpawnSphere"
	  playerSP:registerObject(spawnPointName)
	elseif spawnName == 'camera' then
	  playerSP.spawnClass = "Camera"
	  playerSP.spawnDatablock = "Observer"
	  spawnPointName = "DefaultCameraSpawnSphere"
	  playerSP:registerObject(spawnPointName)
	end
	local missionCleanup = scenetree.MissionCleanup
	if not missionCleanup then
	  log('E', logTag, 'MissionCleanup does not exist')
	  return
	end
	--[[ Add it to the MissionCleanup group so that it doesn't get saved
	  to the Mission (and gets cleaned up of course)
	]]
	missionCleanup:addObject(playerSP.obj)
	return playerSP
  end

function onSumoGameEnd()
	core_gamestate.setGameState('scenario', 'multiplayer', 'multiplayer') --reset the app layout
	allowSumoResets(blockedInputActionsOnRound)
	allowSumoResets(allInputActions)
	goalScale = 1
	goalLocation = nil
	removeSumoPrefabs("all")
	local spawnPoint = pickSpawnPoint('player')
	if not spawnPoint then return end
	for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
		local veh = be:getObjectByID(vehID)
		if not veh then return end
		local spawnPos = spawnPoint:getPosition()
		local spawnQuat = quat(spawnPoint:getRotation()) * quat(0,0,1,0)
		veh:setPositionRotation(spawnPos.x, spawnPos.y, spawnPos.z, spawnQuat.x, spawnQuat.y, spawnQuat.z, spawnQuat.w)
		veh:queueLuaCommand("recovery.startRecovering()")
		veh:queueLuaCommand("recovery.stopRecovering()")
	end
	teleported = false
end

function handleResetState()
	print("handleResetState called player in circle: " .. tostring(isPlayerInCircle) .. " below speed limit: " .. tostring(isPlayerBelowSpeedLimit) .. " dead: " .. tostring(isPlayerDead))
	guihooks.trigger('sumoSetRuleStatus', {rule='Safe Zone', status=isPlayerInCircle})
	guihooks.trigger('sumoSetRuleStatus', {rule='Speed Limit', status=(isPlayerBelowSpeedLimit==false)}) --somehow this is inverted
	if not isPlayerInCircle and isPlayerBelowSpeedLimit and not isPlayerDead then
		-- allowSumoResets(allInputActions)
		disallowSumoResets(blockedInputActionsOnRound)
		guihooks.trigger('sumoSetRuleStatus', {rule='Car Repair', status=false})
	else		
		disallowSumoResets(allInputActions)
		if not isPlayerDead then
			guihooks.trigger('sumoSetRuleStatus', {rule='Car Repair', status=true})
		else
			guihooks.trigger('sumoSetRuleStatus', {rule='Car Repair', status=false})
		end
	end
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
					disallowSumoResets(allInputActions)
					isPlayerDead = true
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
					-- disallowSumoResets(allInputActions)
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
						-- allowSumoResets(allInputActions) 
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
				-- allowSumoResets(allInputActions) --removed this because players might spawn back on the platform, which ruins it for others
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
					core_camera.setByName(0,"chase")
					core_camera.resetCamera(0)
				end
				core_environment.setGravity(9.81)
				isPlayerInReverseGravity = true
				reverseGravitySubjectId = data.subjectID
			elseif data.event == "exit" then
				if ogCamName ~= "chase" and ogCamName ~= "onboard_hood" and ogCamName ~= "driver" then
					core_camera.setByName(0,ogCamName)
					core_camera.resetCamera(0)
					ogCamName = ""
				end
				core_environment.setGravity(-9.81)
				isPlayerInReverseGravity = false
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

	local txt = ""
	if gamestate.randomVehicles and time and time == -28 then 
		spawnSumoRandomVehicle()
		core_gamestate.setGameState('scenario', 'sumo', 'scenario')
		disallowSumoResets(allInputActions)
	end
	if gamestate.randomVehicles and time and time == -20 then 
		reloadUI() --ensures all apps are on the screen (sometimes the gauge cluster wasn't)
	end
	if gamestate.randomVehicles and time and time >= -18 and time <= -8 then 
		MPVehicleGE.applyQueuedEvents()
	end
	if not gamestate.randomVehicles and time and time == -8 then 
		core_gamestate.setGameState('scenario', 'sumo', 'scenario')
		disallowSumoResets(allInputActions)
	end
	if time and time >= -5 and time <= 0 then
		if not teleported then
			teleportToSumoArena()
		end
		if not goalPrefabActive then -- mitigation for when no goal spawned
			spawnSumoGoal("art/goal1.prefab.json")
		end
	end
	if time and time < 0 then
		be:queueAllObjectLua("controller.setFreeze(1)")
		-- for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
		-- 	local veh = be:getObjectByID(vehID)
		-- 	veh:queueLuaCommand('controller.setFreeze(1)')
		-- end
		disallowSumoResets(allInputActions)
		isPlayerDead = false
	end
	if time and time == 0 then 
		guihooks.trigger('sumoStartTimer', 30)
		be:queueAllObjectLua("controller.setFreeze(0)")
		-- for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
		-- 	local veh = be:getObjectByID(vehID)
		-- 	veh:queueLuaCommand('controller.setFreeze(0)')
		-- end
		-- allowSumoResets(allInputActions)
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
		handleResetState() 		
	elseif time and gamestate.endtime and (gamestate.endtime - time) < 7 then
		local timeLeft = gamestate.endtime - time
		txt = "Arena will be removed in "..math.abs(timeLeft-1).." seconds" --game ended
		guihooks.trigger('sumoRemoveTimer', 0)
	end
	if txt ~= "" then
		guihooks.message({txt = txt}, 1, "Sumo.time")
	end
end

function requestSumoGameState()
	if TriggerServerEvent then TriggerServerEvent("requestSumoGameState","nil") end
end

local distancecolor = -1

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

function onPreRender(dt)
	if not gamestate.gameRunning then return end
	if simTimeAuthority.get ~= 1 then
		simTimeAuthority.setInstant(1)
	end
	for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
		local veh = be:getObjectByID(vehID)
		veh:queueLuaCommand("requestSumoAirSpeedKmh()")
	end
	if goalLocation and goalPrefabActive then
		debugDrawer:drawTextAdvanced(goalLocation, "Safezone", ColorF(1,1,1,1), true, false, ColorI(20,20,255,255))
	end
	if not goalPos or not goalVecX or not goalVecY or not goalVecZ then return end
	if not be:getPlayerVehicle(0) then return end
	local playerVehicle = be:getPlayerVehicle(0)
	local bb1 = playerVehicle:getSpawnWorldOOBB()
	local isInsideSafezone = overlapsOBB_OBB(bb1:getCenter(), bb1:getAxis(0) * bb1:getHalfExtents().x, bb1:getAxis(1) * bb1:getHalfExtents().y, bb1:getAxis(2) * bb1:getHalfExtents().z, goalPos, goalVecX, goalVecY, goalVecZ)

	-- this checks if player has transistioned from inside to outside the safezone or vice versa or it is the first time checking
	if not playerVehicle.isInsideSafezone 
		or isInsideSafezone == true
	    or playerVehicle.isInsideSafezone ~= isInsideSafezone 
		then 
			
		playerVehicle.isInsideSafezone = isInsideSafezone
		if isInsideSafezone then
			if debugView then
				debugDrawer:drawSphere(goalPos, 0.1, debugSphereColorTriggered)
				debugDrawer:drawSphere(goalPos + goalVecX, 0.1, debugSphereColorTriggered)
				debugDrawer:drawSphere(goalPos + goalVecY, 0.1, debugSphereColorTriggered)
				debugDrawer:drawSphere(goalPos + goalVecZ, 0.1, debugSphereColorTriggered)
			end
			trigger = {}
			trigger.event = "enter"
			trigger.triggerName = "goalTrigger0"
			trigger.subjectID = playerVehicle:getID()
			onSumoTrigger(trigger)
		else
			if debugView then
				debugDrawer:drawSphere(goalPos, 0.1, debugSphereColorNeutral)
				debugDrawer:drawSphere(goalPos + goalVecX, 0.1, debugSphereColorNeutral)
				debugDrawer:drawSphere(goalPos + goalVecY, 0.1, debugSphereColorNeutral)
				debugDrawer:drawSphere(goalPos + goalVecZ, 0.1, debugSphereColorNeutral)
			end
			trigger = {}
			trigger.event = "exit"
			trigger.triggerName = "goalTrigger0"
			trigger.subjectID = playerVehicle:getID()
			onSumoTrigger(trigger)
		end
	end
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

function onSumoAirSpeedKmh(kmh)
	-- print('onSumoAirSpeedKmh called ' .. kmh)
	if kmh > 20 then
		isPlayerBelowSpeedLimit = false
	else
		isPlayerBelowSpeedLimit = true
	end
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

function isInTable(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

function spawnSumoRandomVehicle()
	local hasCar = false
	local playerName = ""
	for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
		hasCar = true
		playerName = vehData.ownerName
		break
	end
	if not hasCar then return end -- skip spectators
	if not playerName then print("No playername!?!?") return end
	for playername, player in pairs(gamestate.players) do
		if playername == playerName then
			print("Playername: " .. playername .. " chosenConfig: " .. dump(player.chosenConfig))
			core_vehicles.replaceVehicle(player.chosenConfig:match("^vehicles/([^/]+)/") , {config = player.chosenConfig})
			break
		end
	end
end

function onVehicleResetted(vehID)
	-- print( "onVehicleResetted called")
	if MPVehicleGE and isPlayerInReverseGravity then -- roll the vehicle so the wheels touch the ground when resetting in the reverse gravity area
		if MPVehicleGE.isOwn(vehID) then
			local veh = be:getObjectByID(reverseGravitySubjectId)
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

function onSumoShowScoreboard(data)
	print("onSumoShowScoreboard called ")
	if not data then return end
	print("data: " .. data)
	data = jsonDecode(data)
	guihooks.trigger('scoreboardSpawn', {})
	guihooks.trigger('scoreboardSetScores', data)
	-- if data then 
	-- 	local overallWinner = nil
	-- 	local highestScore = 0
	-- 	for i, player in pairs(data) do
	-- 		if player.score and player.score > highestScore then
	-- 			highestScore = player.score
	-- 			overallWinner = player.name
	-- 		end
	-- 	end
	-- 	if not (highestScore > 0) then return end
	-- 	-- guihooks.trigger('scoreboardSelectRoundWinner', roundWinner)
	-- 	-- guihooks.trigger('scoreboardSelectOverallWinner', overallWinner)
	-- end
end

function blockConsole()
	print("blockConsole called")
	extensions.core_input_actionFilter.setGroup('sumoConsole', {"toggleConsoleNG"})
	extensions.core_input_actionFilter.addAction(0, 'sumoConsole', true)
end

function blockEditor()
	print("blockEditor called")
	extensions.core_input_actionFilter.setGroup('sumoEditor', {"editorToggle", "objectEditorToggle", "editorSafeModeToggle"})
	extensions.core_input_actionFilter.addAction(0, 'sumoEditor', true)
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
if MPGameNetwork then AddEventHandler("onSumoAirSpeedKmh", onSumoAirSpeedKmh) end
if MPGameNetwork then AddEventHandler("setSumoArenasData", setSumoArenasData) end
if MPGameNetwork then AddEventHandler("onSumoSaveArena", onSumoSaveArena) end
if MPGameNetwork then AddEventHandler("onSumoCreateSpawn", onSumoCreateSpawn) end
if MPGameNetwork then AddEventHandler("spawnSumoRandomVehicle", spawnSumoRandomVehicle) end
if MPGameNetwork then AddEventHandler("onVehicleResetted", onVehicleResetted) end
if MPGameNetwork then AddEventHandler("onSumoShowScoreboard", onSumoShowScoreboard) end
if MPGameNetwork then AddEventHandler("onSumoRemoveSpawns", onSumoRemoveSpawns) end
if MPGameNetwork then AddEventHandler("blockConsole", blockConsole) end
if MPGameNetwork then AddEventHandler("blockEditor", blockEditor) end
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
M.onVehicleResetted = onVehicleResetted
-- M.onSumoFlagTrigger = onSumoFlagTrigger
-- M.onSumoGoalTrigger = onSumoGoalTrigger
M.explodeSumoCar = explodeSumoCar
M.onSumoTrigger = onSumoTrigger
M.onSumoGameEnd = onSumoGameEnd
M.teleportToSumoArena = teleportToSumoArena
M.onSumoAirSpeedKmh = onSumoAirSpeedKmh
M.setSumoArenasData = setSumoArenasData
M.onSumoSaveArena = onSumoSaveArena
M.onSumoCreateSpawn = onSumoCreateSpawn
M.onReverseGravityTrigger = onReverseGravityTrigger
M.spawnSumoRandomVehicle = spawnSumoRandomVehicle
M.onSumoShowScoreboard = onSumoShowScoreboard
M.onSumoRemoveSpawns = onSumoRemoveSpawns
M.blockConsole = blockConsole
M.blockEditor = blockEditor
-- M.onSumoVehicleSpawned = onSumoVehicleSpawned
-- M.onSumoVehicleDeleted = onSumoVehicleDeleted
return M
