local CurrentCamera = workspace.CurrentCamera 

local loader = {}
loader.__index = loader

function loader.new()
    -- UI Elements --

    local loadingSquare = Drawing.new("Square")
    loadingSquare.Visible = true
    loadingSquare.Filled = true
    loadingSquare.Color = Color3.fromRGB(15, 15, 17)
    loadingSquare.Size = Vector2.new(400, 300)
    loadingSquare.ZIndex = 2
    loadingSquare.Position = CurrentCamera.ViewportSize / 2 - loadingSquare.Size / 2

    local borderVector = Vector2.new(2, 2)
    local borderSquare = Drawing.new("Square")
    borderSquare.Visible = true
    borderSquare.Filled = false
    borderSquare.Color = Color3.fromRGB(23, 0, 65)
    borderSquare.Size = loadingSquare.Size + borderVector
    borderSquare.Thickness = 2
    borderSquare.ZIndex = 1
    borderSquare.Position = loadingSquare.Position - borderVector / 2

    local brandText = Drawing.new("Text")
    brandText.Visible = true
    brandText.Size = 32
    brandText.ZIndex = 2
    brandText.Outline = true
    brandText.OutlineColor = Color3.fromRGB(31, 0, 88)
    brandText.Color = Color3.fromRGB(255, 255, 255)
    brandText.Text = "Aster Loader"
    brandText.Position = loadingSquare.Position + Vector2.new(15, 5)

    local statusDot = Drawing.new("Circle")
    statusDot.Radius = 6
    statusDot.ZIndex = 3
    statusDot.Filled = true
    statusDot.Color = Color3.fromRGB(81, 155, 71)
    statusDot.Visible = true
    statusDot.Position = loadingSquare.Position + loadingSquare.Size - Vector2.new(
        statusDot.Radius + 2, 
        statusDot.Radius + 2
    )

    local versionText = Drawing.new("Text")
    versionText.Visible = true
    versionText.Size = 15
    versionText.ZIndex = 2
    versionText.Outline = true
    versionText.Color = Color3.fromRGB(255, 255, 255)
    versionText.Text = "v1.0"
    versionText.Position = loadingSquare.Position + Vector2.new(2, 
        loadingSquare.Size.Y - versionText.TextBounds.Y - 2
    )

    local loaderText = Drawing.new("Text")
    loaderText.Visible = true
    loaderText.Size = 32
    loaderText.ZIndex = 2
    loaderText.Outline = true
    loaderText.Color = Color3.fromRGB(255, 255, 255)
    loaderText.Text = "Checking version hash..."
    loaderText.Position = loadingSquare.Position + Vector2.new(
        loadingSquare.Size.X / 2 - loaderText.TextBounds.X / 2, 
        loadingSquare.Size.Y - loaderText.TextBounds.Y
    ) - Vector2.new(0, 25)
        
    -- Circle spin --

    local lines = {}
    local count = 12
    local radius = 70
    local center = loadingSquare.Position + loadingSquare.Size / 2

    for i = 1, count do
        local line = Drawing.new("Line")
        line.Visible = true
        line.Color = Color3.fromRGB(160,110,255)
        line.Thickness = 4
        line.ZIndex = 3
        lines[i] = line
    end

    task.spawn(function()
        while loadingSquare do
            for i = 1, count do
                local angle = math.pi * 2 / count * i + tick()
                
                lines[i].From = Vector2.new(
                    center.X + math.cos(angle) * (radius - 18), 
                    center.Y + math.sin(angle) * (radius - 18)
                )
                lines[i].To = Vector2.new(
                    center.X + math.cos(angle) * radius, 
                    center.Y + math.sin(angle) * radius
                )
            end
            
            task.wait()
        end
    end)

    return setmetatable({
        _loadingSquare = loadingSquare,
        _loaderText = loaderText
    }, loader)
end

function loader:UpdateText(text)
    local loadingSquare, loaderText = self._loadingSquare, self._loaderText

    loaderText.Text = text
    loaderText.Position = loadingSquare.Position + Vector2.new(
        loadingSquare.Size.X / 2 - loaderText.TextBounds.X / 2, 
        loadingSquare.Size.Y - loaderText.TextBounds.Y
    ) - Vector2.new(0, 25)
end

return loader.new