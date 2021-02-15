Door = class("Door", PhysObj)

function Door:initialize(x, y, room, targetRoom, r, locked, doorID, i)
	--Body
	self.x = 0
	self.y = 0
	self:createBody("obj_COL", objfile.door["Door_COL"])
	self:setLinearDamping(20)
	self:setAngularDamping(80)
	self:setAngle(r)
	if r == 0 then
		self:setPosition(x+0.5, y+0.5)
	elseif r == math.pi*0.5 then
		self:setPosition(x-0.5, y+0.5)
	elseif r == math.pi then
		self:setPosition(x-0.5, y-0.5)
	elseif r == math.pi*1.5 then
		self:setPosition(x+0.5, y-0.5)
	end

	--create joint connected to walls of the room
	if r == 0 then
		self.joint = love.physics.newRevoluteJoint(self.body, room.body, x+0.5, y+(0.5-0.1), false)
	elseif r == math.pi*0.5 then
		self.joint = love.physics.newRevoluteJoint(self.body, room.body, x-(0.5-0.1), y+0.5, false)
	elseif r == math.pi then
		self.joint = love.physics.newRevoluteJoint(self.body, room.body, x-0.5, y-(0.5-0.1), false)
	elseif r == math.pi*1.5 then
		self.joint = love.physics.newRevoluteJoint(self.body, room.body, x+(0.5-0.1), y-0.5, false)
	end
	self.joint:setLimits(-math.pi,0)
	self.joint:setLimitsEnabled(true)

	--Model
	self.model = model.door
	self.texture = img.box

	--Logic
	self.target = targetRoom
	self.i = i
	self.doorID = doorID
	self.locked = locked
	if doorID and DOORSUNLOCKED[doorID] then
		self.locked = false
	end

	if self.locked then
		self:lock("initial")
	end
	
	local warpDist = 0.75
	spawnObject("Warp", Warp:new(x+math.sin(-r+math.pi)*warpDist, y+math.cos(-r+math.pi)*warpDist, targetRoom, doorID))
	local poofDist = 0.5
	self.dx = x-math.sin(-r+math.pi)*poofDist
	self.dy = y-math.cos(-r+math.pi)*poofDist
end

function Door:update(dt)
	--Hacky fake Z-movement
	if currentRoom == "foyer" then
		local x, y = self:getPosition()
		if x > 1 then
			self.z = -2.5
		else
			self.z = 0
		end
	end

	local v = self.body:getAngularVelocity()
	if math.abs(v) > 6 and not sound.door:isPlaying() then
		playSound(sound.door)
	end
end

function Door:draw()
	self:drawModel()
	if self.locked then
		local texture = img.lock
		if keyTypes[self.doorID] then
			if keyTypes[self.doorID] == "KeySilver" then
				texture = img.lockSilver
			elseif keyTypes[self.doorID] == "KeyBrown" then
				texture = img.lockBrown
			elseif keyTypes[self.doorID] == "KeyBlack" then
				texture = img.lockBlack
			end
		end
		local x, y = self.body:getPosition()
		model.lock:setTexture(texture)
		model.lock:setRotation(0,self.body:getAngle(),0)
		model.lock:draw(-x,self.z or 0,y)
	end
end

function Door:lock(initial)
	self:setStatic(true)
	if not initial then
		KEYS[self.doorID] = true
		DOORSUNLOCKED[self.doorID] = false
	end
	self.locked = true
end

function Door:tryUnlock()
	if self.locked then
		if KEYS[self.doorID] then
			self:unlock()
			playSound(sound.unlock)
		end
	end
	return false
end

function Door:unlock()
	self:setStatic(false)
	KEYS[self.doorID] = false
	DOORSUNLOCKED[self.doorID] = true
	self.locked = false
	makePoof(self.dx, self.dy, -0.5)
end