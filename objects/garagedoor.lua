GarageDoor = class("GarageDoor", PhysObj)

function GarageDoor:initialize(x, y)
	--Body
	self.x = 0
	self.y = 0
	self.z = -2.5
	self:createBody("obj_COL", objfile.garageDoor["GarageDoor_COL"])
	self:setStatic(true)
	self:setMass(1)

	self:setPosition(x, y)

	--Model
	self.model = model.garageDoor
	self.texture = img.garageDoor

	self.collected = false
	self.rotation = 0
end

function GarageDoor:update(dt)
	if self.collected then
		local target = -math.pi*0.5
		self.rotation = self.rotation - (1-(self.rotation/target))*6 *dt
	else
		self.rotation = 0
	end
end

function GarageDoor:draw()
	self.model:setRotation(self.rotation,0,0)
	local x, y = self.body:getPosition()
	self.model:draw(-x,self.z or 0,y+0.5)
end

function GarageDoor:collect()
	self:setActive(false)
	self.collected = true
end

function GarageDoor:unCollect()
	self:setActive(true)
	self.collected = false
	self.rotation = 0
end

function GarageDoor:collide(side,a,b)
	if a == "Truck" then
		self:collect()
		playSound(sound.garagedoorhit)
		return false
	end

	return true
end