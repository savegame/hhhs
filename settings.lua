--Pop-up settings settings so you can open it up mid-game
--This is the most monotonous process good lord
settings = {}

local popupWidth = 380
local popupHeight = 256
local blinking = 0
local settingBlinking = 0
CONTROLBINDING = false
local bindDelay = false
local windowChanged = false
local renderScaleChanged = false
local qualityChanged = false
local repeatDelay = 0.4
local repeatRate = 0.1

--INDIVIDUAL SETTING--
local Setting = class("Setting")
function Setting:initialize(name,list,display,var)
	self.name = name
	self.var = var
	if type(list) == "table" then
		self.type = "list"
		self.list = list
		self.display = display
	elseif list == "bind" then
		self.type = "bind"
	elseif list == "inputDevice" then
		self.type = "inputDevice"
	elseif list == "slider" then
		self.type = "slider"
	elseif type(list) == "function" then
		self.func = list
		self.type = "button"
	end
end
function Setting:refresh()
	if self.var then
		self.target = setting[self.var]
	end
	if self.type == "list" then
		self.i = 1
		for i, t in pairs(self.list) do
			if self.target == t then
				self.i = i
				break
			end
		end
	elseif self.type == "slider" then
		self.v = self.target
	elseif self.type == "inputDevice" then
		
	end
end
function Setting:test(v)
	if v > 0 then
		if self.type == "list" then
			return self.i ~= #self.list
		elseif self.type == "slider" then
			return self.v < 1
		end
	elseif v < 0 then
		if self.type == "list" then
			return self.i ~= 1
		elseif self.type == "slider" then
			return self.v > 0
		end
	end
	return false
end
function Setting:change(v,dt)
	if v == 0 then
		if self.type == "button" then
			self.func()
			playSound(sound.click)
		elseif self.type == "bind" then
			blinking = 0
			CONTROLBINDING = self.var
			bindDelay = true
		elseif self.type == "list" then
			local oldi = self.i
			self.i = math.min(#self.list, self.i + 1)
			if self.i ~= oldi then
				self.target = self.list[self.i]
				playSound(sound.click)
			end
		end
	elseif v > 0 then
		if self.type == "list" then
			local oldi = self.i
			self.i = math.min(#self.list, self.i + 1)
			if self.i ~= oldi then
				self.target = self.list[self.i]
				playSound(sound.click)
			end
		elseif self.type == "slider" then
			self.v = math.min(1, self.v+v*dt)
			love.audio.setVolume(self.v)
			if self.v ~= self.target then
				playSound(sound.click)
			end
			self.target = self.v
		end
	elseif v < 0 then
		if self.type == "list" then
			local oldi = self.i
			self.i = math.max(1, self.i - 1)
			if self.i ~= oldi then
				self.target = self.list[self.i]
				playSound(sound.click)
			end
		elseif self.type == "slider" then
			self.v = math.max(0, self.v+v*dt)
			love.audio.setVolume(self.v)
			if self.v ~= self.target then
				playSound(sound.click)
			end
			self.target = self.v
		end
	end
end
function Setting:draw()
	if self.type == "inputDevice" then
		if love.joystick.getJoystickCount( ) > 0 then
			return TEXT["Gamepad"]
		else
			return TEXT["Keyboard"]
		end
	elseif self.type == "bind" then
		return self.target
	end
	if self.display then
		if self.type == "list" then
			if self.display[self.i] and TEXT[self.display[self.i]] and self.var ~= "language" then
				return TEXT[self.display[self.i]]
			else
				return self.display[self.i] or "Null"
			end
		end
	else
		if self.type == "list" then return self.list[self.i] or "Null" end
	end
	return "Null"
end
function Setting:apply()
	if not (self.var and setting[self.var] ~= nil) then
		return false
	end
	if self.name == "Resolution" or self.name == "Resolution Scale" or self.name == "V-Sync" or self.name == "Antialiasing" or self.name == "Fullscreen" then
		if setting[self.var] ~= self.target then
			windowChanged = true
		end
	end
	if self.name == "Render Scale" then
		if setting[self.var] ~= self.target then
			renderScaleChanged = true
		end
	end
	if self.var == "graphicsQuality" then
		if setting[self.var] ~= self.target then
			qualityChanged = true
		end
	end
	setting[self.var] = self.target
end

local tabs = {"General", "Controls"}
local contents = {
	{   Setting:new("Language",{"en","es","pt"},{"English","Español","Português"},"language"),
		Setting:new("Resolution",{1,2,3,4,5},{"640x360","1280x720","1920x1080","2560x1440","3840x2160"},"resolution"),
		Setting:new("Fullscreen",{false,true},{"No","Yes"},"fullscreen"),
		Setting:new("V-Sync",{0,1},{"No","Yes"},"vsync"),
		Setting:new("Volume","slider",false,"volume"),
		Setting:new("Graphics Quality",{1,2,3,4,5},{"Lowest","Low","Medium","High","Best"},"graphicsQuality"),
		Setting:new("Render Scale",{0.5,0.6,0.75,0.9,1,2},{"50%","60%","75%","90%","100%","200%"},"renderScale"),
		Setting:new("Antialiasing",{0,1,2,4,8,16},false,"antialiasing"),
		Setting:new("Change Controls",function() settings.sel = 1; settings.sel2 = 1; settings.tab = 2 end),
		save = {
			{"OK",function() settings:close("apply"); saveSettings() end},
			{"Cancel",function() settings:close() end},
			{"Apply",function() settings:apply(); saveSettings() end}}
	},
	{   Setting:new("Input Device",{"keyboard","gamepad"},{"Keyboard","Gamepad"},"controlInput"),
		Setting:new("Left","bind",nil,"left"),
		Setting:new("Right","bind",nil,"right"),
		Setting:new("Up","bind",nil,"up"),
		Setting:new("Down","bind",nil,"down"),
		Setting:new("Select / Grab","bind",nil,"action"),
		Setting:new("Rewind","bind",nil,"rewind"),
		--Setting:new("Back","bind",nil,"action"),
		Setting:new("Pause","bind",nil,"pause"),
		save = {
			{"Back",function() settings.sel2 = 1; settings.tab = 1 end},
			{"Reset",function() defaultControls() end}}},
}

--SETTINGS MENU--

settings = {}

function settings:open()
	windowChanged = false
	renderScaleChanged = false
	qualityChanged = false

	--Pop-Up
	self.opened = true
	self.alpha = 1
	self.s = assetScale
	self.w = popupWidth*self.s
	self.h = popupHeight*self.s
	self.x = (GAMEW-self.w)/2
	self.y = (GAMEH-self.h)/2

	--Selection
	self.sel = 1 --Main
	self.sel2 = 1 --OK, Cancel, Apply

	--Update the settings menu to reflect current settings
	for i1 = 1, #contents do
		for j, w in ipairs(contents[i1]) do
			w:refresh()
		end
	end

	--Repeat button presses
	self.repeatButton = false
	self.repeatTimer = repeatDelay

	self.tab = 1
end

function settings:close(apply)
	if apply then
		self:apply()
	end
	self.opened = false
end

function settings:update(dt)
	if bindDelay then
		bindDelay = false
	end
	if CONTROLBINDING then
		settingBlinking = 0.5
	else
		settingBlinking = (settingBlinking + dt)%1
	end
	--Blinking of control CONTROLBINDING input
	blinking = (blinking + 1.2*dt)%1

	--Repeat button presses if held down
	if self.repeatButton and (not CONTROLBINDING) then
		if buttonIsDown(self.repeatButton) then
			self.repeatTimer = self.repeatTimer - dt
			while self.repeatTimer < 0 do
				self.repeatTimer = self.repeatTimer + repeatRate
				self:buttonpressed(self.repeatButton, "repeated")
			end
		else
			self.repeatButton = false
		end
	end
	
	--Update Pop-Up
	self.s = assetScale
	self.w = popupWidth*self.s
	self.h = popupHeight*self.s
	self.x = (GAMEW-self.w)/2
	self.y = (GAMEH-self.h)/2
end

function settings:draw()
	local a = self.alpha
	local s = self.s
	local w = self.w
	local h = self.h
	local x = self.x
	local y = self.y
	love.graphics.push()
	love.graphics.translate(math.floor(x),math.floor(y))
	--Pop-Up
	love.graphics.setColor(0.1,0.1,0.15,0.85*a)
	love.graphics.rectangle("fill",0,0,w,h)
	love.graphics.setColor(1,1,1,a)
	love.graphics.setLineWidth(s)
	love.graphics.rectangle("line",s/2,s/2,w-s,h-s)
	local font = smallFont[s]
	love.graphics.setFont(font)
	--Options
	for i,t in ipairs(contents[self.tab]) do
		if i == self.sel then
			love.graphics.setColor(0.6,0.6,0.7,0.3*(0.7+math.sin(settingBlinking*math.pi)*0.3)*a)
			love.graphics.rectangle("fill",0,(12+24*(i-1))*s,w,22*s)
			love.graphics.setColor(1,1,1,a)
		else
			love.graphics.setColor(0.6,0.6,0.7,a)
		end
		if t.type == "button" then
			love.graphics.print(TEXT[t.name],(w-font:getWidth(TEXT[t.name]))/2,(14+24*(i-1))*s)
		else
			love.graphics.print(TEXT[t.name],w/2-font:getWidth(TEXT[t.name])-(24*s),(14+24*(i-1))*s)
			if t.type == "slider" then
				local v = t.v
				local len = 102
				love.graphics.rectangle("fill",((264-len*0.5)*s),(21+24*(i-1))*s,len*v*s,6*s)
				love.graphics.setColor(0.5,0.5,0.6,a)
				love.graphics.rectangle("fill",((264-len*0.5+len*v)*s),(21+24*(i-1))*s,len*(1-v)*s,6*s)
				if t:test(-1) then
					love.graphics.print("<",(264*s)-(len*s)/2-font:getWidth("< "),(14+24*(i-1))*s)
				end
				if t:test(1) then
					love.graphics.print(" >",(264*s)+(len*s)/2,(14+24*(i-1))*s)
				end
			elseif t.type == "bind" then
				if i == self.sel and CONTROLBINDING then
					love.graphics.setColor(1,1,1,math.sin(blinking*math.pi)*a)
					love.graphics.print("_",(264*s)-font:getWidth("_")/2,(14+24*(i-1))*s)
				else
					local ctrlstr = controls[t.var] or "Null"
					if type(ctrlstr) == "table" then
						ctrlstr = ctrlstr[1]
					end
					love.graphics.print(ctrlstr,(264*s)-font:getWidth(ctrlstr)/2,(14+24*(i-1))*s)
				end
			else
				local text = t:draw()
				love.graphics.print(text,(264*s)-font:getWidth(text)/2,(14+24*(i-1))*s)
				if t:test(-1) then
					love.graphics.print("<",(264*s)-font:getWidth(text)/2-font:getWidth("< "),(14+24*(i-1))*s)
				end
				if t:test(1) then
					love.graphics.print(" >",(264*s)+font:getWidth(text)/2,(14+24*(i-1))*s)
				end
			end
		end
	end
	--Save
	local x = 10
	for i = #contents[self.tab].save, 1, -1 do
		local name = TEXT[contents[self.tab].save[i][1]]
		x = x+(font:getWidth(name)/s)+14
		if self.sel == 0 and i == self.sel2 then
			love.graphics.setColor(0.6,0.6,0.7,0.3*(0.7+math.sin(settingBlinking*math.pi)*0.3)*a)
			love.graphics.rectangle("fill",w-(x+5)*s,h-(28)*s,font:getWidth(name)+(11*s),22*s)
			love.graphics.setColor(1,1,1,a)
		else
			love.graphics.setColor(0.6,0.6,0.7,a)
		end
		love.graphics.print(name,w-(x)*s,h-(26)*s)
	end

	love.graphics.pop()
end

function settings:apply()
	for j, w in ipairs(contents[1]) do
		w:apply()
	end
	loadLanguage(setting.language)
	setGraphicsQuality()
	if _G[gamestate].createCamera and qualityChanged then
		game.createCamera()
		game.updateCamera(dt)
		RENDERSINGLEFRAME = true
	end
	if windowChanged then
		createWindow(RESOLUTIONS[setting.resolution][1],RESOLUTIONS[setting.resolution][2])
	else
		love.resize(WINW,WINH)
	end
	love.audio.setVolume(setting.volume)
	windowChanged = false
	renderScaleChanged = false
	qualityChanged = false
end

function settings:keypressed(k)
	if CONTROLBINDING and not bindDelay then
		controls[CONTROLBINDING] = k
		CONTROLBINDING = false
		self.repeatButton = false
		return true
	end
	if k == "return" or k == "space" then
		self:buttonpressed("action")
		return true
	elseif k == "escape" then
		self:close("apply")
		saveSettings()
		return true
	end
end

function settings:joystickBind(joystick, input,j,dir)
	if CONTROLBINDING and not bindDelay then
		controls[CONTROLBINDING] = {input,j,dir}
		CONTROLBINDING = false
		self.repeatButton = false
		return true
	end
end
	
function settings:keyreleased(k)
	if CONTROLBINDING then
		return false
	end
	if k == "return" or k == "space" then
		self:buttonreleased("action")
	end
end
	
function settings:buttonpressed(i, repeated)
	if CONTROLBINDING then
		return false
	end
	
	if not repeated then
		self.repeatButton = i
		self.repeatTimer = repeatDelay
	end

	if i == "down" then
		self.sel = self.sel + 1
		if self.sel > #contents[self.tab] then
			self.sel = 0
		end
	elseif i == "up" then
		self.sel = self.sel - 1
		if self.sel < 0 then
			self.sel = #contents[self.tab]
		end
	elseif i == "left" then
		if self.sel == 0 then
			self.sel2 = math.max(1, self.sel2 - 1)
		elseif contents[self.tab][self.sel] then
			contents[self.tab][self.sel]:change(-1, 0.1)
		end
	elseif i == "right" then
		if self.sel == 0 then
			self.sel2 = math.min(3, self.sel2 + 1)
		elseif contents[self.tab][self.sel] then
			contents[self.tab][self.sel]:change(1, 0.1)
		end
	elseif i == "action" then
		if self.sel == 0 then
			contents[self.tab].save[self.sel2][2]()
			playSound(sound.click)
		elseif contents[self.tab][self.sel] then
			contents[self.tab][self.sel]:change(0, 0.1)
		end
	end
end
	
function settings:buttonreleased(i)
	self.repeatButton = false
	if CONTROLBINDING then
		return false
	end
end

function settings:mousepressed(x, y, button)
	if CONTROLBINDING then
		return false
	end
	local sel, sel2, dir = self:over(x, y)
	if sel then
		self.sel = sel
		if sel2 then
			self.sel2 = sel2
		end
		if self.sel == 0 then
			contents[self.tab].save[self.sel2][2]()
			playSound(sound.click)
		elseif contents[self.tab][self.sel] then
			contents[self.tab][self.sel]:change(dir, 0.1)
		end
	end
end

function settings:mousemoved(x, y, dx, dy)
	if CONTROLBINDING then
		return false
	end
	local sel, sel2 = self:over(x, y)
	if sel then
		self.sel = sel
	end
	if sel2 then
		self.sel2 = sel2
	end
	self.repeatButton = false
end

function settings:over(mx, my)
	--Options
	local s = self.s
	local w = self.w
	local h = self.h
	local x = self.x
	local y = self.y
	local font = smallFont[s]

	local mx, my = mx-x, my-y

	local dir = -1
	if mx > 264*s then
		dir = 1
	end
	for i,t in ipairs(contents[self.tab]) do 
		if mx > 0 and my > 11*s+(24*s)*(i-1) and mx < w and my < 11*s+(24*s)*(i) then
			if contents[self.tab][i].type == "button" or contents[self.tab][i].type == "bind" then
				dir = 0
			end
			return i, false, dir
		end
	end

	local x = 10
	for i = #contents[self.tab].save, 1, -1 do
		local name = TEXT[contents[self.tab].save[i][1]]
		x = x+(font:getWidth(name)/s)+14
		local x1, y1, w1, h1 = w-(x+5)*s, h-(28)*s, font:getWidth(name)+(11*s), 22*s
		if mx > x1 and my > y1 and mx < x1+w1 and my < y1+h1 then
			return 0, i, 0
		end
	end

	return false, false, 0
end