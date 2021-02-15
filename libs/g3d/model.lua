-- written by groverbuger for g3d
-- august 2020
-- MIT license

----------------------------------------------------------------------------------------------------
-- define a model class
----------------------------------------------------------------------------------------------------

local iqm, anim9, cpml

if FFIEXISTS then
	iqm = require("libs/iqm")
	anim9 = require("libs/anim9")
	cpml  = require("libs/cpml")
end
Model = class("Model")

-- this returns a new instance of the Model class
-- a model must be given a .obj file or equivalent lua table, and a texture
-- translation, rotation, and scale are all 3d vectors and are all optional
function Model:initialize(given, texture, options, translation, rotation, scale)
	local options = options or {}

	self.vertexFormat = {
		{"VertexPosition", "float", 3},
		{"VertexTexCoord", "float", 2},
		{"VertexNormal", "float", 3},
		--{"VertexColor", "float", 3},
	}

    -- if texture is a string, use it as a path to an image file
    -- otherwise texture is already an image, so don't bother
    if type(texture) == "string" then
        texture = love.graphics.newImage(texture)
    end

    -- if given is a string, use it as a path to a .obj file
	-- otherwise given is a table, use it as a model defintion
	if type(given) == "string" then
		local extension = given:sub(-4,-1)
		--OBJ File
		if extension ~= ".obj" and love.filesystem.getInfo(given .. ".obj") then
			given = given .. ".obj"; extension = ".obj"
		end
		if extension == ".obj" then
			given = loadObjFile(given, {vertexColors=false, correctUVs=true})
			
			self.verts = given
			self.mesh = love.graphics.newMesh(self.vertexFormat, self.verts, "triangles")
			self.animated = false
		elseif extension == ".iqm" then
			local data = iqm.load(given)
			self.data = data
			self.verts = data.triangles
			self.mesh = data.mesh
			self.animated = true

			self.anims = iqm.load_anims(given)
			self.animTracks = {}
			self.anim = anim9(self.anims)
		end
	else
		--If given table of verticies
		self.verts = given
		self.mesh = love.graphics.newMesh(self.vertexFormat, self.verts, "triangles")
		self.animated = false
    end

    -- initialize my variables
	self.texture = texture
	self.originaluv = {}
	self.billboard = options.billboard
	self.billboardscale = options.billboardscale
	self.metallic = options.metallic
	
	if options.flip then
		self:flip("initial")
	end

	self.x = 0
	self.y = 0
	self.z = 0

    self.mesh:setTexture(self.texture)
    self:setTransform(translation or {0,0,0}, rotation or {0,0,0}, scale or {1,1,1})

    return self
end

function Model:update(dt)
	if self.animated then
		self.anim:update(dt)
	end
end

-- populate model's normals in model's mesh automatically
function Model:makeNormals()
    for i=1, #self.verts, 3 do
        local vp = self.verts[i]
        local v = self.verts[i+1]
		local vn = self.verts[i+2]

        local vec1 = {v[1]-vp[1], v[2]-vp[2], v[3]-vp[3]}
        local vec2 = {vn[1]-v[1], vn[2]-v[2], vn[3]-v[3]}
        local normal = NormalizeVector(CrossProduct(vec1,vec2))
        vp[6] = normal[1]
        vp[7] = normal[2]
        vp[8] = normal[3]

        v[6] = normal[1]
        v[7] = normal[2]
        v[8] = normal[3]

        vn[6] = normal[1]
        vn[7] = normal[2]
        vn[8] = normal[3]
    end
end

-- set uv
function Model:setUV(t, tu, tv, w, h)
	for i,v in pairs(self.verts) do
		local x,y = v[4],v[5]
		--store original uv
		if not v.u then
			v.u = x
			v.v = y
		end
		--scale uv to bounds
		self.mesh:setVertexAttribute(i, 2, tu+w*v.u, tv+h*v.v)
    end
    self.mesh:setTexture(t)
end
function Model:resetUV()
	for i,v in pairs(self.verts) do
		if v.u then
			self.mesh:setVertexAttribute(i, 2, v.u,v.v)
		end
	end
end
function Model:setTexture(t)
	self.mesh:setTexture(t)
end
function Model:flip(initial)
	--fixes axes to be consistent with default blender settings
	for i,v in pairs(self.verts) do
		--y
		v[3] = -v[3] --flip tri order too!
		v[2] = -v[2]
		--uv
		v[5] = (-v[5])+1
		--normal
		v[6] = v[6]
		v[7] = -v[7]
		v[8] = -v[8]
	end
	--flip order of tris (if flipping z)
    --[[for i=1, #self.verts, 3 do
        local vp = self.verts[i]
        local v = self.verts[i+1]
		local vn = self.verts[i+2]
		self.verts[i+2] = vp
		self.verts[i] = vn
	end]]
	if not initial then
		self.mesh = love.graphics.newMesh(self.vertexFormat, self.verts, "triangles")
	end
end

-- move and rotate given two 3d vectors
function Model:setTransform(translation, rotation, scale)
    self.translation = translation or {0,0,0}
	self.x = self.translation[1]
	self.y = self.translation[2]
	self.z = self.translation[3]
	self.rotation = rotation or {0,0,0}
	self.scale = scale or {1,1,1}
	self.rotationOrder = {1,2,3}
	self.matrix = GetTransformationMatrix(self.translation, self.rotation, self.scale, self.rotationOrder)
	self.matrixInverse = TransposeMatrix(InvertMatrix(self.matrix))
end

-- move given one 3d vector
function Model:setTranslation(tx,ty,tz)
	self.translation[1] = tx
	self.translation[2] = ty
	self.translation[3] = tz
	self.x = tx
	self.y = ty
	self.z = tz
    self.matrix = GetTransformationMatrix(self.translation, self.rotation, self.scale, self.rotationOrder)
	self.matrixInverse = TransposeMatrix(InvertMatrix(self.matrix))
end

-- rotate given one 3d vector
function Model:setRotation(rx,ry,rz,ox,oy,oz)
	if self.rotation[1] == rx and self.rotation[2] == ry and self.rotation[3] == rz and self.rotationOrder[1] == (ox or self.rotationOrder[1]) and self.rotationOrder[2] == (oy or self.rotationOrder[2]) and self.rotationOrder[3] == (oz or self.rotationOrder[3]) then
		return false
	end
	self.rotation[1] = rx
	self.rotation[2] = ry
	self.rotation[3] = rz
	if ox and oy and oz then
		self.rotationOrder[1] = ox
		self.rotationOrder[2] = oy
		self.rotationOrder[3] = oz
	end
    self.matrix = GetTransformationMatrix(self.translation, self.rotation, self.scale, self.rotationOrder)
	self.matrixInverse = TransposeMatrix(InvertMatrix(self.matrix))
end

-- resize model based on a given 3d vector
function Model:setScale(sx,sy,sz)
	if self.scale[1] == sx and self.scale[2] == sy and self.scale[3] == sz then
		return false
	end
	self.scale[1] = sx
	self.scale[2] = sy
	self.scale[3] = sz
	self.matrix = GetTransformationMatrix(self.translation, self.rotation, self.scale, self.rotationOrder)
	self.matrixInverse = TransposeMatrix(InvertMatrix(self.matrix))
end

-- draw the model
function Model:draw(tx,ty,tz)
	--translate
	if tx and (self.x ~= tx or self.y ~= ty or self.z ~= tz) then
		self:setTranslation(tx,ty,tz)
	end
	--draw
	local shader = ActiveCamera.shader
	if self.animated and ActiveCamera.animshader then
		shader = ActiveCamera.animshader
	elseif self.billboard and ActiveCamera.billboardshader then
		shader = ActiveCamera.billboardshader
	elseif self.billboardscale and ActiveCamera.billboardscaleshader then
		shader = ActiveCamera.billboardscaleshader
	end
	love.graphics.setShader(shader)
	if shader:hasUniform("modelMatrix") then
		shader:send("modelMatrix", self.matrix)
	end
	if shader:hasUniform("modelMatrixInverse") then
		shader:send("modelMatrixInverse", self.matrixInverse)
	end
	if shader:hasUniform("modelPos") then
		shader:send("modelPos", self.translation)
	end
	if shader:hasUniform("modelScale") then
		shader:send("modelScale", self.scale)
	end
	if shader:hasUniform("animated") then
		shader:send("animated", self.animated)
	end
	if self.animated and shader:hasUniform("u_pose") then
		shader:send("u_pose", "column", unpack(self.anim.current_pose))
	end
	if self.metallic and shader:hasUniform("metallic") then
		shader:send("metallic", true)
	end
    love.graphics.draw(self.mesh)
	if self.metallic and shader:hasUniform("metallic") then
		shader:send("metallic", false)
	end
    love.graphics.setShader()
end

local function dotProd(a1,a2,a3, b1,b2,b3)
    return a1*b1 + a2*b2 + a3*b3
end

-- check if a vector has collided with this model
-- takes two 3d vectors as arguments, sourcePoint and directionVector
-- returns length of vector from sourcePoint to collisionPoint
-- and returns the collisionPoint
-- length will be nil if no collision was found
-- this function is useful for building game physics
function Model:vectorIntersection(sourcePoint, directionVector)
    local length = nil
    local where = {}

    for v=1, #self.verts, 3 do
        if dotProd(self.verts[v][6],self.verts[v][7],self.verts[v][8], directionVector[1],directionVector[2],directionVector[3]) < 0 then

            local this, w1,w2,w3 = FastRayTriangle(sourcePoint[1],sourcePoint[2],sourcePoint[3],
                directionVector[1],directionVector[2],directionVector[3],
                self.verts[v][1] + self.translation[1],
                self.verts[v][2] + self.translation[2],
                self.verts[v][3] + self.translation[3],
                self.verts[v+1][1] + self.translation[1],
                self.verts[v+1][2] + self.translation[2],
                self.verts[v+1][3] + self.translation[3],
                self.verts[v+2][1] + self.translation[1],
                self.verts[v+2][2] + self.translation[2],
                self.verts[v+2][3] + self.translation[3]
            )

            if this then
                if not length or length > this then
                    length = this
                    where = {w1,w2,w3}
                end
            end
        end
    end

    return length, where
end

function Model:newAnimationTrack(name)
	self.animTracks[name] = self.anim:new_track(name)
end

function Model:playAnimation(name)
	self.anim:play(self.animTracks[name])
	self.anim:update(0)
end

function Model:stopAnimation(name)
	self.anim:stop(self.animTracks[name])
	self.anim:update(0)
end