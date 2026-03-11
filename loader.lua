local uiRepo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local Library = loadstring(game:HttpGet(uiRepo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(uiRepo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(uiRepo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "🪻 Aster 🪻",
    Center = true, 
    AutoShow = false,
})

getgenv().Snowy = {
    UI = {
        Library = Library,
        Window = Window
    },
}

-- Loader logic -- 

local HttpService = game:GetService("HttpService")

local api = "https://api.github.com/repos/SnowyXS/Aster/git/trees/stable?recursive=1"
local repo = "https://raw.githubusercontent.com/SnowyXS/Aster/stable/"
local loaderUI = loadstring(game:HttpGet(repo .. "Libraries" .. "/UI/loader.lua"))()()

task.wait(1)

local path = "Aster"
if not isfolder(path) then makefolder(path) end

local cacheFile = path .. "/hashes.json"
local cache = {}

if isfile(cacheFile) then
    local content = readfile(cacheFile)
    cache = HttpService:JSONDecode(content)
end

local result = game:HttpGet(api)
local tree = HttpService:JSONDecode(result)
local fileList = tree.tree

for _, file in pairs(fileList) do
    if file.type ~= "blob" then continue end
    local treePath = file.path
    local sha = file.sha
    local filePath = path .. "/" .. treePath

    if treePath:find("Libraries/") or treePath:find("Games/") then
        if cache[treePath] ~= sha or not isfile(filePath) then
            loaderUI:UpdateText("Updating Files...")
            local newContent = game:HttpGet(repo .. treePath)
    
            if cache[treePath] ~= sha then
                if isfile(filePath) and newContent ~= readfile(filePath) then
                    cache[treePath] = sha
                end
            end

            writefile(filePath, newContent)
        end
    end
end

writefile(cacheFile, HttpService:JSONEncode(cache))

local gameID = game.GameId
local games = listfiles(`{path}/Games`)

for _, folder in pairs(games) do
    if isfolder(folder) and folder:find(gameID) then
        loaderUI:UpdateText(`Found script for {gameID}`)
        task.wait(1)

        local initPath = folder .. "/init.lua"
        assert(isfile(initPath), "Init.lua file missing.")

        Snowy.paths = {
            features = folder .. "/Features",
            libraries = folder .. "/Libraries",
            info = folder .. "/info.json"
        }
        
        loadfile(initPath)()

        cleardrawcache()
    end
end

SaveManager:SetFolder("Aster/Configs/" .. gameID)

local settingsTab = Window:AddTab("Settings")
local menuGroup = settingsTab:AddLeftGroupbox("Menu")

menuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { 
    Default = "Insert", 
    NoUI = false, 
    Text = "Menu keybind" 
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings() 
ThemeManager:SetFolder("Aster/Configs/Themes")
SaveManager:BuildConfigSection(settingsTab) 
ThemeManager:ApplyToTab(settingsTab)

Library.Toggle()
