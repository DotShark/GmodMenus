local menuFiles = file.Find("ds_menus/*.lua", "LUA")

for _, menuFile in ipairs(menuFiles) do
	if SERVER then
		AddCSLuaFile("ds_menus/" .. menuFile)
	else 
		include("ds_menus/" .. menuFile)
	end
end