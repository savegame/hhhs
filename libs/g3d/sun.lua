-- Alesan
SunLight = class("SunLight")

function SunLight:initialize(resolution, orthoScale, cube)
	self.camera = CameraObj:new(1, {shadowmap=true, flipY=true, ortho=orthoScale or 8, fov=math.pi/2})
	self.camera:setCameraAndLookAt(-2,-3,-2,0,0,0)

	if cube then
		self.canvas = love.graphics.newCanvas(resolution,resolution, {type="cube",format="depth24",readable=true})
	else
		self.canvas = love.graphics.newCanvas(resolution,resolution, {format="depth24",readable=true})
	end
	self.canvas:setFilter("linear","linear")
	--self.canvas:setFilter("nearest","nearest")
	--self.canvas:setDepthSampleMode("greater")
	--self.canvas:setWrap("clampzero","clampzero")

	self:getCoordinates()
	return self
end

function SunLight:set(x,y,z, direction,pitch)
    self.camera:set(x,y,z, direction,pitch)
	self:getCoordinates()
end

function SunLight:setDown(x,y,z)
    self.camera:setDown(x,y,z)
end

function SunLight:setCameraAndLookAt(x,y,z, xAt,yAt,zAt)
    self.camera:setCameraAndLookAt(x,y,z, xAt,yAt,zAt)
	self:getCoordinates()
end

function SunLight:getCoordinates()
	self.x = self.camera.position[1]
	self.y = self.camera.position[2]
	self.z = self.camera.position[3]
	self.tx = self.camera.target[1]
	self.ty = self.camera.target[2]
	self.tz = self.camera.target[3]
end