Warp = class("Warp", PhysObj)

function Warp:initialize(x, y, targetRoom, doorID)
	--Body
	self.x = x
	self.y = y
	self:createBody("rectangle", 1, 1)
	self:setStatic(true)

	self:setPosition(x, y)
	
	self.target = targetRoom
	self.doorID = doorID
	self.warped = false
end

function Warp:collide(side,a,b)
	if a == "Player" and (not self.warped) then
		local pass = true
		--Hacky fake Z-movement
		if b.z < -0.01 and self.x < 1.4 then
			return false
		end
		if pass then
			queueStage(self.target, self.doorID)
			self.warped = true
		end
	end
	if a == "Box" or a == "Basket" or a == "Bucket" or a == "Ball" then
		return true
	end
	return false
end