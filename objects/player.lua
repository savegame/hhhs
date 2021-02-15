Player = class("Player", PhysObj)

function Player:initialize(x, y, r)
	--Body
	self.x = 0
	self.y = 0
	self.z = 0
	self.w = BLOCK*0.8
	self.h = BLOCK*0.8
	self.bevel = 0.15
	--self:createBody("rectangle", self.w, self.h)
	local x1, x2, x3, x4 = -(self.w/2),-(self.w/2-self.bevel),(self.w/2-self.bevel),(self.w/2)
	local y1, y2, y3, y4 = -(self.h/2),-(self.h/2-self.bevel),(self.h/2-self.bevel),(self.h/2)
	self:createBody("polygon", x2,y1, x3,y1, x4,y2, x4,y3, x3,y4, x2,y4, x1,y3, x1,y2)
	self:setAngularDamping(ANGULARFRICTION)

	self:setPosition(x, y)

	--Model
	self.model = model.harold
	self.texture = img.texture

	--Movement
	self.angle = r or 0
	self.speed = 3

	self.grabbing = false

	--Animation
	self.anim = {}
	self.anim.armL = 0--rotation
	self.anim.armR = 0--rotation
	self.anim.armLR = 0--rotation
	self.anim.armRR = 0--rotation
	self.anim.legL = 0--rotation
	self.anim.legR = 0--rotation
	self.anim.body = 0--rotation
	self.anim.bodyS = 1--scale
	self.anim.head = 0--rotation
	self.facingAngle = self.angle
	self.walkTimer = 0
	self.breatheTimer = 0

	self.onStairs = false

	self.riding = false

	self.key = {}
end

local function unwrap(a)
	return a%(math.pi*2)
end
local function angles(a1, a2)
	local a1 = unwrap(a1)-math.pi
	local a2 = unwrap(a2)-math.pi
	local diff = a1-a2
	if math.abs(diff) < math.pi then
		return a1 > a2
	else
		return diff < 0
	end
end
local function anglesdiff(a1, a2)
	local diff = (a2 - a1 + math.pi)%(math.pi*2) - math.pi;
	if diff < -math.pi then
		return diff + math.pi*2
	else
		return diff
	end
end

function Player:update(dt)
	--Move
	if REWINDING then
		self.anim.legL = math.sin(self.walkTimer)*0.8
		self.anim.legR = math.sin(self.walkTimer+math.pi)*0.8
		self.breatheTimer = (self.breatheTimer - 12*dt)%(math.pi*2)
		self.anim.bodyS = 1+math.sin(math.sin(self.breatheTimer))*0.02
	elseif buttonIsDown("left") or buttonIsDown("right") or buttonIsDown("right") or buttonIsDown("up") or buttonIsDown("down") or (joystickStickX and joystickStickDist > DEADZONE) then
		local strength = 1
		local xStrength = 1
		if self.onStairs then xStrength = 0.75 end
		if (joystickStickX and joystickStickY) then
			strength = math.min(1, joystickStickDist)
			self.angle = math.atan2(joystickStickX, -joystickStickY)
		elseif buttonIsDown("left") and buttonIsDown("up") then
			self.angle = math.pi*1.25
		elseif buttonIsDown("right") and buttonIsDown("up")then
			self.angle = math.pi*.75
		elseif buttonIsDown("left") and buttonIsDown("down") then
			self.angle = math.pi*1.75
		elseif buttonIsDown("right") and buttonIsDown("down") then
			self.angle = math.pi*.25
		elseif buttonIsDown("left") then
			self.angle = math.pi*1.5
		elseif buttonIsDown("right") then
			self.angle = math.pi*.5
		elseif buttonIsDown("down") then
			self.angle = 0
		elseif buttonIsDown("up") then
			self.angle = math.pi
		end
		local sx, sy = math.sin(self.angle)*self.speed*strength*xStrength, math.cos(self.angle)*self.speed*strength
		self:setSpeed(sx, sy)

		--Animate Walk
		self.anim.bodyS = 1
		self.walkTimer = (self.walkTimer + 6*strength*dt)%(math.pi*2)
		self.anim.legL = math.sin(self.walkTimer)*0.8
		self.anim.legR = math.sin(self.walkTimer+math.pi)*0.8
	else
		self:setSpeed(0,0)

		--Return to Idle
		self.breatheTimer = (self.breatheTimer + 4*dt)%(math.pi*2)
		self.anim.bodyS = 1+math.sin(math.sin(self.breatheTimer))*0.02
		if self.walkTimer ~= 0 then
			if self.walkTimer < math.pi then
				self.walkTimer = self.walkTimer + 16*dt
				if self.walkTimer >= math.pi then
					self.walkTimer = 0
				end
			else
				self.walkTimer = self.walkTimer + 16*dt
				if self.walkTimer >= math.pi*2 then
					self.walkTimer = 0
				end
			end
		else
			self.walkTimer = 0
		end
		local legReturnSpeed = 8
		if self.anim.legL > 0 then
			self.anim.legL = math.max(0, self.anim.legL - legReturnSpeed*dt)
		elseif self.anim.legL < 0 then
			self.anim.legL = math.min(0, self.anim.legL + legReturnSpeed*dt)
		end
		if self.anim.legR > 0 then
			self.anim.legR = math.max(0, self.anim.legR - legReturnSpeed*dt)
		elseif self.anim.legR < 0 then
			self.anim.legR = math.min(0, self.anim.legR + legReturnSpeed*dt)
		end
	end
	--Turn model in the right direction
	self:setAngle(-self.angle)
	local dir = angles(self.angle,self.facingAngle)
	local diff = anglesdiff(self.angle,self.facingAngle)
	if diff ~= 0 then
		local turnSpeed = math.abs(diff)*20+0.001
		if dir then
			self.facingAngle = (self.facingAngle+turnSpeed*dt)%(math.pi*2)
		else
			self.facingAngle = (self.facingAngle-turnSpeed*dt)%(math.pi*2)
		end
		local dir2 = angles(self.angle,self.facingAngle)
		if dir ~= dir2 then
			self.facingAngle = self.angle
		end
	end

	--Hacky fake Z-movement
	if currentRoom == "foyer" then
		local x, y = self:getPosition()
		local oldOnStairs = self.onStairs
		self.onStairs = (y > 0 and y < 2 and x > -3 and x < 0)
		if self.onStairs then
			local v = math.max(-1,-((x+0.375)/(3-0.375))-1)
			self.z = v*2.5
		elseif not (y > 4.6 and y < 5.6) then
			if x > 0 then
				self.z = -2.5
			else
				self.z = 0
			end
		end
	end

	--Animation
	self.anim.armL = 0
	self.anim.armR = 0
	self.anim.armLR = 0--rotation
	self.anim.armRR = 0--rotation
	if self.grabbing then
		self.anim.armL = math.pi*.25
		self.anim.armR = math.pi*.25
		self.anim.armLR = math.pi*.05
		self.anim.armRR = -math.pi*.05
	end

	self:updateGrab()
end

function Player:updateGrab()
	--Grabbing
	if self.grabbing then
		local b = self.grabbing
		local x, y = self:getPosition()
		local dist = 0.8
		local angle = self.facingAngle
		x, y = x+math.sin(angle)*dist, y+math.cos(angle)*dist
		b:setPosition(x, y)
		b:setAngle(-angle)
	end
end

function Player:draw()
	self.x, self.y = self:getPosition()

	--Animations!
	--Future 3D games will have proper skeletal animations, just couldn't figure it out in time for this one
	local a = -self.facingAngle--self.body:getAngle()
	local x, y = self.body:getPosition()
	self.model["Head"]:setRotation(0,a,0)
	local bodyRockStrength = 0.15
	local bodyRock = math.sin(self.walkTimer)*bodyRockStrength
	self.model["Body"]:setRotation(0,a-bodyRock,0)
	self.model["Body"]:setScale(1,self.anim.bodyS,self.anim.bodyS)
	self.model["ArmR"]:setRotation(self.anim.armR,a,self.anim.armRR,2,3,1)
	self.model["ArmL"]:setRotation(self.anim.armL,a,self.anim.armLR,2,3,1)
	self.model["LegR"]:setRotation(self.anim.legR,a,0,2,1,3)
	self.model["LegL"]:setRotation(self.anim.legL,a,0,2,1,3)
	self.model["Head"]:draw(-x,self.z-(1.5+(self.anim.bodyS-1)),y)
	self.model["Body"]:draw(-x,self.z-1.4,y)
	local armDist = 0.45 --how far his arms are from the center
	local armOffset = -0.1 --how far back his arms are
	local armLBodyRockX, armLBodyRockY = math.sin(-(a-bodyRock)+math.pi*.5)*armDist, math.cos(-(a-bodyRock)+math.pi*.5)*armDist
	local armRBodyRockX, armRBodyRockY = math.sin(-(a-bodyRock)+math.pi*1.5)*armDist, math.cos(-(a-bodyRock)+math.pi*1.5)*armDist
	self.model["ArmR"]:draw(-(x+math.sin(-a)*armOffset+armLBodyRockX),self.z-1.35,y+math.cos(-a)*armOffset+armLBodyRockY)
	self.model["ArmL"]:draw(-(x+math.sin(-a)*armOffset+armRBodyRockX),self.z-1.35,y+math.cos(-a)*armOffset+armRBodyRockY)
	local legDist = 0.25
	self.model["LegR"]:draw(-x+math.sin(a+math.pi*1.5)*legDist,self.z-0.75,y+math.cos(a+math.pi*1.5)*legDist)
	self.model["LegL"]:draw(-x+math.sin(a+math.pi*.5)*legDist,self.z-0.75,y+math.cos(a+math.pi*.5)*legDist)
end

function Player:collide(side, a, b)
	if a == "Basket" then
		if b == self.grabbing then
			return false
		end
	elseif a == "Key" then
		b:collect()
		playSound(sound.key)
	elseif a == "Door" then
		b:tryUnlock()
	end
end

function Player:grab(a, b)
	if self.grabbing then
		return false
	end
	b:grab(self)
	self.grabbing = b

	--Can't push boxes
	for i, b in pairs(OBJ["Box"]) do
		if b.t ~= "Crate" then
			b:setStatic(true)
		end
	end
	for i, b in pairs(OBJ["Door"]) do
		b:setStatic(true)
	end
	for i, b in pairs(OBJ["Bucket"]) do
		b:setStatic(true)
	end
end

function Player:drop()
	if not self.grabbing then
		return false
	end
	if not self.grabbing.noCollisions then
		return false
	end
	self.grabbing:drop()
	self.grabbing = false

	--Push boxes again
	for i, b in pairs(OBJ["Box"]) do
		if b.t ~= "Crate" then
			b:setStatic(false)
		end
	end
	for i, b in pairs(OBJ["Door"]) do
		b:setStatic(b.locked)
	end
	for i, b in pairs(OBJ["Bucket"]) do
		b:setStatic(b.locked)
	end
	return true
end

function Player:buttonpressed(b)
	if b == "action" then
		--Ride Truck
		if self.riding then
			local b = OBJ["Truck"][1]
			local x, y = b:getPosition()
			if y > 8 then
				b:unRide(self)
				return true
			end
		else
			if #OBJ["Truck"] > 0 then
				local b = OBJ["Truck"][1]
				if b then
					local x, y = b:getPosition()
					local dist = (PLAYER.x-x)*(PLAYER.x-x)+(PLAYER.y-y)*(PLAYER.y-y)
					if dist < 2*2 then
						local x, y = self:getPosition()
						makePoof(x, y, -0.5)
						b:ride(self)
						return true
					end
				end
			end
		end
		if self.grabbing then
			--Drop
			if self:drop() then
				playSound(sound.drop)
			end
		else
			--Grab
			local closestDist = math.huge
			local foundBasket = false
			local findBasket = function(fixture, x, y, xn, yn, fraction)
				local object = fixture:getUserData()
				--ignore player
				if object:getName() == "Basket" then
					if fraction < closestDist then
						closestDist = fraction
						foundBasket = object
					end
				end
				return 1 -- Continues with ray cast through all shapes.
			end

			--Cast the ray and to find Baskets
			local range = 0.75
			local x1, y1 = self:getPosition()
			local x2, y2 = x1+math.sin(self.angle)*range,y1+math.cos(self.angle)*range
			WORLD:rayCast(x1, y1, x2, y2, findBasket)

			if foundBasket then
				self:grab("Basket", foundBasket)
				playSound(sound.grab)
			end
		end
	end
end

function Player:buttonreleased(b)

end