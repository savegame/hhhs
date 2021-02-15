--Base class for objects that use Box2D physics
PhysObj = class("PhysObj")

function PhysObj:initialize()
end

function PhysObj:updateBasic(dt)
	if self.doActive == true then
		if self.active ~= self.doActive then
			self:setActive(true)
		end
		self.doActive = nil
	elseif self.doActive == false then
		if self.active ~= self.doActive then
			self:setActive(false)
		end
		self.doActive = nil
	end
	if self.doStatic == true then
		if self.static ~= self.doStatic then
			self:setStatic(true)
		end
		self.doStatic = nil
	elseif self.doStatic == false then
		if self.static ~= self.doStatic then
			self:setStatic(false)
		end
		self.doStatic = nil
	end
end

function PhysObj:createBody(bodyType, ...)
	local vars = {...}
	local state = "dynamic"
	if self.static then
		state = "static"
	end
	if bodyType == "rectangle" then
		--create simple rectangle
		self.body = love.physics.newBody(WORLD, self.x, self.y, state)
		local w, h = vars[1], vars[2]
		self.shape = {love.physics.newRectangleShape(0, 0, w, h)}
		self.fixture = {love.physics.newFixture(self.body, self.shape[1], 0.5)}
	elseif bodyType == "circle" then
		self.body = love.physics.newBody(WORLD, self.x, self.y, state)
		self.ballShape = true
		self.shape = {love.physics.newCircleShape(vars[1])}
		self.fixture = {love.physics.newFixture(self.body, self.shape[1], 0.5)}
	elseif bodyType == "polygon" then
		self.body = love.physics.newBody(WORLD, self.x, self.y, state)
		self.shape = {love.physics.newPolygonShape(vars)}
		self.fixture = {love.physics.newFixture(self.body, self.shape[1], 0.5)}
	elseif bodyType == "obj_COL" then
		--create group of 2d shapes from .obj file with _COL object
		--ANY POLYGON (less or equal to 8 vertices)
		self.body = love.physics.newBody(WORLD, self.x, self.y, state)
		self.shape = {}
		self.fixture = {}
		local polys = vars[1]
		local poly = {}
		local tris = 0
		for i = 1, #polys do --iterate over vertex data (vertPos, vertUV, vertNormal)
			--MAY CRASH IF POLYGON IS TOO SMALL
			--TODO: remove this to improve performance
			--local success, shape = pcall(function() return love.physics.newPolygonShape(polys[i]) end)
			local shape = love.physics.newPolygonShape(polys[i])
			--[[if not success then
				print(shape)
			else]]
				table.insert(self.shape, shape)
				table.insert(self.fixture, love.physics.newFixture(self.body, shape, 0.5))
			--end
			triVert = 0
		end
	elseif bodyType == "obj" then
		--create group of 2d shapes from .obj file
		--ONLY TRIANGLES
		self.body = love.physics.newBody(WORLD, self.x, self.y, state)
		self.shape = {}
		self.fixture = {}
		local verts = vars[1]
		local tri = {}
		local tris = 0
		local triVert = 0
		for i = 1, #verts do --iterate over vertex data (vertPos, vertUV, vertNormal)
			local vp = verts[i] --vertex position
			triVert = triVert + 1
			tri[(triVert-1)*2+1] = vp[1]*10 --insert x and y
			tri[(triVert-1)*2+2] = vp[3]*10
			--Create triangle after 3 vertices
			if triVert == 3 then
				tris = tris + 1
				--MAY CRASH IF POLYGON IS TOO SMALL
				local shape = love.physics.newPolygonShape(tri)
				--[[local success, shape = pcall(function() return love.physics.newPolygonShape(tri) end)
				if not success then
					print(shape)
				else]]
					table.insert(self.shape, shape)
					table.insert(self.fixture, love.physics.newFixture(self.body, shape, 0.5))
				--end
				triVert = 0
			end
		end
	end
	
	for j, w in pairs(self.fixture) do
		w:setUserData(self)
	end
end

function PhysObj:drawModel()
	local x, y = self.body:getPosition()
	self.model:setRotation(0,self.body:getAngle(),0)
	self.model:draw(-x,self.z or 0,y)
end

function PhysObj:debugDraw()
	if self.static then
		love.graphics.setColor(0.5,0.0,0.5)
	else
		love.graphics.setColor(0.5,0.0,0.0)
	end
	love.graphics.push()
	love.graphics.translate(30,30)
	love.graphics.scale(30,30)
	if self.ballShape then
		local x, y = self:getPosition()
		love.graphics.circle("fill", x, y, self.shape[1]:getRadius())
	else
		for i, shape in ipairs(self.shape) do
			love.graphics.polygon("fill", self.body:getWorldPoints(shape:getPoints()))
		end
	end
	if not self.static then
		love.graphics.setColor(1,0,0)
		local x, y = self.body:getPosition()
		love.graphics.circle("fill", x, y, 0.1)
	end
	love.graphics.pop()
end

function PhysObj:collide(side, a, b)
	
end

function PhysObj:setX(x)
	self.body:setX(x)
end
function PhysObj:setY(y)
	self.body:setY(y)
end
function PhysObj:setPosition(x,y)
	self.body:setPosition(x,y)
end

function PhysObj:getX()
	return self.body:getX()
end
function PhysObj:getY()
	return self.body:getY()
end
function PhysObj:getPosition()
	return self.body:getPosition()
end

function PhysObj:setSpeed(x,y)
	self.body:setLinearVelocity(x,y)
end

function PhysObj:applyForce(x,y)
	self.body:applyForce(x,y)
end

function PhysObj:setLinearDamping(ld)
	self.body:setLinearDamping(ld)
end

function PhysObj:setMass(mass)
	self.body:setMass(mass)
end

function PhysObj:getMass()
	return self.body:getMass()
end

function PhysObj:setInertia(inertia)
	self.body:setInertia(inertia)
end

function PhysObj:getInertia()
	return self.body:getInertia()
end

function PhysObj:getAngle()
	return self.body:getAngle()
end

function PhysObj:setAngle(angle)
	self.body:setAngle(angle)
end

function PhysObj:setAngularDamping(angularDamping)
	self.body:setAngularDamping(angularDamping)
end

function PhysObj:setLinearVelocity(vx,vy)
	return self.body:setLinearVelocity(vx,vy)
end

function PhysObj:getLinearVelocity()
	return self.body:getLinearVelocity()
end

function PhysObj:setStatic(static)
	if WORLD:isLocked() then
		self.doStatic = static
	else
		self.static = static
		if static then
			self.body:setType("static")
		else
			self.body:setType("dynamic")
		end
	end
end

function PhysObj:setActive(active)
	if WORLD:isLocked() then
		self.doActive = active
	else
		self.active = active
		self.body:setActive(active)
	end
end

function PhysObj:setSleepingAllowed(allow)
	self.body:setSleepingAllowed(allow)
end