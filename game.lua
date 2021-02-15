
game = {}

local worldBeginContact, worldEndContact, worldPreSolve, worldPostSolve
local initializeRecording, recordRoom, recordingRoom, restoreRoom, rewindRoom, recordRate, rewindRate, rewindRecordingLength, rewindProgress

local queuedStage, queuedStageTransition = false, false
local transitionIn, transitionOut, transitionTo = false, false, "game"
local transitionTime = 0.2
local firstFrame = true --set delta time to 0 on first frame
keyWiggle = false --wiggle keys when collected
keyTypes = {["room10In"]="KeySilver",["room11In"]="KeyBlack",["room9Out"]="KeyBrown"}

local depthview
local freeCam = false

local musicFading, musicFadeTime, musicFadeOut, musicTell, musicStay = false, 0.5, false, 0, false

REWINDING = false
REWINDENDED = false
local paused = false
local pauseSelected = 1
local pauselist = {
	{text="Resume", select=function() game.pause(false) end},
	{text="Restart", select=function() transitionOut = 0; transitionTo = "restart" end},
	{text="Settings", select=function() settings:open() end},
	{text="Exit To Title Screen", select=function() transitionOut = 0; transitionTo = "menu" end},
}

function game.load()
	love.graphics.setBackgroundColor(0,0,0)

	--Load Room
	loadRoom(currentRoom, currentRoomFrom, currentRoomDoorID)

	--Menus
	paused = false
	pauseSelected = 1
	musicFading = false
	musicFadeOut = false

	--Initialize 3D
	game.createCamera()

	love.graphics.setMeshCullMode("back")
	if freeCam then
		love.mouse.setRelativeMode(true)
	end

	--[[love_canvas = {}
	love_canvas[1] = love.graphics.newCanvas(256,256)
	love_canvas[2] = love.graphics.newCanvas(256,256)
	love_canvas[3] = love.graphics.newCanvas(256,256)
	deferredshader = love.graphics.newShader(deferredshader)]]

	game.updateCamera(0)

	musicPlaylist[currentMusicTrack]:stop()
	musicPlaylist[currentMusicTrack]:play()
	musicPlaylist[currentMusicTrack]:setVolume(musicTrackVolume)
end

function game.update(dt)
	if firstFrame then
		firstFrame = false
		dt = 0
	end

	if musicFading then
		if musicFadeOut then
			musicFading = musicFading + dt
			musicPlaylist[currentMusicTrack]:setVolume(math.min(1, 1-(musicFading/musicFadeTime))*musicTrackVolume)
			if musicFading > musicFadeTime then
				musicTell = musicPlaylist[currentMusicTrack]:tell("seconds")
				musicPlaylist[currentMusicTrack]:pause()
				musicFading = false
			end
		else
			musicFading = musicFading - dt
			musicPlaylist[currentMusicTrack]:setVolume(math.max(0, 1-(musicFading/musicFadeTime))*musicTrackVolume)
			if musicFading <= 0 then
				musicFading = false
			end
		end
	elseif (not paused) and (not musicPlaylist[currentMusicTrack]:isPlaying()) and (not REWINDING) then
		if musicStay then
			musicPlaylist[currentMusicTrack]:stop()
			musicPlaylist[currentMusicTrack]:play()
			musicPlaylist[currentMusicTrack]:seek(musicTell or 0, "seconds")
			musicPlaylist[currentMusicTrack]:setVolume(musicTrackVolume)
			musicStay = false
		else
			currentMusicTrack = (currentMusicTrack)%#musicPlaylist+1
			musicPlaylist[currentMusicTrack]:stop()
			musicPlaylist[currentMusicTrack]:play()
			musicPlaylist[currentMusicTrack]:setVolume(musicTrackVolume)
		end
	end

	--Transitions
	if transitionIn then
		transitionIn = transitionIn - dt
		if transitionIn < 0 then
			transitionIn = false
			return false
		end
		
		if transitionIn and transitionIn > transitionTime then
			return false
		end
	elseif transitionOut then
		transitionOut = transitionOut + dt
		if transitionOut > transitionTime then
			transitionOut = false
			if transitionTo == "room" then
				loadRoom(queuedStage[1], currentRoom, queuedStage[2])
			elseif transitionTo == "menu" then
				createSave()
				setgamestate("menu")
			elseif transitionTo == "credits" then
				createSave()
				setgamestate("cutscene", "ending")
			elseif transitionTo == "restart" then
				paused = false
				musicStay = true
				loadRoom(currentRoom, "RESTART")
			end
			return false
		end
	end

	--Settings
	if settings.opened or paused then
		return false
	end

	--Load Queued Stage Warp
	if queuedStageTransition then
		transitionOut = 0
		transitionTo = "room"
		queuedStage = {queuedStageTransition[1], queuedStageTransition[2]}
		queuedStageTransition = nil
		return false
	end

	--Key wiggle animation
	if keyWiggle then
		keyWiggle = keyWiggle + 4*dt
		if keyWiggle > 1 then
			keyWiggle = false
		end
	end

	--Poofs
	local delete = {}
	for i, p in ipairs(POOFS) do
		p:update(dt)
		if p.DELETED then
			table.insert(delete, i)
		end
	end
	table.sort(delete, function(a,b) return a > b end)
	for i, d in ipairs(delete) do
		table.remove(POOFS, d)
	end

	--Physics
	local boxesBeingPushed = false
	for a, objtable in pairs(OBJ) do
		for i, b in pairs(objtable) do
			b:updateBasic(dt)
			if b.update then
				b:update(dt)
				if b.pushing then
					boxesBeingPushed = true
				end
			end
		end
	end
	if REWINDING and sound.pushing:isPlaying() then
		sound.pushing:stop()
	elseif boxesBeingPushed == true and not sound.pushing:isPlaying() then
		sound.pushing:play()
	elseif boxesBeingPushed == false and sound.pushing:isPlaying() then
		sound.pushing:stop()
	end

	--Record or rewind
	local rewindInitial = false
	local rewindEnd = false
	if buttonIsDown("rewind") and (not REWINDENDED) and (not transitionOut) then
		if not REWINDING then
			--Prepare Canvas
			if setting.renderScale == 1 then
				Camera.flipY = true
			end
			rewindInitial = true
			sound.rewinding:play()
		end
		REWINDING = true
	else
		if REWINDING then
			--Prepare Canvas
			if setting.renderScale == 1 then
				Camera.flipY = false
			end
			rewindEnd = true
			sound.rewinding:stop()
		end
		REWINDING = false
	end

	if REWINDING then
		rewindRoom(rewindInitial, dt)
	else
		WORLD:update(dt)
		PLAYER:updateGrab(dt)

		recordingRoom(dt)
	end

	game.updateCamera(dt)
end

function game.createCamera()
	Camera = CameraObj:new(GAMEW/GAMEH, {farClip=100, light=SUNLIGHTVECTOR, forceLight=true, shadow=true, flipY=(setting.renderScale ~= 1), skybox=false, billboard=true})
	Camera:setFOV(CAMERAFOV)
	CameraCanvas = love.graphics.newCanvas(GAMEW*setting.renderScale,GAMEH*setting.renderScale)
	CameraCanvas:setFilter("linear", "linear")
	SetActiveCamera(Camera)

	--Dynamic Shadows
	if setting.shadowMapQuality > 0 then
		local orthoScale = 8
		if setting.graphicsQuality >= 5 then
			orthoScale = 10
		end
		Sun = SunLight:new(setting.shadowMapQuality, orthoScale)
	else
		Sun = SunLight:new(256)
		Sun.canvas = img.white
	end
	local v = NormalizeVector(SUNLIGHTROTATEVECTOR)
	Sun:setDown(v[1],v[2],v[3]) --Spin ShadowMap Canvas around to align with the camera
	Camera:sendShadowMap(Sun)
	if SUNLIGHTVECTOR == false then
		Camera.forceLight=false
	end
end

function game.updateCamera(dt)
	--3D Scene
	local targetX, targetY = PLAYER:getPosition()
	local targetZ = PLAYER.z
	if PLAYER.riding then
		local b = OBJ["Truck"][1]
		targetX, targetY = b:getPosition()
	end
	if not freeCam then
		--Look at Player
		Camera:setCameraAndLookAt(-targetX,targetZ-CAMERADISTY,targetY+CAMERADISTX,-targetX,targetZ,targetY)
	else
		Camera:firstPersonCameraMovement(dt)
	end
	if setting.shadowMapQuality > 0 then
		if currentRoom == "foyer" and targetZ <= -2.5 then --hardcoded fix to hide edge of shadow map when going up stairs (made specifically for foyer)
			targetX = targetX-1.2
		end
		Sun:setCameraAndLookAt(-(targetX+SUNDISTX-CAMERAOFFSETX),SUNDISTZ,targetY+SUNDISTY-CAMERAOFFSETY,-(targetX-CAMERAOFFSETX),0,targetY-CAMERAOFFSETY)
	end
end

local drawScene

function game.draw()
	--Render 3D Scene
	love.graphics.setColor(1,1,1)
	--Shadow Map
	if setting.shadowMapQuality > 0 then
		love.graphics.setMeshCullMode("back")
		SetActiveCamera(Sun.camera)
		love.graphics.setCanvas({depthstencil=Sun.canvas})
		love.graphics.clear(1,0,0)
		love.graphics.setDepthMode("lequal", true)
		drawScene("light")
		love.graphics.setDepthMode()
		love.graphics.setCanvas()
	end
	--Deferred Rendering
	--love.graphics.setCanvas({love_canvas[1],love_canvas[2],love_canvas[3],depth=24})
	--love.graphics.clear(0,0,0)

	--Scene
	if setting.renderScale ~= 1 or REWINDING then
		--Render to canvas under specific circumstances
		love.graphics.setCanvas{CameraCanvas, depth=24}
		love.graphics.clear(0,0,0)
	end
	love.graphics.setMeshCullMode("back")
	Camera:sendShadowMap(Sun)
	SetActiveCamera(Camera)
	love.graphics.setDepthMode("lequal", true)
	drawScene()
	love.graphics.setDepthMode()
	--Tips & Tutorials
	if currentRoom == "room1" and not currentRoomFrom then
		local b = OBJ["Basket"][1]
		if b and not b.grabbedOnce then
			local x, y = b:getPosition()
			local dist = (PLAYER.x-x)*(PLAYER.x-x)+(PLAYER.y-y)*(PLAYER.y-y)
			if dist < 2*2 then
				model.grab:setTexture(img.grab[setting.language])
				model.grab:draw(-x,-1,y)
			end
		end
	elseif #OBJ["Truck"] > 0 then
		local b = OBJ["Truck"][1]
		if b and not b.everRidden then
			local x, y = b:getPosition()
			local dist = (PLAYER.x-x)*(PLAYER.x-x)+(PLAYER.y-y)*(PLAYER.y-y)
			if dist < 2*2 then
				model.grab:setTexture(img.grab[setting.language])
				model.grab:draw(-x,-1,y)
			end
		end
	end

	--HUD
	love.graphics.push()
	love.graphics.scale(setting.renderScale,setting.renderScale)
	local s = assetScale

	local count = 0
	for i, k in pairs(KEYS) do
		if k then --collected
			local image = img.keyIcon
			if keyTypes[i] and keyTypes[i] == "KeySilver" then
				image = img.keySilverIcon
			elseif keyTypes[i] and keyTypes[i] == "KeyBlack" then
				image = img.keyBlackIcon
			elseif keyTypes[i] and keyTypes[i] == "KeyBrown" then
				image = img.keyBrownIcon
			end
			love.graphics.setColor(1,1,1)
			love.graphics.draw(image, 40*s+count*40*s, 40*s, math.sin((keyWiggle or 0)*math.pi*4)*0.2, s*0.25,s*0.25, 128,128)
			count = count + 1
		end
	end
	love.graphics.pop()

	--Rewinding
	if REWINDING then
		love.graphics.push()
		love.graphics.scale(setting.renderScale,setting.renderScale)
		local s = assetScale
		local h = 10*s
		love.graphics.setColor(1,1,1)
		love.graphics.setLineWidth(2*s)
		love.graphics.rectangle("line",(GAMEW-440*s)/2,GAMEH-70*s,440*s,40*s)
		love.graphics.setColor(1,1,1)
		local v = rewindProgress/rewindRecordingLength
		love.graphics.rectangle("fill",(GAMEW-440*s)/2,GAMEH-70*s,440*v*s,40*s)

		--Rewinding Effect
		love.graphics.setColor(1,1,1)
		love.graphics.setFont(VCRFont)
		love.graphics.print("<< REW",20*s,20*s,0,2*s,2*s)

		local time = rewindProgress/(1/recordRate)
		local text = string.format("%02d:%02d:%02d",0,time,time%1*100)
		love.graphics.print(text,GAMEW-20*s-(VCRFont:getWidth(text)*2*s),20*s,0,2*s,2*s)

		love.graphics.pop()
	end
	love.graphics.setCanvas()

	--Present Game Canvas (For post-processing effects)
	if setting.renderScale ~= 1 or REWINDING then
		if REWINDING then
			--Rewinding Effect
			if setting.graphicsQuality > 2 then
				rewindShader:send("wave", rewindProgress*1.5)
				love.graphics.setShader(rewindShader)
			else
				rewindSimpleShader:send("wave", rewindProgress*1.5)
				love.graphics.setShader(rewindSimpleShader)
			end
		end
		love.graphics.draw(CameraCanvas,0,0,0,1/setting.renderScale,1/setting.renderScale)
		love.graphics.setShader()
	end

	--DEBUG stuff
	if SUNDEBUG then
		love.graphics.setColor(1,1,1)
		if not Sun.camera.options.ortho then --perspective
			love.graphics.setShader(depthview)
		end
		love.graphics.draw(Sun.canvas,0,0,0,0.5,0.5)
		love.graphics.setShader()
	end
	if DEFERREDDEBUG then
		love.graphics.draw(love_canvas[1])
		love.graphics.draw(love_canvas[2],love_canvas[2]:getWidth(),0)
		love.graphics.draw(love_canvas[3],0,love_canvas[3]:getHeight())
	end

	--[[Physics
	for a, objtable in pairs(OBJ) do
		for i, b in pairs(objtable) do
			b:debugDraw()
		end
	end]]

	--Paused
	if paused then
		love.graphics.setColor(1,1,1)
		love.graphics.draw(vignette,0,0,0,GAMEW/vignette:getWidth(),GAMEH/vignette:getHeight())
		love.graphics.setColor(0,0,0,0.35)
		love.graphics.rectangle("fill", 0, 0, GAMEW, GAMEH)
		--Main List of Options
		local scale = assetScale
		love.graphics.setFont(textFont[scale])
		local fontHeight = textFont[scale]:getHeight()
		local spacing = 10*scale
		local bottomPadding = 25*scale
		for i, t in ipairs(pauselist) do
			love.graphics.setColor(0.08,0.08,0.08,0.8)
			love.graphics.print(TEXT[t.text], 50*scale, GAMEH-((fontHeight+spacing)*#pauselist)-bottomPadding + (fontHeight+spacing)*(i-1)+2*scale)
			if pauseSelected == i then
				love.graphics.setColor(1,1,1)
			else
				love.graphics.setColor(0.5,0.5,0.5)
			end
			love.graphics.print(TEXT[t.text], 50*scale, GAMEH-((fontHeight+spacing)*#pauselist)-bottomPadding + (fontHeight+spacing)*(i-1))
		end
	end

	--Transition
	if transitionIn then
		love.graphics.setColor(0,0,0,math.min(1,transitionIn/transitionTime))
		love.graphics.rectangle("fill", 0, 0, GAMEW, GAMEH)
		if transitionIn > transitionTime then
			local scale = assetScale
			love.graphics.setFont(textFont[scale])
			local a = 1
			if transitionIn > transitionTime*20-0.5 then
				a = 1-((transitionIn-(transitionTime*20-0.5))/0.5)
			elseif transitionIn < transitionTime+0.5 then
				a = ((transitionIn-transitionTime)/0.5)
			end
			love.graphics.setColor(1,1,1,a)
			love.graphics.printf(TEXT["If you make a mistake,\nyou can hold the rewind button."],0,(WINH-textFont[scale]:getHeight()*2)/2,WINW,"center")
		end
	elseif transitionOut then
		love.graphics.setColor(0,0,0,(transitionOut/transitionTime))
		love.graphics.rectangle("fill", 0, 0, GAMEW, GAMEH)
	end
end

function drawScene(light)
	--Draw Scene
	for a, objtable in pairs(OBJ) do
		for i, b in pairs(objtable) do
			if b.draw then
				local pass = true
				if a ~= "Player" and a ~= "Walls" and not PLAYER.riding then
					--don't draw if too far away
					local x, y = b:getPosition()
					local dist = (PLAYER.x-x)*(PLAYER.x-x)+(PLAYER.y-y)*(PLAYER.y-y)
					pass = dist < DRAWDIST
				end
				if pass then
					love.graphics.setColor(1,1,1)
					b:draw()
				end
			end
		end
	end
	love.graphics.setColor(1,1,1)
	if not light then
		for i, p in ipairs(POOFS) do
			p:draw()
		end
	end
end

function loadRoom(name, from, doorID)
	transitionIn = transitionTime
	--show rewinding tip
	if name == "hallway1" and from == "room1" and not ROOMSTATE["hallway1"] then
		transitionIn = transitionTime*20
	end
	if not ROOMSTATE[name] then
		createSave()
	end
	local restarted = false
	if from == "RESTART" then
		--from = currentRoomFrom
		from = false --start from designated starting spot
		doorID = false
		ROOMSTATE[currentRoom] = nil
		restarted = true
	end

	if from and not restarted then
		--save previous room's state
		if WORLD then
			ROOMSTATE[from] = recordRoom()
			print(string.format("Saved room state of %s!", from))
		end
	end

	--Physics
	if WORLD then WORLD:destroy() end
	love.physics.setMeter(1)
	WORLD = love.physics.newWorld(0,0,true)
	WORLD:setCallbacks(worldBeginContact, worldEndContact, worldPreSolve, worldPostSolve)

	OBJ = {}
	OBJ["Walls"] = {}
	OBJ["Player"] = {}
	OBJ["Box"] = {}
	OBJ["Pile"] = {}
	OBJ["Basket"] = {}
	OBJ["Key"] = {}
	OBJ["Lightswitch"] = {}
	OBJ["Bucket"] = {}
	OBJ["Drips"] = {}
	OBJ["Ball"] = {}
	OBJ["Door"] = {}
	OBJ["Warp"] = {}
	OBJ["Truck"] = {}
	OBJ["GarageDoor"] = {}
	OBJ["Stairs"] = {}
	POOFS = {}
	
	--Load Room model & Collision
	--.obj uses objects: "o OBJECTNAME"
	--Room model is named "Room"
	--Room collision is named "Room_COL"
	--Any object is named "ObjectName_1_OBJ"
	currentRoom = name
	currentRoomFrom = from
	currentRoomDoorID = doorID
	local roomObjFile = loadObjFile("rooms/" .. name .. ".obj", {loadObjects = true, correctUVs = true})
	local roomImg = img.roomTexture
	if love.filesystem.getInfo("rooms/" .. name .. ".png") then
		roomImg = love.graphics.newImage("rooms/" .. name .. ".png", {mipmaps=false})
	end
	spawnObject("Walls", Walls:new(0,0,roomObjFile,roomImg))

	local playerSpawnX, playerSpawnY, playerSpawnRot = 2, 2, 0
	local playerSpawnObjX, playerSpawnObjY = 2, 2
	local foundFromDoor = false
	local keysSubjectToReset = {} --if you reset, only these keys will be removed from inventory
	--Find objects to spawn
	for name, objObject in pairs(roomObjFile) do
		if (name:sub(-4,-1):lower() == "_obj") then
			local x, y = objObject[1]*BLOCK,objObject[2]*BLOCK
			
			--Objects:prop1:prop2#1_OBJ
			local secs = name:split("_")
			local secs2 = secs[1]:split("#")
			local objNum = tonumber(secs2[2] or 1) or 1
			local props = secs2[1]:split(":")
			local objName = props[1]

			if objName == "Spawn" then
				playerSpawnObjX, playerSpawnObjY = x, y
			elseif objName == "Box" then
				local objType = props[2] or "Box"
				local objRot = math.rad(tonumber(props[3] or 0) or 0)
				spawnObject("Box", Box:new(x, y, objType, objRot), objNum)
			elseif objName == "Pile" then
				spawnObject("Pile", Pile:new(x, y), objNum)
			elseif objName == "Basket" then
				spawnObject("Basket", Basket:new(x, y), objNum)
			elseif objName == "Door" then
				local targetRoom = props[2] or "room1"
				local objRot = math.rad(tonumber(props[3] or 0) or 0)
				local locked = (props[4] or "") == "Locked"
				local doorID = props[5] or false
				local room = OBJ["Walls"][1] --walls of current room
				if from == targetRoom and ((not currentRoomDoorID) or (currentRoomDoorID == doorID)) then
					playerSpawnX, playerSpawnY = x+math.sin(-objRot)*1, y+math.cos(-objRot)*1
					playerSpawnRot = math.pi*2-objRot
					foundFromDoor = true
				end
				spawnObject("Door", Door:new(x, y, room, targetRoom, objRot, locked, doorID, objNum), objNum)
			elseif objName == "Warp" then
				local targetRoom = props[2] or "room1"
				local objRot = math.rad(tonumber(props[3] or 0) or 0)
				local doorID = props[4] or false
				if from == targetRoom and ((not currentRoomDoorID) or (currentRoomDoorID == doorID)) then
					playerSpawnX, playerSpawnY = x+math.sin(-objRot)*1, y+math.cos(-objRot)*1
					playerSpawnRot = math.pi*2-objRot
					foundFromDoor = true
				end
				spawnObject("Warp", Warp:new(x, y, targetRoom, doorID), objNum)
			elseif objName == "Key" then
				local keyModel = props[2] or "Key"
				local objRot = math.rad(tonumber(props[3] or 0) or 0)
				local doorID = props[4] or false
				table.insert(keysSubjectToReset, doorID)
				spawnObject("Key", Key:new(x, y, keyModel, objRot, doorID, objNum), objNum)
			elseif objName == "Ball" then
				spawnObject("Ball", Ball:new(x, y), objNum)
			elseif objName == "Bucket" then
				local doorID = props[2] or false
				table.insert(keysSubjectToReset, doorID)
				spawnObject("Bucket", Bucket:new(x, y, doorID), objNum)
			elseif objName == "Drips" then
				spawnObject("Drips", Drips:new(x, y), objNum)
			elseif objName == "Lightswitch" then
				local objRot = math.rad(tonumber(props[2] or 0) or 0)
				spawnObject("Lightswitch", LightSwitch:new(x, y, objRot), objNum)
			elseif objName == "Truck" then
				spawnObject("Truck", Truck:new(x, y), objNum)
			elseif objName == "GarageDoor" then
				spawnObject("GarageDoor", GarageDoor:new(x, y), objNum)
			elseif objName == "Stairs" then
				spawnObject("Stairs", Stairs:new(x, y), objNum)
			end
		end
	end

	--Spawn player
	if not foundFromDoor then
		playerSpawnX, playerSpawnY = playerSpawnObjX, playerSpawnObjY
	end
	PLAYER = spawnObject("Player", Player:new(playerSpawnX, playerSpawnY, playerSpawnRot))

	--reset keys
	if restarted then
		for i = 1, #keysSubjectToReset do
			local k = keysSubjectToReset[i]
			if KEYS[k] and not DOORSUNLOCKED[k] then
				KEYS[k] = false
			end
		end
		keysSubjectToReset = nil
	end

	--Restore room to saved state
	if ROOMSTATE[currentRoom] and not restarted then
		restoreRoom(false,ROOMSTATE[currentRoom])
		print(string.format("Restored room state of %s!", currentRoom))
	end

	initializeRecording()
	collectgarbage("collect")
	collectgarbage("collect")
	firstFrame = true
end

function queueStage(name, doorID)
	queuedStageTransition = {name, doorID}
end
function queueFinish()
	transitionOut = 0; transitionTo = "credits"
end

function spawnObject(objtable, obj, num)
	if num then
		OBJ[objtable][num] = obj
	else
		table.insert(OBJ[objtable], obj)
	end
	return obj
end

function game.pause(p)
	paused = p
	if paused then
		musicFadeOut = true
		if not musicFading then
			musicFading = 0
		end
	else
		if not musicPlaylist[currentMusicTrack]:isPlaying() then
			musicPlaylist[currentMusicTrack]:setVolume(0.001)
			musicPlaylist[currentMusicTrack]:play()
			if not musicPlaylist[currentMusicTrack]:isPlaying() then
				--I guess this is a bug. I tell it to play the source and it still doesn't play it
				musicPlaylist[currentMusicTrack]:play()
				musicPlaylist[currentMusicTrack]:seek(musicTell, "seconds")
				musicPlaylist[currentMusicTrack]:setVolume(0.001)
			end
		end
		musicFadeOut = false
		if not musicFading then
			musicFading = musicFadeTime
		end
	end
	
end

function game.buttonpressed(b)
	--Pause Menu
	if paused then
		if b == "action" then
			pauselist[pauseSelected].select()
			playSound(sound.click)
		elseif b == "up" then
			pauseSelected = pauseSelected - 1
			if pauseSelected < 1 then
				pauseSelected = #pauselist
			end
		elseif b == "down" then
			pauseSelected = pauseSelected + 1
			if pauseSelected > #pauselist then
				pauseSelected = 1
			end
		elseif b == "pause" then
			game.pause(false)
		end
		return
	end
	if b == "pause" then
		if not paused then
			game.pause(true)
		end
	end
	if b == "rewind" then
		REWINDENDED = false
	end

	for i, p in pairs(OBJ["Player"]) do
		p:buttonpressed(b)
	end
end

function game.buttonreleased(b)
	for i, p in pairs(OBJ["Player"]) do
		p:buttonreleased(b)
	end
end

function game.keypressed(k)
	if freeCam then
		if k == "z" then
			Camera:setFOV(math.pi/4)
		end
	end
	if k == "escape" then
		if not paused then
			game.pause(true)
		end
		return true
	elseif k == "up" then
		love.buttonpressed("up")
		return true
	elseif k == "down" then
		love.buttonpressed("down")
		return true
	elseif k == "left" then
		love.buttonpressed("left")
		return true
	elseif k == "right" then
		love.buttonpressed("right")
		return true
	elseif paused and (k == "space" or k == "return") then
		love.buttonpressed("action")
		return true
	end
end

function game.keyreleased(k)
	if freeCam then
		if k == "z" then
			Camera:setFOV(math.pi/2)
		end
	end
end

function game.mousemoved(x, y, dx, dy)
	if freeCam then
		Camera:firstPersonCameraLook(dx,dy)
	end
	if paused then
		local sel = game.pauseOver(x, y)
		if sel then
			pauseSelected = sel
		end
	end
end

function game.mousepressed(x, y, b)
	if b == 1 then
		local sel = game.pauseOver(x, y)
		if sel then
			pauselist[sel]:select()
			playSound(sound.click)
		end
	end
end

function game.pauseOver(x, y)
	local scale = assetScale
	local fontHeight = textFont[scale]:getHeight()
	local spacing = 10*scale
	local bottomPadding = 25*scale
	for i, t in ipairs(pauselist) do
		local x1, y1 = 50*scale, GAMEH-((fontHeight+spacing)*#pauselist)-bottomPadding + (fontHeight+spacing)*(i-1)+2*scale
		local w1, h1 = textFont[scale]:getWidth(TEXT[t.text])+30*scale, fontHeight
		if x > x1 and y > y1 and x < x1+w1 and y < y1+h1 then
			return i
		end
	end
	return false
end

function game.resize(w,h)
	--Window resized!
	--Change aspect ratio of Camera
	Camera.aspectRatio = GAMEW/GAMEH
	Camera:updateProjectionMatrix(Camera.fov, Camera.nearClip, Camera.farClip, Camera.aspectRatio)
	CameraCanvas = love.graphics.newCanvas(GAMEW*setting.renderScale,GAMEH*setting.renderScale)
	CameraCanvas:setFilter("linear", "linear")
	Camera.flipY = (setting.renderScale ~= 1)
	game.updateCamera(dt)
end

--Collision Callbacks
local function normalToAngle(x, y)
	return math.pi+math.atan2(y, x)
end

local function normalToSide(x, y) --normal x, normal y
	if y == 1 then
		return "down"
	elseif y == -1 then
		return "up"
	elseif x == 1  then
		return "right"
	elseif x == -1 then
		return "left"
	end
	return normalToAngle(x, y)
end
function worldBeginContact(f1, f2, coll)
	local p1, p2 = f1:getUserData(), f2:getUserData()
	--collision callbacks
	local nx, ny = coll:getNormal()
	if p1.contact then
		p1:contact(normalToAngle(nx, ny), p2:getName(), p2, f1, f2)
	end
	if p2.contact then
		p2:contact(normalToAngle(-nx, -ny), p1:getName(), p1, f2, f1)
	end
end

function worldEndContact(f1, f2, coll)
	local p1, p2 = f1:getUserData(), f2:getUserData()
	--collision callbacks
	local nx, ny = coll:getNormal()
	if p1.unContact then
		p1:unContact(normalToAngle(nx, ny), p2:getName(), p2, f1, f2)
	end
	if p2.unContact then
		p2:unContact(normalToAngle(-nx, -ny), p1:getName(), p1, f2, f1)
	end
end

function worldPreSolve(f1, f2, coll)
	local p1, p2 = f1:getUserData(), f2:getUserData()
	--ignore "deleted" objects
	if p1.DELETED or p2.DELETED then
		coll:setEnabled(false)
	end
	--collision callbacks
	local nx, ny = coll:getNormal()
	coll:setFriction(math.max(p1.friction or 0,p2.friction or 0))
	coll:setRestitution(math.max(p1.restitution or 0,p2.restitution or 0) )
	if p1:collide(normalToAngle(nx, ny), p2:getName(), p2) == false or p2:collide(normalToAngle(-nx, -ny), p1:getName(), p1) == false then
		coll:setEnabled(false)
	end
end

function worldPostSolve(a, b, coll, normalimpulse, tangentimpulse)
end

--ROOM STATE RECORDING--
recordRate = 0.25 --Rate at which the state of the room is recorded
local recordMaxLength = 25 --How long you can rewind (seconds)
local recordTimer
rewindRate = 0.08 --Rate at which the state of the room is re-established
local rewindTimer
local roomMemories
local changedObj --Table of what properties have changed
function initializeRecording()
	recordTimer = 0
	rewindTimer = 0
	rewindProgress = 0
	rewindRecordingLength = 0
	roomMemories = {}
	changedObj = false
end
local props = {"x","y","angle","vx","vy","facingAngle","walkTimer","collected","grabbing","filled","fillValue","riding"}
function recordRoom(recording)
	local rm = roomMemories
	local m --memory of current state
	if not recording then
		m = {} --don't skip if not recording
	end
	if recording and (not changedObj) then
		changedObj = {}
	end
	local changes = changedObj
	for a, objtable in pairs(OBJ) do
		if a ~= "Walls" and (recording or a ~= "Player") then
			for i, b in pairs(objtable) do
				local objStore

				if recording and (not changes[b]) then
					changes[b] = {}
				end
				for propi = 1, #props do
					local prop = props[propi]
					if recording or ((a ~= "Door" or prop == "locked") and (prop ~= "vx" and prop ~= "vy") and (not b.grabbed)) then
						--only store if property changed
						local oldV
						if recording then
							oldV = changedObj[b][prop]
						end
						local newV = b[prop]
						if type(newV) == "function" then
							error(prop)
						end
						--special properties
						if prop == "x" then
							newV = b:getX()
						elseif prop == "y" then
							newV = b:getY()
						elseif prop == "angle" then
							if b.angle then
								newV = b.angle
							else
								newV = b:getAngle()
							end
						elseif prop == "vx" then
							local vx, vy = b:getLinearVelocity()
							newV = vx
						elseif prop == "vy" then
							local vx, vy = b:getLinearVelocity()
							newV = vy
						elseif prop == "grabbing" then
						end
						--check if changed (if recording)
						if (not recording) or
							((newV ~= nil) and ((oldV == nil) or (oldV ~= newV))) then
							if (not objStore) then
								objStore = {}
								objStore.objtable = a
								objStore.objNum = i
							end
							if (newV ~= nil) and (oldV == nil) then
								objStore[prop] = newV
							else
								objStore[prop] = oldV --actually record old state?
							end
							if recording then
								changes[b][prop] = newV
							end
						end
					end
				end
				
				if objStore then
					--Did anything change?
					if recording and (not m) then
						m = {}
					end
					table.insert(m, objStore)
				end
			end
		end
	end
	if recording then
		--Only record changed properties. For REWINDING
		if #rm/(1/recordRate) > recordMaxLength then
			--Recording is too long
			table.remove(rm, 1)
		end
		if not m then
			--don't add anything to recording if nothing changed
			table.insert(rm, false)
		else
			table.insert(rm, m)
		end
	else
		--Record every property. For long-term saving
		return m
	end
end

function recordingRoom(dt)
	recordTimer = recordTimer + dt
	while recordTimer > recordRate do
		recordRoom("recording")
		recordTimer = recordTimer - recordRate
	end
end

function restoreRoom(recording, state)
	local lastFrame = false
	if recording and #roomMemories < 1 then
		--nothing to rewind!
		REWINDENDED = true
		return false
	elseif recording and #roomMemories == 1 then
		lastFrame = true
	end
	local rm = roomMemories
	local m
	--Rewind room state (Short-Term)
	if recording then
		m = roomMemories[#roomMemories]
	else
	--Load room state (Long-Term)
		m = state
	end

	if m then
		for j, objStore in pairs(m) do
			local a = objStore.objtable
			local objNum = objStore.objNum
			local b = OBJ[a][objNum or 1]

			if b then
				for prop, newV in pairs(objStore) do
					--special properties
					if prop == "objtable" or prop == "objNum" then
					elseif prop == "x" then
						b:setX(newV)
					elseif prop == "y" then
						b:setY(newV)
					elseif prop == "angle" then
						if b.angle then
							b.angle = newV
						end
						b:setAngle(newV)
					elseif prop == "collected" then
						if newV then
							b:collect(recording)
						else
							b:unCollect()
						end
					elseif prop == "locked" then
						if newV then
							b:lock()
						else
							b:unlock()
						end
					elseif prop == "grabbing" then
						if recording then
							if newV and (not lastFrame) then
								b:grab(newV:getName(),newV)
							elseif newV == false then
								b:drop()
							end
						end
					else
						b[prop] = newV
					end
				end
			
				if objStore.vx or objStore.vy then
					local vx, vy = b:getLinearVelocity()
					b:setLinearVelocity(objStore.vx or vx, objStore.vy or vy)
				end
			else
				--object doesn't exist for some reason?
			end
		end
	end

	if recording then
		table.remove(rm, #rm)
	end
end

function rewindRoom(initial, dt)
	if initial then
		rewindRecordingLength = #roomMemories
		rewindProgress = #roomMemories
		changedObj = false
	end
	rewindProgress = math.max(0, rewindProgress - dt/rewindRate)

	rewindTimer = rewindTimer + dt
	while rewindTimer > rewindRate do
		restoreRoom("recording")
		rewindTimer = rewindTimer - rewindRate
	end
end

function makePoof(x, y, z)
	table.insert(POOFS, Poof:new(x,y,z))
end
