-- written by groverbuger for g3d
-- august 2020
-- MIT license

--Alesan: redid this a bit. And added a ton of stuff related to shading and shadows

local shader = love.filesystem.read("shaders/shader.glsl")
local shadowshader = love.filesystem.read("shaders/shadow.glsl")
local depthshader = love.filesystem.read("shaders/depth.glsl")
local shaderlight = love.filesystem.read("shaders/light.glsl")
local skyboxshader = love.filesystem.read("shaders/skybox.glsl")
local billboardshader = love.filesystem.read("shaders/billboard.glsl")
local billboardscaleshader = love.filesystem.read("shaders/billboard_scale.glsl")
local deferredshader = love.filesystem.read("shaders/deferred.glsl")

CameraObj = class("CameraObj")
function CameraObj:initialize(aspectRatio, options)
	self.options = options or {}
    ----------------------------------------------------------------------------------------------------
    -- initialize the 3d shader
    ----------------------------------------------------------------------------------------------------

	if options.deferred then
		self.shader = love.graphics.newShader(deferredshader)
	elseif options.shadowmap then
		self.shader = love.graphics.newShader(depthshader)
	elseif options.shadow and setting.graphicsQuality > 1 then
		self.shader = love.graphics.newShader(shadowshader)
		--self.animshader = love.graphics.newShader(anim9shader)
	elseif options.light and setting.graphicsQuality > 1 then
		self.shader = love.graphics.newShader(shaderlight)
	else
		self.shader = love.graphics.newShader(shader)
	end
	--create shader for skybox
	if options.skybox then
		self.skyshader = love.graphics.newShader(skyboxshader)
	end
	--create shader for billboard models
	if options.billboard then
		self.billboardshader = love.graphics.newShader(billboardshader)
		self.billboardscaleshader = love.graphics.newShader(billboardscaleshader)
	end

    ----------------------------------------------------------------------------------------------------
    -- initialize the shader with a basic CameraObj
    ----------------------------------------------------------------------------------------------------

   	self.fov = options.fov or math.pi/2
	self.nearClip = options.nearClip or 0.01
	self.farClip = options.farClip or 1000
	self.aspectRatio = aspectRatio
	self.position = {0,0,0}
	self.target = {0,1,0}
	self.direction = 0
    self.pitch = 0
	self.down = {0,-1,0}

	self.flipY = options.flipY
	self.light = options.light
	self.forceLight = options.forceLight --don't let sun change light vector

	self.ambientLight = 0.5
	self.ambientLightAdd = 0.25
	self.ambientVector = options.light or {0,-1,0}

    -- create the projection matrix from the CameraObj
	-- and send it to the shader
	self:updateProjectionMatrix(self.fov, self.nearClip, self.farClip, self.aspectRatio)
    
	self:set(0,0,0,0,0)
	--self:UpdateShader()
	
	return self
end

-- move and rotate the CameraObj, given a point and a direction and a pitch (vertical direction)
function CameraObj:set(x,y,z, direction,pitch)
	self.position[1] = x
	self.position[2] = y
	self.position[3] = z
    self.direction = direction or self.direction
    self.pitch = pitch or self.pitch

    -- convert the direction and pitch into a target point
    local sign = math.cos(self.pitch)
    if sign > 0 then
        sign = 1
    elseif sign < 0 then
        sign = -1
    else
        sign = 0
    end
    local cosPitch = sign*math.max(math.abs(math.cos(self.pitch)), 0.001)
    local target = {self.position[1]+math.sin(self.direction)*cosPitch, self.position[2]-math.sin(self.pitch), self.position[3]+math.cos(self.direction)*cosPitch}
    self.target = target

	-- update the CameraObj in the shader
	self:updateViewMatrix(self.position, self.target, self.down)
	self:updateShader()
end

-- give the CameraObj a point to look from and a point to look towards
function CameraObj:setCameraAndLookAt(x,y,z, xAt,yAt,zAt)
	self.position[1] = x
	self.position[2] = y
	self.position[3] = z
	self.target[1] = xAt
	self.target[2] = yAt
	self.target[3] = zAt

    -- update the CameraObj in the shader
	self:updateViewMatrix(self.position, self.target, self.down)
	self:updateShader()
end

-- simple first person CameraObj movement with WASD
-- put this function in your love.update to use, passing in dt
function CameraObj:firstPersonCameraMovement(dt)
    -- collect inputs
    local mx,my = 0,0
    local cameraMoved = false
    if love.keyboard.isDown("w") then
        my = my - 1
    end
    if love.keyboard.isDown("a") then
        mx = mx - 1
    end
    if love.keyboard.isDown("s") then
        my = my + 1
    end
    if love.keyboard.isDown("d") then
        mx = mx + 1
    end
    if love.keyboard.isDown("space") then
        self.position[2] = self.position[2] - 0.15*dt*60
        cameraMoved = true
    end
    if love.keyboard.isDown("lshift") then
        self.position[2] = self.position[2] + 0.15*dt*60
        cameraMoved = true
    end

    -- add CameraObj's direction and movement direction
    -- then move in the resulting direction
    if mx ~= 0 or my ~= 0 then
        local angle = math.atan2(my,mx)
        local speed = 0.15
        local dx,dz = math.cos(self.direction + angle)*speed*dt*60, math.sin(self.direction + angle + math.pi)*speed*dt*60

        self.position[1] = self.position[1] + dx
        self.position[3] = self.position[3] + dz
        cameraMoved = true
    end

    if cameraMoved then
        self:set(self.position[1],self.position[2],self.position[3], self.direction,self.pitch)
    end
end
-- best served with FirstPersonCameraMovement()
-- use this in your love.mousemoved function, passing in the movements
function CameraObj:firstPersonCameraLook(dx,dy)
    local sensitivity = 1/300
    self.direction = self.direction + dx*sensitivity
    self.pitch = math.max(math.min(self.pitch - dy*sensitivity, math.pi*0.5), math.pi*-0.5)

    self:set(self.position[1],self.position[2],self.position[3], self.direction,self.pitch)
end

function CameraObj:setFOV(fov)
	self.fov = fov
	self:updateProjectionMatrix(self.fov, self.nearClip, self.farClip, self.aspectRatio)
	self:updateShader()
end

function CameraObj:setAspectRatio(aspectRatio)
	self.aspectRatio = aspectRatio
	self:updateProjectionMatrix(self.fov, self.nearClip, self.farClip, self.aspectRatio)
	self:updateShader()
end

function CameraObj:setDown(x,y,z)
	self.down = {x,y,z}
	self:updateViewMatrix(self.position, self.target, self.down)
	self:updateShader()
end

function CameraObj:setClipping(nearClip,farClip)
	self.nearClip = nearClip
	self.farClip = farClip
	self:updateProjectionMatrix(self.fov, self.nearClip, self.farClip, self.aspectRatio)
	self:updateShader()
end

function CameraObj:setAmbientLight(light)
	self.ambientLight = light
	self:updateShader()
end

function CameraObj:setLight(ambientVector)
	self.light = true
	self.ambientVector = ambientVector
	self:updateShader()
end

function CameraObj:updateViewMatrix(position, target, down)
	if self.flipY then
		self.viewMatrix = GetViewMatrixFlipped(position, target, down)
	else
		self.viewMatrix = GetViewMatrix(position, target, down)
	end
end
function CameraObj:updateProjectionMatrix(fov, nearClip, farClip, aspectRatio)
	if self.options.ortho then
		self.projectionMatrix = GetOrthoMatrix(fov, self.options.ortho, nearClip, farClip, aspectRatio)
	else
		self.projectionMatrix = GetProjectionMatrix(fov, nearClip, farClip, aspectRatio)
	end
end

function CameraObj:updateShader()
	if self.viewMatrix and self.shader:hasUniform("viewMatrix") then
		self.shader:send("viewMatrix", self.viewMatrix)
	end
	if self.shader:hasUniform("viewDir") then
		self.shader:send("viewDir", self.target)
	end
	if self.shader:hasUniform("viewPos") then
		self.shader:send("viewPos", self.position)
	end
	if self.shader:hasUniform("projectionMatrix") then
		self.shader:send("projectionMatrix", self.projectionMatrix)
	end
	if self.light and self.shader:hasUniform("ambientLight") then
        self.shader:send("ambientLight", self.ambientLight)
        self.shader:send("ambientLightAdd", self.ambientLightAdd)
		if self.shader:hasUniform("ambientVector") then
			self.shader:send("ambientVector", self.ambientVector)
		end
	end
	if self.shader:hasUniform("environmentMap") then
		self.shader:send("environmentMap", img.metal)
	end
	--Skybox
	if self.skyshader then
		if self.viewMatrix then
			self.skyshader:send("viewMatrix", self.viewMatrix)
		end
		self.skyshader:send("projectionMatrix", self.projectionMatrix)
	end
	--Billboard Shader
	if self.billboardshader then
		if self.viewMatrix then
			self.billboardshader:send("viewMatrix", self.viewMatrix)
		end
		self.billboardshader:send("projectionMatrix", self.projectionMatrix)
	end
	--Billboard Shader Uniform Scale
	if self.billboardscaleshader then
		if self.viewMatrix then
			self.billboardscaleshader:send("viewMatrix", self.viewMatrix)
		end
		self.billboardscaleshader:send("projectionMatrix", self.projectionMatrix)
		local canvasFlip = 1
		if self.flipY then canvasFlip = -1 end
		self.billboardscaleshader:send("canvasFlip", canvasFlip)
	end
	--Animation Shader
	if self.animshader then
		if self.viewMatrix and self.animshader:hasUniform("viewMatrix") then
			self.animshader:send("viewMatrix", self.viewMatrix)
		end
		if self.animshader:hasUniform("viewDir") then
			self.animshader:send("viewDir", self.target)
		end
		if self.animshader:hasUniform("viewPos") then
			self.animshader:send("viewPos", self.position)
		end
		if self.animshader:hasUniform("projectionMatrix") then
			self.animshader:send("projectionMatrix", self.projectionMatrix)
		end
		if self.light and self.animshader:hasUniform("ambientLight") then
			self.animshader:send("ambientLight", self.ambientLight)
			self.animshader:send("ambientLightAdd", self.ambientLightAdd)
			if self.animshader:hasUniform("ambientVector") then
				self.animshader:send("ambientVector", self.ambientVector)
			end
		end
	end
end

function CameraObj:sendShadowMap(canvas, camera)
	--send depth buffer
	local buffer, cam = canvas, camera
	if type(canvas) == "table" then
		--Sun Light
		buffer = canvas.canvas
		cam = canvas.camera
		if not self.forceLight then
			self:setLight(NormalizeVector({canvas.x-canvas.tx,canvas.y-canvas.ty,canvas.z-canvas.tz}))
		else
			self:setLight(self.ambientVector)
		end
		if self.shader:hasUniform("lightPos") then
			self.shader:send("lightPos", cam.position)
		end
	end
	if self.shader:hasUniform("shadowMap") or self.shader:hasUniform("shadowMapImage") then
		if self.shader:hasUniform("shadowMap") then
			self.shader:send("shadowMap", buffer)
		end
		if self.shader:hasUniform("shadowMapImage") then
			self.shader:send("shadowMapImage", buffer)
		end
		if self.shader:hasUniform("shadowMapSize") then
			self.shader:send("shadowMapSize", buffer:getWidth() or 256)
		end
		self.shader:send("shadowProjectionMatrix", cam.projectionMatrix)
		self.shader:send("shadowViewMatrix", cam.viewMatrix)
		if self.shader:hasUniform("shadowMapDir") then
			self.shader:send("shadowMapDir", NormalizeVector(NormalizeVector({canvas.x-canvas.tx,canvas.y-canvas.ty,canvas.z-canvas.tz})))
		end
	end
end

function CameraObj:drawSkyBox(model, texture)
	self.skyshader:send("texCube", texture)
	love.graphics.setShader(self.skyshader)
    love.graphics.draw(model.mesh)
	love.graphics.setShader()
end

function SetActiveCamera(cam)
	ActiveCamera = cam
end