--Sumo by Julianstap, 2023

local M = {}

local floor = math.floor
local mod = math.fmod
local rand = math.random

local gameState = {players = {}}
local laststate = gameState
local arena = ""
local arenaNames = {}
local possibleArenas = {}
local requestedArena = ""
local goalPrefabCount = 1
local timeSinceLastContact = 0
local teamSize = 1
local possibleTeams = {"Red", "LightBlue", "Green", "Yellow", "Purple"}
local chosenTeams = {}
local vehiclesToExplode = {}
local goalID = -1
local neededPlayers = 0
local class = ""
local arenaData = {}

gameState.gameRunning = false
gameState.gameEnding = false
gameState.goalCount = 1
gameState.goalScale = 1
gameState.safezoneEndAlarm = true
gameState.randomVehicleCountdown = 0

local roundLength = 5*60 -- length of the game in seconds
local safezoneLength = 30
local goalTime = 30 --TODO make it work with a higher goalTime than 30s
local goalEndTime = -10000
local defaultRedFadeDistance = 100 -- the distance between a flag carrier and someone that doesn't have the flag, where the screen of the flag carrier will turn red
local defaultColorPulse = true -- if the car color should pulse between the car color and blue
local defaultFlagTint = true -- if the infecor should have a blue tint
local defaultDistancecolor = 0.3 -- max intensity of the red filter
local teams = false
local alivePlayers = {}
local MAX_ALIVE = 1 --for debugging use 0, else use 1
local playersNeededForGame = 2 --minimum players needed to start a game
local randomVehicles = false
local autoStart = false
local commandsAllowed = true
local safezoneEndAlarm = true
local scoringSystem = true
local totalScore = {}
local blockConsole = false 
local blockEditor = false
local autoStartTimer = 0
local SUMO_SERVER_DATA_PATH = "Resources/Server/Sumo/Data/" --this is the path from beammp-server.exe (change this if it is in a different path)
local SCORE_FOLDER_OVERWRITE = "" --use this to store the scores between different servers (TODO check if that would work with file locks)
local allowedConfigs = {}
local amountOfSpawnsOnArena = {}
local playerJoinsNextRound = {}
local testingConfigSpawnsTime = 0
local testingAllConfigsOnAllSpawns = false
local testingConfig = 1
local testingSpawn = 1
local testingArena = 1
local testingClassIndex = 1
local testingClass = ""
local testingStep = 0
local testingStepTimer = 0
local waitTimeBetweenTests = 20
local SCORES_LOCK_FILE = 'scores.lock'
local unknown = {}
-- The following line was used to generate the allowedConfigs.json file.
-- local f=io.open("car_configs.json","w") f:write(jsonEncode((function() local t={} local allowedConfigs={'autobello','miramar','etk800','vivace','etkc','etki','bluebuck','nine','sbr','bx','utv','burnside','moonhawk','barstow','covet','bolide','legran','pigeon','wigeon','bastion','scintilla','midsize','pessima','fullsize','sunburst2','lansdale','wendover'} for _,c in pairs(core_vehicles.getConfigList(true)) do if c[1] then print(dump(c)) for _,config in pairs(c) do local isAllowed=false for _,key in ipairs(allowedConfigs) do if config.model_key == key then isAllowed=true break end end if config.aggregates and config.aggregates.Type and config.aggregates.Type.Car and isAllowed then table.insert(t,config) end end end end return t end)())) f:close()
-- hand picked allowedConfigs using for _, model in pairs(core_vehicles.getModelList(true).models) do if model.Type == "Car" then print(dump(model)) end end

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

local function randomizeArray(array)
    math.randomseed(os.time())
    local newArray = array
    for i = #newArray, 2, -1 do
        local j = math.random(1, i)
        newArray[i], newArray[j] = newArray[j], newArray[i]
    end
    return newArray
end

local function readAllowedConfigs()
	local file = io.open(SUMO_SERVER_DATA_PATH .. "allowedConfigs.json", "r")
	if not file then 
		print("allowedconfigs.json not found")
		return
	end
	local contents = file:read("*a")
	file:close()
	-- print("onPlayerJoin" .. playerID .. ": " .. Util.JsonPrettify(contents))
	allowedConfigs = Util.JsonDecode(contents)
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
	MP.RegisterEvent("onVehicleReset", "onVehicleReset")
	MP.RegisterEvent("onVehicleDeleted", "onVehicleDeleted")
	MP.RegisterEvent("onRconCommand", "onRconCommand")
	MP.RegisterEvent("onNewRconClient", "onNewRconClient")
	MP.RegisterEvent("onStopServer", "onStopServer")
	MP.RegisterEvent("sumoSaveArena", "sumoSaveArena")
	MP.RegisterEvent("setSumoJoinNextRound", "setSumoJoinNextRound")
	MP.RegisterEvent("setSumoList", "setSumoList")

	
	print("--------------Sumo Loaded------------------")
	loadSettings()
	math.randomseed(os.time())
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
	
	local goalIndexList = {}
	print('SpawnSumoGoal called ' .. goalPrefabCount)
	for i=1, goalPrefabCount do
		if i ~= goalID then
			table.insert(goalIndexList, i)
		end
	end
	print('goalIndexList: ' .. dump(goalIndexList) .. " size " .. #goalIndexList)
	goalID = goalIndexList[rand(1,#goalIndexList)]
	print("Chosen goal: art/goal" .. goalID .. ".prefab.json")
	MP.TriggerClientEvent(-1, "spawnSumoGoal", "art/goal" .. goalID .. ".prefab.json")
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
	if arena and arenaData and arenaData[arena] and arenaData[arena].spawnLocations then
		amountOfSpawnsOnArena[arena] = #arenaData[arena].spawnLocations
		print('SET THE AMOUNT OF SPAWNS!!!!!')
	else
		print('No freaking spawns on arena ' .. arena .. " Look for yourself: " .. dump(arenaData))
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
	onSumoArenaChange()
	alivePlayers = {}
	if teams then
		for k,v in pairs(possibleTeams) do
			chosenTeams[v] = {}
			chosenTeams[v].chosen = false
		end
	end
	gameState = {}
	gameState.settings = {
		redFadeDistance = defaultRedFadeDistance,
		ColorPulse = defaultColorPulse,
		flagTint = defaultFlagTint,
		distancecolor = defaultDistancecolor
		}
	local playerCount = 0
	for ID,Player in pairs(MP.GetPlayers()) do
		if MP.IsPlayerConnected(ID) and (MP.GetPlayerVehicles(ID) or playerJoinsNextRound[Player]) then
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
	local possibleConfigs = {}
	if randomVehicles then
		local keys = {}
		for k,_ in pairs(allowedConfigs) do
			if k ~= class then
				table.insert(keys, k)
			end
		end
		keys = randomizeArray(keys)
		if #keys > 0 then
			class = keys[rand(1,#keys)]
		end
	end
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
		if randomVehicles and #possibleConfigs == 0 and allowedConfigs and allowedConfigs[class] then
			for _,v in pairs(allowedConfigs[class]) do
				table.insert(possibleConfigs, v)
			end
		end
		possibleConfigs = randomizeArray(possibleConfigs)
		--print(dump(possibleConfigs))
		if MP.IsPlayerConnected(ID) then
			local player = {}
			if randomVehicles and (MP.GetPlayerVehicles(ID) or playerJoinsNextRound[Name]) then		
				if not gameState then gameState = {} end
				if not gameState.players then gameState.players = {} end
				if not gameState.players[Name] then gameState.players[Name] = {} end
				print("Chosen class: " .. class)
				local chosenConfig = rand(1,#possibleConfigs)
				-- print("chosenConfig: " .. chosenConfig .. " possibleConfigs: " .. dump(possibleConfigs) .. " allowedConfigs: " .. dump(allowedConfigs))
				--print(dump(allowedConfigs[class]))
				local configFile = io.open(SUMO_SERVER_DATA_PATH .. possibleConfigs[chosenConfig], 'r')
				if not configFile then 
					print(SUMO_SERVER_DATA_PATH .. possibleConfigs[chosenConfig] .. " not found")
					return
				end
				local contents = configFile:read("*a")
				configFile:close()
				gameState.players[Name].chosenConfig = Util.JsonDecode(contents) 
				table.remove(possibleConfigs, chosenConfig)
				--print("Chosen config: " .. dump(gameState.players[Name].chosenConfig))
			end
			if MP.GetPlayerVehicles(ID) then
				if not gameState then gameState = {} end
				if not gameState.players then gameState.players = {} end
				if not gameState.players[Name] then gameState.players[Name] = {} end
				gameState.players[Name].ID = ID
				gameState.players[Name].team = chosenTeam
				gameState.players[Name].dead = false
				gameState.players[Name].isRoundWinner = false
				teamCount = teamCount + 1
			end
		end
	end

	if playerCount == 0 then
		MP.SendChatMessage(-1,"Failed to start, found no vehicles")
		return
	end

	gameState.playerCount = playerCount
	gameState.randomVehicles = randomVehicles
	gameState.randomVehicleStartWaitTime = -45 --should be equal or less than -30
	if randomVehicles then
		gameState.time = gameState.randomVehicleStartWaitTime + 1
	else
		gameState.time = -9
	end
	gameState.roundLength = roundLength
	gameState.safezoneLength = safezoneLength
	gameState.endtime = -1
	gameState.gameRunning = true
	gameState.gameEnding = false
	gameState.gameEnded = false
	gameState.teams = teams
	gameState.goalCount = 1
	gameState.goalScale = 1
	gameState.safezoneEndAlarm = safezoneEndAlarm

	MP.TriggerClientEvent(-1, "spawnSumoObstacles", "art/" .. arena .. "/")
	updateSumoClients()
	spawnSumoGoal()

	MP.TriggerClientEventJson(-1, "receiveSumoGameState", gameState)
end

function sumoGameEnd(reason)
	-- print("Sumo round ending...")
	gameState.gameEnding = true
	gameState.goalScale = 1
	if reason == nil or reason == "nil" then
		MP.SendChatMessage(-1,"Game stopped for unknown reason")
	else
		if reason == "time" then
			if #alivePlayers > 0 then
				MP.SendChatMessage(-1,"Game over the time limit was reached, the winners are: ")
				for i=1,#alivePlayers do
					MP.SendChatMessage(-1, alivePlayers[i])
					if scoringSystem then
						if not gameState.players[alivePlayers[i]].survivedSafezones then gameState.players[alivePlayers[i]].survivedSafezones = 0 end 
						if not gameState.players[alivePlayers[i]].roundScore then gameState.players[alivePlayers[i]].roundScore = 0 end 
						gameState.players[alivePlayers[i]].roundScore = gameState.players[alivePlayers[i]].roundScore + gameState.players[alivePlayers[i]].survivedSafezones + 1 -- +1 to make it fair for the +1 below
						gameState.players[alivePlayers[i]].isRoundWinner = true
					end
				end
			else
				MP.SendChatMessage(-1,"Game over, time limit was reached")
			end
		elseif reason == "manual" then

			MP.SendChatMessage(-1,"Game stopped, Everyone Looses")
		elseif reason == "last alive" then
			if #alivePlayers > 0 then
				MP.SendChatMessage(-1,"Game over, " .. alivePlayers[1] .. " wins!") --FIXME: if MAX_ALIVE is more than 1 this is fucked, don't think you should set it to more though
				if scoringSystem then
					if not gameState.players[alivePlayers[1]].survivedSafezones then gameState.players[alivePlayers[1]].survivedSafezones = 0 end 
					if not gameState.players[alivePlayers[1]].roundScore then gameState.players[alivePlayers[1]].roundScore = 0 end 
					gameState.players[alivePlayers[1]].roundScore = gameState.players[alivePlayers[1]].roundScore + gameState.players[alivePlayers[1]].survivedSafezones + 1 -- +1 to not have 0 points when everyone falls off in the first 30 seconds
					gameState.players[alivePlayers[1]].isRoundWinner = true
				end
			else
				MP.SendChatMessage(-1,"Game over, everyone died!")
			end
		end
	end
	if not gameState.time then gameState.time = -9 end
	gameState.endtime = gameState.time + 10

	if scoringSystem then
		local totalScore = loadScores()
		MP.SendChatMessage(-1,"The total scores are now: ")
		local data = { players = {} }
		for playername, player in pairs(gameState.players) do
			if not totalScore then totalScore = {} end
			if not totalScore[playername] then totalScore[playername] = 0 end
			if not player then player = {} end
			if not player.roundScore then player.roundScore = 0 end
			-- print(dump(player))
			totalScore[playername] = totalScore[playername] + player.roundScore
			MP.SendChatMessage(-1, "" .. playername .. " : " .. totalScore[playername])
			table.insert(data.players, {
				name  = playername,
				totalScore = totalScore[playername],
				roundScore = player.roundScore,
				isRoundWinner = player.isRoundWinner
			})
			player.roundScore = 0
			player.survivedSafezones = 0
		end
		MP.TriggerClientEvent(-1, "onSumoShowScoreboard", Util.JsonEncode(data))
		saveScores(totalScore)
	end
	alivePlayers = {}
end

function showSumoPrefabs(player, goals) --shows the prefabs belonging to this map and this arena
	MP.TriggerClientEvent(player.playerID, "spawnSumoObstacles", "art/" .. arena .. "/")
	if not goals then return end
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
		MP.SendChatMessage(player.playerID, "\"/sumo show all\" to show all goals and obstacles in the current arena.")
		MP.SendChatMessage(player.playerID, "\"/sumo show arena\" to show the current arena.")
		MP.SendChatMessage(player.playerID, "\"/sumo hide\" to hide all goals and obstacles in the current arena.")
		MP.SendChatMessage(player.playerID, "\"/sumo start \'minutes\' \" to start a sumo game with a duration of the specified minutes.")
		MP.SendChatMessage(player.playerID, "\"/sumo time limit \'minutes\' \" to set the duration of a sumo game to the specified minutes.")
		MP.SendChatMessage(player.playerID, "\"/sumo teams \'true/false\' \" to specify if the sumo games uses teams.")
		MP.SendChatMessage(player.playerID, "\"/sumo create \'goal\' \" to create a goal, so you can make your own arenas! \n Consult the tutorial on GitHub to learn how to do this.")
	elseif argument == "show all" then
		onSumoArenaChange()
		showSumoPrefabs(player, true)
	elseif argument == "test" then
		readAllowedConfigs()
		requestedArena = arenaNames[testingArena]
		onSumoArenaChange()
		print('Testing starting')
		testingAllConfigsOnAllSpawns = true
	elseif string.find(argument, "test %d") then
		readAllowedConfigs()
		requestedArena = arenaNames[testingArena]
		onSumoArenaChange()
		print('Testing starting with specified wait time')
		testingAllConfigsOnAllSpawns = true
		waitTimeBetweenTests = tonumber(string.sub(argument,6,10000))
	elseif argument == "stop test" then
		testingAllConfigsOnAllSpawns = false
	elseif argument == "show arena" then
		onSumoArenaChange()
		showSumoPrefabs(player, false)
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
			if MP.IsPlayerConnected(ID) and (MP.GetPlayerVehicles(ID) or playerJoinsNextRound[Player]) then
				playerCount = playerCount + 1
			end
		end
		if playerCount < playersNeededForGame then
			MP.SendChatMessage(player.playerID, "Can't start the game with less than " .. playersNeededForGame .. ".")
			return 1
		end
		if not gameState or not gameState.gameRunning then
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
			readAllowedConfigs()
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
	elseif string.find(argument, "remove %S") then
		local createString = string.sub(argument,8,10000) 
		if createString == "goals" then
			MP.TriggerClientEvent(player.playerID, "removeSumoPrefabs", "goal")
		elseif createString == "spawns" then
			MP.TriggerClientEvent(player.playerID, "onSumoRemoveSpawns", "nil")
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
		if gameState.time > gameState.randomVehicleStartWaitTime + 20 then 
			local playerCount = 0
			for ID,Player in pairs(MP.GetPlayers()) do
				if MP.IsPlayerConnected(ID) and (MP.GetPlayerVehicles(ID) or playerJoinsNextRound[Player]) then
					playerCount = playerCount + 1
				end
			end
			if not gameState.gameEnding and playerCount < playersNeededForGame then
				sumoGameEnd('manual')
			end
		end
	elseif gameState.time == 0 then
		sumoGameStarting()
	end

	if gameState.time < -3 and gameState.time > -10 then
		local possibleSpawns = {}
		for ID,Player in pairs(MP.GetPlayers()) do
			if MP.IsPlayerConnected(ID) and (MP.GetPlayerVehicles(ID) or playerJoinsNextRound[Player]) then
				if amountOfSpawnsOnArena and requestedArena and amountOfSpawnsOnArena[arena] then
					if #possibleSpawns == 0 then
						for i=1, amountOfSpawnsOnArena[arena] do
							table.insert(possibleSpawns, i) 
						end
					end
					possibleSpawns = randomizeArray(possibleSpawns)
					local chosenSpawn = rand(1,amountOfSpawnsOnArena[arena]) --chosenSpawn is the index so that we can remove it by index from possibleSpawns
					MP.TriggerClientEvent(ID, "teleportToSumoArena", "" .. tostring(possibleSpawns[chosenSpawn % #possibleSpawns + 1]))
					table.remove(possibleSpawns, chosenSpawn % #possibleSpawns + 1)
				else
					if not arena then requestedArena = "" end
					print("Warning! the amountOfSpawnsOnArena wasn't filled correctly " .. arena .. " " .. dump(amountOfSpawnsOnArena))
					MP.TriggerClientEvent(ID, "teleportToSumoArena", "" .. tostring(ID))
				end
			end
		end
	end

	if not gameState.gameEnding and gameState.playerCount == 0 then
		gameState.gameEnding = true
		gameState.endtime = gameState.time + 2
	end

	local aliveCount = 2 
	if gameState.gameRunning and not gameState.gameEnding and gameState.time > 0 then
		aliveCount = 0
		local playercount = 0
		alivePlayers = {}
		--print(dump(players))
		for playername,player in pairs(gameState.players) do
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
			for playername, explode in pairs(vehiclesToExplode) do
				if explode then
					MP.TriggerClientEvent(-1, "explodeSumoCar", playername)
					vehiclesToExplode[playername] = false
				end
			end
			MP.TriggerClientEvent(-1, "removeSumoPrefabs", "goal")
			if #alivePlayers > 0 then
				for i=1,#alivePlayers do
					if scoringSystem then
						if not gameState.players[alivePlayers[i]].survivedSafezones then gameState.players[alivePlayers[i]].survivedSafezones = 0 end
						if not gameState.players[alivePlayers[i]].roundScore then gameState.players[alivePlayers[i]].roundScore = 0 end
						gameState.players[alivePlayers[i]].survivedSafezones = gameState.players[alivePlayers[i]].survivedSafezones + 1
						gameState.players[alivePlayers[i]].roundScore = gameState.players[alivePlayers[i]].roundScore + 1
					end
				end
			end
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
	elseif autoStart and MP.GetPlayerCount() >= playersNeededForGame then
		local playerCount = 0
		for ID,Player in pairs(MP.GetPlayers()) do
			if MP.IsPlayerConnected(ID) and (MP.GetPlayerVehicles(ID) or playerJoinsNextRound[Player]) then
				playerCount = playerCount + 1
			end
		end
		if playerCount < playersNeededForGame then 
			neededPlayers = playersNeededForGame - playerCount
			return
		end
		autoStartTimer = autoStartTimer + 1
		MP.SendChatMessage(-1, "Waiting to start next round for: " .. 30 - autoStartTimer .. "s")
		MP.SendChatMessage(-1, "Spawn a car or press ctrl+s and check \'Join Next Round\' to join")
		if autoStartTimer >= 30 then
			autoStartTimer = 0
			selectRandomArena()
			sumoGameSetup()
		end
	elseif testingAllConfigsOnAllSpawns then
		testingStepTimer = testingStepTimer + 1

		if testingStep == 0 and testingStepTimer >= 2 then
			MP.TriggerClientEvent(-1, 'removeSumoPrefabs', 'all')
			MP.TriggerClientEvent(-1, 'removeAllVehicles', 'nil')
			testingStep = 2
			testingStepTimer = 0

		elseif testingStep == 1 and testingStepTimer >= 1 then
			onSumoArenaChange()
			testingStep = 1
			testingStepTimer = 0

		elseif testingStep == 2 and testingStepTimer >= 5 then
			for ID, _ in pairs(MP.GetPlayers()) do
				local player = {}
				player.playerID = ID
				showSumoPrefabs(player, true)
			end
			testingStep = 3
			testingStepTimer = 0
			local keys = {}
			for k,_ in pairs(allowedConfigs) do
				if k ~= testingClass then
					table.insert(keys, k)
				end
			end
			if #keys > 0 then
				testingClass = keys[testingClassIndex]
			end

		elseif testingStep == 3 and testingStepTimer >= 1 then
			MP.TriggerClientEvent(-1, 'removeAllVehicles', 'nil')
			testingStep = 4
			testingStepTimer = 0

		elseif testingStep == 4 and testingStepTimer >= 4 then
			local configFile = io.open(SUMO_SERVER_DATA_PATH .. allowedConfigs[testingClass][testingConfig], 'r')
			if not configFile then 
				print(SUMO_SERVER_DATA_PATH .. allowedConfigs[testingClass][testingConfig] .. " not found")
				return
			end
			local contents = configFile:read("*a")
			configFile:close()
			currentConfig = Util.JsonDecode(contents)			
			-- print('allowedConfigs: ' .. dump(allowedConfigs))
			print('testingConfig: ' .. dump(currentConfig))
			MP.TriggerClientEvent(0, 'spawnVehicleConfig',  Util.JsonEncode(currentConfig))
			
			testingStep = 5
			testingStepTimer = 0

		elseif testingStep == 5 and testingStepTimer >= 3 then
			MP.TriggerClientEvent(-1, 'cloneVehicleToSpawns', 'nil')
			testingStep = 6
			testingStepTimer = 0

		elseif testingStep == 6 and testingStepTimer >= 10 then
			MP.TriggerClientEvent(-1, 'teleportToSumoArena', 'nil')
			testingStep = 7
			testingStepTimer = 0

		elseif testingStep == 7 and testingStepTimer >= waitTimeBetweenTests then
			-- Move to next config
			testingConfig = testingConfig + 1
			if testingConfig > #allowedConfigs[testingClass] then
				testingClassIndex = testingClassIndex + 1
				testingConfig = 1
				if testingClassIndex > #allowedConfigs then
					testingArena = testingArena + 1
					testingClassIndex = 1

					if testingArena > #arenaNames then
						testingArena = 1
						testingAllConfigsOnAllSpawns = false
						MP.TriggerClientEvent(-1, 'removeSumoPrefabs', 'all')
						MP.TriggerClientEvent(-1, 'removeAllVehicles', 'nil')
						return
					end

					requestedArena = arenaNames[testingArena]
					testingStep = 0
					testingStepTimer = 0
					return
				end
			end
			-- Restart config testing sequence
			testingStep = 3
			testingStepTimer = 0
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
	arenaData = Util.JsonDecode(contents)
	if next(arenaNames) == nil then --fill arenaNames
		for name, value in pairs(arenaData) do
			table.insert(arenaNames, name)
			if value.spawnLocations then
				amountOfSpawnsOnArena[name] = #value.spawnLocations
			end
		end
	end
	if arena and gameState.gameRunning then
		MP.TriggerClientEvent(playerID, "spawnSumoObstacles", "art/" .. arena .. "/")
		MP.TriggerClientEvent(playerID, "spawnSumoGoal", "art/goal" .. goalID .. ".prefab.json")
	end
	if blockConsole then
		MP.TriggerClientEvent(playerID, "blockConsole", "nil")
	end
	if blockEditor then
		MP.TriggerClientEvent(playerID, "blockEditor", "nil")
	end
	MP.TriggerClientEvent(playerID, "setSumoLayout", "nil")
end

--called whenever a player disconnects from the server
function onPlayerDisconnect(playerID)
	gameState.players[MP.GetPlayerName(playerID)] = nil
	playerJoinsNextRound[MP.GetPlayerName(playerID)] = nil
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
	print('onVehicleSpawn called')
	if (not randomVehicles and gameState and gameState.gameRunning) 
		or (randomVehicles and gameState and gameState.gameRunning and gameState.time and gameState.randomVehicleStartWaitTime 
		and gameState.time > (gameState.randomVehicleStartWaitTime + 20)) then -- 20 seconds to allow slower PC's to spawn a car
		MP.SendChatMessage(playerID, "You can't spawn during a round, press \'ctrl+s\' and check join next round.")
		return 1
	end		
	if autoStart then
		local playerCount = 0
		for ID,Player in pairs(MP.GetPlayers()) do
			if MP.IsPlayerConnected(ID) and (MP.GetPlayerVehicles(ID) or playerJoinsNextRound[Player]) then
				playerCount = playerCount + 1
			end
		end
		neededPlayers = playersNeededForGame - playerCount
		if neededPlayers < 0 then
			neededPlayers = 0
		end
	end
	if autoStart and neededPlayers > 1 then
		MP.SendChatMessage(-1, "Not enough players to start a game, " .. neededPlayers - 1 .. " more player(s) need to spawn a car.")
	end
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
--	MP.TriggerClientEvent(-1, "removeSumoPrefabs", "goal")
--	MP.TriggerClientEvent(playerID, "onScore", "nil")
--	updateSumoClients()
--	MP.SendChatMessage(-1,"".. MP.GetPlayerName(playerID) .." Scored a point!")
--	spawnSumoGoal()
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
--	levels = {}
--	for name in data:gmatch("%S+") do 
--		table.insert(levels, name) 
--	end
-- end
function onSumoPlayerExplode(playerID, playerName)
	--print(playerName .. "   " .. dump(gameState))
	if not gameState then print('No gameState onSumoPlayerExplode') return end
	if not gameState.players then print('No gameState.players onSumoPlayerExplode') return end
	if not gameState.players[playerName] then print('No gameState onSumoPlayerExplode ' .. playerName) return end
	gameState.players[playerName].dead = true
end

function setSumoGoalCount(playerID, data)
	goalPrefabCount = tonumber(data)
end

function markSumoVehicleToExplode(playerID, playername)
	vehiclesToExplode["" .. playername] = true
  --print("Veh marked for exploding: " .. playername)
end

function unmarkSumoVehicleToExplode(playerID, playername)
	vehiclesToExplode["" .. playername] = false
  --print("Veh unmarked for exploding: " .. playername)
end

function selectRandomArena()
	if #possibleArenas == 0 then
		for k,name in pairs(arenaNames) do
			table.insert(possibleArenas, name)
		end 
	end
	possibleArenas = randomizeArray(possibleArenas)
	if next(possibleArenas) ~= nil then
		-- math.random(#arenaNames) will generate a random index in the range of the arenaNames table
		local chosenIndex = math.random(1,#possibleArenas)
		requestedArena = possibleArenas[chosenIndex]
		table.remove(possibleArenas, chosenIndex)
	end
	print("selectRandomArena: " .. requestedArena)
	onSumoArenaChange()
end

function loadSettings()
	local file = io.open(SUMO_SERVER_DATA_PATH .. "settings.json", "r")
    if file then
        local content = file:read("*all") -- Read the entire file content
        file:close()
        local data = Util.JsonDecode(content) -- Decode the JSON data
		if data then
			autoStart = data["autoStart"]
			commandsAllowed = data["chatCommands"]
			safezoneEndAlarm = data["safezoneEndAlarm"]
			randomVehicles = data["randomVehicles"]
			playersNeededForGame = data["playersNeededForGame"]
			blockConsole = data["blockConsole"]
			blockEditor = data["blockEditor"]
		end
    else
        print("Cannot open file:", path)
    end
	if randomVehicles then
		readAllowedConfigs()
	end
end

function aqcuireFileLock(lockFileName) --blocking
	local initialFileLock = io.open(SUMO_SERVER_DATA_PATH .. lockFileName, 'r')
	local waitingForLock = false
	if initialFileLock then
		waitingForLock = true
		initialFileLock:close()
	end
	while(waitingForLock) do -- block while another process is accessing the file
		print(lockFileName .. ' is locked by another process')
		fileLock = io.open(SUMO_SERVER_DATA_PATH .. lockFileName, 'r')
		if fileLock then
			fileLock:close()
			local timeNow = os.time()
			while(os.time() - timeNow < 3) do end -- wait three seconds to lower the chance of two threads waiting and thinking they aqcuired the lock at the same time
		else
			waitingForLock = false
			print('Aqcuired lock: ' .. lockFileName)
		end
	end		
	local newFileLock = io.open(SUMO_SERVER_DATA_PATH .. lockFileName,'w')
	if not newFileLock then print('making the file lock didnt work') return end
	newFileLock:write('locked')
	newFileLock:close()
end

function releaseFileLock(lockFileName)
  os.remove(SUMO_SERVER_DATA_PATH .. lockFileName)
  print(lockFileName .. ' is released')
end

function loadScores()
	aqcuireFileLock(SCORES_LOCK_FILE)
	local file = io.open(SUMO_SERVER_DATA_PATH .. "scores.json", "r")
    if file then
        local content = file:read("*all")
        file:close()
		if not content then content = "{}" end
        local data = Util.JsonDecode(content)
		if data then
			releaseFileLock(SCORES_LOCK_FILE)
			return data
		end
    else
        print("Cannot open file:", path)
    end
  releaseFileLock(SCORES_LOCK_FILE)
	return {}
end

function saveScores(totalScore) -- reads the scores.json file and adds the new scores to it
	aqcuireFileLock(SCORES_LOCK_FILE)
	local file = io.open(SUMO_SERVER_DATA_PATH .. "scores.json", "w")
  if file then
		file:write(Util.JsonPrettify(Util.JsonEncode(totalScore)))
		file:close()
  else
      print("Cannot open file:", SUMO_SERVER_DATA_PATH .. "scores.json")
  end
	releaseFileLock(SCORES_LOCK_FILE)
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

local missingItem = ""
local function tables_equal(t1, t2) --unordered
	local ignore_list = {
		core_vehicle_partmgmt = true,
		ui_gameBlur = true,
		ui_console = true,
		core_repository = true,
		core_metrics = true
	}
	missingItem = ""
	local set1, set2 = {}, {}
	for _, v in ipairs(t1) do
		if not ignore_list[v] then set1[v] = true end
	end
	for _, v in ipairs(t2) do
		if not ignore_list[v] then set2[v] = true end
	end
	for k in pairs(set1) do
		if not set2[k] then
			missingItem = k
			return false
		end
	end
	for k in pairs(set2) do
		if not set1[k] then
			missingItem = k
			return false
		end
	end
	return true
end

function setSumoList(playerID, data)
	local file = io.open(SUMO_SERVER_DATA_PATH .. "normalStuff.json", "r")
	local contents = Util.JsonDecode(file:read("*a"))
	file:close()
	data = Util.JsonDecode(data)
	if tables_equal(data, contents.stuff) then return end --same stuff
	local amount = #unknown
	unknown[missingItem] = true
	if amount ~= #unknown then 
		print(dump(unknown))
	end
	-- print("DATA:   " .. dump(data) .. "    CONTENTS:   " .. dump(contents.stuff))
	-- MP.DropPlayer(playerID, "Unknown mod detected: " .. missingItem)
end

function setSumoJoinNextRound(playerID, state)
	print("" .. MP.GetPlayerName(playerID) .. "changed state to " .. state)
	if state == "true" then
		MP.SendChatMessage(-1, "" .. MP.GetPlayerName(playerID) .. " signed up for a round of sumo! press \'ctrl+s\' to do the same")
		playerJoinsNextRound[MP.GetPlayerName(playerID)] = true
	else
		playerJoinsNextRound[MP.GetPlayerName(playerID)] = nil	
	end
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
M.loadScores = loadScores
M.saveScores = saveScores
M.setSumoJoinNextRound = setSumoJoinNextRound
M.loadSettings = loadSettings
M.setSumoList = setSumoList

return M
