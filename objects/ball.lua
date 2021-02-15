Ball = class("Ball", PhysObj)

function Ball:initialize(x, y)
	--Body
	self.x = 0
	self.y = 0
	self.z = 0
	self:createBody("circle",0.4)
	self:setLinearDamping(0.8)
	self:setAngularDamping(1)
	self.body:setSleepingAllowed(true)
	self:setMass(0.4)
	self.restitution = 1
	self.fixture[1]:setRestitution(self.restitution)

	self:setPosition(x, y)

	--Model
	self.model = model.ball
	self.texture = img.texture

	self.matrix = {1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
	self.matrixInverse = self.matrix
end

function Ball:update(dt)
	--Rotate ball model
	local vx, vy = self:getLinearVelocity()
	local len = math.sqrt(vx*vx+vy*vy)
	if len > 0 then
		local rewind = 1
		if REWINDING then
			rewind = -2
		end
		self:rotateMatrix(-vy*math.pi*rewind*dt,-vx*math.pi*rewind*dt)
	end
end

function Ball:rotateMatrix(rotx, roty)
	-- translations
	--self.matrix = IdentityMatrix()
	local rotmatrix = IdentityMatrix()
	if rotx and roty then
		-- x
		local rx = IdentityMatrix()
		rx[6] = math.cos(rotx)
		rx[7] = -1*math.sin(rotx)
		rx[10] = math.sin(rotx)
		rx[11] = math.cos(rotx)
		rotmatrix = MatrixMult(rotmatrix, rx)
		-- z
		local rz = IdentityMatrix()
		rz[1] = math.cos(roty)
		rz[2] = -math.sin(roty)
		rz[5] = math.sin(roty)
		rz[6] = math.cos(roty)
		rotmatrix = MatrixMult(rotmatrix, rz)
	end
	self.matrix = MatrixMult(rotmatrix, self.matrix)
end

function Ball:draw()
	--self.model:setRotation(self.spinx,0,self.spiny)
	local x, y = self.body:getPosition()
	self.matrix[4] = -x
	self.matrix[8] = -0.4
	self.matrix[12] = y
	self.matrixInverse = TransposeMatrix(InvertMatrix(self.matrix))
	self.model.matrix = self.matrix
	self.model.matrixInverse = self.matrixInverse
	self.model:draw()
end

function Ball:collide(side, a, b)
end