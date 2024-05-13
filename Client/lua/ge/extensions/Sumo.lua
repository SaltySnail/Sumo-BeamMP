local M = {}

local floor = math.floor
local mod = math.fmod
local rand = math.random

local gamestate = {players = {}, settings = {}}

--blocked inputs when dead
local blockedInputActionsOnDeath = 			{'slower_motion','faster_motion','toggle_slow_motion','modify_vehicle','vehicle_selector','saveHome','loadHome', 'reset_all_physics','toggleTraffic', "recover_vehicle", "recover_vehicle_alt", "recover_to_last_road", "reload_vehicle", "reload_all_vehicles", "parts_selector", "dropPlayerAtCamera", "nodegrabberRender",'reset_physics','dropPlayerAtCameraNoReset'} 
local blockedInputActionsOnRound = 			{'slower_motion','faster_motion','toggle_slow_motion','modify_vehicle','vehicle_selector','saveHome','loadHome', 'reset_all_physics','toggleTraffic', "recover_vehicle_alt", "recover_to_last_road", "reload_vehicle", "reload_all_vehicles", "parts_selector", "dropPlayerAtCamera", "nodegrabberRender",'reset_physics','switch_previous_vehicle','switch_next_vehicle','dropPlayerAtCameraNoReset'} 
local blockedInputActionsOnSpeedOrCircle = 	{'slower_motion','faster_motion','toggle_slow_motion','modify_vehicle','vehicle_selector','saveHome','loadHome', 'reset_all_physics','toggleTraffic', "recover_vehicle", "recover_vehicle_alt", "recover_to_last_road", "reload_vehicle", "reload_all_vehicles", "parts_selector", "dropPlayerAtCamera", "nodegrabberRender",'reset_physics','switch_previous_vehicle','switch_next_vehicle','dropPlayerAtCameraNoReset'} 

local colors = {["Red"] = {255,50,50,255},["LightBlue"] = {50,50,160,255},["Green"] = {50,255,50,255},["Yellow"] = {200,200,25,255},["Purple"] = {150,50,195,255}}
local thisArenaData = {}
local mapData = {} --TODO: this should be a json file or something for easily adding arenas + this is stupid
local isPlayerInCircle = false
mapData.arenaData = {}
mapData.arenas = "" 

--Star arena data:
thisArenaData = {}
thisArenaData.name = "Star"
thisArenaData.goalcount = "9"
thisArenaData.goalOffsets = {}
thisArenaData.goalOffsets["1"] = {}
thisArenaData.goalOffsets["1"].x = 203.609
thisArenaData.goalOffsets["1"].y = 423.144
thisArenaData.goalOffsets["1"].z = 408.726
thisArenaData.goalOffsets["2"] = {}
thisArenaData.goalOffsets["2"].x = 317.879
thisArenaData.goalOffsets["2"].y = 402.012
thisArenaData.goalOffsets["2"].z = 426.932
thisArenaData.goalOffsets["3"] = {}
thisArenaData.goalOffsets["3"].x = 298.732
thisArenaData.goalOffsets["3"].y = 490.086
thisArenaData.goalOffsets["3"].z = 426.932
thisArenaData.goalOffsets["4"] = {}
thisArenaData.goalOffsets["4"].x = 224.334
thisArenaData.goalOffsets["4"].y = 535.701
thisArenaData.goalOffsets["4"].z = 426.932
thisArenaData.goalOffsets["5"] = {}
thisArenaData.goalOffsets["5"].x = 138.712
thisArenaData.goalOffsets["5"].y = 515.891
thisArenaData.goalOffsets["5"].z = 426.932
thisArenaData.goalOffsets["6"] = {}
thisArenaData.goalOffsets["6"].x = 92.969
thisArenaData.goalOffsets["6"].y = 442.258
thisArenaData.goalOffsets["6"].z = 426.932
thisArenaData.goalOffsets["7"] = {}
thisArenaData.goalOffsets["7"].x = 107.114
thisArenaData.goalOffsets["7"].y = 357.139
thisArenaData.goalOffsets["7"].z = 426.932
thisArenaData.goalOffsets["8"] = {}
thisArenaData.goalOffsets["8"].x = 182.852
thisArenaData.goalOffsets["8"].y = 310.846
thisArenaData.goalOffsets["8"].z = 426.574
thisArenaData.goalOffsets["9"] = {}
thisArenaData.goalOffsets["9"].x = 269.193
thisArenaData.goalOffsets["9"].y = 327.620
thisArenaData.goalOffsets["9"].z = 426.574
thisArenaData.spawnLocationCount = 9
thisArenaData.spawnLocation = {}
thisArenaData.spawnLocation[1] = {}
thisArenaData.spawnLocation[1].x = 203.609
thisArenaData.spawnLocation[1].y = 423.144
thisArenaData.spawnLocation[1].z = 408.726
thisArenaData.spawnLocation[1].rx = 0
thisArenaData.spawnLocation[1].ry = 0
thisArenaData.spawnLocation[1].rz = 0
thisArenaData.spawnLocation[2] = {}
thisArenaData.spawnLocation[2].x = 317.879
thisArenaData.spawnLocation[2].y = 402.012
thisArenaData.spawnLocation[2].z = 426.932
thisArenaData.spawnLocation[2].rx = 0
thisArenaData.spawnLocation[2].ry = 0
thisArenaData.spawnLocation[2].rz = 99.768
thisArenaData.spawnLocation[3] = {}
thisArenaData.spawnLocation[3].x = 298.732
thisArenaData.spawnLocation[3].y = 490.086
thisArenaData.spawnLocation[3].z = 426.932
thisArenaData.spawnLocation[3].rx = 0
thisArenaData.spawnLocation[3].ry = 0
thisArenaData.spawnLocation[3].rz = 54.762
thisArenaData.spawnLocation[4] = {}
thisArenaData.spawnLocation[4].x = 224.334
thisArenaData.spawnLocation[4].y = 535.701
thisArenaData.spawnLocation[4].z = 426.932
thisArenaData.spawnLocation[4].rx = 0
thisArenaData.spawnLocation[4].ry = 0
thisArenaData.spawnLocation[4].rz = 13.800
thisArenaData.spawnLocation[5] = {}
thisArenaData.spawnLocation[5].x = 138.712
thisArenaData.spawnLocation[5].y = 515.891
thisArenaData.spawnLocation[5].z = 426.932
thisArenaData.spawnLocation[5].rx = 0
thisArenaData.spawnLocation[5].ry = 0
thisArenaData.spawnLocation[5].rz = -33.727
thisArenaData.spawnLocation[6] = {}
thisArenaData.spawnLocation[6].x = 92.969
thisArenaData.spawnLocation[6].y = 442.258
thisArenaData.spawnLocation[6].z = 426.932
thisArenaData.spawnLocation[6].rx = 0
thisArenaData.spawnLocation[6].ry = 0
thisArenaData.spawnLocation[6].rz = -82.901
thisArenaData.spawnLocation[7] = {}
thisArenaData.spawnLocation[7].x = 107.114
thisArenaData.spawnLocation[7].y = 357.139
thisArenaData.spawnLocation[7].z = 426.932
thisArenaData.spawnLocation[7].rx = 0
thisArenaData.spawnLocation[7].ry = 0
thisArenaData.spawnLocation[7].rz = -126.955
thisArenaData.spawnLocation[8] = {}
thisArenaData.spawnLocation[8].x = 182.852
thisArenaData.spawnLocation[8].y = 310.846
thisArenaData.spawnLocation[8].z = 426.574
thisArenaData.spawnLocation[8].rx = 0
thisArenaData.spawnLocation[8].ry = 0
thisArenaData.spawnLocation[8].rz = -168.239
thisArenaData.spawnLocation[9] = {}
thisArenaData.spawnLocation[9].x = 269.193
thisArenaData.spawnLocation[9].y = 327.620
thisArenaData.spawnLocation[9].z = 426.574
thisArenaData.spawnLocation[9].rx = 0
thisArenaData.spawnLocation[9].ry = 0
thisArenaData.spawnLocation[9].rz = 145.975
mapData.arenaData[thisArenaData.name] = thisArenaData
mapData.arenas = mapData.arenas .. " " .. thisArenaData.name

--Targets arena data:
thisArenaData = {}
thisArenaData.name = "Targets"
thisArenaData.goalcount = "9"
thisArenaData.goalOffsets = {}
thisArenaData.goalOffsets["1"] = {}
thisArenaData.goalOffsets["1"].x = 250.203
thisArenaData.goalOffsets["1"].y = 361.423
thisArenaData.goalOffsets["1"].z = 422.835
thisArenaData.goalOffsets["2"] = {}
thisArenaData.goalOffsets["2"].x = 156.142
thisArenaData.goalOffsets["2"].y = 363.116
thisArenaData.goalOffsets["2"].z = 422.813
thisArenaData.goalOffsets["3"] = {}
thisArenaData.goalOffsets["3"].x = 156.307
thisArenaData.goalOffsets["3"].y = 485.312
thisArenaData.goalOffsets["3"].z = 422.814
thisArenaData.goalOffsets["4"] = {}
thisArenaData.goalOffsets["4"].x = 250.117
thisArenaData.goalOffsets["4"].y = 483.486
thisArenaData.goalOffsets["4"].z = 422.813
thisArenaData.goalOffsets["5"] = {}
thisArenaData.goalOffsets["5"].x = 202.546
thisArenaData.goalOffsets["5"].y = 545.955
thisArenaData.goalOffsets["5"].z = 409.842
thisArenaData.goalOffsets["6"] = {}
thisArenaData.goalOffsets["6"].x = 203.609
thisArenaData.goalOffsets["6"].y = 423.144
thisArenaData.goalOffsets["6"].z = 409.841
thisArenaData.goalOffsets["7"] = {}
thisArenaData.goalOffsets["7"].x = 203.669
thisArenaData.goalOffsets["7"].y = 301.157
thisArenaData.goalOffsets["7"].z = 409.841
thisArenaData.goalOffsets["8"] = {}
thisArenaData.goalOffsets["8"].x = 265.276
thisArenaData.goalOffsets["8"].y = 425.334
thisArenaData.goalOffsets["8"].z = 396.918
thisArenaData.goalOffsets["9"] = {}
thisArenaData.goalOffsets["9"].x = 142.464
thisArenaData.goalOffsets["9"].y = 421.787
thisArenaData.goalOffsets["9"].z = 396.708
thisArenaData.spawnLocationCount = 9
thisArenaData.spawnLocation = {}
thisArenaData.spawnLocation[1] = {}
thisArenaData.spawnLocation[1].x = 250.203
thisArenaData.spawnLocation[1].y = 361.423
thisArenaData.spawnLocation[1].z = 422.835
thisArenaData.spawnLocation[1].rx = 0
thisArenaData.spawnLocation[1].ry = 0
thisArenaData.spawnLocation[1].rz = 180
thisArenaData.spawnLocation[2] = {}
thisArenaData.spawnLocation[2].x = 156.142
thisArenaData.spawnLocation[2].y = 363.116
thisArenaData.spawnLocation[2].z = 422.813
thisArenaData.spawnLocation[2].rx = 0
thisArenaData.spawnLocation[2].ry = 0
thisArenaData.spawnLocation[2].rz = 180
thisArenaData.spawnLocation[3] = {}
thisArenaData.spawnLocation[3].x = 156.307
thisArenaData.spawnLocation[3].y = 485.312
thisArenaData.spawnLocation[3].z = 422.814
thisArenaData.spawnLocation[3].rx = 0
thisArenaData.spawnLocation[3].ry = 0
thisArenaData.spawnLocation[3].rz = 0
thisArenaData.spawnLocation[4] = {}
thisArenaData.spawnLocation[4].x = 250.117
thisArenaData.spawnLocation[4].y = 483.486
thisArenaData.spawnLocation[4].z = 422.813
thisArenaData.spawnLocation[4].rx = 0
thisArenaData.spawnLocation[4].ry = 0
thisArenaData.spawnLocation[4].rz = 0
thisArenaData.spawnLocation[5] = {}
thisArenaData.spawnLocation[5].x = 202.546
thisArenaData.spawnLocation[5].y = 545.955
thisArenaData.spawnLocation[5].z = 409.842
thisArenaData.spawnLocation[5].rx = 0
thisArenaData.spawnLocation[5].ry = 0
thisArenaData.spawnLocation[5].rz = 0
thisArenaData.spawnLocation[6] = {}
thisArenaData.spawnLocation[6].x = 203.609
thisArenaData.spawnLocation[6].y = 423.144
thisArenaData.spawnLocation[6].z = 409.841
thisArenaData.spawnLocation[6].rx = 0
thisArenaData.spawnLocation[6].ry = 0
thisArenaData.spawnLocation[6].rz = 0
thisArenaData.spawnLocation[7] = {}
thisArenaData.spawnLocation[7].x = 203.669
thisArenaData.spawnLocation[7].y = 301.157
thisArenaData.spawnLocation[7].z = 409.841
thisArenaData.spawnLocation[7].rx = 0
thisArenaData.spawnLocation[7].ry = 0
thisArenaData.spawnLocation[7].rz = 180
thisArenaData.spawnLocation[8] = {}
thisArenaData.spawnLocation[8].x = 265.276
thisArenaData.spawnLocation[8].y = 425.334
thisArenaData.spawnLocation[8].z = 396.918
thisArenaData.spawnLocation[8].rx = 0
thisArenaData.spawnLocation[8].ry = 0
thisArenaData.spawnLocation[8].rz = 0
thisArenaData.spawnLocation[9] = {}
thisArenaData.spawnLocation[9].x = 142.464
thisArenaData.spawnLocation[9].y = 421.787
thisArenaData.spawnLocation[9].z = 396.708
thisArenaData.spawnLocation[9].rx = 0
thisArenaData.spawnLocation[9].ry = 0
thisArenaData.spawnLocation[9].rz = 0
mapData.arenaData[thisArenaData.name] = thisArenaData
mapData.arenas = mapData.arenas .. " " .. thisArenaData.name


--Containers arena data:
thisArenaData = {}
thisArenaData.name = "Containers"
thisArenaData.goalcount = "9"
thisArenaData.goalOffsets = {}
thisArenaData.goalOffsets["1"] = {}
thisArenaData.goalOffsets["1"].x = -727.211914
thisArenaData.goalOffsets["1"].y = 518.098877
thisArenaData.goalOffsets["1"].z = 306.968048
thisArenaData.goalOffsets["2"] = {}
thisArenaData.goalOffsets["2"].x = -727.794556
thisArenaData.goalOffsets["2"].y = 518.650757
thisArenaData.goalOffsets["2"].z = 305.332855
thisArenaData.goalOffsets["3"] = {}
thisArenaData.goalOffsets["3"].x = -705.320679
thisArenaData.goalOffsets["3"].y = 472.900055
thisArenaData.goalOffsets["3"].z = 301.13562
thisArenaData.goalOffsets["4"] = {}
thisArenaData.goalOffsets["4"].x = -659.325562
thisArenaData.goalOffsets["4"].y = 444.512512
thisArenaData.goalOffsets["4"].z = 301.13562
thisArenaData.goalOffsets["5"] = {}
thisArenaData.goalOffsets["5"].x = -606.366455
thisArenaData.goalOffsets["5"].y = 470.73764
thisArenaData.goalOffsets["5"].z = 304.165985
thisArenaData.goalOffsets["6"] = {}
thisArenaData.goalOffsets["6"].x = -580.354187
thisArenaData.goalOffsets["6"].y = 516.894653
thisArenaData.goalOffsets["6"].z = 304.165985
thisArenaData.goalOffsets["7"] = {}
thisArenaData.goalOffsets["7"].x = -602.158691
thisArenaData.goalOffsets["7"].y = 563.109131
thisArenaData.goalOffsets["7"].z = 300.849365
thisArenaData.goalOffsets["8"] = {}
thisArenaData.goalOffsets["8"].x = -646.113464
thisArenaData.goalOffsets["8"].y = 592.166077
thisArenaData.goalOffsets["8"].z = 300.849365
thisArenaData.goalOffsets["9"] = {}
thisArenaData.goalOffsets["9"].x = -653.119812
thisArenaData.goalOffsets["9"].y = 518.963196
thisArenaData.goalOffsets["9"].z = 297.88031
thisArenaData.spawnLocationCount = 8
thisArenaData.spawnLocation = {}
thisArenaData.spawnLocation[1] = {}
thisArenaData.spawnLocation[1].x = -653.911
thisArenaData.spawnLocation[1].y = 496.857
thisArenaData.spawnLocation[1].z = 298.702
thisArenaData.spawnLocation[1].rx = 0
thisArenaData.spawnLocation[1].ry = 0
thisArenaData.spawnLocation[1].rz = 0
thisArenaData.spawnLocation[2] = {}
thisArenaData.spawnLocation[2].x = -660.306
thisArenaData.spawnLocation[2].y = 501.879
thisArenaData.spawnLocation[2].z = 298.702
thisArenaData.spawnLocation[2].rx = 0
thisArenaData.spawnLocation[2].ry = 0
thisArenaData.spawnLocation[2].rz = 0
thisArenaData.spawnLocation[3] = {}
thisArenaData.spawnLocation[3].x = -669.765
thisArenaData.spawnLocation[3].y = 512.217
thisArenaData.spawnLocation[3].z = 298.702
thisArenaData.spawnLocation[3].rx = 0
thisArenaData.spawnLocation[3].ry = 0
thisArenaData.spawnLocation[3].rz = 0
thisArenaData.spawnLocation[4] = {}
thisArenaData.spawnLocation[4].x = -669.083
thisArenaData.spawnLocation[4].y = 524.352
thisArenaData.spawnLocation[4].z = 298.702
thisArenaData.spawnLocation[4].rx = 0
thisArenaData.spawnLocation[4].ry = 0
thisArenaData.spawnLocation[4].rz = 0
thisArenaData.spawnLocation[5] = {}
thisArenaData.spawnLocation[5].x = -661.670
thisArenaData.spawnLocation[5].y = 530.656
thisArenaData.spawnLocation[5].z = 298.702
thisArenaData.spawnLocation[5].rx = 0
thisArenaData.spawnLocation[5].ry = 0
thisArenaData.spawnLocation[5].rz = 0
thisArenaData.spawnLocation[6] = {}
thisArenaData.spawnLocation[6].x = -654.750
thisArenaData.spawnLocation[6].y = 538.767
thisArenaData.spawnLocation[6].z = 298.702
thisArenaData.spawnLocation[6].rx = 0
thisArenaData.spawnLocation[6].ry = 0
thisArenaData.spawnLocation[6].rz = 0
thisArenaData.spawnLocation[7] = {}
thisArenaData.spawnLocation[7].x = -649.366
thisArenaData.spawnLocation[7].y = 533.698
thisArenaData.spawnLocation[7].z = 298.702
thisArenaData.spawnLocation[7].rx = 0
thisArenaData.spawnLocation[7].ry = 0
thisArenaData.spawnLocation[7].rz = 0
thisArenaData.spawnLocation[8] = {}
thisArenaData.spawnLocation[8].x = -645.389
thisArenaData.spawnLocation[8].y = 530.172
thisArenaData.spawnLocation[8].z = 298.702
thisArenaData.spawnLocation[8].rx = 0
thisArenaData.spawnLocation[8].ry = 0
thisArenaData.spawnLocation[8].rz = 0
mapData.arenaData[thisArenaData.name] = thisArenaData
mapData.arenas = mapData.arenas .. " " .. thisArenaData.name

--Grid arena data:
thisArenaData = {}
thisArenaData.name = "Grid"
thisArenaData.goalcount = "9"
thisArenaData.goalOffsets = {}
thisArenaData.goalOffsets["1"] = {}
thisArenaData.goalOffsets["1"].x = -158.539
thisArenaData.goalOffsets["1"].y = 288.868
thisArenaData.goalOffsets["1"].z = 404.369
thisArenaData.goalOffsets["2"] = {}
thisArenaData.goalOffsets["2"].x = -108.967
thisArenaData.goalOffsets["2"].y = 289.826
thisArenaData.goalOffsets["2"].z = 404.369
thisArenaData.goalOffsets["3"] = {}
thisArenaData.goalOffsets["3"].x = -59.002
thisArenaData.goalOffsets["3"].y = 290.674
thisArenaData.goalOffsets["3"].z = 404.369
thisArenaData.goalOffsets["4"] = {}
thisArenaData.goalOffsets["4"].x = -58.997
thisArenaData.goalOffsets["4"].y = 240.462
thisArenaData.goalOffsets["4"].z = 404.369
thisArenaData.goalOffsets["5"] = {}
thisArenaData.goalOffsets["5"].x = -108.942
thisArenaData.goalOffsets["5"].y = 240.387
thisArenaData.goalOffsets["5"].z = 404.369
thisArenaData.goalOffsets["6"] = {}
thisArenaData.goalOffsets["6"].x = -159.484
thisArenaData.goalOffsets["6"].y = 240.200
thisArenaData.goalOffsets["6"].z = 404.369
thisArenaData.goalOffsets["7"] = {}
thisArenaData.goalOffsets["7"].x = -159.454
thisArenaData.goalOffsets["7"].y = 191.454
thisArenaData.goalOffsets["7"].z = 404.369
thisArenaData.goalOffsets["8"] = {}
thisArenaData.goalOffsets["8"].x = -109.668
thisArenaData.goalOffsets["8"].y = 192.132
thisArenaData.goalOffsets["8"].z = 404.369
thisArenaData.goalOffsets["9"] = {}
thisArenaData.goalOffsets["9"].x = -61.094
thisArenaData.goalOffsets["9"].y = 190.782
thisArenaData.goalOffsets["9"].z = 404.369
thisArenaData.spawnLocationCount = 10
thisArenaData.spawnLocation = {}
thisArenaData.spawnLocation[1] = {}
thisArenaData.spawnLocation[1].x = -84.037
thisArenaData.spawnLocation[1].y = 191.150
thisArenaData.spawnLocation[1].z = 404.369
thisArenaData.spawnLocation[1].rx = 0
thisArenaData.spawnLocation[1].ry = 0
thisArenaData.spawnLocation[1].rz = 0
thisArenaData.spawnLocation[2] = {}
thisArenaData.spawnLocation[2].x = -134.538
thisArenaData.spawnLocation[2].y = 191.863
thisArenaData.spawnLocation[2].z = 404.369
thisArenaData.spawnLocation[2].rx = 0
thisArenaData.spawnLocation[2].ry = 0
thisArenaData.spawnLocation[2].rz = 0
thisArenaData.spawnLocation[3] = {}
thisArenaData.spawnLocation[3].x = -159.593
thisArenaData.spawnLocation[3].y = 214.515
thisArenaData.spawnLocation[3].z = 404.369
thisArenaData.spawnLocation[3].rx = 0
thisArenaData.spawnLocation[3].ry = 0
thisArenaData.spawnLocation[3].rz = 0
thisArenaData.spawnLocation[4] = {}
thisArenaData.spawnLocation[4].x = -134.023
thisArenaData.spawnLocation[4].y = 240.901
thisArenaData.spawnLocation[4].z = 404.369
thisArenaData.spawnLocation[4].rx = 0
thisArenaData.spawnLocation[4].ry = 0
thisArenaData.spawnLocation[4].rz = 0
thisArenaData.spawnLocation[5] = {}
thisArenaData.spawnLocation[5].x = -84.458
thisArenaData.spawnLocation[5].y = 240.198
thisArenaData.spawnLocation[5].z = 404.369
thisArenaData.spawnLocation[5].rx = 0
thisArenaData.spawnLocation[5].ry = 0
thisArenaData.spawnLocation[5].rz = 0
thisArenaData.spawnLocation[6] = {}
thisArenaData.spawnLocation[6].x = -61.367
thisArenaData.spawnLocation[6].y = 264.458
thisArenaData.spawnLocation[6].z = 404.369
thisArenaData.spawnLocation[6].rx = 0
thisArenaData.spawnLocation[6].ry = 0
thisArenaData.spawnLocation[6].rz = 0
thisArenaData.spawnLocation[7] = {}
thisArenaData.spawnLocation[7].x = -109.176
thisArenaData.spawnLocation[7].y = 266.262
thisArenaData.spawnLocation[7].z = 404.369
thisArenaData.spawnLocation[7].rx = 0
thisArenaData.spawnLocation[7].ry = 0
thisArenaData.spawnLocation[7].rz = 0
thisArenaData.spawnLocation[8] = {}
thisArenaData.spawnLocation[8].x = -158.166
thisArenaData.spawnLocation[8].y = 264.569
thisArenaData.spawnLocation[8].z = 404.369
thisArenaData.spawnLocation[8].rx = 0
thisArenaData.spawnLocation[8].ry = 0
thisArenaData.spawnLocation[8].rz = 0
thisArenaData.spawnLocation[9] = {}
thisArenaData.spawnLocation[9].x = -135.742
thisArenaData.spawnLocation[9].y = 289.760
thisArenaData.spawnLocation[9].z = 404.369
thisArenaData.spawnLocation[9].rx = 0
thisArenaData.spawnLocation[9].ry = 0
thisArenaData.spawnLocation[9].rz = 0
thisArenaData.spawnLocation[10] = {}
thisArenaData.spawnLocation[10].x = -84.185
thisArenaData.spawnLocation[10].y = 290.456
thisArenaData.spawnLocation[10].z = 404.369
thisArenaData.spawnLocation[10].rx = 0
thisArenaData.spawnLocation[10].ry = 0
thisArenaData.spawnLocation[10].rz = 0
mapData.arenaData[thisArenaData.name] = thisArenaData
mapData.arenas = mapData.arenas .. " " .. thisArenaData.name

--GridSlanted arena data:
thisArenaData = {}
thisArenaData.name = "GridSlanted"
thisArenaData.goalcount = "9"
thisArenaData.goalOffsets = {}
thisArenaData.goalOffsets["1"] = {}
thisArenaData.goalOffsets["1"].x = -158.999
thisArenaData.goalOffsets["1"].y = 290.939
thisArenaData.goalOffsets["1"].z = 404.369
thisArenaData.goalOffsets["2"] = {}
thisArenaData.goalOffsets["2"].x = -158.525
thisArenaData.goalOffsets["2"].y = 240.790
thisArenaData.goalOffsets["2"].z = 400.141
thisArenaData.goalOffsets["3"] = {}
thisArenaData.goalOffsets["3"].x = -159.247
thisArenaData.goalOffsets["3"].y = 191.517
thisArenaData.goalOffsets["3"].z = 404.379
thisArenaData.goalOffsets["4"] = {}
thisArenaData.goalOffsets["4"].x = -110.042
thisArenaData.goalOffsets["4"].y = 192.177
thisArenaData.goalOffsets["4"].z = 408.660
thisArenaData.goalOffsets["5"] = {}
thisArenaData.goalOffsets["5"].x = -110.020
thisArenaData.goalOffsets["5"].y = 240.130
thisArenaData.goalOffsets["5"].z = 404.366
thisArenaData.goalOffsets["6"] = {}
thisArenaData.goalOffsets["6"].x = -110.042
thisArenaData.goalOffsets["6"].y = 288.824
thisArenaData.goalOffsets["6"].z = 408.596
thisArenaData.goalOffsets["7"] = {}
thisArenaData.goalOffsets["7"].x = -62.374
thisArenaData.goalOffsets["7"].y = 191.435
thisArenaData.goalOffsets["7"].z = 404.373
thisArenaData.goalOffsets["8"] = {}
thisArenaData.goalOffsets["8"].x = -62.374
thisArenaData.goalOffsets["8"].y = 289.017
thisArenaData.goalOffsets["8"].z = 404.297
thisArenaData.goalOffsets["9"] = {}
thisArenaData.goalOffsets["9"].x = -59.958
thisArenaData.goalOffsets["9"].y = 240.944
thisArenaData.goalOffsets["9"].z = 399.866
thisArenaData.spawnLocationCount = 9
thisArenaData.spawnLocation = {}
thisArenaData.spawnLocation[1] = {}
thisArenaData.spawnLocation[1].x = -158.999
thisArenaData.spawnLocation[1].y = 290.939
thisArenaData.spawnLocation[1].z = 404.369
thisArenaData.spawnLocation[1].rx = 0
thisArenaData.spawnLocation[1].ry = 0
thisArenaData.spawnLocation[1].rz = 0
thisArenaData.spawnLocation[2] = {}
thisArenaData.spawnLocation[2].x = -158.525
thisArenaData.spawnLocation[2].y = 240.790
thisArenaData.spawnLocation[2].z = 400.141
thisArenaData.spawnLocation[2].rx = 0
thisArenaData.spawnLocation[2].ry = 0
thisArenaData.spawnLocation[2].rz = 0
thisArenaData.spawnLocation[3] = {}
thisArenaData.spawnLocation[3].x = -159.247
thisArenaData.spawnLocation[3].y = 191.517
thisArenaData.spawnLocation[3].z = 404.379
thisArenaData.spawnLocation[3].rx = 0
thisArenaData.spawnLocation[3].ry = 0
thisArenaData.spawnLocation[3].rz = 0
thisArenaData.spawnLocation[4] = {}
thisArenaData.spawnLocation[4].x = -110.042
thisArenaData.spawnLocation[4].y = 192.177
thisArenaData.spawnLocation[4].z = 408.660
thisArenaData.spawnLocation[4].rx = 0
thisArenaData.spawnLocation[4].ry = 0
thisArenaData.spawnLocation[4].rz = 0
thisArenaData.spawnLocation[5] = {}
thisArenaData.spawnLocation[5].x = -110.020
thisArenaData.spawnLocation[5].y = 240.130
thisArenaData.spawnLocation[5].z = 404.366
thisArenaData.spawnLocation[5].rx = 0
thisArenaData.spawnLocation[5].ry = 0
thisArenaData.spawnLocation[5].rz = 0
thisArenaData.spawnLocation[6] = {}
thisArenaData.spawnLocation[6].x = -110.042
thisArenaData.spawnLocation[6].y = 288.824
thisArenaData.spawnLocation[6].z = 408.596
thisArenaData.spawnLocation[6].rx = 0
thisArenaData.spawnLocation[6].ry = 0
thisArenaData.spawnLocation[6].rz = 0
thisArenaData.spawnLocation[7] = {}
thisArenaData.spawnLocation[7].x = -62.374
thisArenaData.spawnLocation[7].y = 191.435
thisArenaData.spawnLocation[7].z = 404.373
thisArenaData.spawnLocation[7].rx = 0
thisArenaData.spawnLocation[7].ry = 0
thisArenaData.spawnLocation[7].rz = 0
thisArenaData.spawnLocation[8] = {}
thisArenaData.spawnLocation[8].x = -62.374
thisArenaData.spawnLocation[8].y = 289.017
thisArenaData.spawnLocation[8].z = 404.297
thisArenaData.spawnLocation[8].rx = 0
thisArenaData.spawnLocation[8].ry = 0
thisArenaData.spawnLocation[8].rz = 0
thisArenaData.spawnLocation[9] = {}
thisArenaData.spawnLocation[9].x = -59.958
thisArenaData.spawnLocation[9].y = 240.944
thisArenaData.spawnLocation[9].z = 399.866
thisArenaData.spawnLocation[9].rx = 0
thisArenaData.spawnLocation[9].ry = 0
thisArenaData.spawnLocation[9].rz = 0
mapData.arenaData[thisArenaData.name] = thisArenaData
mapData.arenas = mapData.arenas .. " " .. thisArenaData.name

--Platforms arena data:
thisArenaData = {}
thisArenaData.name = "Platforms"
thisArenaData.goalcount = "11"
thisArenaData.goalOffsets = {}
thisArenaData.goalOffsets["1"] = {}
thisArenaData.goalOffsets["1"].x = -357.030
thisArenaData.goalOffsets["1"].y = -36.792
thisArenaData.goalOffsets["1"].z = 408.328
thisArenaData.goalOffsets["2"] = {}
thisArenaData.goalOffsets["2"].x = -381.936
thisArenaData.goalOffsets["2"].y = -52.446
thisArenaData.goalOffsets["2"].z = 404.412
thisArenaData.goalOffsets["3"] = {}
thisArenaData.goalOffsets["3"].x = -422.445
thisArenaData.goalOffsets["3"].y = 6.978
thisArenaData.goalOffsets["3"].z = 402.679
thisArenaData.goalOffsets["4"] = {}
thisArenaData.goalOffsets["4"].x = -398.043
thisArenaData.goalOffsets["4"].y = 25.460
thisArenaData.goalOffsets["4"].z = 399.779
thisArenaData.goalOffsets["5"] = {}
thisArenaData.goalOffsets["5"].x = -335.157
thisArenaData.goalOffsets["5"].y = -23.031
thisArenaData.goalOffsets["5"].z = 399.483
thisArenaData.goalOffsets["6"] = {}
thisArenaData.goalOffsets["6"].x = -370.959
thisArenaData.goalOffsets["6"].y = -16.009
thisArenaData.goalOffsets["6"].z = 399.457
thisArenaData.goalOffsets["7"] = {}
thisArenaData.goalOffsets["7"].x = -396.439
thisArenaData.goalOffsets["7"].y = -31.147
thisArenaData.goalOffsets["7"].z = 395.353
thisArenaData.goalOffsets["8"] = {}
thisArenaData.goalOffsets["8"].x = -408.689
thisArenaData.goalOffsets["8"].y = -14.022
thisArenaData.goalOffsets["8"].z = 393.584
thisArenaData.goalOffsets["9"] = {}
thisArenaData.goalOffsets["9"].x = -363.301
thisArenaData.goalOffsets["9"].y = 17.614
thisArenaData.goalOffsets["9"].z = 387.025
thisArenaData.goalOffsets["10"] = {}
thisArenaData.goalOffsets["10"].x = -351.454
thisArenaData.goalOffsets["10"].y = 0.231
thisArenaData.goalOffsets["10"].z = 390.627
thisArenaData.goalOffsets["11"] = {}
thisArenaData.goalOffsets["11"].x = -397.140
thisArenaData.goalOffsets["11"].y = 25.399
thisArenaData.goalOffsets["11"].z = 399.481
thisArenaData.spawnLocationCount = 11
thisArenaData.spawnLocation = {}
thisArenaData.spawnLocation[1] = {}
thisArenaData.spawnLocation[1].x = -357.030
thisArenaData.spawnLocation[1].y = -36.792
thisArenaData.spawnLocation[1].z = 408.328
thisArenaData.spawnLocation[1].rx = 0
thisArenaData.spawnLocation[1].ry = 0
thisArenaData.spawnLocation[1].rz = 0
thisArenaData.spawnLocation[2] = {}
thisArenaData.spawnLocation[2].x = -381.936
thisArenaData.spawnLocation[2].y = -52.446
thisArenaData.spawnLocation[2].z = 404.412
thisArenaData.spawnLocation[2].rx = 0
thisArenaData.spawnLocation[2].ry = 0
thisArenaData.spawnLocation[2].rz = 0
thisArenaData.spawnLocation[3] = {}
thisArenaData.spawnLocation[3].x = -422.445
thisArenaData.spawnLocation[3].y = 6.978
thisArenaData.spawnLocation[3].z = 402.679
thisArenaData.spawnLocation[3].rx = 0
thisArenaData.spawnLocation[3].ry = 0
thisArenaData.spawnLocation[3].rz = 0
thisArenaData.spawnLocation[4] = {}
thisArenaData.spawnLocation[4].x = -398.043
thisArenaData.spawnLocation[4].y = 25.460
thisArenaData.spawnLocation[4].z = 399.779
thisArenaData.spawnLocation[4].rx = 0
thisArenaData.spawnLocation[4].ry = 0
thisArenaData.spawnLocation[4].rz = 0
thisArenaData.spawnLocation[5] = {}
thisArenaData.spawnLocation[5].x = -335.157
thisArenaData.spawnLocation[5].y = -23.031
thisArenaData.spawnLocation[5].z = 399.483
thisArenaData.spawnLocation[5].rx = 0
thisArenaData.spawnLocation[5].ry = 0
thisArenaData.spawnLocation[5].rz = 0
thisArenaData.spawnLocation[6] = {}
thisArenaData.spawnLocation[6].x = -370.959
thisArenaData.spawnLocation[6].y = -16.009
thisArenaData.spawnLocation[6].z = 399.457
thisArenaData.spawnLocation[6].rx = 0
thisArenaData.spawnLocation[6].ry = 0
thisArenaData.spawnLocation[6].rz = 0
thisArenaData.spawnLocation[7] = {}
thisArenaData.spawnLocation[7].x = -396.439
thisArenaData.spawnLocation[7].y = -31.147
thisArenaData.spawnLocation[7].z = 395.353
thisArenaData.spawnLocation[7].rx = 0
thisArenaData.spawnLocation[7].ry = 0
thisArenaData.spawnLocation[7].rz = 0
thisArenaData.spawnLocation[8] = {}
thisArenaData.spawnLocation[8].x = -408.689
thisArenaData.spawnLocation[8].y = -14.022
thisArenaData.spawnLocation[8].z = 393.584
thisArenaData.spawnLocation[8].rx = 0
thisArenaData.spawnLocation[8].ry = 0
thisArenaData.spawnLocation[8].rz = 0
thisArenaData.spawnLocation[9] = {}
thisArenaData.spawnLocation[9].x = -363.301
thisArenaData.spawnLocation[9].y = 17.614
thisArenaData.spawnLocation[9].z = 387.025
thisArenaData.spawnLocation[9].rx = 0
thisArenaData.spawnLocation[9].ry = 0
thisArenaData.spawnLocation[9].rz = 0
thisArenaData.spawnLocation[10] = {}
thisArenaData.spawnLocation[10].x = -351.454
thisArenaData.spawnLocation[10].y = 0.231
thisArenaData.spawnLocation[10].z = 390.627
thisArenaData.spawnLocation[10].rx = 0
thisArenaData.spawnLocation[10].ry = 0
thisArenaData.spawnLocation[10].rz = 0
thisArenaData.spawnLocation[11] = {}
thisArenaData.spawnLocation[11].x = -397.140
thisArenaData.spawnLocation[11].y = 25.399
thisArenaData.spawnLocation[11].z = 399.481
thisArenaData.spawnLocation[11].rx = 0
thisArenaData.spawnLocation[11].ry = 0
thisArenaData.spawnLocation[11].rz = 0
mapData.arenaData[thisArenaData.name] = thisArenaData
mapData.arenas = mapData.arenas .. " " .. thisArenaData.name

--Halfpipes arena data:
thisArenaData = {}
thisArenaData.name = "Halfpipes"
thisArenaData.goalcount = "13"
thisArenaData.goalOffsets = {}
thisArenaData.goalOffsets["1"] = {}
thisArenaData.goalOffsets["1"].x = 203.452
thisArenaData.goalOffsets["1"].y = 423.118
thisArenaData.goalOffsets["1"].z = 408.906
thisArenaData.goalOffsets["2"] = {}
thisArenaData.goalOffsets["2"].x = 204.753
thisArenaData.goalOffsets["2"].y = 586.354
thisArenaData.goalOffsets["2"].z = 408.906
thisArenaData.goalOffsets["3"] = {}
thisArenaData.goalOffsets["3"].x = 129.762
thisArenaData.goalOffsets["3"].y = 533.976
thisArenaData.goalOffsets["3"].z = 408.906
thisArenaData.goalOffsets["4"] = {}
thisArenaData.goalOffsets["4"].x = 56.483
thisArenaData.goalOffsets["4"].y = 484.595
thisArenaData.goalOffsets["4"].z = 408.906
thisArenaData.goalOffsets["5"] = {}
thisArenaData.goalOffsets["5"].x = 40.167
thisArenaData.goalOffsets["5"].y = 420.017
thisArenaData.goalOffsets["5"].z = 408.906
thisArenaData.goalOffsets["6"] = {}
thisArenaData.goalOffsets["6"].x = 92.353
thisArenaData.goalOffsets["6"].y = 345.092
thisArenaData.goalOffsets["6"].z = 408.906
thisArenaData.goalOffsets["7"] = {}
thisArenaData.goalOffsets["7"].x = 141.823
thisArenaData.goalOffsets["7"].y = 268.366
thisArenaData.goalOffsets["7"].z = 408.906
thisArenaData.goalOffsets["8"] = {}
thisArenaData.goalOffsets["8"].x = 206.112
thisArenaData.goalOffsets["8"].y = 258.589
thisArenaData.goalOffsets["8"].z = 408.906
thisArenaData.goalOffsets["9"] = {}
thisArenaData.goalOffsets["9"].x = 280.110
thisArenaData.goalOffsets["9"].y = 308.898
thisArenaData.goalOffsets["9"].z = 408.906
thisArenaData.goalOffsets["10"] = {}
thisArenaData.goalOffsets["10"].x = 354.196
thisArenaData.goalOffsets["10"].y = 361.364
thisArenaData.goalOffsets["10"].z = 408.906
thisArenaData.goalOffsets["11"] = {}
thisArenaData.goalOffsets["11"].x = 370.975
thisArenaData.goalOffsets["11"].y = 427.061
thisArenaData.goalOffsets["11"].z = 408.906
thisArenaData.goalOffsets["12"] = {}
thisArenaData.goalOffsets["12"].x = 321.679
thisArenaData.goalOffsets["12"].y = 503.894
thisArenaData.goalOffsets["12"].z = 408.906
thisArenaData.goalOffsets["13"] = {}
thisArenaData.goalOffsets["13"].x = 268.402
thisArenaData.goalOffsets["13"].y = 581.583
thisArenaData.goalOffsets["13"].z = 408.906
thisArenaData.spawnLocationCount = 13
thisArenaData.spawnLocation = {}
thisArenaData.spawnLocation[1] = {}
thisArenaData.spawnLocation[1].x = 203.452
thisArenaData.spawnLocation[1].y = 423.118
thisArenaData.spawnLocation[1].z = 408.906
thisArenaData.spawnLocation[1].rx = 0
thisArenaData.spawnLocation[1].ry = 0
thisArenaData.spawnLocation[1].rz = 0
thisArenaData.spawnLocation[2] = {}
thisArenaData.spawnLocation[2].x = 204.753
thisArenaData.spawnLocation[2].y = 586.354
thisArenaData.spawnLocation[2].z = 408.906
thisArenaData.spawnLocation[2].rx = 0
thisArenaData.spawnLocation[2].ry = 0
thisArenaData.spawnLocation[2].rz = 0
thisArenaData.spawnLocation[3] = {}
thisArenaData.spawnLocation[3].x = 129.762
thisArenaData.spawnLocation[3].y = 533.976
thisArenaData.spawnLocation[3].z = 408.906
thisArenaData.spawnLocation[3].rx = 0
thisArenaData.spawnLocation[3].ry = 0
thisArenaData.spawnLocation[3].rz = 0
thisArenaData.spawnLocation[4] = {}
thisArenaData.spawnLocation[4].x = 56.483
thisArenaData.spawnLocation[4].y = 484.595
thisArenaData.spawnLocation[4].z = 408.906
thisArenaData.spawnLocation[4].rx = 0
thisArenaData.spawnLocation[4].ry = 0
thisArenaData.spawnLocation[4].rz = 0
thisArenaData.spawnLocation[5] = {}
thisArenaData.spawnLocation[5].x = 40.167
thisArenaData.spawnLocation[5].y = 420.017
thisArenaData.spawnLocation[5].z = 408.906
thisArenaData.spawnLocation[5].rx = 0
thisArenaData.spawnLocation[5].ry = 0
thisArenaData.spawnLocation[5].rz = 0
thisArenaData.spawnLocation[6] = {}
thisArenaData.spawnLocation[6].x = 92.353
thisArenaData.spawnLocation[6].y = 345.092
thisArenaData.spawnLocation[6].z = 408.906
thisArenaData.spawnLocation[6].rx = 0
thisArenaData.spawnLocation[6].ry = 0
thisArenaData.spawnLocation[6].rz = 0
thisArenaData.spawnLocation[7] = {}
thisArenaData.spawnLocation[7].x = 141.823
thisArenaData.spawnLocation[7].y = 268.366
thisArenaData.spawnLocation[7].z = 408.906
thisArenaData.spawnLocation[7].rx = 0
thisArenaData.spawnLocation[7].ry = 0
thisArenaData.spawnLocation[7].rz = 0
thisArenaData.spawnLocation[8] = {}
thisArenaData.spawnLocation[8].x = 206.112
thisArenaData.spawnLocation[8].y = 258.589
thisArenaData.spawnLocation[8].z = 408.906
thisArenaData.spawnLocation[8].rx = 0
thisArenaData.spawnLocation[8].ry = 0
thisArenaData.spawnLocation[8].rz = 0
thisArenaData.spawnLocation[9] = {}
thisArenaData.spawnLocation[9].x = 280.110
thisArenaData.spawnLocation[9].y = 308.898
thisArenaData.spawnLocation[9].z = 408.906
thisArenaData.spawnLocation[9].rx = 0
thisArenaData.spawnLocation[9].ry = 0
thisArenaData.spawnLocation[9].rz = 0
thisArenaData.spawnLocation[10] = {}
thisArenaData.spawnLocation[10].x = 354.196
thisArenaData.spawnLocation[10].y = 361.364
thisArenaData.spawnLocation[10].z = 408.906
thisArenaData.spawnLocation[10].rx = 0
thisArenaData.spawnLocation[10].ry = 0
thisArenaData.spawnLocation[10].rz = 0
thisArenaData.spawnLocation[11] = {}
thisArenaData.spawnLocation[11].x = 370.975
thisArenaData.spawnLocation[11].y = 427.061
thisArenaData.spawnLocation[11].z = 408.906
thisArenaData.spawnLocation[11].rx = 0
thisArenaData.spawnLocation[11].ry = 0
thisArenaData.spawnLocation[11].rz = 0
thisArenaData.spawnLocation[12] = {}
thisArenaData.spawnLocation[12].x = 321.679
thisArenaData.spawnLocation[12].y = 503.894
thisArenaData.spawnLocation[12].z = 408.906
thisArenaData.spawnLocation[12].rx = 0
thisArenaData.spawnLocation[12].ry = 0
thisArenaData.spawnLocation[12].rz = 0
thisArenaData.spawnLocation[13] = {}
thisArenaData.spawnLocation[13].x = 268.402
thisArenaData.spawnLocation[13].y = 581.583
thisArenaData.spawnLocation[13].z = 408.906
thisArenaData.spawnLocation[13].rx = 0
thisArenaData.spawnLocation[13].ry = 0
thisArenaData.spawnLocation[13].rz = 0
mapData.arenaData[thisArenaData.name] = thisArenaData
mapData.arenas = mapData.arenas .. " " .. thisArenaData.name

local currentArena = ""
local currentLevel = ""
local lastCreatedGoalID = 1

local defaultRedFadeDistance = 20

local goalPrefabActive = false
local goalPrefabPath
local goalPrefabName
local goalPrefabObj
local goalLocation = {}

local obstaclesPrefabActive = false
local obstaclesPrefabPath
local obstaclesPrefabName
local obstaclesPrefabObj

local goalMarker = {}
goalMarker.x = 140
goalMarker.y = 0
goalMarker.arrowAngle = 0
goalMarker.showArrow = false
goalMarker.showHeightArrow = false
goalMarker.showIcon = false
goalMarker.abovePlayer = false

local uiMessages = {}
uiMessages.showMSGYouScored = false
uiMessages.showMSGYouScoredEndTime = 0
uiMessages.showForTime = 2 --2s because the timing is inconsistent, maybe I should add a onSecond function or something

local screenWidth = GFXDevice.getDesktopMode().width
local screenHeight = GFXDevice.getDesktopMode().height
if screenHeight > 1080 then screenHeight = 1080 end --it seems ui apps are limited to 1080p
if screenWidth > 1920 then screenWidth = 1920 end

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
end

function disallowSumoResets(data)
	extensions.core_input_actionFilter.setGroup('sumo', data)
	extensions.core_input_actionFilter.addAction(0, 'sumo', true)
end

function spawnSumoGoal(filepath, offset, scale) 
	goalPrefabActive = true
	goalPrefabPath   = filepath
	goalPrefabName   = string.gsub(filepath, "(.*/)(.*)", "%2"):sub(1, -13)
	local goalNumber = string.match(goalPrefabName, "%d+") 
	goalPrefabPath = "art/goal.prefab.json"
	-- 	-- local line = jsonDecode(jsonString)
	-- 	-- if line.name == "goalTrigger" then 
	-- 	-- 	goalLocation = vec3(line.position)
	-- 	-- end
	-- end
	-- local modifiedFile = jsonEncode(data)
	-- file = io.open(goalPrefabPath, "w")
	-- if not file then retu4rn end
	-- file:write(modifiedFile)
	-- file:close()

	-- local file = io.open(goalPrefabPath, "rb")
	-- if not file then return end
	-- local jsonString = file:read("*all")
	-- file:close()
	-- print( "prefab json after modifying: " .. dump(jsonString))	

	-- print( filepath)
	local offsetString = '0 0 0'
	local scaleString = '1 1 1'
	if offset then
		offsetString = "" .. offset.x .. " " .. offset.y .. " " .. offset.z
	end
	print(currentArena .. " " .. goalNumber)
	if mapData.arenaData[currentArena].goalOffsets[goalNumber] then
		offsetString = "" .. mapData.arenaData[currentArena].goalOffsets[goalNumber].x .. " " .. mapData.arenaData[currentArena].goalOffsets[goalNumber].y .. " " .. mapData.arenaData[currentArena].goalOffsets[goalNumber].z
	end
	-- if scale then
	-- 	scaleString = "" .. scale.x .. " " .. scale.y .. " " .. scale.z
	-- end
	if gamestate.goalScale then
		scaleString = "" .. gamestate.goalScale .. " " .. gamestate.goalScale .. " 1" --.. gamestate.goalScale
	end
	-- print( "Offset: " .. offsetString)
	-- print( "Scale: " .. scaleString)
	goalPrefabObj    = spawnPrefab(goalPrefabName, goalPrefabPath,  offsetString, '0 0 1', scaleString)
	-- print( "goalPrefabObj: " .. dump(goalPrefabObj))
	-- -- -- read local file 
	-- local file = io.open(goalPrefabPath, "rb")
	-- if not file then return end
	-- local jsonString = file:read("*all")
	-- file:close()
	-- local data = jsonDecode(jsonString)
	-- print( "prefab json: " .. dump(jsonString))	
	-- if data and gamestate.goalScale then 
	-- 	for _, entry in ipairs(data) do
	-- 		if entry.name == "goalTrigger" then
	-- 			goalLocation = entry.position
	-- 			-- entry.scale[1] = entry.scale[1] * gamestate.goalScale
	-- 			-- entry.scale[2] = entry.scale[2] * gamestate.goalScale
	-- 			-- entry.scale[3] = entry.scale[3] * gamestate.goalScale
	-- 			-- entry.scale = {gamestate.goalScale, gamestate.goalScale, gamestate.goalScale}
	-- 		elseif entry.name == goalPrefabName .. "TSStatic" then  
	-- 			-- entry.scale[1] = entry.scale[1] * gamestate.goalScale
	-- 			-- entry.scale[2] = entry.scale[2] * gamestate.goalScale
	-- 			-- entry.scale[3] = entry.scale[3] * gamestate.goalScale
	-- 			-- entry.scale = {gamestate.goalScale, gamestate.goalScale, gamestate.goalScale}
	-- 		end
	-- 	end
	-- end
end

function onSumoCreateGoal()
	local currentVehID = be:getPlayerVehicleID(0)
	local veh = be:getObjectByID(currentVehID)
	if not veh then return end
	spawnSumoGoal("art/goal.prefab.json", veh:getPosition())
end

function spawnSumoObstacles(filepath) 
	print(filepath)
	obstaclesPrefabActive = true
	obstaclesPrefabPath   = filepath
	obstaclesPrefabName   = string.gsub(obstaclesPrefabPath, "(.*/)(.*)", "%2"):sub(1, -13)
	obstaclesPrefabObj    = spawnPrefab(obstaclesPrefabName, obstaclesPrefabPath, '0 0 0', '0 0 1', '1 1 1')
	be:reloadStaticCollision(true)
	disallowSumoResets(blockedInputActionsOnRound)
end

function removeSumoPrefabs(type)
	print( "removeSumoPrefabs(" .. type .. ") Called" )
	if type == "goal" and goalPrefabActive then 
		removePrefab(goalPrefabName)
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
		goals = arenaData["goalcount"]
		for goalID=1,tonumber(goals) do
			prefabPath = "goal" .. goalID
			-- print( "Removing: " .. prefabPath)
			removePrefab(prefabPath)
		end
	end
end

function teleportToSumoArena()
	print("teleportToSumoArena Called")
	for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
		-- local veh = be:getObjectByID(be:getPlayerVehicleID(0))
		print("veh:" .. vehID .." : " .. dump(vehData))
		local veh = be:getObjectByID(vehID)
		if not veh then return end --Should not be called but just to be safe
		local arenaData = mapData.arenaData[currentArena]
		local chosenLocation = rand(1, arenaData.spawnLocationCount)
		if arenaData.spawnLocation[chosenLocation] then
			-- print(dump(quatFromEuler(arenaData.spawnLocation[chosenLocation].rx, arenaData.spawnLocation[chosenLocation].ry, arenaData.spawnLocation[chosenLocation].rz)))
			local q = quatFromEuler(math.rad(arenaData.spawnLocation[chosenLocation].rx), math.rad(arenaData.spawnLocation[chosenLocation].ry), math.rad(arenaData.spawnLocation[chosenLocation].rz))
			veh:setPositionRotation(arenaData.spawnLocation[chosenLocation].x, arenaData.spawnLocation[chosenLocation].y, arenaData.spawnLocation[chosenLocation].z, q.x, q.y, q.z, q.w)
		end
		veh:queueLuaCommand("recovery.startRecovering()")
		veh:queueLuaCommand("recovery.stopRecovering()")
	end
end

function onSumoGameEnd()
	allowSumoResets(blockedInputActionsOnRound)
	allowSumoResets(blockedInputActionsOnSpeedOrCircle)
	allowSumoResets(blockedInputActionsOnDeath)
	goalScale = 1
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
						TriggerServerEvent("onPlayerExplode", vehicle.ownerName) 
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
	if trigger == "goalTrigger" then	
		if data.event == "enter" then
			for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
				if vehID == data.subjectID then
					-- if TriggerServerEvent then TriggerServerEvent("unmarkSumoVehicleToExplode", data.subjectID) end
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
					-- if TriggerServerEvent then TriggerServerEvent("markSumoVehicleToExplode",  data.subjectID) end
					allowSumoResets(blockedInputActionsOnSpeedOrCircle)
					isLocalVehicle = true
					break
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
	elseif trigger == "outOfBoundTrigger" then
		--explode player
		for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
			if vehID == data.subjectID then
				-- if TriggerServerEvent then TriggerServerEvent("markSumoVehicleToExplode",  data.subjectID) end
				allowSumoResets(blockedInputActionsOnSpeedOrCircle)
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
	goals = arenaData["goalcount"]
	print( "There are " .. goals .. " goals in " .. levelName .. ", " .. currentArena)
	if TriggerServerEvent then TriggerServerEvent("setSumoGoalCount", goals) end
end

function updateSumoGameState(data)
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
		if not isPlayerInCircle then
			allowSumoResets(blockedInputActionsOnSpeedOrCircle) --TODO: check if this is really a good way to handle this, it might cancel the inputblocking while on the flag
			for vehID, vehData in pairs(MPVehicleGE.getOwnMap()) do
				-- local veh = be:getObjectByID(be:getPlayerVehicleID(0))
				-- print("veh:" .. vehID .." : " .. dump(vehData))
				local veh = be:getObjectByID(vehID)
				veh:queueLuaCommand("isSumoAirSpeedHigherThan(20)") --If speed > 20 km/h no more resets!
			end
		end
	elseif time and gamestate.endtime and (gamestate.endtime - time) < 7 then
		local timeLeft = gamestate.endtime - time
		txt = "Sumo Colors reset in "..math.abs(timeLeft-1).." seconds" --game ended
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
					vehicle.transition = math.max(0,transition - dt)
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
	if MPCoreNetwork and not MPCoreNetwork.isMPSession() then return end

	-- local currentVehID = be:getPlayerVehicleID(0)
	-- local currentOwnerName = MPConfig.getNickname()
	-- if currentVehID and MPVehicleGE.getVehicleByGameID(currentVehID) then
	-- 	currentOwnerName = MPVehicleGE.getVehicleByGameID(currentVehID).ownerName
	-- end

	-- if not gamestate.gameRunning or gamestate.gameEnding then 
	-- 	local veh = be:getObjectByID(currentVehID)
	-- 	-- if veh then 												--TODO: get the UI working 
	-- 	-- 	local uiData = {}
	-- 	-- 	uiData.gameRunning = false or gamestate.gameEnding
	-- 	-- 	uiData.goalAbovePlayer = goalMarker.abovePlayer
	-- 	-- 	uiData.showGoalArrow = false
	-- 	-- 	uiData.showGoalHeightArrow = false
	-- 	-- 	uiData.showGoalIcon = false
	-- 	-- 	uiData.goalX = -140
	-- 	-- 	uiData.goalY = -140
	-- 	-- 	uiData.goalAngle = goalMarker.arrowAngle		
	-- 	-- 	veh:queueLuaCommand('gui.send(\'Sumo\',' .. serialize(uiData) ..')')
	-- 	-- end
	-- 	return 
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

	-- local uiData = {}
	-- -- local player = gamestate.players[vehicle.ownerName]
	-- -- local veh = MPVehicleGE.getVehicleByGameID(currentVehID)	

	-- uiData.gameRunning = true 
	-- uiData.goalAbovePlayer = goalMarker.abovePlayer
	-- uiData.showGoalArrow = goalMarker.showArrow
	-- uiData.showGoalHeightArrow = goalMarker.showHeightArrow
	-- uiData.showGoalIcon = goalMarker.showIcon
	-- uiData.goalX = goalMarker.x
	-- uiData.goalY = goalMarker.y
	-- uiData.goalAngle = goalMarker.arrowAngle
	-- uiData.showMSGYouScored = uiMessages.showMSGYouScored

	-- local veh = be:getObjectByID(currentVehID)
	-- if veh then
	-- 	veh:queueLuaCommand('gui.send(\'Sumo\',' .. serialize(uiData) ..')')
	-- end
	-- print( "Resolution: " .. screenWidth .. "x" .. screenHeight)
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
if MPGameNetwork then AddEventHandler("onSumoAirSpeedTooHigh", onSumoAirSpeedTooHigh) end

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
-- M.onSumoVehicleSpawned = onSumoVehicleSpawned
-- M.onSumoVehicleDeleted = onSumoVehicleDeleted
return M