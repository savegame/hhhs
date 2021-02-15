Truck = class("Truck", PhysObj)

function Truck:initialize(x, y)
	--Body
	self.x = 0
	self.y = 0
	self.z = 0
	self:createBody("obj_COL", objfile.truck["Truck_COL"])
	self:setLinearDamping(8)
	self:setAngularDamping(80)
	self:setMass(100)
	self:setInertia(100)

	self:setPosition(x, y)

	--Model
	self.t = t
	self.model = model.truck

	self.everRidden = false
	self.finished = false

	self.acceleration = 4000
	self.speed = 0
	self.maxSpeed = 5000
end

function Truck:update(dt)
	--Move forward or backwards
	if PLAYER.riding and (buttonIsDown("up") or buttonIsDown("down") or (joystickStickY and joystickStickY > DEADZONE)) and not REWINDING then
		local r = -self:getAngle()+math.pi
		local dir = 1
		if buttonIsDown("down") or (joystickStickY and joystickStickY < 0) then
			dir = -1
		end

		self.speed = math.min(self.maxSpeed, self.speed + self.acceleration*dt)

		local s = self.speed*dir
		self.body:applyForce(math.sin(r)*s, math.cos(r)*s)
	else
		self.speed = 0
	end
	--Finish Game
	local x, y = self:getPosition()
	if (not self.finished) and y < 1 then
		queueFinish()
		self.finished = true
	end
end

function Truck:draw()
	self:drawModel()
end

function Truck:collide(side, a, b)
end

function Truck:ride(b)
	b.riding = true
	self.everRidden = true
	b:setPosition(99,99)
	playSound(sound.car)
end

function Truck:unRide(b)
	b.riding = false
	local x, y = self:getPosition()
	local r = -self:getAngle()+math.pi*1.5
	local dist = 1.6
	b:setPosition(x+math.sin(r)*dist,y+math.cos(r)*dist)
end