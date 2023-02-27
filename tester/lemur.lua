package.path = package.path .. ";?/init.lua"

local lemur = require("modules.lemur")

local ModulesToLoad = {
    TNet = "src",
    TestEZ = "modules/testez/src"
}

local habitat = lemur.Habitat.new()

local ReplicatedStorage = habitat.game:GetService("ReplicatedStorage")

for moduleName, modulePath in pairs(ModulesToLoad) do
    local loadedModule = habitat:loadFromFs(modulePath)
    loadedModule.Name = moduleName
    loadedModule.Parent = ReplicatedStorage
end

local testRunner = habitat:loadFromFs("tester/testrunner.server.lua")
habitat:require(testRunner)