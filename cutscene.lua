cutscene = {}

local transitionIn, transitionOut, transitionTo = false, false, "menu"
local transitionTime = 1

local sceneModel, sceneImg
local sceneSounds

local cutSceneTimer, cutSceneEnd
local soundSequence

function cutscene.load(scene)
	if not FFIEXISTS then
		setgamestate("credits")
		return false
	end

	love.graphics.setBackgroundColor(178/255,228/255,255/255)
	transitionIn = transitionTime
	firstFrame = true

	if scene == "ending" then
		sceneImg = love.graphics.newImage("assets/cutscenes/" .. scene .. ".png")
		sceneModel = Model:new("assets/cutscenes/" .. scene .. ".iqm",sceneImg)
		sceneModel:newAnimationTrack("cutscene")
		sceneModel:playAnimation("cutscene")
		cutSceneTimer = 0
		cutSceneEnd = 5.59

		sceneSounds = {}
		sceneSounds.fruitotruck = love.audio.newSource("sounds/fruitotruck.ogg", "static")
		sceneSounds.crash = love.audio.newSource("sounds/crash.ogg", "static")
		sceneSounds.scream = love.audio.newSource("sounds/wilhelm.ogg", "static")
		sceneSounds.scrape = love.audio.newSource("sounds/scrape.ogg", "static")
		sceneSounds.carpass = love.audio.newSource("sounds/carpass.ogg", "static")
		sceneSounds.skid = love.audio.newSource("sounds/skid.ogg", "static")
		sceneSounds.speed = love.audio.newSource("sounds/speed.ogg", "static")

		soundSequence = {
			{0,sceneSounds.fruitotruck},
			{2.4,sound.garagedoorhit},
			{2.45,sceneSounds.carpass},
			{2.8,sceneSounds.scrape},
			{3.7,sceneSounds.skid},
			{4.2,sceneSounds.crash},
			{4.3,sceneSounds.scream},
			{4.45,sceneSounds.speed},
			{4.5,sceneSounds.scrape},
		}
		soundSequenceStage = 1
	end

	--Initialize 3D
	cutscene.createCamera()

	love.graphics.setMeshCullMode("back")
	if freeCam then
		love.mouse.setRelativeMode(true)
	end
end

function cutscene.update(dt)
	if firstFrame then
		firstFrame = false
		dt = 0
	end
	--dt = dt * 0.5
	cutSceneTimer = cutSceneTimer + dt
	--print(cutSceneTimer)
	if soundSequence[soundSequenceStage] and cutSceneTimer > soundSequence[soundSequenceStage][1] then
		playSound(soundSequence[soundSequenceStage][2])
		soundSequenceStage = soundSequenceStage + 1
	end
	if cutSceneTimer > cutSceneEnd then
		sceneModel = nil
		sceneImg:release()
		sceneImg = nil
		setgamestate("credits")
		return true
	end

	cutscene.updateCamera(dt)

	sceneModel:update(dt)

	--Transitions
	if transitionIn then
		transitionIn = transitionIn - dt
		if transitionIn < 0 then
			transitionIn = false
			return false
		end
	elseif transitionOut then
		transitionOut = transitionOut + dt
		if transitionOut > transitionTime then
			transitionOut = false
			if transitionTo == "menu" then
				setgamestate("menu")
			end
			return false
		end
	end
end

local drawScene

function cutscene.draw()
	--Cutscene
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

	--Scene
	if setting.renderScale ~= 1 then
		--Render to canvas under specific circumstances
		love.graphics.setCanvas{CameraCanvas, depth=24}
		love.graphics.clear(178/255,228/255,255/255)
	end
	love.graphics.setMeshCullMode("back")
	Camera:sendShadowMap(Sun)
	SetActiveCamera(Camera)
	love.graphics.setDepthMode("lequal", true)
	drawScene()
	love.graphics.setDepthMode()

	if Camera.aspectRatio > 1.8 then --Screen is too wide
		local targetRatio = 16/9
		local target = WINW-(16/9*WINH)
		love.graphics.setColor(0,0,0)
		love.graphics.rectangle("fill", 0, 0, target/2, WINH)
		love.graphics.rectangle("fill", target/2+WINH*targetRatio, 0, target/2, WINH)
	end
	love.graphics.setCanvas()
	if setting.renderScale ~= 1 then
		love.graphics.draw(CameraCanvas,0,0,0,1/setting.renderScale,1/setting.renderScale)
	end

	--SUN DEBUG	
	--[[love.graphics.setColor(1,1,1)
	if not Sun.camera.options.ortho then --perspective
		love.graphics.setShader(depthview)
	end
	love.graphics.draw(Sun.canvas,0,0,0,0.5,0.5)
	love.graphics.setShader()]]

	--Transition
	if transitionIn then
		love.graphics.setColor(0,0,0,transitionIn/transitionTime)
		love.graphics.rectangle("fill", 0, 0, GAMEW, GAMEH)
	elseif transitionOut then
		love.graphics.setColor(0,0,0,(transitionOut/transitionTime))
		love.graphics.rectangle("fill", 0, 0, GAMEW, GAMEH)
	end
end

function drawScene(light)
	--Draw Scene
	love.graphics.setColor(1,1,1)
	sceneModel:setRotation(math.pi*1.5,math.pi,0)
	sceneModel:draw()
end

function cutscene.createCamera()
	Camera = CameraObj:new(GAMEW/GAMEH, {farClip=100, light=SUNLIGHTVECTOR, forceLight=false, shadow=true, flipY=(setting.renderScale ~= 1), skybox=false, billboard=false})
	Camera:setFOV(math.pi*0.2)
	CameraCanvas = love.graphics.newCanvas(GAMEW*setting.renderScale,GAMEH*setting.renderScale)
	CameraCanvas:setFilter("linear", "linear")
	SetActiveCamera(Camera)

	--Dynamic Shadows
	if setting.shadowMapQuality > 0 then
		Sun = SunLight:new(setting.shadowMapQuality, 16)
	else
		Sun = SunLight:new(256, 16)
		Sun.canvas = img.white
	end
	local v = NormalizeVector(SUNLIGHTROTATEVECTOR)
	--Sun:setDown(v[1],v[2],v[3]) --Spin ShadowMap Canvas around to align with the camera
	Camera:sendShadowMap(Sun)
end

function cutscene.updateCamera(dt)
	--3D Scene
	local targetX, targetY = -3,0
	local targetZ = -1.5

	local cameraX, cameraY, cameraZ = 12.28, 19, -1.9-(cutSceneTimer/cutSceneEnd)*0.3
	if not freeCam then
		--Look at Player
		Camera:setCameraAndLookAt(-cameraX,cameraZ,cameraY,-targetX,targetZ,targetY)
	else
		Camera:firstPersonCameraMovement(dt)
	end

	local sunX, sunY, sunZ = 20, 20, -20
	if setting.shadowMapQuality > 0 then
		Sun:setCameraAndLookAt(-sunX,sunZ,sunY,-targetX,targetZ,targetY)
	end
end

function cutscene.resize()
	--Window resized!
	--Change aspect ratio of Camera
	Camera.aspectRatio = GAMEW/GAMEH
	Camera:updateProjectionMatrix(Camera.fov, Camera.nearClip, Camera.farClip, Camera.aspectRatio)
	CameraCanvas = love.graphics.newCanvas(GAMEW*setting.renderScale,GAMEH*setting.renderScale)
	CameraCanvas:setFilter("linear", "linear")
	Camera.flipY = (setting.renderScale ~= 1)
	cutscene.updateCamera(dt)
end

function cutscene.keypressed(k)
end

function cutscene.buttonpressed(b)
end

function cutscene.mousemoved(x, y, dx, dy)
end

function cutscene.mousepressed(x, y, b)
end