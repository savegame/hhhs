credits = {}

local transitionIn, transitionOut, transitionTo = false, false, "menu"
local transitionTime = 0.6

local firstFrame = true --set delta time to 0 on first frame

local scroll = 0

local creditsRoll = {
	"A game by Alesan99",
	"",
	"",
	"",
	"Made with LÖVE",
	"",
	"",
	"Assets created with Blender",
	"",
	"Libraries Used",
	"Groverburger's 3D Engine",
	"Cirno's Perfect Math Library",
	"Anim9",
	"Inter-Quake Model Loader",
	"",
	"Music",
	"Kevin MacLeod - AcidJazz",
	"Kevin MacLeod - I Knew a Guy",
	"Kevin MacLeod - Off to Osaka",
	"Jesse Spillane - Face Punch",
	"Provided by freemusicarchive.org",
	"",
	"Sound Effects",
	"Eric Matyas (soundimage.org)",
	"freesound.org",
	"",
	"Fonts",
	"Work Sans by Wei Huang",
	"VCR OSD by Riciery Leal",
	"Luckiest Guy by Astigmatic",
	"",
	"Special Thanks",
	"opengl-tutorial.org",
	"learnopengl.com",
	"",
	"",
	"",
	"THE END"
}
local scrollSpeed = 0.1
local scrollingStop = 5.95
local creditsEnd = 6.15
local logo

function credits.load()
	love.graphics.setBackgroundColor(0,0,0)
	transitionIn = transitionTime
	firstFrame = true

	logo = love.graphics.newImage("graphics/logo.png", {mipmaps=true})
	logo:setFilter("linear", "linear")

	music.credits:stop()
	music.credits:play()
	music.credits:setVolume(1)
	if not music.credits:isPlaying() then
		music.credits:play()
	end

	scroll = 0
end

function credits.update(dt)
	if firstFrame then
		firstFrame = false
		dt = 0
	end

	local mult = 1
	if buttonIsDown("action") then
		mult = 5
	end
	scroll = scroll + scrollSpeed*mult*dt
	if scroll > creditsEnd and not transitionOut then
		transitionOut = 0
	end

	--Transitions
	if transitionIn then
		transitionIn = transitionIn - dt
		if transitionIn < 0 then
			transitionIn = false
			return false
		end
	elseif transitionOut then
		transitionOut = transitionOut + dt
		music.credits:setVolume(math.max(0,1-(transitionOut/transitionTime)))
		if transitionOut > transitionTime then
			transitionOut = false
			if transitionTo == "menu" then
				logo:release()
				logo = nil
				setgamestate("menu")
				music.credits:stop()
			end
			return false
		end
	end
end

function credits.draw()
	--Credits
	local scale = assetScale
	local scale2 = WINH/DEFAULTWINH
	love.graphics.setFont(textFont[scale])
	local topPadding = 800*scale2
	local spacing = 100 *scale2
	local scrolling = math.min(scrollingStop,scroll)*DEFAULTWINH*scale2
	for i, text in ipairs(creditsRoll) do
		local y = topPadding+spacing*i-scrolling
		if y > -textFont[scale]:getHeight() and y < WINH then
			local textToDraw = text
			if TEXT[text] then
				textToDraw = TEXT[text]
			end
			love.graphics.printf(textToDraw,0,y,WINW,"center")
		end
	end
	--Logo
	local y = 160*scale2-math.max(0,scrolling-100*scale2)
	if y > -logo:getHeight() and y < WINH then
		love.graphics.draw(logo,WINW/2,y,0,scale2*0.6,scale2*0.6,logo:getWidth()/2,0)
	end


	--Transition
	if transitionIn then
		--love.graphics.setColor(0,0,0,transitionIn/transitionTime)
		--love.graphics.rectangle("fill", 0, 0, GAMEW, GAMEH)
	elseif transitionOut then
		love.graphics.setColor(0,0,0,(transitionOut/transitionTime))
		love.graphics.rectangle("fill", 0, 0, GAMEW, GAMEH)
	end
end

function credits.keypressed(k)
end

function credits.buttonpressed(b)
end

function credits.mousemoved(x, y, dx, dy)
end

function credits.mousepressed(x, y, b)
end