
if not onServer() then return end

Player():removeScript("data/scripts/player/mapcommands.lua")
Player():removeScript("data/scripts/player/mapcommandarrowlines.lua")
Player():removeScript("data/scripts/player/map/mapcommandarrowlines.lua")

Player():addScriptOnce("data/scripts/player/map/mapcommands.lua")
Player():addScriptOnce("data/scripts/player/client/musiccoordinator.lua")

Player():addScriptOnce("mods/SectorManager/scripts/player/sectorOpener.lua")