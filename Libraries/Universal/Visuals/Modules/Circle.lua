local Camera = workspace.CurrentCamera
local BindableEvents = loadfile("libraries/bindablevents.lua")()

--[[
    Circle.new(
        <int> corners, 
        <int> radius, 
        <Color3> color : Color3.fromRGB(128, 0, 128), 
        <Boolean> visible : true,
        <Vector3> position : Vector3.new(0, 0, 0)
    ) 

    // Functions
    Circle:SetPoints(<int> corners, <int> radius) // Sets up the circle points for drawing
    Circle:OnUpdate(<Function> callback) // Called on every frame before the circle is updated

    // Variables Setter/Getter
    <Boolean> Circle.Visible
    <Color3> Circle.Color
    <Position> Circle.Position

    The examples below contains both a Static Circle and a Dynamic Circle.

    // Static Example 
    local position = primaryPart.Position - Vector3.new(0, 2.5, 0)
    local playerCircle = Circle.new(12, 10, Color3.new(1, 0, 0), true, position)

    // Dynamic Example
    local playerCircle = Circle.new(12, 10)
    playerCircle:OnUpdate(function()
        local position = primaryPart.Position - Vector3.new(0, 2.5, 0)

        playerCircle.Position = position
    end)
--]]

local Circle = {
    _circles = {}
}
Circle.__index = Circle

-- Creates a new circle
function Circle.new(corners, radius, color, visible, position)
    local self = setmetatable({
        -- Inner Vars ---
        points = {},
        lines = {},
        _updateEvent = BindableEvents:Create(),

        -- Public Vars --
        Color = color or Color3.fromRGB(128, 0, 128),
        Visible = visible or true,
        Position = position or Vector3.new(0, 0, 0)
    }, Circle)

    self:SetPoints(corners, radius)
    
    return self
end

-- Setups the points of the circle
function Circle:SetPoints(corners, radius)
    self:_clear()
    local circles = self._circles
    local points = self.points
    local lines = self.lines

    for i = 1, corners do 
        local angle = i/corners * math.pi * 2
        local point = Vector3.new(
            math.cos(angle) * radius, 
            0, 
            math.sin(angle) * radius
        )

        local line = Drawing.new("Line")
        line.Thickness = 2
        line.Visible = self.Visible
        line.Color = self.Color

        table.insert(lines, line)
        table.insert(points, point)
    end
    
    table.insert(circles, self)
end

-- Connects a callback to a bindable event that is called every frame before the circle is updated.
function Circle:OnUpdate(callback)
    local updateEvent = self._updateEvent
    updateEvent:Connect(callback)
end

-- A function used by the rendered to update all the circles to their positions
function Circle.update()
    local circles = Circle._circles

    for _, circle in pairs(circles) do
        circle._updateEvent:Fire()
        local worldPosition = circle.Position
        local points, lines = circle.points, circle.lines
        local corners = #points

        for i = 1, corners do
            local nextPoint = i % corners + 1

            local point, onScreen = Camera:WorldToViewportPoint(
                worldPosition + points[i]
            )
            local destination, onScreen2 = Camera:WorldToViewportPoint(
                worldPosition + points[nextPoint]
            )

            local line = lines[i]

            if circle.Visible and point.Z > 0 and destination.Z > 0 then 
                line.From = Vector2.new(point.X, point.Y)
                line.To = Vector2.new(destination.X, destination.Y)
                line.Color = circle.Color
                line.Visible = true
            else
                line.Visible = false
            end
        end
    end
end

-- Inner Function to clear the old points
function Circle:_clear()
    local points = self.points
    local lines = self.lines

    for i, v in pairs(lines) do -- We can clear both arrays using one loop due to them having indentical size
        lines[i] = nil
        points[i] = nil
        v:Destroy()
    end
end

return Circle