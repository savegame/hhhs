-- written by groverbuger for g3d
-- august 2020
-- MIT license

----------------------------------------------------------------------------------------------------
-- simple obj loader
----------------------------------------------------------------------------------------------------
--alesan99 additions
	--optional vertex color loading

-- stitch two tables together and return the result
-- useful for use in the loadObjFile function
local compileObj
local function concatTables2(t1,t2)
    local ret = {}
    for i,v in ipairs(t1) do
        ret[#ret +1] = v
    end
    for i,v in ipairs(t2) do
        ret[#ret +1] = v
    end

    return ret
end
local function concatTables3(t1,t2,t3)
    local ret = {}
    for i,v in ipairs(t1) do
        ret[#ret +1] = v
    end
    for i,v in ipairs(t2) do
        ret[#ret +1] = v
    end
    for i,v in ipairs(t3) do
        ret[#ret +1] = v
    end

    return ret
end
local function concatTables4(t1,t2,t3,t4)
    local ret = {}
    for i,v in ipairs(t1) do
        ret[#ret +1] = v
    end
    for i,v in ipairs(t2) do
        ret[#ret +1] = v
    end
    for i,v in ipairs(t3) do
        ret[#ret +1] = v
    end
    for i,v in ipairs(t4) do
        ret[#ret +1] = v
    end

    return ret
end

-- give path of file
-- returns a lua table representation
-- can also load collision mesh (_COLL)
function loadObjFile(path, options)
	options = options or {}
    local verts = {}
    local faces = {}
    local uvs = {}
	local normals = {}
	local colors = {}

	local vertexColors = options.vertexColors
	local loadObjects = options.loadObjects
	local correctUVs = options.correctUVs

	--Vertices added to compiled table {x,y,z,u,v,nx,ny,nz,r,g,b}
	--IF loading objects: multiple
	local compiled
	if loadObjects then
		compiled = {}
	end

	local name = false
	local mitlib = ""
	local isCOL = false

	local isOBJ = false --will only store one vertex for spawning in game

    -- go line by line through the file
    for line in love.filesystem.lines(path) do
        local words = {}

        -- split the line into words
        for word in line:gmatch("([^".."%s".."]+)") do
            table.insert(words, word)
		end
		
		-- if the first word in this line is a "o", then this defines an object
		if loadObjects and words[1] == "o" then
			--compile previous object (if there was one)
			if name then
				compiled[name or #compiled+1] = compileObj(verts, uvs, normals, faces, colors, isCOL, isOBJ, vertexColors)
			end
			name = words[2]
			isCOL = (name:sub(-4,-1):lower() == "_col")
			isOBJ = (name:sub(-4,-1):lower() == "_obj")
			faces = {}
        end

        -- if the first word in this line is a "v", then this defines a vertex
        if words[1] == "v" then
			verts[#verts+1] = {tonumber(words[2]), tonumber(words[3]), tonumber(words[4])}
			--vertex colors appended to end
			if vertexColors then
				if words[5] then
					colors[#colors+1] = {tonumber(words[5]), tonumber(words[6]), tonumber(words[7])}
				else
					colors[#colors+1] = {1,1,1}
				end
			end
        end

        -- if the first word in this line is a "vt", then this defines a texture coordinate
		if words[1] == "vt" then
			if correctUVs then
				uvs[#uvs+1] = {tonumber(words[2]), 1-tonumber(words[3])}
			else
				uvs[#uvs+1] = {tonumber(words[2]), tonumber(words[3])}
			end
        end

        -- if the first word in this line is a "vn", then this defines a vertex normal
		if words[1] == "vn" then
            normals[#normals+1] = {tonumber(words[2]), tonumber(words[3]), tonumber(words[4])}
		end

        -- if the first word in this line is a "f", then this is a face
        -- a face takes three arguments which refer to points, each of those points take three arguments
        -- the arguments a point takes is v,vt,vn
        if words[1] == "f" then
            local store = {}
            for i=2, #words do
                local num = ""
                local word = words[i]
                local ii = 1
                local char = word:sub(ii,ii)

                while true do
                    char = word:sub(ii,ii)
                    if char ~= "/" then
                        num = num .. char
                    else
                        break
                    end
                    ii = ii + 1
                end
                store[#store+1] = tonumber(num)

                local num = ""
                ii = ii + 1
                while true do
                    char = word:sub(ii,ii)
                    if ii <= #word and char ~= "/" then
						num = num .. char
                    else
                        break
                    end
                    ii = ii + 1
                end
                store[#store+1] = tonumber(num) or false

                local num = ""
                ii = ii + 1
                while true do
                    char = word:sub(ii,ii)
                    if ii <= #word and char ~= "/" then
                        num = num .. char
                    else
                        break
                    end
                    ii = ii + 1
                end
                store[#store+1] = tonumber(num) or false
            end

            faces[#faces+1] = store
		end
	end
	
	if loadObjects then
		compiled[name or #compiled+1] = compileObj(verts, uvs, normals, faces, colors, isCOL, isOBJ, vertexColors)
	else
		compiled = compileObj(verts, uvs, normals, faces, colors, isCOL, isOBJ, vertexColors)
	end

    return compiled
end

function compileObj(verts, uvs, normals, faces, colors, isCOL, isOBJ, vertexColors)
	-- put it all together in the right order
	local compiled = {}

	local no_uv = {0,0}
	local hasUVs = true
	if #uvs == 0 then
		hasUVs = false
	end

	if isCOL then
		--only store x, y (assume no uv)
		--{{x,y,x,y,x,y},{x,y,x,y,x,y}}
		for i,face in pairs(faces) do
			local f = {}
			for i2 = 1, #face, 3 do --skip over uvs and normals
				table.insert(f, -verts[face[i2]][1]) --x
				table.insert(f, verts[face[i2]][3]) --y
			end
			table.insert(compiled, f)
		end
	elseif isOBJ then
		--only store one vertex to spawn object
		local count = 0
		compiled[1] = 0
		compiled[2] = 0
		for i,face in pairs(faces) do
			for i2 = 1, #face, 3 do --skip over uvs and normals
				count = count + 1
				compiled[1] = compiled[1] + (-verts[face[i2]][1])
				compiled[2] = compiled[2] + (verts[face[i2]][3])
			end
		end
		compiled[1] = compiled[1]/count
		compiled[2] = compiled[2]/count
	else
		if vertexColors then
			for i,face in pairs(faces) do
				compiled[#compiled +1] = concatTables4(verts[face[1]], uvs[face[2]] or no_uv, normals[face[3]], colors[face[1]])
				compiled[#compiled +1] = concatTables4(verts[face[4]], uvs[face[5]] or no_uv, normals[face[6]], colors[face[4]])
				compiled[#compiled +1] = concatTables4(verts[face[7]], uvs[face[8]] or no_uv, normals[face[9]], colors[face[7]])
			end
		elseif hasUVs then
			for i,face in pairs(faces) do
				compiled[#compiled +1] = concatTables3(verts[face[1]], uvs[face[2]], normals[face[3]])
				compiled[#compiled +1] = concatTables3(verts[face[4]], uvs[face[5]], normals[face[6]])
				compiled[#compiled +1] = concatTables3(verts[face[7]], uvs[face[8]], normals[face[9]])
			end
		else--no uvs
			for i,face in pairs(faces) do
				compiled[#compiled +1] = concatTables2(verts[face[1]], normals[face[3]])
				compiled[#compiled +1] = concatTables2(verts[face[4]], normals[face[6]])
				compiled[#compiled +1] = concatTables2(verts[face[7]], normals[face[9]])
			end
		end
	end

	return compiled
end