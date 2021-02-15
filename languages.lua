local currentLanguage
function loadLanguage(n)
	if n ~= currentLanguage then
		currentLanguage = n
		local s = love.filesystem.read("languages/" .. n .. ".json")
		TEXT = JSON:decode(s)
	end
end