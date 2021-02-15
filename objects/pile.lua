Pile = class("Pile", PhysObj)

function Pile:initialize(x, y)
	--Body
	self.x = 0
	self.y = 0
	self:createBody("obj_COL", objfile.pile["Pile_COL"])
	self:setStatic(true)
	self:setMass(1)

	self:setPosition(x, y)

	--Model
	self.model = model.pile
	self.texture = img.box

	self.collected = false
end

function Pile:update(dt)
	
end

function Pile:draw()
	if not self.collected then
		self.model:setScale(1,1,1)
		self:drawModel()
	end
end

function Pile:collect(initial)
	--Collected in Basket
	if self.collected then
		return false
	end

	if initial == nil then
		playSound(sound.pile)
	end

	self:setActive(false)
	self.collected = true
	return true
end

function Pile:unCollect()
	--Rewind
	self:setActive(true)
	self.collected = false
	return true
end