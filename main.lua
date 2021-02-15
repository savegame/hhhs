---------------------------------------------------
--------------------BY ALESAN99--------------------
---------------------------------------------------
--STARTED: 11/1/20 (Worked on 3D a bit before)-----
--FINISHED: 12/24/20 ------------------------------
---------------------------------------------------

local randomize, shallowcopy
local gameCanvas

WEBVERSION = false

local joystick, joystickhats, joystickaxes, joystickhatdown, joystickaxisdown, joystickaxespos, updateJoystick
local joystickhatdown, joystickaxisdown = {}, {}
joystickStickX, joystickStickY, joystickStickDist = false, false
local supported
local debugGraph,fpsGraph,memGraph,drawGraph


-- Touchscreen
local press_id = nil

function love.load()
	randomize()
	
	JSON = require("libs/JSON")
	class = require("libs/middleclass")
	easing = require("libs/easing")
	--debugGraph = require "debugGraph"
	require "libs/g3d"

	require "intro"
	require "game"
	require "menu"
	require "variables"
	require "assets"
	require "languages"
	require "settings"
	require "credits"
	require "cutscene"

	require "objects/phys_obj"
	require "objects/player"
	require "objects/walls"
	require "objects/box"
	require "objects/pile"
	require "objects/basket"
	require "objects/door"
	require "objects/warp"
	require "objects/ball"
	require "objects/bucket"
	require "objects/drips"
	require "objects/key"
	require "objects/poof"
	require "objects/truck"
	require "objects/garagedoor"
	require "objects/stairs"

	supported = love.graphics.getSupported()
	
	--Settings
	love.filesystem.setIdentity("hhhs")
	defaultSettings()
	loadSettings()
	defaultSave()
	loadSave()

	createWindow(RESOLUTIONS[setting.resolution][1],RESOLUTIONS[setting.resolution][2])
	love.window.setIcon(love.image.newImageData("graphics/icon.png"))
	love.window.setTitle("Hoarder's Horrible House of Stuff")

	--Assets
	assets.loadAssets()
	assets.loadGame()
	debugFont = love.graphics.newFont(12)
	
	--[[Performance Debug
	fpsGraph = debugGraph:new('fps', 0, 0)
	memGraph = debugGraph:new('mem', 0, 30)
	drawGraph = debugGraph:new('custom', 0, 60)]]
	
	setgamestate("intro")
end

function love.update(dt)
	updateJoystick()
	if _G[gamestate].update then
		_G[gamestate].update(dt)
	end
	if settings.opened then
		settings:update(dt)
	end
	--[[Update the graphs
	fpsGraph:update(dt)
	memGraph:update(dt)
	drawGraph:update(dt, drawGraph.drawcalls)]]
end

function love.draw()
	--Render Game directly to screen
	love.graphics.setColor(1,1,1)
	love_draw()
	--[[Draw graphs
	local stats = love.graphics.getStats()
	love.graphics.setLineWidth(2)
	drawGraph.label = "Drawcalls: " .. stats.drawcalls
	drawGraph.drawcalls = stats.drawcalls
	fpsGraph:draw()
	memGraph:draw()
	drawGraph:draw()]]
end

function love_draw()
	if _G[gamestate].draw then
		_G[gamestate].draw()
	end

	if settings.opened then
		settings:draw()
	end
end

function love.keypressed(k)
	if k == "return" and love.keyboard.isDown("lalt") then
		--Enter Fullscreen
		setting.fullscreen = not setting.fullscreen
		createWindow()
		return
	end
	if settings.opened then
		if settings:keypressed(k) then
			return true
		end
	else
		if _G[gamestate].keypressed then
			if _G[gamestate].keypressed(k) then
				return true
			end
		end
	end
	for i, ks in pairs(controls) do
		if k == ks then
			love.buttonpressed(i)
		end
	end
end

function love.keyreleased(k)
	if settings.opened then
		settings:keyreleased(k)
	else
		if _G[gamestate].keyreleased then
			_G[gamestate].keyreleased(k)
		end
	end
	
	for i, ks in pairs(controls) do
		if k == ks then
			love.buttonreleased(i)
		end
	end
end

function love.buttonpressed(i)
	if settings.opened then
		settings:buttonpressed(i)
	else
		if _G[gamestate].buttonpressed then
			_G[gamestate].buttonpressed(i)
		end
	end
end

function love.buttonreleased(i)
	if settings.opened then
		settings:buttonreleased(i)
	else
		if _G[gamestate].buttonreleased then
			_G[gamestate].buttonreleased(i)
		end
	end
end

function love.textinput(t)
	if _G[gamestate].textinput then
		_G[gamestate].textinput(t)
	end
end

function love.mousepressed(x, y, button)
	if settings.opened then
		settings:mousepressed(x, y, button)
	else
		if _G[gamestate].mousepressed then
			_G[gamestate].mousepressed(x, y, button)
		end
	end
end

function love.mousereleased(x, y, button)
	if _G[gamestate].mousereleased then
		_G[gamestate].mousereleased(x, y, button)
	end
end

function love.mousemoved(x, y, dx, dy)
	if settings.opened then
		settings:mousemoved(x, y, dx, dy)
	else
		if _G[gamestate].mousemoved then
			_G[gamestate].mousemoved(x, y, dx, dy)
		end
	end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    if press_id == nil then
        press_id = id
		if settings.opened then
			settings:mousepressed(x, y, button)
		else
			if _G[gamestate].mousepressed then
				_G[gamestate].mousepressed(x, y, button)
			end
		end
    end
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    if press_id ~= id then
        return
    end
	if settings.opened then
		settings:mousemoved(x, y, dx, dy)
	else
		if _G[gamestate].mousemoved then
			_G[gamestate].mousemoved(x, y, dx, dy)
		end
	end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    if press_id == id then
        press_id = nil
		if _G[gamestate].mousereleased then
			_G[gamestate].mousereleased(x, y, button)
		end
    end
end

function love.wheelmoved(dx, dy)
	if _G[gamestate].wheelmoved then
		_G[gamestate].wheelmoved(dx, dy)
	end
end

function setgamestate(state, ...)
	love.audio.stop()
	assert(_G[state], "Invalid game state")
	gamestate = state
	local args = {...}
	_G[state].load(unpack(args))
end

function createWindow(w, h)
	w, h = w or WINW, h or WINH
	WINW = w
	WINH = h
	GAMEW = w
	GAMEH = h
	love.window.setMode(w, h, {
		minwidth=WINMINW,
		minheight=WINMINH,
		fullscreen=setting.fullscreen,
		vsync=setting.vsync,
		resizable=true,
		depth=24,
		msaa=setting.antialiasing
	})
	love.resize(w, h)
end

function love.resize(w, h)
	WINW = w
	WINH = h
	GAMEW = w
	GAMEH = h
	if gameCanvas then
		gameCanvas:release()
	end
	assets.updateScale()
	if gamestate and _G[gamestate].resize then
		_G[gamestate].resize(w,h)
	end
end

--Settings
function defaultSettings()
	setting = {}

	--General
	setting.language = "en"
	loadLanguage(setting.language)
	setting.volume = 0.5
	love.audio.setVolume(setting.volume)

	--Graphics
	setting.vsync = 1
	setting.fullscreen = false
	setting.resolution = 2
	setting.renderScale = 1
	setting.graphicsQuality = 4
	setting.shadowMapQuality = 512
	setGraphicsQuality()
	setting.antialiasing = 0

	--Controls
	defaultControls()
end
function defaultControls()
	--default keyboard
	controlsKB = {}
	controlsKB["up"] = "up"
	controlsKB["down"] = "down"
	controlsKB["left"] = "left"
	controlsKB["right"] = "right"

	controlsKB["action"] = "x"
	--controlsKB["back"] = "backspace"

	controlsKB["rewind"] = "z"
	controlsKB["pause"] = "escape"
	--default gamepad
	controlsGP = {}
	controlsGP["up"] = "lefty"
	controlsGP["down"] = "lefty"
	controlsGP["left"] = "leftx"
	controlsGP["right"] = "leftx"

	controlsGP["action"] = "a"
	--controlsGP["back"] = "b"

	controlsGP["rewind"] = "x"
	controlsGP["pause"] = "start"
	--set to keyboard controls automatically
	setting.controlInput = "keyboard"
	controls = shallowcopy(controlsKB)
end

function saveSettings()
	local t = {}
	t.controls = controls
	for i, v in pairs(setting) do
		t[i] = v
	end

	local s = JSON:encode_pretty(t,nil,{pretty=true,indent="	"})
	local success = love.filesystem.write("settings.txt", s)
end

function loadSettings()
	--Exists?
	if not love.filesystem.getInfo("settings.txt") then
		return
	end
	local s = love.filesystem.read("settings.txt")
	if not s then
		print("Could not read settings file!")
		return
	end
	--Load Settings
	local t = JSON:decode(s)
	for name, v in pairs(t) do
		if name ~= "controls" then
			setting[name] = v
		end
	end
	loadLanguage(setting.language)
	love.audio.setVolume(setting.volume)
	setGraphicsQuality()

	--Load Controls
	for a, b in pairs(t.controls) do
		controls[a] = b
	end
end

function setGraphicsQuality()
	if setting.graphicsQuality == 5 then
		setting.shadowMapQuality = 2048
	elseif setting.graphicsQuality == 4 then
		setting.shadowMapQuality = 1024
	elseif setting.graphicsQuality == 3 then
		setting.shadowMapQuality = 512
	elseif setting.graphicsQuality == 2 then
		setting.shadowMapQuality = 0
	elseif setting.graphicsQuality == 1 then
		setting.shadowMapQuality = 0
	end
end

--Save File
function defaultSave()
	ROOMSTATE = {}
	KEYS = {} --Keys
	DOORSUNLOCKED = {}
	currentRoom = "room1"
	currentRoomFrom = false
	currentRoomDoorID = false
	currentMusicTrack = 1
end
function createSave()
	local t = {}
	t.roomState = ROOMSTATE
	t.keys = KEYS
	t.doorsUnlocked = DOORSUNLOCKED
	t.currentRoom = currentRoom
	t.currentRoomFrom = currentRoomFrom
	t.currentRoomDoorID = currentRoomDoorID
	t.currentMusicTrack = currentMusicTrack

	local s = JSON:encode_pretty(t,nil,{pretty=true,indent="	"})
	local success = love.filesystem.write("save", s)
end

function loadSave()
	--Exists?
	if not love.filesystem.getInfo("save") then
		return
	end
	local s = love.filesystem.read("save")
	if not s then
		print("Could not read save file!")
		return
	end
	--Load Save
	local t = JSON:decode(s)
	ROOMSTATE = t.roomState
	KEYS = t.keys
	DOORSUNLOCKED = t.doorsUnlocked
	currentRoom = t.currentRoom
	currentRoomFrom = t.currentRoomFrom
	currentRoomDoorID = t.currentRoomDoorID
	currentMusicTrack = t.currentMusicTrack or 1
end

--https://stackoverflow.com/questions/1426954/split-string-in-lua
function string:split(sep)
	sep = sep or '%s'
	local t = {}
	for field, self in string.gmatch(self, "([^"..sep.."]*)("..sep.."?)") do
		table.insert(t,field)
		if self == "" then
			return t
		end
	end
end

function playSound(sound, stopCurrent)
	if not stopCurrent then
		sound:stop()
	end
	sound:play()
end

function randomize()
	math.randomseed(os.time())
	for i = 1, 5 do
		math.random()
	end
end

function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

--badly rushed joystick implementation, no really, there's a lot of hack-y stuff here
--TODO: Improved a tiny bit, but still redo this
function love.joystickadded(j)
	joystick = j
	joystickhats = joystick:getHatCount() --buttons
	joystickaxes = joystick:getAxisCount() --sticks
	joystickhatdown = {}
	joystickaxisdown = {}
	joystickaxespos = {}
	for j = 1, joystickhats do
		joystickhatdown[j] = false
	end
	for j = 1, joystickaxes do
		joystickaxisdown[j] = false
		joystickaxespos[j] = joystick:getAxis(j)
	end
	setting.controlInput = "gamepad"
end
function love.joystickpressed(joystick, button)
	for i, k in pairs(controls) do
		if type(k) == "table" then
			local t = k[1]--input type
			local b = k[2] or 1 --button
			if t == "button" and button == b and not CONTROLBINDING then
				love.buttonpressed(i)
				--if getinversion() ~= v then idk why this was in invertio
					break
				--end
			end
		end
	end
	if CONTROLBINDING then
		settings:joystickBind(joystick, "button", button, false)
	end
	if _G[gamestate].joystickpressed then
		_G[gamestate].joystickpressed(joystick, button)
	end
end
function love.joystickreleased(joystick, button)
	for i, k in pairs(controls) do
		if type(k) == "table" then
			local t = k[1]--input type
			local b = k[2] or 1 --button
			if t == "button" and button == b then
				love.buttonreleased(i)
			end
		end
	end
	if _G[gamestate].joystickreleased then
		_G[gamestate].joystickreleased(joystick, button)
	end
end

function updateJoystick()
	if joystick then
		--Joystick Angle
		joystickStickX, joystickStickY = false, false
		for i, k in pairs(controls) do --is there any axes?
			if type(k) == "table" then
				local t = k[1]
				local b = k[2] or 1
				local d = k[3]
				if t == "axis" then
					joystickStickX, joystickStickY = 0, 0
					break
				end
			end
		end
		if joystickStickX then
			for j = 1, joystickaxes do
				local p = joystick:getAxis(j)
				if not CONTROLBINDING then
					local control = false
					local dir = false
					for i, k in pairs(controls) do
						if type(k) == "table" then
							local t = k[1]
							local b = k[2] or 1
							local d = k[3]
							if t == "axis" and j == b then
								dir = d
								control = i
								break
							end
						end
					end
					if control == "right" then
						joystickStickX = joystickStickX + p
					elseif control == "down" then
						joystickStickY = joystickStickY - p
					end
				end
			end
			joystickStickDist = 0
			if not (joystickStickX == 0 and joystickStickY == 0) then
				joystickStickDist = math.sqrt(joystickStickX*joystickStickX + joystickStickY*joystickStickY)
			end
		end
		--Trigger button inputs
		for j = 1, joystickhats do
			local dir = joystick:getHat(j)
			if dir ~= "c" then
				if not CONTROLBINDING then
					if joystickhatdown[j] ~= true then
						local control = false
						for i, k in pairs(controls) do
							if type(k) == "table" then
								local t = k[1]
								local b = k[2] or 1
								local d = k[3]
								if t == "hat" and j == b and d == joystick:getHat(j) then control = i break end
							end
						end
						if control then
							love.buttonpressed(control)
						end
					end
				else
					settings:joystickBind(joystick, "hat", j, dir)
				end
				joystickhatdown[j] = true
			else
				if joystickhatdown[j] == true then
					local control = false
					for i, k in pairs(controls) do
						if type(k) == "table" then
							local t = k[1]
							local b = k[2] or 1
							local d = k[3]
							if t == "hat" and j == b and d == joystick:getHat(j) then control = i break end
						end
					end
					if control then
						love.buttonreleased(control)
					end
				end
				joystickhatdown[j] = false
			end
		end
		
		for j = 1, joystickaxes do
			local p = joystick:getAxis(j)
			if p > joystickaxespos[j] + DEADZONE then
				if not CONTROLBINDING then
					if joystickaxisdown[j] ~= true then
						local control = false
						for i, k in pairs(controls) do
							if type(k) == "table" then
								local t = k[1]
								local b = k[2] or 1
								local d = k[3]
								if t == "axis" and j == b and d == "pos" then control = i break end
							end
						end
						if control then
							love.buttonpressed(control)
						end
					end
				else
					settings:joystickBind(joystick, "axis", j, "pos")
				end
				joystickaxisdown[j] = true
			elseif p < joystickaxespos[j] - DEADZONE then
				if not CONTROLBINDING then
					if joystickaxisdown[j] ~= true then
						local control = false
						for i, k in pairs(controls) do
							if type(k) == "table" then
								local t = k[1]
								local b = k[2] or 1
								local d = k[3]
								if t == "axis" and j == b and d == "neg" then control = i break end
							end
						end
						if control then
							love.buttonpressed(control)
						end
					end
				else
					settings:joystickBind(joystick, "axis", j, "neg")
				end
				joystickaxisdown[j] = true
			else
				if joystickaxisdown[j] == true then
					local control = false
					for i, k in pairs(controls) do
						if type(k) == "table" then
							local t = k[1]
							local b = k[2] or 1
							local d = k[3]
							if t == "axis" and j == b then control = i break end
						end
					end
					if control then
						love.buttonreleased(control)
					end
				end
				joystickaxisdown[j] = false
			end
		end
	end
end

function buttonIsDown(b)
	if type(controls[b]) == "table" then
		if joystick then
			local c = controls[b]
			local t = c[1]
			local i = c[2] or 1
			local d = c[3]
			if t == "hat" then
				local dir = joystick:getHat(i)
				if dir == d then return true else return false end
			elseif t == "axis" then
				local p = joystick:getAxis(i)
				if d == "pos" and p > joystickaxespos[i] + DEADZONE then
					return true
				elseif d == "neg" and p < joystickaxespos[i] - DEADZONE then
					return true
				else return false end
			elseif t == "button" then
				return joystick:isDown(i)
			end
		end
	else
		return love.keyboard.isDown(controls[b])
	end
end

--https://stackoverflow.com/questions/15429236/how-to-check-if-a-module-exists-in-lua
function isModuleAvailable(name)
	if package.loaded[name] then
	  return true
	else
	  for _, searcher in ipairs(package.searchers or package.loaders) do
		local loader = searcher(name)
		if type(loader) == 'function' then
		  package.preload[name] = loader
		  return true
		end
	  end
	  return false
	end
end

FFIEXISTS = isModuleAvailable("ffi")