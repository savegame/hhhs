menu = {}

local transitionIn, transitionOut, transitionTo = false, false, "game"
local transitionTime = 0.2

local mainlist = {
	{text="Continue", select=function() transitionTo = "game"; transitionOut = 0 end},
	{text="New Game", select=function() defaultSave(); transitionTo = "game"; transitionOut = 0 end},
	{text="Settings", select=function() settings:open() end},
	{text="Quit", select=function() love.event.quit() end},
}
local selected = 1
local skyboxTurn = 0.5
local skybox
local logo
local firstFrame = true --set delta time to 0 on first frame

function menu.load()
	skybox = love.graphics.newCubeImage("assets/skybox.png")
	skybox:setFilter("linear", "linear")
	logo = love.graphics.newImage("graphics/logo.png")
	logo:setFilter("linear", "linear")
	Camera = CameraObj:new(GAMEW/GAMEH, {farClip=100, flipY=false, skybox=true})
	Camera:setFOV(1.6)
	transitionIn = transitionTime
	firstFrame = true
end

function menu.update(dt)
	if firstFrame then
		firstFrame = false
		dt = 0
	end

	--Background
	skyboxTurn = (skyboxTurn + 0.01*dt)%1
	local mx, my = love.mouse.getPosition()
	local vtilt = ((my/WINH)-0.5)*0.08
	Camera:set(0,0,0, skyboxTurn*math.pi*2,-(0.25+vtilt))
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
			if transitionTo == "game" then
				skybox:release()
				skybox = nil
				logo:release()
				logo = nil
				setgamestate("game")
			end
			return false
		end
	end
end

function menu.draw()
	--Background
	love.graphics.setMeshCullMode("back")
	love.graphics.setColor(1,1,1)
	SetActiveCamera(Camera)
	Camera:drawSkyBox(model.skybox, skybox)

	--Logo
	local scale = assetScale
	love.graphics.setColor(1,1,1)
	love.graphics.draw(logo,40*scale,30*scale,0,scale*0.2,scale*0.2)
	
	--Main List of Options
	love.graphics.setFont(textFont[scale])
	local fontHeight = textFont[scale]:getHeight()
	local spacing = 10*scale
	local bottomPadding = 25*scale
	for i, t in ipairs(mainlist) do
		love.graphics.setColor(0,0,0,0.8)
		love.graphics.print(TEXT[t.text], 50*scale, GAMEH-((fontHeight+spacing)*#mainlist)-bottomPadding + (fontHeight+spacing)*(i-1)+2*scale)
		if selected == i then
			love.graphics.setColor(1,1,1)
		else
			love.graphics.setColor(0.5,0.5,0.5)
		end
		love.graphics.print(TEXT[t.text], 50*scale, GAMEH-((fontHeight+spacing)*#mainlist)-bottomPadding + (fontHeight+spacing)*(i-1))
	end
	love.graphics.setColor(1,1,1,0.5)
	love.graphics.print("Alesan99", WINW-textFont[scale]:getWidth("Alesan99")-20*scale, WINH-fontHeight-10*scale)

	--Transition
	if transitionIn then
		love.graphics.setColor(0,0,0,transitionIn/transitionTime)
		love.graphics.rectangle("fill", 0, 0, GAMEW, GAMEH)
	elseif transitionOut then
		love.graphics.setColor(0,0,0,(transitionOut/transitionTime))
		love.graphics.rectangle("fill", 0, 0, GAMEW, GAMEH)
	end
end

function menu.keypressed(k)
	if k == "escape" then
		love.event.quit()
		return true
	end
	if transitionIn then
		return false
	end
	if k == "up" then
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
	elseif k == "space" or k == "return" then
		love.buttonpressed("action")
		return true
	end
end

function menu.buttonpressed(b)
	if transitionIn then
		return false
	end
	if b == "action" then
		mainlist[selected].select()
		playSound(sound.click)
	elseif b == "up" then
		selected = selected - 1
		if selected < 1 then
			selected = #mainlist
		end
	elseif b == "down" then
		selected = selected + 1
		if selected > #mainlist then
			selected = 1
		end
	end
end

function menu.mousemoved(x, y, dx, dy)
	if freeCam then
		Camera:firstPersonCameraLook(dx,dy)
	end
	local sel = menu.pauseOver(x, y)
	if sel then
		selected = sel
	end
end

function menu.mousepressed(x, y, b)
	if b == 1 then
		local sel = menu.pauseOver(x, y)
		if sel then
			mainlist[sel]:select()
			playSound(sound.click)
		end
	end
end

function menu.pauseOver(x, y)
	local scale = assetScale
	local fontHeight = textFont[scale]:getHeight()
	local spacing = 10*scale
	local bottomPadding = 25*scale
	for i, t in ipairs(mainlist) do
		local x1, y1 = 50*scale, GAMEH-((fontHeight+spacing)*#mainlist)-bottomPadding + (fontHeight+spacing)*(i-1)+2*scale
		local w1, h1 = textFont[scale]:getWidth(TEXT[t.text])+30*scale, fontHeight
		if x > x1 and y > y1 and x < x1+w1 and y < y1+h1 then
			return i
		end
	end
	return false
end

function menu.resize(w,h)
	--Window resized!
	--Change aspect ratio of Camera
	Camera.aspectRatio = GAMEW/GAMEH
	Camera:updateProjectionMatrix(Camera.fov, Camera.nearClip, Camera.farClip, Camera.aspectRatio)
end