local BindableEvents = loadfile("Aster/Libraries/Dependencies/BindableEvents.lua")()

local VirtualInputManager = game:GetService("VirtualInputManager")
local Stats = game:GetService("Stats")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local networkStats = Stats.Network
local serverStatsItem = networkStats.ServerStatsItem

local dataPing = serverStatsItem["Data Ping"]

local LocalPlayer = Players.LocalPlayer
local backpack = LocalPlayer.Backpack

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid.Animator

local packages = ReplicatedStorage:WaitForChild("packages")
local Net = require(packages:WaitForChild("Net"))

local RodController = {}
RodController.__index = RodController

local function IsRod(instance)
    local name = instance.Name:lower()
    return instance:IsA("Tool") and (name:find("rod") or instance:FindFirstChild("rod/client"))
end

function RodController.new()
    local rodAddedEvent = BindableEvents:Create()
    local onCastEvent = BindableEvents:Create()
    local rodEquippedEvent = BindableEvents:Create()
    local rodUnEquippedEvent = BindableEvents:Create()
    local childRemovedEvent = BindableEvents:Create()

    local Controller = setmetatable({
        _isEquipped = false,
        _rodAddedEvent = rodAddedEvent,
        _onCastEvent = onCastEvent,
        _rodEquippedEvent = rodEquippedEvent,
        _rodUnEquippedEvent = rodUnEquippedEvent,
        _rodChildRemoved = childRemovedEvent,
        _castRemote = Net:RemoteFunction("FishingRod/Cast", -1),
        _resetRemote = Net:RemoteEvent("FishingRod/Reset", -1)
    }, RodController)

    for _, v in pairs(backpack:GetChildren()) do
        if IsRod(v) then
            Controller._rod = v
    
            break
        end
    end
    
    for _, v in pairs(character:GetChildren()) do
        if IsRod(v) then
            Controller._rod = v
            Controller._isEquipped = true
            
            break
        end
    end

    local function OnCastChanged(newValue)
        onCastEvent:Fire(newValue)
    end

    local function OnEquip()
        Controller._isEquipped = true
        rodEquippedEvent:Fire()
    end

    local function OnUnequip()
        Controller._isEquipped = false
        rodUnEquippedEvent:Fire()
    end

    local function OnChildRemoved(instance)
        childRemovedEvent:Fire(instance)
    end

    local function OnChildAdded(instance)
        if Controller._rod == instance or not IsRod(instance) then return end
        Controller._rod = instance

        local values = instance.values
        local casted = values.casted

        instance.Equipped:Connect(OnEquip)
        instance.Unequipped:Connect(OnUnequip)
        instance.ChildRemoved:Connect(OnChildRemoved)
        casted.Changed:Connect(OnCastChanged)

        rodAddedEvent:Fire(instance)
    end
    
    local function OnCharacterAdded(newCharacter)
        humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
        humanoid = newCharacter:WaitForChild("Humanoid")
        
        backpack = LocalPlayer.Backpack
        character = newCharacter

        backpack.ChildAdded:Connect(OnChildAdded)
    end

    local rodObject = Controller._rod
    local values = rodObject.values
    local casted = values.casted

    rodObject.Equipped:Connect(OnEquip)
    rodObject.Unequipped:Connect(OnUnequip)
    rodObject.ChildRemoved:Connect(OnChildRemoved)

    casted.Changed:Connect(OnCastChanged)

    backpack.ChildAdded:Connect(OnChildAdded)
    LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

    return Controller
end

-- Main functions --

function RodController:GetRod()
    return self._rod
end

function RodController:IsEquipped()
    return self._isEquipped
end

function RodController:Cast(skip, percentage)
    if not skip then return VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1) end
    
    local castRemote = self._castRemote
    castRemote:InvokeServer(percentage, percentage == 100) 
end

function RodController:Reset()
    local resetRemote = self._resetRemote

    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    resetRemote.FireServer(resetRemote)

    for i, v in pairs(animator:GetPlayingAnimationTracks()) do
        if v.Name == "waiting" then
            v:Stop()
            break
        end
    end
end

-- Bindables --

function RodController:OnAdded(callback)
    local rodAddedEvent = self._rodAddedEvent

    rodAddedEvent:Connect(callback)
end

function RodController:OnCastChanged(callback)
    local castEventChanged = self._onCastEvent

    castEventChanged:Connect(callback)
end

function RodController:OnEquipped(callback)
    local rodEquippedEvent = self._rodEquippedEvent

    rodEquippedEvent:Connect(callback)
end

function RodController:OnUnEquipped(callback)
    local rodUnEquippedEvent = self._rodUnEquippedEvent

    rodUnEquippedEvent:Connect(callback)
end

function RodController:OnChildRemoved(callback)
    local rodChildRemoved = self._rodChildRemoved

    rodChildRemoved:Connect(callback)
end

return RodController