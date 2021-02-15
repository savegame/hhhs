--I got lazy and hard-coded stairs into the foyer
--This object is just to prevent balls from going into the stairs
Stairs = class("Stairs", PhysObj)

function Stairs:initialize(x, y)
	--Body
	self.x = 0
	self.y = 0
	self:createBody("rectangle", 3,2)
	self:setStatic(true)
	self:setMass(1)

	self:setPosition(x, y)
end

function Stairs:update(dt)
	
end

function Stairs:collide(side, a, b)
	if a == "Ball" or a == "Box" then
		return true
	end
	return false
end