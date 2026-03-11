local PropertyChanged = {}
PropertyChanged.__index = PropertyChanged
PropertyChanged.instances = {}
PropertyChanged.connections = {}

function PropertyChanged.new(...)
    local PropertyChanged = setmetatable({}, PropertyChanged)

    PropertyChanged:AddInstances(...)

    return PropertyChanged
end

function PropertyChanged:AddInstances(...)
    local parameters = {...}
    local instances = self.instances

    for _, paramter in ipairs(parameters) do
        if not table.find(instances, paramter) then
            if connectionFunction then
                self:Connect(self.connectionFunction)
            end

            table.insert(instances, paramter)
        end
    end
end

function PropertyChanged:Connect(instance, func)
    assert(typeof(instance) == "Instance" and typeof(func) == "function", "Invaild type")

    local connections = self.connections
    local connection = instance:GetPropertyChangedSignal("Value"):Connect(func)
    
    connections[instance] = connection
end

function PropertyChanged:Disconnect(instance)
    assert(typeof(instance) == "Instance", "Invaild type")

    local connections = self.connections
    local connection = connections[instance]

    if connection then
        connection:Disconnect()
    end
end

function PropertyChanged:ConnectAll(func)
    assert(typeof(func) == "function", "Invaild type")

    local instances = self.instances  

    self.connectionFunction = func

    for _, instance in ipairs(instances) do
        self:Connect(instance, func)
    end
end

function PropertyChanged:DisconnectAll()
    local instances = self.instances

    for _, instance in ipairs(instances) do
        self:Disconnect(instance)
    end
end

return PropertyChanged
