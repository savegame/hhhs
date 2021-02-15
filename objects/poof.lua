Poof = class("Poof")

function Poof:initialize(x, y, z)
	self.x = x or 0
	self.y = y or 0
	self.z = z or -0.5

	self.v = 0
end

function Poof:update(dt)
	self.v = self.v + 5*dt
	if self.v > 1 then
		self:delete()
	end
end

function Poof:draw()
	if not self.DELETED then
		local v = 1-self.v
		model.poof:setScale(v, v, v)
		local r = math.floor(self.v*4%2)*math.pi
		model.poof:setRotation(0, r, 0)
		model.poof:draw(-self.x,self.z,self.y)
	end
end

function Poof:delete()
	self.DELETED = true
end