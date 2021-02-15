Key = class("Key", PhysObj)

function Key:initialize(x, y, t, r, doorID, i)
	--Body
	self.x = 0
	self.y = 0
	self.z = 0
	self:createBody("obj_COL", objfile.key["Key_COL"])
	self:setLinearDamping(40)
	self:setAngularDamping(80)
	self:setStatic(false)
	self:setMass(0.3)
	self:setAngle(r)

	self:setPosition(x, y)

	self.i = i
	self.doorID = doorID

	--Model
	self.model = model.key
	self.texture = img.key
	if t == "KeySilver" then
		self.texture = img.keySilver
	elseif t == "KeyBrown" then
		self.texture = img.keyBrown
	elseif t == "KeyBlack" then
		self.texture = img.keyBlack
	end
	
	self.collected = false
end

function Key:update(dt)
	
end

function Key:draw()
	if not self.collected then
		self.model:setScale(1,1,1)
		self.model:setTexture(self.texture)
		self:drawModel()
	end
end

function Key:collect()
	if self.collected then
		return false
	end

	self:setActive(false)
	self.collected = true

	if not DOORSUNLOCKED[self.doorID] then
		local x, y = self:getPosition()
		makePoof(x, y, self.z-0.5)
		KEYS[self.doorID] = true
		keyWiggle = 0
		playSound(sound.key)
	end
	return true
end

function Key:unCollect()
	--Rewind
	KEYS[self.doorID] = false
	self:setActive(true)
	self.collected = false
	return true
end