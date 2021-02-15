Walls = class("Walls", PhysObj)

function Walls:initialize(x, y, obj, image)
	self.obj = obj
	if not self.obj["Room"] then
		print("Room object file is missing Mesh Object named \"Room\" ")
	end
	self.model = Model:new(self.obj["Room"], image)

	self.static = true
	if not self.obj["Room_COL"] then
		print("Room object file is missing Collision Mesh named \"Room_COL\" ")
	end
	self:createBody("obj_COL", self.obj["Room_COL"])
end

function Walls:update(dt)

end

function Walls:draw()
	self.model:draw(0,0,0)
end