local UI = Snowy.UI
local gameTab = UI.gameTab

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera

local packages = ReplicatedStorage.packages
local netModule = packages.Net

local Net = require(netModule)

local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character
local rootPart = character:WaitForChild("HumanoidRootPart")

local world = workspace.world
local npcs = world.npcs

local autoTabbox = gameTab:AddRightTabbox()


local function ClickProximityPrompt(prompt)
    local part = Instance.new("Part")
    part.Size = Vector3.new(1, 1, 1) 
    part.Anchored = true
    part.CanCollide = false
    part.Position = rootPart.Position + (Camera.CFrame.LookVector * 10) 
    part.Parent = workspace
        
    local oldParent = prompt.Parent 

    prompt.MaxActivationDistance = 2e9
    prompt.RequiresLineOfSight = false
    prompt.Parent = part
                
    prompt.PromptShown:wait()

    prompt:InputHoldBegin()
    prompt:InputHoldEnd()

    prompt.MaxActivationDistance = 7
    prompt.RequiresLineOfSight = true
    prompt.Parent = oldParent

    part:Destroy()
end

local mutations

local test = require(game:GetService("ReplicatedStorage").shared.modules.fishing.mutations)

do -- appraise
    LocalPlayer:RequestStreamAroundAsync(
        Vector3.new(383.10113525390625, 131.2406005859375, 243.93385314941406)
    )

    local dialogInteract = netModule["RF/DialogInteract"]
    local appraiser = npcs:WaitForChild("Appraiser")
    local proximityPrompt = appraiser.ProximityPrompt

    ClickProximityPrompt(proximityPrompt)
    
    local function Appraise()
        dialogInteract:InvokeServer(1, 1)
        dialogInteract:InvokeServer(5, 1)
        dialogInteract:InvokeServer(3, 1)
    end

    local appraiseTab = autoTabbox:AddTab("Appraise")
    local autoAppraiseToggle = appraiseTab:AddToggle("AutoAppraiseToggle", {
        Text = "Auto-Appraise",
        Default = false,
        Tooltip = "Spear da fish.",
    })

    local attributeType = appraiseTab:AddDropdown("AttributeDropDown", {
        Values = {
            "Shiny", 
            "Sparkling",
        },
        Default = 1,
        Multi = true,
    
        Text = "Attribute",
        Tooltip = "List of all attributes.",
    })

    local mutationType = appraiseTab:AddDropdown("mutationDropDown", {
        Values = { 
            "Albino",
            "Darkened",
            "Negative",
            "Glossy",
            "Translucent",
            "Lunar",
            "Electric",
            "Silver",
            "Hexed",
            "Frozen",
            "Mosaic",
            "Scorched",
            "Amber",
            "Abyssal",
            "Coral",
            "Poisoned",
            "Fossilized",
            "Vined",
            "Crimson",
            "Midas",
            "Boreal",
            "Fallen",
            "Spirit",
            "Greedy",
            "Mythical",
            "Mourned",
            "Shrouded"
        },
        Default = 1,
        Multi = true,
    
        Text = "Mutations",
        Tooltip = "List of all mutations.",
    })

    autoAppraiseToggle:OnChanged(function(boolean)
        while autoAppraiseToggle.Value do
            local fishinfo = character:WaitForChild("fishinfo")
            local info = fishinfo.Info
            local subValues = info.Subvalues
            local text = subValues.Text

            local attributes, mutations = attributeType.Value, mutationType.Value 
            local hasAttributes, hasMutation = true, false

            for i, _ in pairs(attributes) do
                if not text:find(i) then
                    hasAttributes = false
                end
            end

            for i, _ in pairs(mutations) do
                if text:find(i) then
                    hasMutation = true
                    break
                end
            end

            if hasAttributes and hasMutation then return autoAppraiseToggle:SetValue(false) end

            Appraise()
            task.wait()
        end
    end)
end

do -- enchant
    local enchantTab = autoTabbox:AddTab("Enchant")
end