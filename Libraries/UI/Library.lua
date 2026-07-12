local UserInputService = game:GetService("UserInputService")
local Library = {}
local Base = {}
Base.__index = Base

local screengui = Instance.new("ScreenGui", game.CoreGui)

do
	function Base:create_button(title) 
		local Window = self.Window
		local button = {
			Window = Window,
		}
		
		local bindable = BindableEvents:Create()
		local objects = self.objects

		local row = Library.create_row(self.category_frame, title)
		button.instance = row
		
		function button:on_changed(func)
			bindable:Connect(func)
		end

		function button:fire(...)
			bindable:Fire(...)
		end
		
		function button:click()
			local window = self.Window
			local linked_category = self.linked_category

			if linked_category then
				window:open_category(linked_category)
			else
				bindable:Fire()
			end
		end
		
		function button:set_category(category)
			local image_label = Instance.new("ImageLabel", row)
			image_label.AnchorPoint = Vector2.new(1, 0.5)
			image_label.BackgroundTransparency = 1
			image_label.Position = UDim2.new(1, -5, 0.5, 1)
			image_label.Size = UDim2.new(0, 25, 0, 25)
			image_label.Image = "rbxassetid://133800611596665"
			
			button.linked_category = category
		end
		
		table.insert(objects, button)
		
		Library.init_highlight(self, row)

		self.size = self.size + 1
		Window:resize(self)
		
		return button
	end

	function Base:create_toggle(title) 
		local Window = self.Window
		local toggle = {
			Window = Window,
			Value = false,
		}

		local bindable = BindableEvents:Create()
		local objects = self.objects

		local row = Library.create_row(self.category_frame, title)
		toggle.instance = row
		
		local toggle_status = Instance.new("Frame", row)
		toggle_status.AnchorPoint = Vector2.new(1, 0.5)
		toggle_status.BackgroundColor3 = Color3.fromRGB(255, 0, 4)
		toggle_status.Position = UDim2.new(1, -12, 0.5, 1)
		toggle_status.Size = UDim2.new(0, 10, 0, 10)
		
		local UICorner = Instance.new("UICorner", toggle_status)
		UICorner.CornerRadius = UDim.new(0, 90)
		
		function toggle:on_changed(func)
			bindable:Connect(func)
		end

		function toggle:fire(...)
			bindable:Fire(...)
		end

		function toggle:click()
			self.Value = not self.Value

			toggle_status.BackgroundColor3 = self.Value and Color3.fromRGB(18, 255, 1) or Color3.fromRGB(255, 0, 4)
			
			bindable:Fire(self.Value)
		end

		table.insert(objects, toggle)
		
		Library.init_highlight(self, row)
		
		self.size = self.size + 1
		Window:resize(self)
		
		return toggle
	end
	

	function Base:create_slider(title, options) 
		local Window = self.Window
		local slider = {
			Window = Window,
			Min = options.Min,
			Max = options.Max,
			Increment = options.Increment,
			Prefix = options.Prefix or "",
			Value = options.Default
		}

		local bindable = BindableEvents:Create()
		local objects = self.objects

		local row = Library.create_row(self.category_frame, title)
		slider.instance = row

		local slider_value = Instance.new("TextLabel", row)
		slider_value.AnchorPoint = Vector2.new(1, 0.5)
		slider_value.TextColor3 = Color3.fromRGB(184, 184 ,184)
		slider_value.BackgroundTransparency = 1
		slider_value.Text = `< {slider.Value}{slider.Prefix} >`
		slider_value.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		slider_value.TextSize = 14
		slider_value.TextXAlignment = Enum.TextXAlignment.Right
		slider_value.Position = UDim2.new(1, -6, 0.5, 1)
		slider_value.Size = UDim2.new(1, 0, 0, 35)
		
		function slider:on_changed(func)
			bindable:Connect(func)
		end

		function slider:fire(...)
			bindable:Fire(...)
		end

		function slider:set_value(direction)
			local value = math.clamp(self.Value + direction * self.Increment, self.Min, self.Max)
			local decimals = math.max(0, -math.floor(math.log10(self.Increment)))
			value = math.floor(value * (10 ^ decimals) + 0.5) / (10 ^ decimals)
			
			self.Value = value
			slider_value.Text = `< {value}{self.Prefix} >`
			bindable:Fire(value)
		end

		table.insert(objects, slider)

		Library.init_highlight(self, row)

		self.size = self.size + 1
		Window:resize(self)

		return slider
	end
	
	function Base:move(amount)
		local objects = self.objects
		local count = #objects
		local old_selected = self.selected
		if not old_selected or #objects <= 1 then return end
		
		self.selected = self.selected + amount

		if self.selected > count then
			self.selected = 1
		elseif self.selected < 1 then
			self.selected = count
		end
			
		local current_object = objects[self.selected].instance
		Library.set_properties(current_object, {
			TextColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.5,
			BackgroundColor3 = Color3.fromRGB(77, 15, 138) 
		})

		local old_object = objects[old_selected].instance
		Library.set_properties(old_object, {
			TextColor3 = Color3.fromRGB(184, 184 ,184),
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		})
	end
	
	function Base:click()
		local obj = self.objects[self.selected]
		
		if obj and obj.click then
			obj:click()
		end
	end
	
	function Base:step(direction)
		local obj = self.objects[self.selected]

		if obj and obj.set_value then
			obj:set_value(direction)
		end
	end
end

function Library:create_window(title, icon, version)
	local categories = {}
	local opened_categories = {}
	
	local Window = {
		categories = categories,
		opened_categories = opened_categories,
		current_category = nil
	}

	local main_frame = Instance.new("Frame", screengui)
	main_frame.Name = "main"
	main_frame.Position = UDim2.new(0, 24, 0, 24)
	main_frame.Size = UDim2.new(0, 300, 0, 70)
	main_frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	
	Window.window_frame = main_frame
	
	Instance.new("UICorner", main_frame)

	local top_bar = Instance.new("Frame", main_frame)
	top_bar.Name = "top_bar"
	top_bar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	top_bar.Size = UDim2.new(0, 300, 0, 35)
	
	local ui_corner = Instance.new("UICorner", top_bar)
	ui_corner.BottomLeftRadius = UDim.new(0, 0)
	ui_corner.BottomRightRadius = UDim.new(0, 0)
	
	local title_label = Instance.new("TextLabel", top_bar)
	title_label.Name = "title"
	title_label.Text = title
	title_label.Size = UDim2.new(0.2, 0, 1, 0)
	title_label.Position = UDim2.new(0, 20, 0, 0)
	title_label.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	title_label.TextSize = 14
	title_label.TextColor3 = Color3.fromRGB(255, 255, 255)
	title_label.BackgroundTransparency = 1

	local icon_label = Instance.new("ImageLabel", top_bar)
	icon_label.Name = "icon"
	icon_label.Position = UDim2.new(0, 2, 0, 2)
	icon_label.Size = UDim2.new(0, 30, 0, 30)
	icon_label.BackgroundTransparency = 1
	icon_label.Image = icon

	local holder_frame = Instance.new("Frame", main_frame)
	holder_frame.Name = "holder"
	holder_frame.Position = UDim2.new(0, 0, 0.5, 0)
	holder_frame.Size = UDim2.new(1, 0, 1, -70)
	holder_frame.AnchorPoint = Vector2.new(0, 0.5)
	holder_frame.BackgroundTransparency = 1

	local bottom_bar = Instance.new("Frame", main_frame)
	bottom_bar.Name = "bottom_bar"
	bottom_bar.AnchorPoint = Vector2.new(0, 1)
	bottom_bar.Position = UDim2.new(0, 0, 1, 0)
	bottom_bar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	bottom_bar.Size = UDim2.new(0, 300, 0, 35)

	local ui_corner = Instance.new("UICorner", bottom_bar)
	ui_corner.TopRightRadius = UDim.new(0, 0)
	ui_corner.TopLeftRadius = UDim.new(0, 0)
	
	local version_label = Instance.new("TextLabel", bottom_bar)
	version_label.Name = "version"
	version_label.Text = version
	version_label.Size = UDim2.new(0.073, 35, 1, 0)
	version_label.Position = UDim2.new(0, 0, 0, 0)
	version_label.FontFace = Font.new("rbxasset://fonts/families/Roboto.json")
	version_label.TextSize = 12
	version_label.TextColor3 = Color3.fromRGB(148, 148, 148)
	version_label.BackgroundTransparency = 1

	function Window:create_category(name)
		local category_frame = Instance.new("Frame", holder_frame)
		category_frame.Name = name
		category_frame.Size = UDim2.new(1, 0, 1, 0)
		category_frame.BackgroundTransparency = 1
		category_frame.Visible = #categories == 0

		local category = setmetatable({
			Window = Window,
			category_frame = category_frame,
			objects = {},
			selected = nil,
			size = 0,
		}, Base)

		Instance.new("UIListLayout", category_frame)

		function category:SetVisible(bool)
			category_frame.Visible = bool
		end
		
		if #categories == 0 then
			Window.current_category = category
			table.insert(opened_categories, category)
		end
		
		table.insert(categories, category)

		return category
	end
	
	function Window:open_category(category)
		local current_category = Window.current_category
		
		current_category:SetVisible(false)
		category:SetVisible(true)
		
		Window.current_category = category
		
		Window:resize(category)
		table.insert(opened_categories, category)
	end
	
	function Window:close_category()
		if #opened_categories <= 1 then return end 
		table.remove(opened_categories)
		
		local previous = opened_categories[#opened_categories]
		if not previous then return end
		
		local current_category = Window.current_category
		
		current_category:SetVisible(false)
		previous:SetVisible(true)
		
		Window:resize(previous)
		Window.current_category = previous
	end
	
	function Window:resize(category)
		main_frame.Size = UDim2.new(0, 300, 0, 70 + category.size * 35)
	end
	
	UserInputService.InputBegan:Connect(function(input)
		local key = input.KeyCode
		local category = Window.current_category

		if key == Enum.KeyCode.Up then
			category:move(-1)
		elseif key == Enum.KeyCode.Down then
			category:move(1)
		elseif key == Enum.KeyCode.Left then
			category:step(-1)
		elseif key == Enum.KeyCode.Right then
			category:step(1)
		elseif key == Enum.KeyCode.Return or key == Enum.KeyCode.KeypadEnter then
			category:click()
		elseif key == Enum.KeyCode.Backspace then
			Window:close_category()
		end
	end)
	
	local ContextActionService = game:GetService("ContextActionService")

	ContextActionService:BindActionAtPriority("DisableArrowKeys", function()
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right)
	
	return Window	
end

function Library.create_row(category_frame, title)
	local text_button = Instance.new("TextLabel", category_frame)
	text_button.Size = UDim2.new(0, 300, 0, 35)
	text_button.FontFace = Font.new("rbxasset://fonts/families/Roboto.json")
	text_button.TextSize = 14
	text_button.Text = title
	text_button.TextXAlignment = Enum.TextXAlignment.Left
	text_button.TextColor3 = Color3.fromRGB(184, 184, 184)
	text_button.BackgroundTransparency = 1
	text_button.BorderSizePixel = 0

	local UIPadding = Instance.new("UIPadding", text_button)
	UIPadding.PaddingLeft = UDim.new(0, 12)

	return text_button
end

function Library.init_highlight(category, text_button)
	if not category.selected then
		category.selected = 1

		text_button.TextColor3 = Color3.fromRGB(255, 255, 255)
		text_button.BackgroundTransparency = 0.5
		text_button.BackgroundColor3 = Color3.fromRGB(77, 15, 138)
	end
end

function Library.set_properties(instance, properties)
	for i, v in pairs(properties) do
		instance[i] = v
	end
end


return Library