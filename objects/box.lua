Box = class("Box", PhysObj)

function Box:initialize(x, y, t, r)
	--Body
	self.x = 0
	self.y = 0
	assert(objfile[t:lower()], string.format("Obj file not found for %s!", (t or ""):lower()))
	self:createBody("obj_COL", objfile[t:lower()][t .. "_COL"])
	self:setLinearDamping(20)
	self:setAngularDamping(80)
	self:setMass(0.8)
	self:setAngle(r)

	if t == "Box" then --0.06
		self:setInertia(0.3)
	elseif t == "Couch" then --0.59
		self:setInertia(0.7)
	elseif t == "Couch3" then --1.12
		self:setInertia(1.4)
	end

	self:setPosition(x, y)

	--Model
	self.t = t
	self.model = model[t:lower()]
	self.texture = img.box

	if t == "Crate" then
		--Crates should only be move-able when being touched by the player
		--But changing bodytype to static causes all contacts to be reset, which makes it forget the player is touching it
		--So I have to settle for a fake static
		self.shouldBeFakeStatic = true
		self.fakeStatic = true
		self:setLinearDamping(999999)
		self:setAngularDamping(999999)
		self:setInertia(999999)
		self:setMass(999999)
	end

	self.touching = false
	self.pushing = false
end

function Box:update(dt)
	if self.t == "Crate" then
		if self.shouldBeFakeStatic == true and self.fakeStatic == false then
			self:setLinearDamping(99999)
			self:setAngularDamping(99999)
			self:setInertia(999999)
			self:setMass(999999)
			self.fakeStatic = true
		elseif self.shouldBeFakeStatic == false and self.fakeStatic == true then
			self:setLinearDamping(34)
			self:setAngularDamping(100)
			self:setMass(2)
			self:setInertia(1)
			self.fakeStatic = false
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

function Box:draw()
	self:drawModel()
end

function Box:contact(side, a, b)
	if self.t == "Crate" and a == "Player" then
		if not b.grabbing then
			self.shouldBeFakeStatic = false
		end
	end
	if a == "Player" then
		self.touching = true
	end
end

function Box:unContact(side, a, b)
	if self.t == "Crate" and a == "Player" then
		self.shouldBeFakeStatic = true
	end
	if a == "Player" then
		self.touching = false
	end
end

function Box:collide(side, a, b)
	if a == "Player" then
	end
end