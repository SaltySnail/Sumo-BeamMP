--Sumo by Julianstap, 2023

local M = {}

local floor = math.floor
local mod = math.fmod
local rand = math.random

local gameState = {players = {}}
local players = {}
local laststate = gameState
-- local levelName = ""
local arena = ""
local arenaNames = {}
-- local levels = {}
local requestedArena = ""
local goalPrefabCount = 1
local timeSinceLastContact = 0
local teamSize = 1
local possibleTeams = {"Red", "LightBlue", "Green", "Yellow", "Purple"}
local chosenTeams = {}
local vehiclesToExplode = {}
local goalID = -1

gameState.gameRunning = false
gameState.gameEnding = false
gameState.goalCount = 1
gameState.goalScale = 1
gameState.safezoneEndAlarm = true
-- gameState.goalScaleResize = 0

local roundLength = 5*60 -- length of the game in seconds
local goalTime = 30
local goalEndTime = -10000
local defaultRedFadeDistance = 100 -- the distance between a flag carrier and someone that doesn't have the flag, where the screen of the flag carrier will turn red
local defaultColorPulse = true -- if the car color should pulse between the car color and blue
local defaultFlagTint = true -- if the infecor should have a blue tint
local defaultDistancecolor = 0.3 -- max intensity of the red filter
local teams = false
local alivePlayers = {}
local MAX_ALIVE = 1 --for debugging use 0, else use 1
local randomVehicles = false
local autoStart = false
local commandsAllowed = true
local safezoneEndAlarm = true
local scoringSystem = true
local autoStartTimer = 0
local SUMO_SERVER_DATA_PATH = "Resources/Server/Sumo/Data/" --this is the path from beammp-server.exe (change this if it is in a different path)

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

--called whenever the extension is loaded
function onInit()
    MP.RegisterEvent("requestSumoGameState","requestSumoGameState")
    MP.RegisterEvent("sumo","sumo")
    MP.RegisterEvent("SUMO","SUMO")
    MP.TriggerClientEventJson(-1, "receiveSumoGameState", gameState)
	
	MP.CancelEventTimer("counter")
	MP.CancelEventTimer("sumoSecond")
	MP.CreateEventTimer("sumoSecond",1000)
	MP.RegisterEvent("sumoSecond", "sumoTimer")

	MP.RegisterEvent("onSumoContact", "onSumoContact")
	MP.RegisterEvent("onChatMessage", "onChatMessage")
	-- MP.RegisterEvent("setSumoLevelName", "setSumoLevelName")
	MP.RegisterEvent("onSumoGoal", "onSumoGoal")
	MP.RegisterEvent("setSumoArenaNames", "setSumoArenaNames")
	-- MP.RegisterEvent("setSumoLevels", "setSumoLevels")
	MP.RegisterEvent("setSumoGoalCount", "setSumoGoalCount")
	MP.RegisterEvent("markSumoVehicleToExplode", "markSumoVehicleToExplode")
	MP.RegisterEvent("unmarkSumoVehicleToExplode", "unmarkSumoVehicleToExplode")
	MP.RegisterEvent("onSumoPlayerExplode", "onSumoPlayerExplode")
	MP.RegisterEvent("onPlayerFirstAuth", "onPlayerFirstAuth")
	MP.RegisterEvent("onPlayerAuth", "onPlayerAuth")
	MP.RegisterEvent("onPlayerJoining", "onPlayerJoining")
	MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
	MP.RegisterEvent("onPlayerDisconnect", "onPlayerDisconnect")
	MP.RegisterEvent("onVehicleSpawn", "onVehicleSpawn")
	MP.RegisterEvent("onVehicleEdited", "onVehicleEdited")
	MP.RegisterEvent("onVehicleEdited", "onVehicleEdited")
	MP.RegisterEvent("onVehicleReset", "onVehicleReset")
	MP.RegisterEvent("onVehicleDeleted", "onVehicleDeleted")
	MP.RegisterEvent("onRconCommand", "onRconCommand")
	MP.RegisterEvent("onNewRconClient", "onNewRconClient")
	MP.RegisterEvent("onStopServer", "onStopServer")
	MP.RegisterEvent("sumoSaveArena", "sumoSaveArena")

	print("--------------Sumo Loaded------------------")
	loadSettings()
end

function seconds_to_days_hours_minutes_seconds(total_seconds) --modified code from https://stackoverflow.com/questions/45364628/lua-4-script-to-convert-seconds-elapsed-to-days-hours-minutes-seconds
    local time_days     = floor(total_seconds / 86400)
    local time_hours    = floor(mod(total_seconds, 86400) / 3600)
    local time_minutes  = floor(mod(total_seconds, 3600) / 60)
    local time_seconds  = floor(mod(total_seconds, 60))

	if time_days == 0 then
		time_days = nil
	end
    if time_hours == 0 then
        time_hours = nil
    end
	if time_minutes == 0 then
		time_minutes = nil
	end
	if time_seconds == 0 then
		time_seconds = nil
	end
    return time_days ,time_hours , time_minutes , time_seconds
end

function sumoGameStarting()
	local days, hours , minutes , seconds = seconds_to_days_hours_minutes_seconds(roundLength)
	local amount = 0
	if days then
		amount = amount + 1
	end
	if hours then
		amount = amount + 1
	end
	if minutes then
		amount = amount + 1
	end
	if seconds then
		amount = amount + 1
	end
	if days then
		amount = amount - 1
		if days == 1 then
			if amount > 1 then
				days = ""..days.." day, "
			elseif amount == 1 then
				days = ""..days.." day and "
			elseif amount == 0 then
				days = ""..days.." day "
			end
		else
			if amount > 1 then
				days = ""..days.." days, "
			elseif amount == 1 then
				days = ""..days.." days and "
			elseif amount == 0 then
				days = ""..days.." days "
			end
		end
	end
	if hours then
		amount = amount - 1
		if hours == 1 then
			if amount > 1 then
				hours = ""..hours.." hour, "
			elseif amount == 1 then
				hours = ""..hours.." hour and "
			elseif amount == 0 then
				hours = ""..hours.." hour "
			end
		else
			if amount > 1 then
				hours = ""..hours.." hours, "
			elseif amount == 1 then
				hours = ""..hours.." hours and "
			elseif amount == 0 then
				hours = ""..hours.." hours "
			end
		end
	end
	if minutes then
		amount = amount - 1
		if minutes == 1 then
			if amount > 1 then
				minutes = ""..minutes.." minute, "
			elseif amount == 1 then
				minutes = ""..minutes.." minute and "
			elseif amount == 0 then
				minutes = ""..minutes.." minute "
			end
		else
			if amount > 1 then
				minutes = ""..minutes.." minutes, "
			elseif amount == 1 then
				minutes = ""..minutes.." minutes and "
			elseif amount == 0 then
				minutes = ""..minutes.." minutes "
			end
		end
	end
	if seconds then
		if seconds == 1 then
			seconds = ""..seconds.." second "
		else
			seconds = ""..seconds.." seconds "
		end
	end

	goalEndTime = goalTime
	MP.SendChatMessage(-1,"Sumo game started, you have to survive for "..(days or "")..""..(hours or "")..""..(minutes or "")..""..(seconds or "").."")
end

function compareTable(gameState,tempTable,laststate)
	for variableName,variable in pairs(gameState) do
		if type(variable) == "table" then
			if not laststate[variableName] then
				laststate[variableName] = {}
			end
			if not tempTable[variableName] then
				tempTable[variableName] = {}
			end
			compareTable(gameState[variableName],tempTable[variableName],laststate[variableName])
			if type(tempTable[variableName]) == "table" and next(tempTable[variableName]) == nil then
				tempTable[variableName] = nil
			end
		elseif variable == "remove" then
			tempTable[variableName] = gameState[variableName]
			laststate[variableName] = nil
			gameState[variableName] = nil
		elseif laststate[variableName] ~= variable then
			tempTable[variableName] = gameState[variableName]
			laststate[variableName] = gameState[variableName]
		end
	end
end

function updateSumoClients()
	local tempTable = {}
	compareTable(gameState,tempTable,laststate)
	-- print("updateSumoClients: " .. dump(tempTable))

	if tempTable and next(tempTable) ~= nil then
		MP.TriggerClientEventJson(-1, "updateSumoGameState", tempTable)
	end
end

function spawnSumoGoal()
	-- gameState.goalScale = (gameState.goalScale or 1) - gameState.goalScaleResize
	gameState.goalScale = gameState.goalScale * 0.7
	rand() --Some implementation need this before the numbers become random
	rand()
	rand()
	local newGoalID = rand(1,goalPrefabCount)
	while (newGoalID == goalID) do
		newGoalID = rand(1,goalPrefabCount)
	end
	goalID = newGoalID
	print("Chosen goal: art/goal" .. goalID .. ".prefab.json")
	MP.TriggerClientEvent(-1, "spawnSumoGoal", "art/goal" .. goalID .. ".prefab.json") --flagPrefabTable[rand(1, flagPrefabTable.size())]
end

function onSumoArenaChange()	
	local foundArena = false
	for key,arenaName in pairs(arenaNames) do
		if arenaName == requestedArena then
			arena = arenaName
			foundArena = true
		else
			print("Arena: " .. arenaName .. " doesn\'t match requested arena: " .. requestedArena)
		end
	end
	if arena == "" or not foundArena then
		if arenaNames[1] then
			arena = arenaNames[1]
			print("The requested arena for the sumo gamemode was not on this map, so it will default to the arena " .. arena)
		else
			MP.SendChatMessage(-1, "Could not find an arena to play on")
			if arenaNames == {} then MP.TriggerClientEvent(-1, "requestSumoArenaNames", "nil") end
		end
	end
	MP.TriggerClientEvent(-1, "setSumoCurrentArena", arena)
	MP.TriggerClientEvent(-1, "requestSumoGoalCount", "nil")
end

function sumoTeamAlreadyChosen(team)
    if not team then return false end
    if not chosenTeams then return false end
    if not chosenTeams[team] then return false end
    return chosenTeams[team].chosen
end

function sumoGameSetup()
	math.randomseed(os.time())
	onSumoArenaChange()
	if teams then
		for k,v in pairs(possibleTeams) do
			chosenTeams[v] = {}
			chosenTeams[v].chosen = false
			-- chosenTeams[v].score = 0  
		end
	end
	gameState = {}
	gameState.players = players
	gameState.settings = {
		redFadeDistance = defaultRedFadeDistance,
		ColorPulse = defaultColorPulse,
		flagTint = defaultFlagTint,
		distancecolor = defaultDistancecolor
		}
	local playerCount = 0
	for ID,Player in pairs(MP.GetPlayers()) do
		if MP.IsPlayerConnected(ID) and MP.GetPlayerVehicles(ID) then
			playerCount = playerCount + 1
		end
	end
	if playerCount % 2 == 0 then
		teamSize = playerCount / 2
	elseif playerCount % 3 == 0 then
		teamSize = playerCount / 3
	else
		teamSize = 1
	end
	local chosenTeam = possibleTeams[rand(1,#possibleTeams)]
	local teamCount = 0
	for ID,Name in pairs(MP.GetPlayers()) do
		if teams then
			if teamCount == teamSize then
				chosenTeam = possibleTeams[rand(1,#possibleTeams)]
				while sumoTeamAlreadyChosen(chosenTeam) do --possibility for endless loop, maybe need some better way for this
					chosenTeam = possibleTeams[rand(1,#possibleTeams)]
				end
				chosenTeams[chosenTeam].chosen = true
			end
			teamCount = 0
		end
		if MP.IsPlayerConnected(ID) and MP.GetPlayerVehicles(ID) then
			local player = {}
			if not gameState.players[Name] then gameState.players[Name] = {} end
			gameState.players[Name].ID = ID
			gameState.players[Name].team = chosenTeam
			gameState.players[Name].dead = false
			teamCount = teamCount + 1
		end
	end

	if playerCount == 0 then
		MP.SendChatMessage(-1,"Failed to start, found no vehicles")
		return
	end

	gameState.playerCount = playerCount
	gameState.randomVehicles = randomVehicles
	if randomVehicles then
		gameState.time = -29
	else
		gameState.time = -9
	end
	gameState.roundLength = roundLength
	gameState.endtime = -1
	gameState.gameRunning = true
	gameState.gameEnding = false
	gameState.gameEnded = false
	gameState.teams = teams
	gameState.goalCount = 1
	gameState.goalScale = 1
	gameState.safezoneEndAlarm = safezoneEndAlarm

	spawnSumoGoal()
	-- MP.TriggerClientEvent(-1, "spawnSumoObstacles", "art/" .. levelName .. "/multiplayer/" .. arena .. "/obstacles.prefab.json")
	MP.TriggerClientEvent(-1, "spawnSumoObstacles", "art/" .. arena .. "/obstacles.prefab.json")
	MP.TriggerClientEvent(-1, "teleportToSumoArena", "nil")
	updateSumoClients()

	MP.TriggerClientEventJson(-1, "receiveSumoGameState", gameState)
end

function sumoGameEnd(reason)
	-- print("Sumo round ending...")
	gameState.gameEnding = true
	gameState.goalScale = 1
	if reason == nil or reason == "nil" then
		MP.SendChatMessage(-1,"Game stopped for uknown reason")
	else
		if reason == "time" then
			if #alivePlayers > 0 then
				MP.SendChatMessage(-1,"Game over the time limit was reached, the winners are: ")
				for i=1,#alivePlayers do
					MP.SendChatMessage(-1, alivePlayers[i])
					if scoringSystem then
						if gameState.players[alivePlayers[i]].score then
							gameState.players[alivePlayers[i]].score = gameState.players[alivePlayers[i]].score + 1
						else
							gameState.players[alivePlayers[i]].score = 1
						end
					end
				end
			else
				MP.SendChatMessage(-1,"Game over, time limit was reached")
			end
		elseif reason == "manual" then
			MP.SendChatMessage(-1,"Game stopped, Everyone Looses")
			gameState.endtime = gameState.time + 10
		elseif reason == "score" then
			MP.SendChatMessage(-1,"Game over, score limit was reached")
			gameState.endtime = gameState.time + 10
		elseif reason == "last alive" then
			if #alivePlayers > 0 then
				MP.SendChatMessage(-1,"Game over, " .. alivePlayers[1] .. " wins!") --FIXME: if MAX_ALIVE is more than 1 this is fucked, don't think you should set it to more though
				if scoringSystem then
					if gameState.players[alivePlayers[1]].score then
						gameState.players[alivePlayers[1]].score = gameState.players[alivePlayers[1]].score + 1
					else
						gameState.players[alivePlayers[1]].score = 1
					end
				end
			else
				MP.SendChatMessage(-1,"Game over, everyone died!")
			end
			gameState.endtime = gameState.time + 10
		end
	end

	if scoringSystem then
		local hasAnyoneScored = false
		for playername, player in pairs(gameState.players) do
			if player.score then hasAnyoneScored = true end
		end
		if hasAnyoneScored then
			MP.SendChatMessage(-1,"The scores this round are: ")
			for playername, player in pairs(gameState.players) do
				MP.SendChatMessage(-1, playername .. " : " .. player.score or 0)
			end
		end
	end
end

function showSumoPrefabs(player) --shows the prefabs belonging to this map and this arena
	MP.TriggerClientEvent(player.playerID, "spawnSumoObstacles", "art/" .. arena .. "/obstacles.prefab.json")
	for goalID=1,goalPrefabCount do
		MP.TriggerClientEvent(player.playerID, "spawnSumoGoal", "art/goal" .. goalID .. ".prefab.json")
	end
end

function sumo(player, argument)
	if argument == "help" then
		MP.SendChatMessage(player.playerID, "Anything between double qoutes; \"\" is a command. \n Anything between single quotes; \'\' is an argument, \n if there is a slash it means those are the argument options for that command.")
		MP.SendChatMessage(player.playerID, "\"/sumo start\" to start a sumo game.")
		MP.SendChatMessage(player.playerID, "\"/sumo stop\" to stop a sumo game.")
		MP.SendChatMessage(player.playerID, "\"/sumo arena \'chosenArena\' \" to choose an arena to play sumo on.")
		MP.SendChatMessage(player.playerID, "\"/sumo list \'arenas\' \" to list the possible arenas to play sumo on.")
		MP.SendChatMessage(player.playerID, "\"/sumo show\" to show all goals and obstacles in the current arena.")
		MP.SendChatMessage(player.playerID, "\"/sumo hide\" to hide all goals and obstacles in the current arena.")
		MP.SendChatMessage(player.playerID, "\"/sumo start \'minutes\' \" to start a sumo game with a duration of the specified minutes.")
		MP.SendChatMessage(player.playerID, "\"/sumo time limit \'minutes\' \" to set the duration of a sumo game to the specified minutes.")
		MP.SendChatMessage(player.playerID, "\"/sumo teams \'true/false\' \" to specify if the sumo games uses teams.")
		MP.SendChatMessage(player.playerID, "\"/sumo create \'goal\' \" to create a goal, so you can make your own arenas! \n Consult the tutorial on GitHub to learn how to do this.")
	elseif argument == "show" then
		onSumoArenaChange()
		showSumoPrefabs(player)
	elseif argument == "hide" then
		MP.TriggerClientEvent(player.playerID, "removeSumoPrefabs", "all")
	elseif argument == "start" or string.find(argument, "start %d") then
		local number = 5
		if string.find(argument, "start %d") then
			number = tonumber(string.sub(argument,7,10000))
			roundLength = number * 60
			print("Sumo game starting with duration: " .. number)
		end
		local playerCount = 0
		for ID,Player in pairs(MP.GetPlayers()) do
			if MP.IsPlayerConnected(ID) and MP.GetPlayerVehicles(ID) then
				playerCount = playerCount + 1
			end
		end
		if playerCount <= MAX_ALIVE then
			MP.SendChatMessage(player.playerID, "Can't start the game on your own.")
			return 1
		end
		if not gameState.gameRunning then
			sumoGameSetup()
			MP.SendChatMessage(-1, "Sumo started, GO GO GO!")
		else
			MP.SendChatMessage(-1, "A sumo game has already started.")
		end
	elseif string.find(argument, "time limit %d") then
		local number = tonumber(string.sub(argument,11,10000))
		roundLength = number * 60
		print("Sumo game time limit is now: " .. roundLength)
	elseif string.find(argument, "teams %S") then
		local teamsString = string.sub(argument,7,10000)
		if teamsString == "true" then
			teams = true
		elseif teamsString == "false" then
			teams = false
		end
		MP.SendChatMessage(-1, "Playing with teams: " .. dump(teams) .. " (available options are true or false)")
	elseif string.find(argument, "auto %S") then
		local autoString = string.sub(argument,6,10000)
		if autoString == "true" then
			autoStart = true
		elseif autoString == "false" then
			autoStart = false
		end
		MP.SendChatMessage(player.playerID, "Sumo auto mode : " .. autoString)
	elseif string.find(argument, "random vehicles %S") then
		local randomVehiclesString = string.sub(argument,17,10000)
		if randomVehiclesString == "true" then
			randomVehicles = true
		elseif randomVehiclesString == "false" then
			randomVehicles = false
		else
			MP.SendChatMessage(player.playerID, "I don't know " .. randomVehiclesString .. ", available options are true or false.")
		end
		MP.SendChatMessage(player.playerID, "Sumo random vehicles mode : " .. tostring(randomVehicles))
	elseif string.find(argument, "create %S") then
		local createString = string.sub(argument,8,10000) 
		if createString == "goal" then
			MP.TriggerClientEvent(player.playerID, "onSumoCreateGoal", "nil")
		elseif createString == "spawn" then
			MP.TriggerClientEvent(player.playerID, "onSumoCreateSpawn", "nil")
		end
	elseif string.find(argument, "save as %S") then
		local arenaName = string.sub(argument,9,10000)
		MP.TriggerClientEvent(player.playerID, "onSumoSaveArena", arenaName)
	elseif string.find(argument, "list %S") then
		local subArgument = string.sub(argument,6,10000)
		if subArgument == "arenas" then
			if arenaNames == {} then
				MP.SendChatMessage(player.playerID, "There are no arenas made for this map, a server restart might fix it or try a different map.")
			else
				MP.SendChatMessage(player.playerID, "Possible arenas to play on this map: " .. dump(arenaNames))
			end
		else
			MP.SendChatMessage(player.playerID, "I can't " .. argument .. ", try something else (like list arenas).")
		end
	elseif string.find(argument, "arena %S") then
		requestedArena = string.sub(argument,7,10000)
		onSumoArenaChange()
		MP.SendChatMessage(-1, "Requested arena: " .. requestedArena)
	elseif argument == "stop" then
		sumoGameEnd("manual")
		MP.SendChatMessage(-1, "Sumo stopping...")
	end
	return 1
end

function SUMO(player, argument) --alias for sumo
	sumo(player, argument)
end

function sumoGameRunningLoop()
	if gameState.time < 0 then
		MP.SendChatMessage(-1,"Sumo game starting in "..math.abs(gameState.time).." second")

	elseif gameState.time == 0 then
		sumoGameStarting()
	end

	if not gameState.gameEnding and gameState.playerCount == 0 then
		gameState.gameEnding = true
		gameState.endtime = gameState.time + 2
	end

	local players = gameState.players

	local aliveCount = 2 
	if gameState.gameRunning and not gameState.gameEnding and gameState.time > 0 then
		aliveCount = 0
		local playercount = 0
		alivePlayers = {}
		print(dump(players))
		for playername,player in pairs(players) do
			playercount = playercount + 1
			-- print(dump(player))
			if not player.dead then
				aliveCount = aliveCount + 1
				table.insert(alivePlayers, playername)
			end
		end
		gameState.playerCount = playercount
		if gameState.time >= 5 and aliveCount <= MAX_ALIVE then
			sumoGameEnd("last alive")
		end
	end
	if not gameState.gameEnding and gameState.time == gameState.roundLength then
		sumoGameEnd("time")
		gameState.endtime = gameState.time + 10
	elseif gameState.gameEnding and gameState.time == gameState.endtime then
		gameState = {}
		gameState.players = {}
		gameState.gameRunning = false
		gameState.gameEnding = false
		gameState.gameEnded = true
		MP.TriggerClientEvent(-1, "onSumoGameEnd", "nil")
		MP.TriggerClientEvent(-1, "removeSumoPrefabs", "all")
	end
	if gameState.gameRunning then
		if gameState.time == goalEndTime then
			for vehID, explode in pairs(vehiclesToExplode) do
				if explode then
					MP.TriggerClientEvent(-1, "explodeSumoCar", vehID)
					vehiclesToExplode[vehID] = false
				end
			end
			MP.TriggerClientEvent(-1, "removeSumoPrefabs", "goal")
			spawnSumoGoal()
			goalEndTime = gameState.time + goalTime
			print("It's time to blow some stuff up " .. dump(vehiclesToExplode))
		end
		timeSinceLastContact = timeSinceLastContact + 1
		gameState.time = gameState.time + 1
	end

	updateSumoClients()
end

function sumoTimer()
	if gameState.gameRunning then
		sumoGameRunningLoop()
		--force stopping the game when there are less players than MAX_ALIVE:
		local aliveCount = 2 
		if gameState.gameRunning and not gameState.gameEnding and gameState.time > 0 then
			aliveCount = 0
			for playername,player in pairs(gameState.players) do
				if not player.dead then
					aliveCount = aliveCount + 1
				end
			end
			if gameState.time >= 5 and aliveCount == MAX_ALIVE then
				sumoGameEnd("last alive")
			end
		end
	elseif autoStart and MP.GetPlayerCount() > MAX_ALIVE then
		local playerCount = 0
		for ID,Player in pairs(MP.GetPlayers()) do
			if MP.IsPlayerConnected(ID) and MP.GetPlayerVehicles(ID) then
				playerCount = playerCount + 1
			end
		end
		if playerCount <= MAX_ALIVE then return end
		autoStartTimer = autoStartTimer + 1
		MP.SendChatMessage(-1, "New round starts in: " .. 30 - autoStartTimer .. "s")
		if autoStartTimer >= 30 then
			autoStartTimer = 0
			selectRandomArena()
			sumoGameSetup()
		end
	end
end


function onUnload()

end

--called whenever a player is authenticated by the server for the first time.
function onPlayerFirstAuth(playerID)

end

--called whenever the player is authenticated by the server.
function onPlayerAuth(playerID)

end

--called when a player begins loading
function onPlayerJoining(player)

end

--called whenever a player has fully joined the session
function onPlayerJoin(playerID)
	-- MP.TriggerClientEvent(-1, "requestSumoLevelName", "nil") --TODO: fix this when changing levels somehow
	print("sumo: onPlayerJoin called")
	local file = io.open(SUMO_SERVER_DATA_PATH .. "arenas.json", "r")
	if not file then 
		print("arenas.json not found")
		return
	end
	local contents = file:read("*a")
	-- print(Util.JsonPrettify(contents))
	file:close()
	-- print("onPlayerJoin" .. playerID .. ": " .. Util.JsonPrettify(contents))
	MP.TriggerClientEvent(playerID, "setSumoArenasData", Util.JsonMinify(contents))
	if next(arenaNames) == nil then --fill arenaNames
		for name, value in pairs(Util.JsonDecode(contents)) do
			table.insert(arenaNames, name)
		end
	end
	if arena and gameState.gameRunning then
		MP.TriggerClientEvent(playerID, "spawnSumoObstacles", "art/" .. arena .. "/obstacles.prefab.json")
		MP.TriggerClientEvent(playerID, "spawnSumoGoal", "art/goal" .. goalID .. ".prefab.json")
	end
end

--called whenever a player disconnects from the server
function onPlayerDisconnect(playerID)
	gameState.players[MP.GetPlayerName(playerID)] = nil
end

--called whenever a player sends a chat message
function onChatMessage(playerID, playerName, chatMessage)
	if not commandsAllowed then return end
	local player = {}
	player.playerID = playerID
	-- print("onChatMessage( " .. dump(player) .. ", " .. chatMessage .. ")")
	if string.find(chatMessage, "/sumo ") then
		chatMessage = string.gsub(chatMessage, "/sumo ", "")
		sumo(player, chatMessage)
		return 1
	elseif string.find(chatMessage, "/SUMO ") then
		chatMessage = string.gsub(chatMessage, "/SUMO ", "")
		sumo(player, chatMessage)
		return 1
	end
end

--called whenever a player spawns a vehicle.
function onVehicleSpawn(playerID, vehID,  data)

end

--called whenever a player applies their vehicle edits.
function onVehicleEdited(playerID, vehID,  data)

end

--called whenever a player resets their vehicle, holding insert spams this function.
function onVehicleReset(playerID, vehID, data)

end

--called whenever a vehicle is deleted
function onVehicleDeleted(playerID, vehID,  source)

end

--whenever a message is sent to the Rcon
function onRconCommand(playerID, message, password, prefix)

end

--whenever a new client interacts with the RCON
function onNewRconClient(client)

end

--called when the server is stopped through the stopServer() function
function onStopServer()

end

function requestSumoGameState(localPlayerID)
	-- if levelName == "" then MP.TriggerClientEvent(-1, "requestSumoLevelName", "nil") end
	if arenaNames == {} then MP.TriggerClientEvent(-1, "requestSumoArenaNames", "nil") end
	-- if levels == {} then MP.TriggerClientEvent(-1, "requestSumoLevels", "nil") end
	if arena == "" then onSumoArenaChange() end
	MP.TriggerClientEventJson(localPlayerID, "receiveSumoGameState", gameState)
end

-- function onSumoGoal(playerID)
-- 	MP.TriggerClientEvent(-1, "removeSumoPrefabs", "goal")
-- 	MP.TriggerClientEvent(playerID, "onScore", "nil")
-- 	updateSumoClients()
-- 	MP.SendChatMessage(-1,"".. MP.GetPlayerName(playerID) .." Scored a point!")
-- 	spawnSumoGoal()
-- end

function setSumoArenaNames(playerID, data)
	arenaNames = {} 
	-- print("setSumoArenaNames " .. playerID .. " " ..  data)
	print("Available arenas: " .. data)
	for name in data:gmatch("%S+") do 
		table.insert(arenaNames, name)
	end
	onSumoArenaChange()
end

-- function setSumoLevels(playerID, data)
-- 	levels = {}
-- 	for name in data:gmatch("%S+") do 
-- 		table.insert(levels, name) 
-- 	end
-- end
function onSumoPlayerExplode(playerID, playerName)
	-- print(playerName .. "   " .. dump(gameState))
	gameState.players[playerName].dead = true
end

function setSumoGoalCount(playerID, data)
	goalPrefabCount = tonumber(data)
end

function markSumoVehicleToExplode(playerID, vehID)
	vehiclesToExplode["" .. vehID] = true
	-- print("Veh marked for exploding: " .. vehID)
end

function unmarkSumoVehicleToExplode(playerID, vehID)
	vehiclesToExplode["" .. vehID] = false
	-- print("Veh unmarked for exploding: " .. vehID)
end

function selectRandomArena()
	-- Check if the arenaNames table is not empty
	if next(arenaNames) ~= nil then
		-- math.random(#arenaNames) will generate a random index in the range of the arenaNames table
		requestedArena = arenaNames[math.random(#arenaNames)]
	end
	print("selectRandomArena: " .. requestedArena)
	onSumoArenaChange()
end

function loadSettings()
	local file = io.open(SUMO_SERVER_DATA_PATH .. "settings.json", "r") -- Open the file in read mode
    if file then
        local content = file:read("*all") -- Read the entire file content
        file:close()
        local data = Util.JsonDecode(content) -- Decode the JSON data
		if data then
			autoStart = data["autoStart"]
			commandsAllowed = data["chatCommands"]
			safezoneEndAlarm = data["safezoneEndAlarm"]
			randomVehicles = data["randomVehicles"]
		end
    else
        print("Cannot open file:", path)
    end
end

function sumoSaveArena(playerID, data)
	local file = io.open(SUMO_SERVER_DATA_PATH .. "arenas.json", "r")
	local jsonTable = Util.JsonDecode(file:read("*a"))
	file:close()
	data = Util.JsonDecode(data)
	local arenaName = data.name
	data.name = nil
	jsonTable[arenaName] = data
	file = io.open(SUMO_SERVER_DATA_PATH .. "arenas.json", "w")
	file:write(Util.JsonPrettify(Util.JsonEncode(jsonTable)))
	file:close()
end

M.onInit = onInit
M.onUnload = onUnload

M.onPlayerFirstAuth = onPlayerFirstAuth

M.onPlayerAuth = onPlayerAuth
-- M.onPlayerConnecting = onPlayerConnecting
M.onPlayerJoining = onPlayerJoining
M.onPlayerJoin = onPlayerJoin
M.onPlayerDisconnect = onPlayerDisconnect

M.onChatMessage = onChatMessage

M.onVehicleSpawn = onVehicleSpawn
M.onVehicleEdited = onVehicleEdited
M.onVehicleReset = onVehicleReset
M.onVehicleDeleted = onVehicleDeleted

M.onRconCommand = onRconCommand
M.onNewRconClient = onNewRconClient

M.onStopServer = onStopServer

M.requestSumoGameState = requestSumoGameState

-- M.onSumoGoal = onSumoGoal
M.setSumoArenaNames = setSumoArenaNames
-- M.setSumoLevels = setSumoLevels
M.setSumoGoalCount = setSumoGoalCount

-- M.setSumoLevelName = setSumoLevelName

M.markSumoVehicleToExplode = markSumoVehicleToExplode
M.unmarkSumoVehicleToExplode = unmarkSumoVehicleToExplode
M.onSumoPlayerExplode = onSumoPlayerExplode

M.selectRandomArena = selectRandomArena

M.sumo = sumo
M.SUMO = SUMO
M.sumoSaveArena = sumoSaveArena

return M
