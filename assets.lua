assets = {}

assetScale = 2--1,2,3
function assets.updateScale()
	if WINH < (DEFAULTWINH*0.8) then
		assetScale = 1
	elseif WINH > (DEFAULTWINH*1.4) then
		assetScale = 3
	else
		assetScale = 2
	end
end

function assets.loadAssets()
	--For Menus
	textFont = {}
	textFont[1] = love.graphics.newFont("work-sans.medium.ttf",34)
	textFont[2] = love.graphics.newFont("work-sans.medium.ttf",44)
	textFont[3] = love.graphics.newFont("work-sans.medium.ttf",64)
	--For Settings
	smallFont = {}
	smallFont[1] = love.graphics.newFont("work-sans.regular.ttf",16)
	smallFont[2] = love.graphics.newFont("work-sans.regular.ttf",30)
	smallFont[3] = love.graphics.newFont("work-sans.regular.ttf",44)

	VCRFont = love.graphics.newFont("VCR_OSD_MONO.ttf", 20)
	VCRFont:setFilter("nearest", "nearest")

	rewindShader = love.graphics.newShader("shaders/rewind.glsl")
	rewindSimpleShader = love.graphics.newShader("shaders/rewind_simple.glsl")
end

function assets.loadGame()
	--Load Assets
	love.graphics.setDefaultFilter("nearest","nearest")
	vignette = love.graphics.newImage("graphics/vignette.png")
	vignette:setFilter("linear", "linear")

	img = {}
	img.white = love.graphics.newImage("assets/white.png")
	img.harold = love.graphics.newImage("assets/harold.png")
	img.drip = love.graphics.newImage("assets/drip.png")
	img.ball = love.graphics.newImage("assets/ball.png")
	img.box = love.graphics.newImage("assets/objects/box.png")
	img.couch = love.graphics.newImage("assets/objects/couch.png")
	img.couch3 = love.graphics.newImage("assets/objects/couch3.png")
	img.crate = love.graphics.newImage("assets/objects/crate.png")
	img.door = love.graphics.newImage("assets/objects/door.png")
	img.basket = love.graphics.newImage("assets/objects/basket.png")
	img.pile = love.graphics.newImage("assets/objects/pile.png")
	img.puddle = love.graphics.newImage("assets/objects/puddle.png")
	img.truck = love.graphics.newImage("assets/objects/truck.png")
	img.garageDoor = love.graphics.newImage("assets/objects/garagedoor.png")
	img.bucket = love.graphics.newImage("assets/bucket.png")
	img.metal = love.graphics.newCubeImage("assets/metal.png")
	img.metal:setFilter("linear", "linear")
	img.key = love.graphics.newImage("assets/objects/key.png")
	img.keySilver = love.graphics.newImage("assets/objects/keysilver.png")
	img.keyBrown = love.graphics.newImage("assets/objects/keybrown.png")
	img.keyBlack = love.graphics.newImage("assets/objects/keyblack.png")
	img.lock = love.graphics.newImage("assets/lock.png")
	img.lockSilver = love.graphics.newImage("assets/locksilver.png")
	img.lockBrown = love.graphics.newImage("assets/lockbrown.png")
	img.lockBlack = love.graphics.newImage("assets/lockblack.png")
	img.keyIcon = love.graphics.newImage("graphics/keyicon.png")
	img.keySilverIcon = love.graphics.newImage("graphics/keysilvericon.png")
	img.keyBlackIcon = love.graphics.newImage("graphics/keyblackicon.png")
	img.keyBrownIcon = love.graphics.newImage("graphics/keybrownicon.png")
	img.keyIcon:setFilter("linear", "linear")
	img.keySilverIcon:setFilter("linear", "linear")
	img.keyBlackIcon:setFilter("linear", "linear")
	img.keyBrownIcon:setFilter("linear", "linear")

	img.roomTexture = love.graphics.newImage("rooms/default.png", {mipmaps=false})

	local langs = {"en","es","pt"}
	img.grab = {}
	for i = 1, #langs do
		img.grab[langs[i]] = love.graphics.newImage("graphics/tips/grab_" .. langs[i] .. ".png")
		img.grab[langs[i]]:setFilter("linear", "linear")
	end

	objfile = {}
	objfile.box = loadObjFile("assets/objects/box.obj", {loadObjects = true, correctUVs = true})
	objfile.crate = loadObjFile("assets/objects/crate.obj", {loadObjects = true, correctUVs = true})
	objfile.couch = loadObjFile("assets/objects/couch.obj", {loadObjects = true, correctUVs = true})
	objfile.couch3 = loadObjFile("assets/objects/couch3.obj", {loadObjects = true, correctUVs = true})
	objfile.pile = loadObjFile("assets/objects/pile.obj", {loadObjects = true, correctUVs = true})
	objfile.basket = loadObjFile("assets/objects/basket.obj", {loadObjects = true, correctUVs = true})
	objfile.door = loadObjFile("assets/objects/door.obj", {loadObjects = true, correctUVs = true})
	objfile.harold = loadObjFile("assets/harold.obj", {loadObjects = true, correctUVs = true})
	objfile.puddle = loadObjFile("assets/objects/puddle.obj", {loadObjects = true, correctUVs = true})
	objfile.key = loadObjFile("assets/objects/key.obj", {loadObjects = true, correctUVs = true})
	objfile.truck = loadObjFile("assets/objects/truck.obj", {loadObjects = true, correctUVs = true})
	objfile.garageDoor = loadObjFile("assets/objects/garagedoor.obj", {loadObjects = true, correctUVs = true})
	collectgarbage("collect")
	collectgarbage("collect")

	model = {}
	model.skybox = Model:new("assets/skybox", img.skybox)
	model.ball = Model:new("assets/ball", img.ball)
	model.bucket = Model:new("assets/bucket", img.bucket, {metallic=false})
	model.bucketWater = Model:new("assets/bucketwater", img.puddle)
	model.drip = Model:new("assets/drip", img.drip, {billboard=true})
	model.grab = Model:new("assets/billboard", img.grab["en"], {billboardscale=true})
	model.poof = Model:new("assets/poof", img.white)
	model.lock = Model:new("assets/lock", img.lock)

	model.box = Model:new(objfile.box["Box"], img.box)
	model.couch = Model:new(objfile.couch["Couch"], img.couch)
	model.couch3 = Model:new(objfile.couch3["Couch3"], img.couch3)
	model.crate = Model:new(objfile.crate["Crate"], img.crate)
	model.pile = Model:new(objfile.pile["Pile"], img.pile)
	model.basket = Model:new(objfile.basket["Basket"], img.basket)
	model.door = Model:new(objfile.door["Door"], img.door)
	model.puddle = Model:new(objfile.puddle["Puddle"], img.puddle)
	model.key = Model:new(objfile.key["Key"], img.key)
	model.truck = Model:new(objfile.truck["Truck"], img.truck)
	model.garageDoor = Model:new(objfile.garageDoor["GarageDoor"], img.garageDoor)
 
	model.harold = {}
	model.harold["Head"] = Model:new(objfile.harold["Head"], img.harold)
	model.harold["Body"] = Model:new(objfile.harold["Body"], img.harold)
	model.harold["ArmL"] = Model:new(objfile.harold["ArmL"], img.harold)
	model.harold["ArmR"] = Model:new(objfile.harold["ArmR"], img.harold)
	model.harold["LegL"] = Model:new(objfile.harold["LegL"], img.harold)
	model.harold["LegR"] = Model:new(objfile.harold["LegR"], img.harold)
	collectgarbage("collect")
	collectgarbage("collect")

	sound = {}
	sound.click = love.audio.newSource("sounds/click.ogg","static")
	sound.rewinding = love.audio.newSource("sounds/rewinding.ogg","stream")
	sound.rewinding:setLooping(true)
	sound.grab = love.audio.newSource("sounds/grab.ogg","static")
	sound.drop = love.audio.newSource("sounds/drop.ogg","static")
	sound.pile = love.audio.newSource("sounds/pile.ogg","static")
	sound.pushing = love.audio.newSource("sounds/pushing.ogg","static")
	sound.pushing:setLooping(true)
	sound.unlock = love.audio.newSource("sounds/unlock.ogg","static")
	sound.key = love.audio.newSource("sounds/key.ogg","static")
	sound.water = love.audio.newSource("sounds/water.ogg","static")
	sound.door = love.audio.newSource("sounds/door.ogg","static")
	sound.car = love.audio.newSource("sounds/car.ogg","static")
	sound.garagedoorhit = love.audio.newSource("sounds/garagedoorhit.ogg","static")

	music = {}
	music.track1 = love.audio.newSource("music/kevin_macLeod_-_i_knew_a_guy.ogg","stream")
	music.track2 = love.audio.newSource("music/kevin_macleod_-_off_to_osaka.ogg","stream")
	music.track3 = love.audio.newSource("music/kevin_macleod_-_acidjazz.ogg","stream")
	musicTrackVolume = 0.5
	musicPlaylist = {music.track2, music.track3, music.track1}
	for j, w in ipairs(musicPlaylist) do
		w:setVolume(musicTrackVolume)
	end
	music.credits = love.audio.newSource("music/jesse_spillane_-_02_-_face_punch.ogg","stream")

	collectgarbage("collect")
	collectgarbage("collect")
end