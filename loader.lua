--[[

local uiRepo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local Library = loadstring(game:HttpGet(uiRepo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(uiRepo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(uiRepo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Aster",
    Center = true, 
    AutoShow = false,
})

]]
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/Aster/refs/heads/stable/Libraries/UI/Library.lua"))()
local Window = Library:create_window(
	"Aster", 
	"rbxassetid://115819865049802", 
	"v1.0.6"
)
local Category = Window:create_category("main")

getgenv().Snowy = {
    UI = {
        Library = Library,
        Window = Window,
        Category = Category
    },
}

Window.set_visible(false)

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

local settings = Category:create_category("Settings")
local menu_key =  settings:create_label("Menu Key"):add_keybind(Enum.KeyCode.Insert)

menu_key:on_keypress(function(key, is_pressed)
    if is_pressed then
        Window.set_visible(not Window.window_frame.Visible)
    end
end)

Window.set_visible(true)

--[[
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
]]
