Bucket = class("Bucket", PhysObj)

function Bucket:initialize(x, y, doorID)
	--Body
	self.x = 0
	self.y = 0
	self.z = 0
	self.w = 0.95
	self.h = 0.95
	self.bevel = 0.3
	local x1, x2, x3, x4 = -(self.w/2),-(self.w/2-self.bevel),(self.w/2-self.bevel),(self.w/2)
	local y1, y2, y3, y4 = -(self.h/2),-(self.h/2-self.bevel),(self.h/2-self.bevel),(self.h/2)
	self:createBody("polygon", x2,y1, x3,y1, x4,y2, x4,y3, x3,y4, x2,y4, x1,y3, x1,y2)
	self:setLinearDamping(15)
	self.body:setFixedRotation(true)
	self:setMass(1)

	self:setPosition(x, y)

	--Model
	self.model = model.bucket
	self.texture = img.texture

	self.filling = false
	self.fillValue = 0

	self.doorID = doorID
	self.collected = false
end

function Bucket:update(dt)
	if self.filling and not REWINDING then
		self.fillValue = math.min(1, self.fillValue + dt)
		if self.fillValue >= 1 and not self.collected then
			self:collect()
			local x, y = self:getPosition()
			makePoof(x, y, self.z-1)
		end
	end
	
	self.pushing = false
	if self.touching then
		local vx, vy = self.body:getLinearVelocity()
		if (vx)*(vx)+(vy)*(vy) > 1 then
			self.pushing = true
		end
	end
end

function Bucket:draw()
	local x, y = self.body:getPosition()
	self:drawModel()
	local fillRange = 0.75
	local fillStart = 0.1
	if self.fillValue > 0 then
		model.bucketWater:draw(-x,self.z-fillStart-self.fillValue*fillRange,y)
	end
	if not self.collected then
		local texture = img.key
		if keyTypes[self.doorID] then
			if keyTypes[self.doorID] == "KeySilver" then
				texture = img.keySilver
			elseif keyTypes[self.doorID] == "KeyBlack" then
				texture = img.keyBlack
			end
		end
		model.key:setTexture(texture)
		model.key:setScale(0.75,0.75,0.75)
		model.key:setRotation(0,math.pi*0.6,0)
		model.key:draw(-x,self.z-fillStart-math.max(0, self.fillValue-0.1)*fillRange-0.1,y)
	end
end

function Bucket:contact(side, a, b)
	if a == "Drips" then
		self.filling = true
		if (not REWINDING) and self.fillValue < 0.5 then
			playSound(sound.water)
		end
	end
	if a == "Player" then
		self.touching = true
	end
end

function Bucket:unContact(side, a, b)
	if a == "Drips" then
		self.filling = false
	end
	if a == "Player" then
		self.touching = false
	end
end

function Bucket:collide(side, a, b)
end

function Bucket:collect()
	if self.collected then
		return false
	end

	self.collected = true
	if not DOORSUNLOCKED[self.doorID] then
		KEYS[self.doorID] = true
		keyWiggle = 0
		playSound(sound.key)
	end
	return true
end

function Bucket:unCollect()
	--Rewind
	KEYS[self.doorID] = false
	self.collected = false
	return true
end