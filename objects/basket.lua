Basket = class("Basket", PhysObj)

function Basket:initialize(x, y)
	--Body
	self.x = 0
	self.y = 0
	self.z = 0
	self:createBody("obj_COL", objfile.basket["Basket_COL"])
	
	self.shape[2] = love.physics.newRectangleShape(0, 0, 0.55, 0.55)
	self.fixture[2] = love.physics.newFixture(self.body, self.shape[2], 0.5)
	self.fixture[2]:setUserData(self)
	self.fixture[2]:setSensor(true)

	self:setLinearDamping(20)
	self:setAngularDamping(80)
	self:setMass(1)

	self:setPosition(x, y)

	--Model
	self.model = model.basket
	self.texture = img.box

	self.grabbed = false --Grabbed by player?
	self.grabbedOnce = false --has the basket ever been grabbed? (For tutorial)
	self.filled = false --Pile inside?

	self.noCollisions = true

	self.oldX, self.oldY = 0, 0

	self.contacts = 0
end

function Basket:update(dt)
	self.noCollisions = self.contacts <= 0

	if self.grabbed then
		self.z = -0.3
	else
		self.z = 0
	end
end

function Basket:draw()
	if (not self.noCollisions) and self.grabbed then
		love.graphics.setColor(1,0.6,0.6)
	else
		love.graphics.setColor(1,1,1)
	end
	self:drawModel()
	if self.filled then
		love.graphics.setColor(1,1,1)
		model.pile:setRotation(0,self:getAngle(),0)
		model.pile:setScale(0.8,1,0.8)
		local x, y = self:getPosition()
		model.pile:draw(-x,self.z-0.2,y)
	end
end

function Basket:collide(side, a, b)
	if a == "Pile" and (not self.filled) then
		self:fill(a, b)
		return true
	end

	if self.grabbed then
		return false
	end
end

function Basket:fill(a, b)
	--Fill with pile of clothes
	if b:collect() then
		self.filled = true
		local x, y = b:getPosition()
		makePoof(x, y, -0.5)
	end
end

function Basket:grab(b)
	--Grabbed by player
	self.grabbed = true
	self.grabbedOnce = true
	self.parent = b
	self.body:setSleepingAllowed(false)
end

function Basket:drop()
	--Dropped by player
	self.grabbed = false
	self.parent = nil
	self.body:setSleepingAllowed(true)
end

function Basket:unContact(side, a, b, c, d)
	if c == self.fixture[2] then
		if a ~= "Player" then
			self.contacts = self.contacts - 1
			self.noCollisions = self.contacts <= 0
		end
	end
end

function Basket:contact(side, a, b, c, d)
	if c == self.fixture[2] then
		if a ~= "Player" then
			self.contacts = self.contacts + 1
			self.noCollisions = self.contacts <= 0
		end
	end
end