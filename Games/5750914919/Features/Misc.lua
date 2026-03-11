local UI = Snowy.UI
local gameTab = UI.gameTab

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera

local packages = ReplicatedStorage.packages
local netModule = packages.Net

local shared = ReplicatedStorage:WaitForChild("shared")
local modules = shared.modules

local Net = require(netModule)
local NumberUtils = require(modules.NumberUtils)
local CurrencyController = require(ReplicatedStorage.client.legacyControllers.CurrencyController)

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local character = LocalPlayer.Character
local rootPart = character:WaitForChild("HumanoidRootPart")

local events = ReplicatedStorage.events

local world = workspace.world
local npcs = world.npcs

local box = gameTab:AddRightTabbox()

do -- Misc
    
    local client = ReplicatedStorage:WaitForChild("client")
    local modules = client.modules
    local backpack = modules.ui.Backpack
    local confirmation = require(backpack.confirmation)

    local backpack = playerGui:WaitForChild("backpack")
    local inventory = backpack.inventory
    local topButtons = inventory.TopButtons

    local miscTab = box:AddTab("Misc")

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

    do -- Spear Fishing
        local spearFishingToggle = miscTab:AddToggle("SpearFishingToggle", {
            Text = "Spear Fishing (Risky)",
            Default = false,
            Tooltip = "Spear da fish.",
        })
            
        local spearWater = workspace["Spearfishing Water"]
        local minigame = netModule["RE/SpearFishing/Minigame"]
        local junglePos = Vector3.new(-2713.29638671875, 157.14395141601562, -2058.97998046875)

        spearFishingToggle:OnChanged(function(value)
            LocalPlayer:RequestStreamAroundAsync(junglePos)
                
            while spearFishingToggle.Value do
                for _, zone in pairs(spearWater:GetChildren()) do
                    if not spearFishingToggle.Value then break end
                    LocalPlayer:RequestStreamAroundAsync(junglePos)

                    for _, fish in pairs(zone.ZoneFish:GetChildren()) do
                        if not spearFishingToggle.Value then break end
                        minigame:FireServer(fish:GetAttribute("UID"))
                        task.wait(0.55)
                        minigame:FireServer(fish:GetAttribute("UID"), true)
                    end
                end
                    
                task.wait()
            end
        end)
    end

    do -- Appraise anywhere
        local appraiseButton = topButtons.Appraise
        local appraiseButtonCon = getconnections(appraiseButton.Activated)[1]
        local appraiseButtonFunc = appraiseButtonCon.Function
        local appraiseToggle = miscTab:AddToggle("AppraiseToggle", {
            Text = "Unlock Appraise Gamepass",
            Default = false,
            Tooltip = "Lets you use appraise anywhere gamepass for free.",
        })
        
        local dialogInteract = netModule["RF/DialogInteract"]

        local Original
        Original = hookfunction(appraiseButtonCon.Function, function()
            LocalPlayer:RequestStreamAroundAsync(
                Vector3.new(383.10113525390625, 131.2406005859375, 243.93385314941406)
            )

            local appraiser = npcs:WaitForChild("Appraiser")
            local proximityPrompt = appraiser.ProximityPrompt
            ClickProximityPrompt(proximityPrompt)
            if appraiseToggle.Value then
                local cost = Net:RemoteFunction("AppraiseAnywhere/GetCost"):InvokeServer()

                return confirmation.prompt({
                    ["text"] = ("Appraise for %s" .. CurrencyController:GetDisplay()):format(cost),
                    ["no"] = function() end,
                    ["yes"] = function()
                        dialogInteract:InvokeServer(1, 1)
                        dialogInteract:InvokeServer(6, 1)
                    end
                })
            end

            return Original()
        end)
    end

    do -- Sell anywhere
        local sellEvent = events.SellAll
        local sellButton = topButtons.Sell
        local sellButtonCon = getconnections(sellButton.Activated)[1]
        local sellToggle = miscTab:AddToggle("SellToggle", {
            Text = "Unlock Sell Gamepass",
            Default = false,
            Tooltip = "Lets you use sell all anywhere gamepass for free.",
        })

        LocalPlayer:RequestStreamAroundAsync(
            Vector3.new(383.10113525390625, 131.2406005859375, 243.93385314941406)
        )

        local merchant = npcs:WaitForChild("Marc Merchant")
        local proximityPrompt = merchant.ProximityPrompt
        ClickProximityPrompt(proximityPrompt)
        
        local Original
        Original = hookfunction(sellButtonCon.Function, function()
            if sellToggle.Value then
                local confirmationData = {
                    ["text"] = "Sell every fish not favourited in your inventory?",
                    ["no"] = function() end,
                    ["yes"] = function()
                        sellEvent:InvokeServer()
                    end
                }

                local prompt = confirmation.prompt(confirmationData)
                local sellValue = events.PreviewSellAll:InvokeServer(false)
                prompt.Text = prompt.Text .. (" [<font color=\'#e4e596\'><b>%* C$</b></font>]"):format((NumberUtils:Comma(sellValue)))
                
                return
            end

            return Original()
        end)
    end

    local function OnCharacterAdded(newCharacter)
        character = newCharacter
        rootPart = character:WaitForChild("HumanoidRootPart")
    end

    LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
end
do -- Items
    local chests = world.chests
            
    --local inventory = CharacterModule.PS(LocalPlayer):WaitForChild("Inventory")

    local purchaseRemote = events.purchase
    local library = modules.library

    local allRods = require(library.rods)
    local allFish = require(library.fish)

    local rods, crates = {}, {}

    for i, v in pairs(allRods) do
        if typeof(v) ~= "table" then continue end
        if v.Unpurchasable or not v.Price or v.Price == math.huge then continue end

        table.insert(rods, i)
    end

    for i, v in pairs(allFish) do
        if typeof(v) ~= "table" then continue end
        if not v.IsCrate or not v.BuyMult then continue end
            
        table.insert(crates, i)
    end
            
    local itemsTab = box:AddTab("Shop")

    local rodsDropDown = itemsTab:AddDropdown("rodsDown", {
        Values = rods,
        Default = 1,
        Multi = false,
            
        Text = "Rods",
        Tooltip = "This is a tooltip",
    })

    itemsTab:AddButton("Buy", function() 
        local rod = rodsDropDown.Value
        purchaseRemote:FireServer(rod, "Rod", nil, 1)
    end)
    itemsTab:AddDivider()

    local cratesDropDown = itemsTab:AddDropdown("cratesDown", {
        Values = crates,
        Default = 1,
        Multi = false,
    
        Text = "Crates",
        Tooltip = "This is a tooltip",
    })

    local cratesAmount = itemsTab:AddSlider("CrateAmountSlider", {
        Text = "Amount",
        Default = 1,
        Min = 1,
        Max = 500,
        Rounding = 0,
        Compact = false,
    })

    itemsTab:AddButton("Buy", function() 
        local crate = cratesDropDown.Value
        local amount = cratesAmount.Value
        purchaseRemote:FireServer(crate, "fish", nil, amount)
    end)
end

do -- Bestiary
    local bestiaryTab = box:AddTab("Bestiary")
    local discoverLocation = events.discoverlocation

    local hud = playerGui:WaitForChild("hud")
    local safezone = hud.safezone
    local bestiary = safezone.bestiary

    local limitedCatagory = bestiary.NormalCategory
    local normalCatagory = bestiary.NormalCategory

    bestiaryTab:AddButton("Discover all locations", function() 
        for i, v in pairs(normalCatagory.scroll:GetChildren()) do
            if not v:IsA("ImageButton") then continue end
            discoverLocation:FireServer(v.Name)
        end

        for i, v in pairs(limitedCatagory.scroll:GetChildren()) do
            if not v:IsA("ImageButton") then continue end
            discoverLocation:FireServer(v.Name)
        end
    end)
end