Drips = class("Drips", PhysObj)

function Drips:initialize(x, y)
	--Body
	self.x = 0
	self.y = 0
	self.z = -0.01
	self:createBody("circle",0.2)
	self:setStatic(true)
	self:setMass(1)
	self.fixture[1]:setSensor(true)

	self:setPosition(x, y)

	--Model
	self.model = model.puddle
	self.texture = img.box

	--Animation
	self.over = false --bucket on spot?
	self.scale = 1

	self.dripY = 2.5
	self.drip1 = 0
	self.drip2 = 0.5
	self.drip3 = 0.8
end

function Drips:update(dt)
	--Falling water droplets
	local minSpeed = 0.1
	local maxSpeed = 4
	local speedMult = 5
	local rewind = 1
	if REWINDING then
		rewind = -3
	end
	self.drip1 = (self.drip1+math.min(maxSpeed,math.max(minSpeed,self.drip1*speedMult)*rewind*dt))%1
	self.drip2 = (self.drip2+math.min(maxSpeed,math.max(minSpeed,self.drip2*speedMult)*rewind*dt))%1
	self.drip3 = (self.drip3+math.min(maxSpeed,math.max(minSpeed,self.drip3*speedMult)*rewind*dt))%1

	--Puddle shrinks if bucket is over it (Not realistic but works as an indicator bucket is in the right place)
	if self.over then
		self.scale = math.max(0, self.scale-dt)
	else
		self.scale = math.min(1, self.scale+dt)
	end
end

function Drips:draw()
	--Puddle
	if self.scale > 0 then
		self.model:setScale(self.scale,self.scale,self.scale)
		self:drawModel()
	end
	--Drops of water falling from ceiling
	local x, y = self:getPosition()
	local dripDist = 0.2 --distance from center
	local dripFormDist = 0.3 --Distance it takes to form into a full droplet
	local scale = math.min(1, (self.drip1*self.dripY)/dripFormDist)
	model.drip:setScale(scale,scale,scale)
	model.drip:draw(-(x+math.sin(0)*dripDist),               (-self.dripY)+self.drip1*self.dripY, y+math.sin(0)*dripDist)
	local scale = math.min(1, (self.drip2*self.dripY)/dripFormDist)
	model.drip:setScale(scale,scale,scale)
	model.drip:draw(-(x+math.sin(math.pi*2*0.333)*dripDist), (-self.dripY)+self.drip2*self.dripY, y+math.sin(math.pi*2*0.333)*dripDist)
	local scale = math.min(1, (self.drip3*self.dripY)/dripFormDist)
	model.drip:setScale(scale,scale,scale)
	model.drip:draw(-(x+math.sin(math.pi*2*0.666)*dripDist), (-self.dripY)+self.drip3*self.dripY, y+math.sin(math.pi*2*0.666)*dripDist)
end

function Drips:contact(side, a, b)
	if a == "Bucket" then
		self.over = true
	end
end

function Drips:unContact(side, a, b)
	if a == "Bucket" then
		self.over = false
	end
end