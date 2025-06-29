local M = {}

local sock = require('socket')
local sumoStartTime

local floor = math.floor
local mod = math.fmod
local rand = math.random

local gamestate = {players = {}, settings = {}}
local alivePlayers = {}

--blocked inputs when dead
local blockedInputActionsOnRound = 			{'slower_motion','faster_motion','toggle_slow_motion','modify_vehicle','vehicle_selector','saveHome','loadHome', 'reset_all_physics','toggleTraffic', 					         "recover_vehicle_alt", "recover_to_last_road", "reload_vehicle", "reload_all_vehicles", "parts_selector", "dropPlayerAtCamera", "nodegrabberRender",'reset_physics','dropPlayerAtCameraNoReset',"forceField", "funBoom", "funBreak", "funExtinguish", "funFire", "funHinges", "funTires", "funRandomTire", "latchesOpen", "latchesClose","toggleWalkingMode","photomode","toggleTrackBuilder","toggleBigMap","toggleRadialMenuSandbox", "toggleRadialMenuPlayerVehicle", "toggleRadialMenuFavorites", "toggleRadialMenuMulti","appedit","pause"}
local allInputActions = 								{'slower_motion','faster_motion','toggle_slow_motion','modify_vehicle','vehicle_selector','saveHome','loadHome', 'reset_all_physics','toggleTraffic', "recover_vehicle", "recover_vehicle_alt", "recover_to_last_road", "reload_vehicle", "reload_all_vehicles", "parts_selector", "dropPlayerAtCamera", "nodegrabberRender",'reset_physics','dropPlayerAtCameraNoReset',"forceField", "funBoom", "funBreak", "funExtinguish", "funFire", "funHinges", "funTires", "funRandomTire", "latchesOpen", "latchesClose","toggleWalkingMode","photomode","toggleTrackBuilder","toggleBigMap","toggleRadialMenuSandbox", "toggleRadialMenuPlayerVehicle", "toggleRadialMenuFavorites", "toggleRadialMenuMulti","appedit","pause"}
--for testing with nodegrabber:
-- local blockedInputActionsOnRound = 			{'slower_motion','faster_motion','toggle_slow_motion','modify_vehicle','vehicle_selector','saveHome','loadHome', 'reset_all_physics','toggleTraffic', 					         "recover_vehicle_alt", "recover_to_last_road", "reload_vehicle", "reload_all_vehicles", "parts_selector", "dropPlayerAtCamera",'reset_physics','dropPlayerAtCameraNoReset',"forceField", "funBoom", "funBreak", "funExtinguish", "funFire", "funHinges", "funTires", "funRandomTire", "latchesOpen", "latchesClose","toggleWalkingMode","photomode","toggleTrackBuilder","toggleBigMap","toggleRadialMenuSandbox", "toggleRadialMenuPlayerVehicle", "toggleRadialMenuFavorites", "toggleRadialMenuMulti","appedit","pause"}
-- local allInputActions = 								{'slower_motion','faster_motion','toggle_slow_motion','modify_vehicle','vehicle_selector','saveHome','loadHome', 'reset_all_physics','toggleTraffic', "recover_vehicle", "recover_vehicle_alt", "recover_to_last_road", "reload_vehicle", "reload_all_vehicles", "parts_selector", "dropPlayerAtCamera",'reset_physics','dropPlayerAtCameraNoReset',"forceField", "funBoom", "funBreak", "funExtinguish", "funFire", "funHinges", "funTires", "funRandomTire", "latchesOpen", "latchesClose","toggleWalkingMode","photomode","toggleTrackBuilder","toggleBigMap","toggleRadialMenuSandbox", "toggleRadialMenuPlayerVehicle", "toggleRadialMenuFavorites", "toggleRadialMenuMulti","appedit","pause"}

local colors = {["Red"] = {255,50,50,255},["LightBlue"] = {50,50,160,255},["Green"] = {50,255,50,255},["Yellow"] = {200,200,25,255},["Purple"] = {150,50,195,255}}
local mapData = {}
local isPlayerInCircle = false
local isPlayerBelowSpeedLimit = false
local isPlayerDead = false
local playerDiedAtTime = 0
local playerIsResetting = false
local startResettingTime = 0
local resetDelay = 1.5 --s
local isPlayerInReverseGravity = false
local reverseGravitySubjectId = 0 -- may be unnecessary
local spectatingPlayer = "" -- player that is being spectated

local ogCamBeforeSpectating = "orbit"
local ogUIState = "multiplayer"
local ogUIStateBeforeMenu = "multiplayer"
local sumoMenuOpen = false

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


local gameRunning = false -- this is dumb but needed for comparing if gameRunning state has changed

local playerPressedReset = true -- primed because the function isn't called yet when this happens
local teleported = false
local joinNextRound = false
local autoSpectate = true
local motd = {}
motd.title = "This server is running Sumo"
motd.description = [[
  [color=#8D8300]Join by Spawning:[/color][br] Spawn any Car to join the game. [br]If a game is already in progress, press [b]ctrl+S[/b] to open the menu and check [b]Join Next Round[/b] to auto-spawn when the current game ends.
  [color=#8D8300]Automatic Start:[/color][br] The game starts automatically when five or more players have joined.
  [color=#8D8300]Safezone Mechanics:[/color][br] Every 30 seconds, a new smaller safezone appears.
  [color=#8D8300]Explosive Elimination:[/color][br] Still outside the zone when the timer runs out? You’ll explode!
  [color=#8D8300]Vehicle Reset:[/color][br] To reset after surviving a safezone, [b]hold the reset in place button[/b] until the progress bar fills—your car will then reset automatically.
  [color=#8D8300]No Resets After Death:[/color][br] Once eliminated, all reset functions are disabled until the round ends.
  [color=#8D8300]Victory Conditions:[/color][br] You win by being the last player standing, or by being among the survivors after 5 minutes.
  [color=#8D8300]Scoring:[/color][br] You earn 1 point for every safezone you survive. Winners get bonus points equal to zones survived.

  [color=#7F7F00][i][right]Brought to you by Julianstap & the BeamMP team![/right][/i][/color]
]]
motd.type = "htmlOnly" -- htmlOnly: simple (large) motd || selectableVehicle: motd with the ability to select a vehicle
motd.enabled = true

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

local function updateAlivePlayers()
	alivePlayers = {}
	for playername, player in pairs(gamestate.players) do
  	if not player.dead and playername ~= MPConfig.getNickname then
    	table.insert(alivePlayers, playername)
  	end
	end
	--guihooks.trigger('setSumoPlayerList', alivePlayers)
end

local function getPlayerList()
	updateAlivePlayers()
	guihooks.trigger('setSumoPlayerList', alivePlayers)
	if spectatingPlayer ~= "" then
		guihooks.trigger('setSpectatingPlayer', spectatingPlayer)
	end
end

local function spectatePlayer(playername)
	--updateAlivePlayers()
	local activeCam = core_camera.getActiveCamName(0)
	if activeCam ~= "external" and activeCam ~= "helicam" then
		ogCamBeforeSpectating = core_camera.getActiveCamName(0)
	end
	if HeliCam then
		local gameVehID = 0
		if not MPVehicleGE.getPlayerByName(playername) then 
			print("No player by the name of " .. playername .. " the player list is: " .. dump(MPVehicleGE.getPlayers))
			return
		end 
		for _, vehicleData in pairs(MPVehicleGE.getPlayerByName(playername).vehicles) do gameVehID = vehicleData.gameVehicleID break end
		if spectatingPlayer ~= "" then
			HeliCam.despawnHeli()
		end
		HeliCam.setAllInOne(gameVehID, 3, 25, 25, false)
		HeliCam.toggleUiRender(false) --somehow need to call this twice to not make the UI spawn
		HeliCam.toggleUiRender(false)
	else
		MPVehicleGE.focusCameraOnPlayer(playername)
		core_camera.setByName(0,"external")
		core_camera.resetCamera(0)
	end
	spectatingPlayer = playername
	guihooks.trigger('setSpectatingPlayer', spectatingPlayer)
end

function sumoSpectateAlivePlayer()
	updateAlivePlayers()
	guihooks.trigger('setSumoPlayerList', alivePlayers) 
	for _, playername in pairs(alivePlayers) do
		if playername ~= MPConfig.getNickname() then
			spectatePlayer(playername)
			--guihooks.trigger('spectatePlayerByName', playername)
			break
		end
	end
end

function sumoStopSpectating()
	spectatingPlayer = ""
	MPVehicleGE.focusCameraOnPlayer(MPConfig.getNickname())
	if HeliCam then
		HeliCam.despawnHeli()
	end
	print(ogCamBeforeSpectating)
	core_camera.setByName(0,ogCamBeforeSpectating) 
	core_camera.resetCamera(0)
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
end

function receiveSumoGameState(data)
	local data = jsonDecode(data)
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
	if sumoStartTime then
		sumoStartTime = sock.gettime() -- if sumo already started, sync on every safezone length
	end
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
	career_career.closeAllMenus() -- just to be sure
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

function teleportToSumoArena(spawnPointID)
	print("" .. tostring(spawnPointID))
	if spawnPointID == 'nil' then --teleportCars to as many spawns as possible for testing
		print('teleporting all vehicles.... ')
		local arenaData = mapData.arenaData[currentArena]
		local spawnIndex = 0
		for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
			spawnIndex = spawnIndex + 1
			local veh = be:getObjectByID(vehID)
			local chosenLocation = (spawnIndex % #arenaData.spawnLocations) + 1
			if arenaData.spawnLocations[chosenLocation] then
				-- print(dump(quatFromEuler(arenaData.spawnLocations[chosenLocation].rx, arenaData.spawnLocations[chosenLocation].ry, arenaData.spawnLocations[chosenLocation].rz)))
				local q = quatFromEuler(math.rad(arenaData.spawnLocations[chosenLocation].rx), math.rad(arenaData.spawnLocations[chosenLocation].ry), math.rad(arenaData.spawnLocations[chosenLocation].rz))
				-- veh:setPositionRotation(arenaData.spawnLocations[chosenLocation].x, arenaData.spawnLocations[chosenLocation].y, arenaData.spawnLocations[chosenLocation].z, q.x, q.y, q.z, q.w)
				spawn.safeTeleport(veh, arenaData.spawnLocations[chosenLocation], q) 
				teleported = true
			end
			veh:queueLuaCommand("recovery.recoverInPlace()")
		end
		return
	end
	print("teleportToSumoArena Called")
	if teleported == true then return end -- only teleport once per round
	for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
		-- local veh = be:getObjectByID(be:getPlayerVehicleID(0))
		-- print("veh:" .. vehID .." : " .. dump(vehData))
		local veh = be:getObjectByID(vehID)
		if not veh then return end --Should not be called but just to be safe
		local arenaData = mapData.arenaData[currentArena]
		local chosenLocation = (spawnPointID % #arenaData.spawnLocations) + 1 -- make sure the spawn point is within the range of the spawn locations

		if arenaData.spawnLocations[chosenLocation] then
			-- print(dump(quatFromEuler(arenaData.spawnLocations[chosenLocation].rx, arenaData.spawnLocations[chosenLocation].ry, arenaData.spawnLocations[chosenLocation].rz)))
			local q = quatFromEuler(math.rad(arenaData.spawnLocations[chosenLocation].rx), math.rad(arenaData.spawnLocations[chosenLocation].ry), math.rad(arenaData.spawnLocations[chosenLocation].rz))
			-- veh:setPositionRotation(arenaData.spawnLocations[chosenLocation].x, arenaData.spawnLocations[chosenLocation].y, arenaData.spawnLocations[chosenLocation].z, q.x, q.y, q.z, q.w)
			spawn.safeTeleport(veh, arenaData.spawnLocations[chosenLocation], q) 
			teleported = true
		end
		veh:queueLuaCommand("recovery.recoverInPlace()")
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
	core_gamestate.setGameState(ogUIState['state'], ogUIState['appLayout'], ogUIState['appLayout']) --reset the app layout
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
		spawnPos.x = spawnPos.x + rand(-10,10)
		spawnPos.y = spawnPos.y + rand(-10,10)
		spawnPos.z = spawnPos.z + rand(1,10)
		spawn.safeTeleport(veh, spawnPos, spawnQuat)
		-- veh:setPositionRotation(spawnPos.x + rand(-10,10), spawnPos.y + rand(-10,10), spawnPos.z + rand(1,10), spawnQuat.x, spawnQuat.y, spawnQuat.z, spawnQuat.w) -- random offset to make it less likely to spawn inside of each other
		veh:queueLuaCommand("recovery.recoverInPlace()")
	end
	teleported = false
end

function handleResetState()
	-- print("handleResetState called player in circle: " .. tostring(isPlayerInCircle) .. " below speed limit: " .. tostring(isPlayerBelowSpeedLimit) .. " dead: " .. tostring(isPlayerDead))
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
function explodeSumoCar(playername)
	print('explodeSumoCar called: ' .. playername)
	for vid, vehData in pairs(MPVehicleGE.getVehicles()) do
		-- local veh = be:getObjectByID(vehData.gameVehicleID)
		local serverVeh = MPVehicleGE.getVehicleByGameID(vehData.gameVehicleID)
		print('explodeSumoCar - checking if player ' .. playername .. ' is the same as ' .. serverVeh.ownerName .. '  ' .. dump(serverVeh))
		if serverVeh.ownerName == playername then
			local veh = be:getObjectByID(vehData.gameVehicleID)
			veh:queueLuaCommand("fire.explodeVehicle()")
			veh:queueLuaCommand("beamstate.breakAllBreakgroups()")
			veh:queueLuaCommand("fire.igniteVehicle()") -- TODO make sure this is not causing the issues and update random about it
			if MPConfig.getNickname() == serverVeh.ownerName then
				disallowSumoResets(allInputActions)
				isPlayerDead = true
				playerDiedAtTime = gamestate.time 
				if autoSpectate and serverVeh and serverVeh.ownerName == spectatingPlayer then
					sumoSpectateAlivePlayer() -- spectate a new player when the current one dies
				end
				if TriggerServerEvent and serverVeh and serverVeh.ownerName then
					TriggerServerEvent("onSumoPlayerExplode", serverVeh.ownerName) 
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
					if TriggerServerEvent then TriggerServerEvent("unmarkSumoVehicleToExplode", vehData.ownerName) end
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
					if TriggerServerEvent then TriggerServerEvent("markSumoVehicleToExplode", vehData.ownerName) end
					isPlayerInCircle = false
				end
			end
			-- print( "Marked " .. data.subjectID .. " for exploding")
			--mark player to explode
		-- else
		-- 	if TriggerServerEvent then TriggerServerEvent("unmarkSumoVehicleToExplode", data.subjectID) end
		end
	elseif string.find(trigger, "outOfBoundTrigger") then
		if gamestate and (gamestate.time and gamestate.time < -3) or not gamestate.gameRunning then return end
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
				explodeSumoCar(vehData.ownerName)
				if TriggerServerEvent then TriggerServerEvent("markSumoVehicleToExplode", vehData.ownerName) end
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

function setSumoLayout(appLayout)
	if gamestate.gameRunning then
		career_career.closeAllMenus()
		core_gamestate.setGameState('scenario', appLayout, 'scenario')
	end
end

function updateSumoGameState(data)
	print('updateSumoGameState called: ' .. data)
	mergeSumoTable(jsonDecode(data),gamestate)
--	if gameRunning ~= gamestate.gameRunning then
		gameRunning = gamestate.gameRunning
		be:queueAllObjectLua("Sumo.setSumoGameRunning(".. tostring(gameRunning) ..")")
--	end
	
	local time = 0

	if gamestate.time then time = gamestate.time-1 end

	local txt = ""
	if gamestate.gameRunning and gamestate.randomVehicles and time and time == gamestate.randomVehicleStartWaitTime + 2 then 
		spawnSumoRandomVehicle()
		setSumoLayout('sumo')
		disallowSumoResets(allInputActions)
	end
	if gamestate.gameRunning and gamestate.randomVehicles and time and time == gamestate.randomVehicleStartWaitTime + 10 then 
		-- reloadUI() --ensures all apps are on the screen (sometimes the gauge cluster wasn't)		
		for vehID, _ in pairs(MPVehicleGE.getOwnMap()) do
			core_camera.setVehicleCameraByNameWithId(vehID, 'orbit', true, {}) 
		end
	end
	if gamestate.gameRunning and gamestate.randomVehicles and time and time >= gamestate.randomVehicleStartWaitTime + 12 and time <= gamestate.randomVehicleStartWaitTime + 22 then 
		MPVehicleGE.applyQueuedEvents()
	end
	if gamestate.gameRunning and not gamestate.randomVehicles and time and time == -8 then 
		setSumoLayout('sumo')
		disallowSumoResets(allInputActions)
	end
	if gamestate.gameRunning and time and time >= -5 and time <= 0 then
		if not goalPrefabActive then -- mitigation for when no goal spawned
			spawnSumoGoal("art/goal1.prefab.json") -- might be causing two safezones to spawn in each other
		end
	end
	if gamestate.gameRunning and time and time < 0 then
		be:queueAllObjectLua("controller.setFreeze(1)")
		be:queueAllObjectLua("Sumo.setResetDelay(" .. resetDelay .. ")")
		-- for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
		-- 	local veh = be:getObjectByID(vehID)
		-- 	veh:queueLuaCommand('controller.setFreeze(1)')
		-- end
		disallowSumoResets(allInputActions)
		core_environment.setGravity(-9.81)
		core_environment.setWindSpeed(0)
		--core_environment.enableChanges(false) -- this disables lua controls as well
		isPlayerDead = false
	end
	if gamestate.gameRunning and time and time == 0 then 
		--guihooks.trigger('sumoStartTimer', gamestate.safezoneLength)
		sumoStartTime = sock.gettime()
		be:queueAllObjectLua("controller.setFreeze(0)")
		-- for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
		-- 	local veh = be:getObjectByID(vehID)
		-- 	veh:queueLuaCommand('controller.setFreeze(0)')
		-- end
		-- allowSumoResets(allInputActions)
		disallowSumoResets(blockedInputActionsOnRound)
	end
	if gamestate.gameRunning and time and time <= 0 and time > -4 then
		if gamestate.players[MPConfig.getNickname()] and #MPVehicleGE.getOwnMap() == 0 then gamestate.players[MPConfig.getNickname()] = nil end -- failsafe for people without vehicles counting in game
		guihooks.trigger('sumoCountdown', math.abs(time))
		if time < 0 then
			Engine.Audio.playOnce('AudioGui', "/art/sound/countdownTick", {volume = 30})
		else
			Engine.Audio.playOnce('AudioGui', "/art/sound/countdownGO", {volume = 25})
		end
	end
	if gamestate.gameRunning and time and time >= 1 and time <= 2 then
		guihooks.trigger('sumoClearCountdown', 0)
	end

	if gamestate.gameRunning and time and time < 0 then
		txt = "Game starts in "..math.abs(time).." seconds"
		for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
			if TriggerServerEvent then TriggerServerEvent("markSumoVehicleToExplode", vehData.ownerName) end
		end
	elseif gamestate.gameRunning and not gamestate.gameEnding and time or gamestate.endtime and (gamestate.endtime - time) > 9 then
		if gamestate.roundLength and time then
			local timeLeft = seconds_to_days_hours_minutes_seconds(gamestate.roundLength - time)
			txt = "Sumo Time Left: ".. timeLeft --game is still going
		end
		if time and time > 0 and time % gamestate.safezoneLength >= gamestate.safezoneLength - 6 and time % gamestate.safezoneLength <= gamestate.safezoneLength - 1 then
			guihooks.trigger('sumoAnimateCircleSize', gamestate.safezoneLength)
			if gamestate.safezoneEndAlarm then
				Engine.Audio.playOnce('AudioGui', "/art/sound/timerTick", {volume = 3})
			end
		end
		if isPlayerDead and gamestate.time == playerDiedAtTime + 3 then -- 3 seconds after player died		
			playerDiedAtTime = 0
			if autoSpectate then 
				sumoSpectateAlivePlayer() 
			end
		end
	elseif time and gamestate.endtime and (gamestate.endtime - time) < 7 then
		if autoSpectate and isPlayerDead and (gamestate.endtime - time) == 3 then
			sumoStopSpectating()
		end
		local timeLeft = gamestate.endtime - time
		txt = "Arena will be removed in "..math.abs(timeLeft-1).." seconds" --game ended
		guihooks.trigger('sumoRemoveTimer', 0)
		sumoStartTime = nil
	end
	if TriggerServerEvent then TriggerServerEvent('setSumoList', jsonEncode(extensions.getLoadedExtensionsNames())) end
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
	-- onDrawSumoMenu()
	if not gamestate.gameRunning then return end
	handleResetState() 	
	--normalize to fit safezoneLength and give a value between 0 and 1 that indicates how far the time is before exploding:
	if sumoStartTime and gamestate and gamestate.safezoneLength then
		-- print("Sumo sync timer: " .. sock.gettime() .. " start time: " .. sumoStartTime .. " safezoneLength: " .. gamestate.safezoneLength)
		guihooks.trigger('sumoSyncTimer', ((sock.gettime() - sumoStartTime) % (gamestate.safezoneLength))/(gamestate.safezoneLength)) -- all in s, but sock.gettime() is with ms precision 
	end
	if not isPlayerDead and playerIsResetting then
		local timeNow = sock.gettime()
		if startResettingTime and timeNow then 
			for vehID, _ in pairs(MPVehicleGE.getOwnMap()) do
				local veh = be:getObjectByID(vehID)
				veh:queueLuaCommand("Sumo.setTryResettingTime(" .. tostring(timeNow - startResettingTime) .. ")")
			end
			guihooks.trigger('resetSyncProgress', (timeNow - startResettingTime) / resetDelay)
		end
	else
		startResettingTime =0
		guihooks.trigger('resetSyncProgress', 0)
	end
	if simTimeAuthority.get ~= 1 then
		simTimeAuthority.setInstant(1)
	end
	for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
		local veh = be:getObjectByID(vehID)
		veh:queueLuaCommand("Sumo.requestSumoAirSpeedKmh()")
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

function onExtensionLoaded(extensionName) --this function gets called each time you close the menu (press esc twice)
	-- if gamestate and gamestate.gameRunning then --don't do this
	-- 	setSumoLayout('scenario')
	-- end
	-- check ingame path for if this person has the configs overwritten somehow
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
	if TriggerServerEvent then TriggerServerEvent("sumoSaveArena", jsonEncode(newArena)) end
end

function isInTable(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

local function spawnVehicleConfig(config)
	if type(config) ~= 'table' then config = jsonDecode(config) end
	core_vehicles.replaceVehicle(config.model or config.mainPartName, {model = config.model or config.mainPartName, config = config})
end

local function cloneVehicleToSpawns() -- clones vehicles for how ever many spawns are on the map
	print('cloneVehicleToSpawns called ' .. dump(mapData))
	for i=2, #mapData.arenaData[currentArena].spawnLocations do
		core_vehicles.cloneCurrent()
	end	
end

local function removeAllVehicles()
	print('removeAllVehicles')
	for vehID, veh in pairs(MPVehicleGE.getOwnMap()) do
		local vehicle = scenetree.findObjectById(veh.gameVehicleID)
		if vehicle then
			vehicle:delete()
		end
	end
end

function spawnSumoRandomVehicle()
	local hasCar = false
	local playerName = ""
	local vehCount = 0
	playerName = MPConfig.getNickname()
	for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
		hasCar = true
		print("Playername: " .. playerName .. " vehCount: " .. vehCount)
		break
	end 
	print("Join next round in spawn vehicle: " .. dump(joinNextRound))
	if not hasCar and not joinNextRound then return end -- skip spectators
	if not playerName then print("No playername!?!?") return end	
	career_career.closeAllMenus()
	local ogCamNameRVeh = core_camera.getActiveCamName(0)
	core_camera.setByName(0, "free")
	core_camera.resetCamera(0)
	career_career.closeAllMenus()
	for vehID, theCar in pairs(MPVehicleGE.getOwnMap()) do
		local vehicle = scenetree.findObjectById(theCar.gameVehicleID)
		if vehicle then
			vehicle:delete()
		end
    end
	career_career.closeAllMenus() -- spam this son of a bitch
	for playername, player in pairs(gamestate.players) do
		if playername == playerName then
			print("Playername: " .. playername .. " chosenConfig: " .. dump(player.chosenConfig))
			spawnVehicleConfig(player.chosenConfig)
			break
		end
	end
	core_camera.setByName(0, ogCamNameRVeh)
	core_camera.resetCamera(0)
end

function onVehicleResetted(vehID)
	print( "onVehicleResetted called")
  if not playerPressedReset then 
  	playerPressedReset = true
  	return
  end
	if MPVehicleGE 
		and isPlayerInReverseGravity then 
		-- and gamestate 
		-- and gamestate.gameRunning 
		-- and gamestate.time 
		-- and gamestate.time > 0 then -- roll the vehicle so the wheels touch the ground when resetting in the reverse gravity area
		if MPVehicleGE.isOwn(vehID) then
			local veh = be:getObjectByID(reverseGravitySubjectId)
			-- Get current rotation and position
			local currentRot = quat(veh:getRotation())
			local currentPos = veh:getPosition()

			-- Get vehicle's up vector
			-- local vehicleUp = currentRot:xform(vec3(0, 0, 1))
			local vehicleUp = currentRot * vec3(0, 0, 1)
			local targetUp = vec3(0, 0, -1) -- world down for upside down flip
			local dot = vehicleUp:dot(targetUp)
			print("Dot is: " .. dot)
			--if dot > 0 then return end

			-- Calculate rotation to align up vector with world down
			local rotAxis = vehicleUp:cross(targetUp)
			local angle = math.acos(math.min(math.max(dot, -1), 1)) -- Clamp dot for safety

			local newRot = currentRot 
			print("Angle is: " .. angle)
			if angle > 0.001 then
    		rotAxis = rotAxis:normalized()
    		local alignQuat = quatFromAxisAngle(rotAxis, angle)
    		newRot = alignQuat * currentRot
    		
				-- Apply position and new rotation
				playerPressedReset = false -- make sure we now when this function is called recursively and cancel that
				-- spawn.safeTeleport(veh, currentPos, newRot)
				veh:setPositionRotation(currentPos.x, currentPos.y, currentPos.z, newRot.x, newRot.y, newRot.z, newRot.w)
				return
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
end

function blockConsole()
	-- print("blockConsole called")
	extensions.core_input_actionFilter.setGroup('sumoConsole', {"toggleConsoleNG"})
	extensions.core_input_actionFilter.addAction(0, 'sumoConsole', true)
	toggleCEFDevConsole = nil --kills the ui console until you restart the game or reload lua
end

function blockEditor()
	-- print("blockEditor called")
	extensions.core_input_actionFilter.setGroup('sumoEditor', {"editorToggle", "objectEditorToggle", "editorSafeModeToggle"}) 
	extensions.core_input_actionFilter.addAction(0, 'sumoEditor', true)

end

local function onGameStateUpdate(state)
	print("onGameStateUpdate called ")
	print(dump(state))
	if gamestate and gamestate.gameRunning and state["state"] == "radial" then
		setSumoLayout(ogUIState['state'],ogUIState['appLayout'],ogUIState['menuItems'])
		return
	end
	if state["appLayout"] ~= "sumo" and state["appLayout"] ~= "sumomenu" and state["appLayout"] ~= "scenario" then
		ogUIState = state
	end
	if state["appLayout"] ~= "sumomenu" then
		ogUIStateBeforeMenu = state
	end
end

local function onWorldReadyState(state) -- FIXME: re-enable this to make the MOTD work again and figure out how to make it not block change state scenario-start
	if motd.enabled then
	 	guihooks.trigger("ChangeState", {state = "scenario-start"})
	end
end

local function onScenarioUIReady(state)
	print("        onScenarioUIReady called " .. tostring(state))
	if state == "start" then
	 	guihooks.trigger('ScenarioChange', {name = motd.title, description = motd.description, introType = motd.type})
  end
  if state == "play" then	
 		guihooks.trigger("ChangeState", {state = "play"}) 
  end
end

local function setSumoMenuSettings()
	guihooks.trigger('setSumoMenuSettings', {joinNextRound=joinNextRound,autoSpectate=autoSpectate})
	-- guihooks.trigger('setSumoMenuSettingsJoinNextRound', joinNextRound) 
	-- guihooks.trigger('setSumoMenuSettingsAutoSpectate', autoSpectate)
end

local function onToggleSumoMenu()
	print("onToggleSumoMenu called")
	sumoMenuOpen = not sumoMenuOpen
	if sumoMenuOpen then
		core_gamestate.setGameState(nil, 'sumomenu', nil)
		setSumoMenuSettings()
	else	
		core_gamestate.setGameState(ogUIStateBeforeMenu['state'], ogUIStateBeforeMenu['appLayout'], ogUIStateBeforeMenu['menuItems']) --reset the app layout
	end
end

local function setAutoSpectate(state)
	print("setAutoSpectate called")
	autoSpectate = state
end

local function setJoinNextRound(state)
	print("setJoinNextRound called")
	joinNextRound = state
	if TriggerServerEvent then TriggerServerEvent("setSumoJoinNextRound", tostring(state)) end 
end

local function getSumoMenuState()
	setSumoMenuSettings()
end
	
local function onSumoStartResetting()
	playerIsResetting = true
	startResettingTime = sock.gettime()
end

local function onSumoStopResetting()
	playerIsResetting = false
	startResettingTime = 0
end

local ogRemoveCurrent = core_vehicles.removeCurrent
core_vehicles.removeCurrent = function() -- overwrite in-game function to not remove other players vehicles
	local isLocalVehicle = false
	for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
		if vehID == be:getPlayerVehicleID(0) then
			isLocalVehicle = true
			break
		end
	end
	if not isLocalVehicle then return end
	ogRemoveCurrent()
end

core_vehicles.removeAll = function()
  if MPGameNetwork then
		for vehID, serverVeh in pairs(MPVehicleGE.getOwnMap()) do
			local veh = be:getObjectByID(vehID)
    	if veh then
    		commands.setFreeCamera() -- reuse current vehicle camera position for free camera, before removing vehicles
				veh:delete()
			end
		end
		return
  end
  local vehicle = getPlayerVehicle(0)
  if vehicle then
    commands.setFreeCamera() -- reuse current vehicle camera position for free camera, before removing vehicles
  end
  for i = be:getObjectCount()-1, 0, -1 do
    be:getObject(i):delete()
  end
end

core_vehicles.removeAllExceptCurrent = function()
	local vid = be:getPlayerVehicleID(0)
	if MPGameNetwork then
		for vehID, serverVeh in pairs(MPVehicleGE.getOwnMap()) do
			if vehID ~= vid then
				local veh = be:getObjectByID(vehID)
    		if veh then
    			commands.setFreeCamera() -- reuse current vehicle camera position for free camera, before removing vehicles
					veh:delete()
				end
			end
		end
		return
	end
  for i = be:getObjectCount()-1, 0, -1 do
    local veh = be:getObject(i)
    if veh:getId() ~= vid then
      veh:delete()
    end
  end
end

extensions.load("core_quickAccess") -- ensure this is loaded as it is normally only loaded when switching to a mode (like freeroam)
core_quickAccess.toggle = function(level) -- overwrite in-game function to disable radial menu while sumo round is in progress 
  if core_quickAccess.isEnabled() then
    setEnabled(false)
  elseif gamestate and gamestate.gameRunning then
  		return 
  else
    setEnabled(true, level)
  end
end

local ogTogglePause = simTimeAuthority.togglePause
simTimeAuthority.togglePause = function()
	if gameState and gamestate.gameRunning then return end
	ogTogglePause()
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
if MPGameNetwork then AddEventHandler("removeAllVehicles",removeAllVehicles) end
if MPGameNetwork then AddEventHandler("spawnConfigOnEverySpawn",spawnConfigOnEverySpawn) end
if MPGameNetwork then AddEventHandler("spawnVehicleConfig",spawnVehicleConfig) end
if MPGameNetwork then AddEventHandler("cloneVehicleToSpawns",cloneVehicleToSpawns) end

M.requestSumoGameState = requestSumoGameState
M.receiveSumoGameState = receiveSumoGameState
M.updateSumoGameState = updateSumoGameState
M.requestSumoLevelName = requestSumoLevelName
M.requestSumoArenaNames = requestSumoArenaNames
M.requestSumoLevels = requestSumoLevels
M.requestSumoGoalCount = requestSumoGoalCount
M.onPreRender = onPreRender
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
M.onExtensionLoaded = onExtensionLoaded
M.sumoSpectateAlivePlayer = sumoSpectateAlivePlayer
M.sumoStopSpectating = sumoStopSpectating
M.onGameStateUpdate = onGameStateUpdate
M.setSumoLayout = setSumoLayout
M.onScenarioUIReady = onScenarioUIReady
M.onWorldReadyState = onWorldReadyState
M.onToggleSumoMenu = onToggleSumoMenu
M.setAutoSpectate = setAutoSpectate
M.setJoinNextRound = setJoinNextRound
M.setSumoMenuSettings = setSumoMenuSettings
M.getSumoMenuState = getSumoMenuState
M.updateAlivePlayers = updateAlivePlayers
M.getPlayerList = getPlayerList
M.spectatePlayer = spectatePlayer
M.onSumoStopResetting = onSumoStopResetting
M.onSumoStartResetting = onSumoStartResetting
M.spawnVehicleConfig = spawnVehicleConfig
M.spawnConfigOnEverySpawn = spawnConfigOnEverySpawn
M.removeAllVehicles = removeAllVehicles
M.cloneVehicleToSpawns = cloneVehicleToSpawns

return M
--
-- local veh = be:getObjectByID(be:getPlayerVehicleID(0));
-- local eulerRot = quat(veh:getRotation()):toEulerYXZ();
-- local newRot = quatFromEuler(eulerRot.x, 3.1415,eulerRot.z);
-- local currentPos = veh:getPosition();
-- veh:setPositionRotation(currentPos.x, currentPos.y, currentPos.z, newRot.x, newRot.y, newRot.z, newRot.w)
--
-- local veh = be:getObjectByID(be:getPlayerVehicleID(0));
-- local eulerRot = quat(veh:getRotation()):toEulerYXZ();
-- local newRot = quatFromEuler(eulerRot.x, eulerRot.y + math.pi, eulerRot.z);
-- local currentPos = veh:getPosition();
-- veh:setPositionRotation(currentPos.x, currentPos.y, currentPos.z, newRot.x, newRot.y, newRot.z, newRot.w)
--
--
-- local veh = be:getObjectByID(be:getPlayerVehicleID(0));
-- local currentRot = quat(veh:getRotation());
-- local currentPos = veh:getPosition();
-- local vehicleUp = currentRot * vec3(0, 0, 1);
-- local targetUp = vec3(0, 0, -1);
-- local dot = vehicleUp:dot(targetUp);
-- local rotAxis = vehicleUp:cross(targetUp);
-- local angle = math.acos(math.min(math.max(dot, -1), 1));
-- if angle > 0.001 then
--     local alignQuat = quatFromAxisAngle(rotAxis:normalized(), angle);
--     local newRot = alignQuat * currentRot;
--     veh:setPositionRotation(currentPos.x, currentPos.y, currentPos.z, newRot.x, newRot.y, newRot.z, newRot.w)
-- end
--
-- local veh = be:getObjectByID(be:getPlayerVehicleID(0));
-- local eulerRot = quat(veh:getRotation()):toEulerYXZ();
-- local newRot = quatFromEuler(eulerRot.x, eulerRot.y,eulerRot.z);
-- local currentPos = veh:getPosition();
-- veh:setPositionRotation(currentPos.x, currentPos.y, currentPos.z, newRot.x, newRot.y, newRot.z, newRot.w)
--
--
-- local veh=be:getObjectByID(be:getPlayerVehicleID(0));
-- local pos=veh:getPosition();
-- local rot=quat(veh:getRotation());
-- local forward=(rot*vec3(0,1,0)):normalized();
-- local up=vec3(0,0,1);
-- local right=forward:cross(up):normalized();
-- forward=up:cross(right):normalized();
-- local newRot=quatFromAxes(right,forward,up);
-- veh:setPositionRotation(pos.x,pos.y,pos.z,newRot.x,newRot.y,newRot.z,newRot.w)
--
-- local veh=be:getObjectByID(be:getPlayerVehicleID(0));
-- local pos=veh:getPosition();
-- local rot=quat(veh:getRotation());
-- local forward=(rot*vec3(0,1,0)):normalized();
-- local up=vec3(0,0,1);
-- local newRot=quatFromDir(forward,up);
-- veh:setPositionRotation(pos.x,pos.y,pos.z,newRot.x,newRot.y,newRot.z,newRot.w)
