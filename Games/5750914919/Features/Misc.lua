local UI = Snowy.UI
local gameTab = UI.gameTab

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera

local packages = ReplicatedStorage.packages
local netModule = packages.Net

local shared = ReplicatedStorage:WaitForChild("shared")
local sharedModules = shared.modules

local Net = require(netModule)
local NumberUtils = require(sharedModules.NumberUtils)
local CurrencyController = require(ReplicatedStorage.client.legacyControllers.CurrencyController)

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local character = LocalPlayer.Character
local rootPart = character:WaitForChild("HumanoidRootPart")

local events = ReplicatedStorage.events

local world = workspace.world
local npcs = world.npcs

local box = gameTab:create_category("Misc")

do -- Misc
    
    local client = ReplicatedStorage:WaitForChild("client")
    local modules = client.modules
    local backpack = modules.ui.Backpack
    local confirmation = require(backpack.confirmation)

    local backpack = playerGui:WaitForChild("backpack")
    local inventory = backpack.inventory
    local topButtons = inventory.TopButtons

    local miscTab = box:create_category("Risky Functions")

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
        local spearFishingToggle = miscTab:create_toggle("Spear Fishing")
            
        local spearWater = workspace["Spearfishing Water"]
        local minigame = netModule["RE/SpearFishing/Minigame"]
        local junglePos = Vector3.new(-2713.29638671875, 157.14395141601562, -2058.97998046875)

        spearFishingToggle:on_changed(function(value)
            LocalPlayer:RequestStreamAroundAsync(junglePos)
                
            while spearFishingToggle.Value do
                for _, zone in pairs(spearWater:GetChildren()) do
                    if not spearFishingToggle.Value then break end
                    LocalPlayer:RequestStreamAroundAsync(junglePos)

                    for _, fish in pairs(zone.ZoneFish:GetChildren()) do
                        if not spearFishingToggle.Value then break end
                        minigame:FireServer(fish:GetAttribute("UID"))
                        task.wait(2)
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
        local appraiseToggle = miscTab:create_toggle("Unlock Appraise Gamepass")
        
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
                        dialogInteract:InvokeServer(5, 1)
                        dialogInteract:InvokeServer(3, 1)
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
        local sellToggle = miscTab:create_toggle("Unlock Sell Gamepass")

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
    --[[ Temporarily disabled due to missing keybinds on ui library
    do --  Fast Place Crab Cages
        local SharedCrabCage = require(sharedModules:WaitForChild("SharedCrabCage"))
        local CrabCageController = require(ReplicatedStorage.client.legacyControllers.CrabCageController)
        miscTab:AddDivider()
        
        miscTab:AddLabel("Fast Place | Crab Cages"):AddKeyPicker("FastPlace", {
            Default = "Z",
            Mode = "Hold",
            NoUI = false, 
            Text = "Fast Place Crab Cages",
        })

        miscTab:AddLabel("Fast Claim | Crab Cages"):AddKeyPicker("FastClaim", {
            Default = "X",
            NoUI = false, 
            Text = "Fast Claim Crab Cages",

            Callback = function(Value)
                for _, v in pairs(CrabCageController.ActiveCages) do
                    local data = v.data.s

                    if data == SharedCrabCage.CageState.Claimable then
                        CrabCageController:Claim(v)

                        task.wait(0.1)
                    end
                end
            end,
        })

        task.spawn(function()
            while true do
                local state = Options.FastPlace:GetState()

                if state and CrabCageController._HeldCage then
                    CrabCageController:Place(CrabCageController._HeldCage, CrabCageController._PreviewModel:GetPivot())
                end

                task.wait()
            end
        end)
    end
    ]]
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
    local library = sharedModules.library

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
            
    local itemsTab = box:create_category("Shop")

    do -- Rods
        local rodsTab = itemsTab:create_category("Rods")
        local rodsDropDown = rodsTab:create_dropdown("Rod", {
            Options = rods,
        })

        local buybutton = rodsTab:create_button("Buy")

        buybutton:on_changed(function() 
            local rod = rodsDropDown:get_value()
            purchaseRemote:FireServer(rod, "Rod", nil, 1)
        end)
    end

    do -- Crates
        local cratesTab = itemsTab:create_category("Crates")

        local cratesDropDown = cratesTab:create_dropdown("Crate", {
            Options = crates,
        })

        local cratesAmount = cratesTab:create_slider("Amount", {
            Default = 1,
            Min = 1,
            Max = 50,
        })

        local buybutton = cratesTab:create_button("Buy")

        buybutton:on_changed(function() 
            local crate = cratesDropDown:get_value()
            local amount = cratesAmount.Value
            purchaseRemote:FireServer(crate, "fish", nil, amount)
        end)
    end
end