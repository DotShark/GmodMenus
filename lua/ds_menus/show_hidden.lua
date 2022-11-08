local MaterialEnum = ShowHidden.MaterialEnum
local DEFAULT_BRUSH_COLORS = ShowHidden.DEFAULT_BRUSH_COLORS
local DEFAULT_TRIGGERS_COLORS = ShowHidden.DEFAULT_TRIGGERS_COLORS
local DEFAULT_PROPS_COLOR = ShowHidden.DEFAULT_PROPS_COLOR
local BRUSH_TEXTURE_NAME = ShowHidden.BRUSH_TEXTURE_NAME
local Material = Material

ShowHidden.Config = {
	List = {
		-- Brushes
		{
			ID = "ShowPlayerClips", Type = "brush", BrushType = 1, Text = "#showclips.type.1", Icon = "playerclip.png",
			Enabled = false, Material = MaterialEnum.DEFAULT, Color = DEFAULT_BRUSH_COLORS[1].color
		},
		{
			ID = "ShowWallBrushes", Type = "brush", BrushType = 2, Text = "#showclips.type.2", Icon = "playerclip.png",
			Enabled = false, Material = MaterialEnum.DEFAULT, Color = DEFAULT_BRUSH_COLORS[2].color
		},
		{
			ID = "ShowLadders", Type = "brush", BrushType = 3, Text = "#showclips.type.3", Icon = "ladder.png",
			Enabled = false, Material = MaterialEnum.DEFAULT, Color = DEFAULT_BRUSH_COLORS[3].color
		},
		{
			ID = "ShowNoDrawBrushes", Type = "brush", BrushType = 4, Text = "#showclips.type.4", Icon = "nodraw.png",
			Enabled = false, Material = MaterialEnum.DEFAULT, Color = DEFAULT_BRUSH_COLORS[4].color
		},
		{
			ID = "ShowSkyBoxBrushes", Type = "brush", BrushType = 5, Text = "#showclips.type.5", Icon = "skybox.png",
			Enabled = false, Material = MaterialEnum.DEFAULT, Color = DEFAULT_BRUSH_COLORS[5].color
		},
		-- Triggers
		{
			ID = "ShowTeleports", Type = "trigger", TriggerType = 2, Text = "#showtriggers.type.2", Icon = "teleport.png",
			Enabled = false, Material = MaterialEnum.DEFAULT, Color = DEFAULT_TRIGGERS_COLORS[2].color
		},
		{
			ID = "ShowFilteredTeleports", Type = "trigger", TriggerType = 3, Text = "#showtriggers.type.3", Icon = "teleport.png",
			Enabled = false, Material = MaterialEnum.DEFAULT, Color = DEFAULT_TRIGGERS_COLORS[3].color
		},
		{
			ID = "ShowPushBoosters", Type = "trigger", TriggerType = 4, Text = "#showtriggers.type.4", Icon = "booster.png",
			Enabled = false, Material = MaterialEnum.DEFAULT, Color = DEFAULT_TRIGGERS_COLORS[4].color
		},
		{
			ID = "ShowBaseVLBoosters", Type = "trigger", TriggerType = 5, Text = "#showtriggers.type.5", Icon = "booster.png",
			Enabled = false, Material = MaterialEnum.DEFAULT, Color = DEFAULT_TRIGGERS_COLORS[5].color
		},
		{
			ID = "ShowGravityBoosters", Type = "trigger", TriggerType = 6, Text = "#showtriggers.type.6", Icon = "booster.png",
			Enabled = false, Material = MaterialEnum.DEFAULT, Color = DEFAULT_TRIGGERS_COLORS[6].color
		},
		{
			ID = "ShowPreSpeedPreventers", Type = "trigger", TriggerType = 7, Text = "#showtriggers.type.7", Icon = "interrogation.png",
			Enabled = false, Material = MaterialEnum.DEFAULT, Color = DEFAULT_TRIGGERS_COLORS[7].color
		},
		{
			ID = "ShowBhopPlatforms", Type = "trigger", TriggerType = 8, Text = "#showtriggers.type.8", Icon = "interrogation.png",
			Enabled = false, Material = MaterialEnum.DEFAULT, Color = DEFAULT_TRIGGERS_COLORS[8].color
		},
		{
			ID = "ShowOtherTriggers", Type = "trigger", TriggerType = 1, Text = "#showtriggers.type.1", Icon = "interrogation.png",
			Enabled = false, Material = MaterialEnum.DEFAULT, Color = DEFAULT_TRIGGERS_COLORS[1].color
		},
		-- Props collisions
		{
			ID = "ShowPropsCollisions", Type = "prop", Text = "#showclips.props", Icon = "prop.png",
			Enabled = false, Material = DEFAULT_PROPS_COLOR.material, Color = DEFAULT_PROPS_COLOR.color
		}
	},
	Settings = {},

	Init = function(self)
		local env = {self = self}
		setmetatable(env, {__index = _G, __newindex = _G})	
		for _, func in pairs(self) do
			if isfunction(func) then setfenv(func, env) end
		end

		for _, setting in ipairs(self.List) do
			local id = setting.ID
			self.Settings[id] = setting
			setting.Apply = self.ApplySetting
		end

		hook.Add("PlayerDataLoaded", "ShowHiddenConfig", self.LoadData)
		hook.Add("OnReloaded", "ShowHiddenConfig", self.RefreshData)
	end,

	RefreshData = function()
		http.Fetch("https://api.dotshark.ovh/bhop/player/" .. LocalPlayer():SteamID64(), function(json, s, headers)
			local data = util.JSONToTable(json)
			if data then self.LoadData(data) end
		end)
	end,

	LoadData = function(data)
		local settings = self.Settings
		local triggerTypes = 0
		local displaySettings = ShowHidden.GetDisplaySettings()

		for _, setting in ipairs(self.List) do
			local id = setting.ID
			if not data[id] then continue end
			
			local enabled = data[id].Enabled
			local col, mat = data[id].Color, data[id].Material
			local displaySetting
			
				
			if setting.Type == "brush" then
				enabled = false
				displaySetting = displaySettings.brushes[setting.BrushType] or {}
				displaySettings.brushes[setting.BrushType] = displaySetting
			elseif setting.Type == "trigger" then
				triggerTypes = triggerTypes + (enabled and bit.rol(1, setting.TriggerType - 1) or 0)
				displaySetting = displaySettings.triggers[setting.TriggerType] or {}
				displaySettings.triggers[setting.TriggerType] = displaySetting
			elseif setting.Type == "prop" then 
				GetConVar("showprops"):SetBool(a)
				displaySetting = displaySettings.props or {}
				displaySettings.props = displaySetting
			end

			if istable(col) then displaySetting.color = Color(col.r, col.g, col.b, col.a) end 
			if mat then displaySetting.material = mat end

			if setting.Type == "brush" then
				ShowHidden.UpdateBrushMaterial(setting.BrushType, displaySetting.material, displaySetting.color)
			elseif setting.Type == "prop" then
				ShowHidden.UpdatePropsMaterial(displaySetting.material, displaySetting.color)
			end

			setting.Enabled = enabled
			setting.Material = mat
			setting.Color = istable(col) and Color(col.r, col.g, col.b, col.a) or setting.Color
		end

		GetConVar("showtriggers_types"):SetInt(triggerTypes)
		GetConVar("showtriggers_enabled"):SetBool(triggerTypes > 0)
		ShowHidden.UpdateVisibleTriggers()
	end,

	ApplySetting = function(setting)
		local brushTypes = GetConVar("showclips"):GetInt()
		local triggerTypes = GetConVar("showtriggers_types"):GetInt()
		local displaySettings = ShowHidden.GetDisplaySettings()

		local enabled = setting.Enabled
		local displaySetting
		
		if setting.Type == "brush" then
			local bitFlag = bit.rol(1, setting.BrushType - 1)
			brushTypes = enabled and bit.bor(brushTypes, bitFlag) or bit.band( brushTypes, bit.bnot(bitFlag) )
			displaySetting = displaySettings.brushes[setting.BrushType] or {}
		elseif setting.Type == "trigger" then
			local bitFlag = bit.rol(1, setting.TriggerType - 1)
			triggerTypes = enabled and bit.bor(triggerTypes, bitFlag) or bit.band( triggerTypes, bit.bnot(bitFlag) )
			displaySetting = displaySettings.triggers[setting.TriggerType] or {}
		elseif setting.Type == "prop" then 
			GetConVar("showprops"):SetBool(enabled)
			displaySetting = displaySettings.props or {}
		end

		displaySetting.color = setting.Color
		displaySetting.material = setting.Material

		if setting.Type == "brush" then
			ShowHidden.UpdateBrushMaterial(setting.BrushType, displaySetting.material, displaySetting.color)
		elseif setting.Type == "prop" then
			ShowHidden.UpdatePropsMaterial(displaySetting.material, displaySetting.color)
		end

		GetConVar("showclips"):SetInt(brushTypes)
		GetConVar("showtriggers_types"):SetInt(triggerTypes)
		GetConVar("showtriggers_enabled"):SetBool(triggerTypes > 0)
		ShowHidden.UpdateVisibleTriggers()

		Core:SaveSetting(setting.ID, {Enabled = setting.Enabled, Material = setting.Material, Color = setting.Color})
	end
}

ShowHidden.Config:Init()


ShowHidden.ConfigMenu = {
	Title = "#showhidden.title",

	Colors = {
		Background = Color(35, 35, 35),
		Foreground = Color(42, 42, 42),
		Text = Color(255, 255, 255),
		Expressions = {
			Important = function(self) return _C.ImportantColor end
		}
	},

	ChoicesFor = {
		Material = {
			{Text = "#showhidden.mat.1", Value = 1, Icon = "trigger.png"},
			{Text = "#showhidden.mat.2", Value = 2, Icon = "plain.png"},
			{Text = "#showhidden.mat.0", Value = 0, Icon = "wireframe.png"}
		},
		Color = {
			{Text = "#showhidden.col.w", Value = Color(255, 255 , 255)},
			{Text = "#showhidden.col.r", Value = Color(255, 0 , 0)},
			{Text = "#showhidden.col.y", Value = Color(255, 255, 0)},
			{Text = "#showhidden.col.g", Value = Color(0, 255 , 0)},
			{Text = "#showhidden.col.c", Value = Color(0, 255, 255)},
			{Text = "#showhidden.col.b", Value = Color(0, 0 , 255)},
			{Text = "#showhidden.col.m", Value = Color(255, 0, 255)}
		}
	},

	CachedMaterials = {},

	Init = function(self)
		local colorsMeta = {
			__index = function(t, k)
				if t.Expressions[k] then
					return t.Expressions[k](t)
				end
			end
		}
		setmetatable(self.Colors, colorsMeta)
	end,

	Open = function(self)
		self:LoadMaterials(function()
			local window = vgui.CreateFromTable(self.Window)
			window.Colors = self.Colors
			window.Title = self.Title
	
			window.TitlePart = vgui.CreateFromTable(self.TitlePart, window)
				window.TitlePart.Close = vgui.CreateFromTable(self.CloseButton, window.TitlePart)
			window.ScrollPanel = vgui.CreateFromTable(self.ScrollPanel, window)
			window.SettingsPart = vgui.CreateFromTable(self.SettingsPart, window.ScrollPanel)
			for _, setting in ipairs(ShowHidden.Config.List) do	
				window.SettingsPart:Add(self.SettingPanel)
					:BindTo(setting)
			end		
		end)
	end,

	LoadMaterials = function(self, callback)
		local cachedMaterials = self.CachedMaterials
		
		if cachedMaterials.loaded then 
			if callback then callback() end
			return
		end 

		local loadedFiles = 0
		local filesToLoad = 0

		if not ( file.Exists("showhidden_icons", "DATA") and file.IsDir("showhidden_icons", "DATA") ) then
			file.CreateDir("showhidden_icons")		
		end

		local function loadWebMaterial(f)
			filesToLoad = filesToLoad + 1
			local fastDLPath = string.find(f, ".png") and f or string.sub(f, #"tools//") .. ".png"

			http.Fetch("https://fastdl.dotshark.ovh/materials/showhidden/" .. fastDLPath, function(body, l)
				file.Write("showhidden_icons/" .. fastDLPath, body)
				local cacheKey = string.find(f, ".png") and "showhidden/" .. f or f
				cachedMaterials[cacheKey] = Material("../data/showhidden_icons/" .. fastDLPath)
				file.Delete("showhidden_icons/" .. f, body)
				loadedFiles = loadedFiles + 1

				if loadedFiles < filesToLoad then return end
				cachedMaterials.loaded = true
				Material = function(mat) return cachedMaterials[mat] end
				if callback then callback() end
			end)
		end

		for _, setting in ipairs(ShowHidden.Config.List) do loadWebMaterial(setting.Icon) end
		loadWebMaterial("arrow.png")
		for _, material in ipairs(self.ChoicesFor.Material) do loadWebMaterial(material.Icon) end
		for _, brushMat in pairs(BRUSH_TEXTURE_NAME) do loadWebMaterial(brushMat) end
		loadWebMaterial("tools/toolstrigger")
	end,

	Window = {
		Base = "DPanel",
		Size = {800, 600},

		Init = function(self)
			self:SetSize( unpack(self.Size) )
			self:Center()
		end,

		Think = function(self)
			if not vgui.CursorVisible() then
				gui.EnableScreenClicker(true)
			end
		end,

		Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, self.Colors.Background)
			draw.RoundedBox(5, 5, 5, w - 10, h - 10, self.Colors.Foreground)
		end,
	},

	TitlePart = {
		Base = "DPanel",
		Height = 36,

		Init = function(self)
			self.Window = self:GetParent()
			self.Colors = self.Window.Colors
			self:SetPos(5, 5)
			self:SetSize(self.Window:GetWide() - 10, self.Height)
		end,

		Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, self.Colors.Important)
			draw.SimpleText(self.Window.Title, "HUDFont", 5, h * 0.5, self.Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	},

	CloseButton = {
		Base = "DLabel",
		Size = {22, 22},

		Init = function(self)
			self.Window = self:GetParent().Window
			self.Colors = self.Window.Colors
			local w, h = self:GetParent():GetSize()
			self:SetPos(w - 5 - self.Size[1], h * 0.5 - self.Size[2] * 0.5)
			self:SetSize( unpack(self.Size) )
			self:SetMouseInputEnabled(true)
			self:SetText("")
		end,

		OnCursorEntered = function(self)
			self:SetCursor("hand")
			self.Hovered = true
		end,

		OnCursorExited = function(self)
			self:SetCursor("arrow")
			self.Hovered = false
		end,

		Paint = function(self, w, h)
			local center = TEXT_ALIGN_CENTER
			draw.RoundedBox(w * 0.5, 0, 0, w, h, self.Hovered and self.Colors.Foreground or self.Colors.Background)
			draw.SimpleText("x", "HUDFont", w * 0.5, h * 0.5 - 2, self.Colors.Text, center, center)
		end,

		DoClick = function(self)
			self.Window:SetVisible(false)
			self.Window:Remove()
			gui.EnableScreenClicker(false)
		end
	},

	ScrollPanel = {
		IsPanel = true,
		Base = "DScrollPanel",
		Size = {false, false},
		Margin = {0, 0},
		Font = "HUDLabel",
		TitleFont = "HUDTitle",
		ListMargin = 20,
		TitleSpacing = 10,
		LineSpacing = 5,
		ScrollPadding = 3,
		
		Init = function(self)
			self.Window = self:GetParent()
			self.Colors = self.Window.Colors
			local tpHeight = self.Window.TitlePart.Height
			self:SetPos(10, 5 + tpHeight + 5)
			self:SetSize(self.Window:GetWide() - 15, self.Window:GetTall() - tpHeight - 10 - 5)

			local scrollbar = self:GetVBar()
			scrollbar:SetHideButtons(true)
			scrollbar:SetSize(12, 12)
			scrollbar.LastScroll = 0
			scrollbar.PreviousScroll = 0

			scrollbar.Think = function(pnl)
				if pnl:GetScroll() != pnl.PreviousScroll then
					CloseDermaMenus()
					pnl.LastScroll = CurTime()
				end
				pnl.PreviousScroll = pnl:GetScroll()
			end

			scrollbar.Paint = function(pnl, w, h)
				surface.SetDrawColor(self.Colors.Foreground)
				surface.DrawRect(0, 0, w, h)
			end

			scrollbar.btnGrip.Paint = function(pnl, w, h)
				local padding, col = self.ScrollPadding
				local lastScroll = pnl:GetParent().LastScroll
				
				if pnl.Depressed then
					col = self.Colors.Important
				elseif pnl.Hovered or (CurTime() < lastScroll + 0.3) then
					local important = self.Colors.Important
					col = Color(important.r, important.g, important.b, 150)
				else
					col = self.Colors.Background
				end

				surface.SetDrawColor(col)
				surface.DrawRect(padding, padding, w - 2 * padding, h - 2 * padding)
			end
		end,

		Paint = function(self, w, h)
			surface.SetDrawColor(self.Colors.Foreground)
			surface.DrawRect(0, 0, w, h)
		end
	},

	SettingsPart = {
		Base = "DIconLayout",

		Init = function(self)
			local parent = self:GetParent():GetParent()
			self.Window = parent.Window
			self.Colors = self.Window.Colors

			local tpHeight = self.Window.TitlePart.Height
			self:SetPos(0, 0)
			self:SetSize( parent:GetWide() - 12, parent:GetTall() )
			self:SetSpaceY(5)
		end
	},

	SettingPanel = {
		Base  = "DPanel",
		Height = 70,
		Setting = {},
		Icon = nil,

		Init = function(self)
			self.Window = self:GetParent().Window 
			self.Colors = self.Window.Colors
			self:SetSize(self:GetParent():GetWide(), self.Height)
		end,

		BindTo = function(self, setting)
			self.Setting = setting
			self.Icon = Material("showhidden/"..setting.Icon)

			self.CheckBox = vgui.CreateFromTable(ShowHidden.ConfigMenu.CheckBox, self)
			self.CheckBox:SetPos(self.Height, 2 * 5 + 25)
			self.CheckBox:SetSize((self:GetWide() - self.Height - 5 * 3) / 3, 30)
			self.CheckBox:BindTo(setting, "Enabled")

			self.StyleChoice = vgui.CreateFromTable(ShowHidden.ConfigMenu.StyleChoice, self)
			self.StyleChoice:SetPos(self.Height + (self:GetWide() - self.Height - 5 * 3) / 3 + 5, 2 * 5 + 25)
			self.StyleChoice:SetSize((self:GetWide() - self.Height - 5 * 3) / 3, 30)
			self.StyleChoice:BindTo(setting, "Material")

			self.StyleChoice = vgui.CreateFromTable(ShowHidden.ConfigMenu.StyleChoice, self)
			self.StyleChoice:SetPos(self.Height + (self:GetWide() - self.Height - 5 * 3) / 1.5 + 5 * 2, 2 * 5 + 25)
			self.StyleChoice:SetSize((self:GetWide() - self.Height - 5 * 3) / 3 + 1, 30)
			self.StyleChoice:BindTo(setting, "Color")
		end,

		Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, self.Colors.Background)

			draw.RoundedBox(5, 5, 5, h - 10, h - 10, self.Colors.Foreground)
			if self.Icon then
				surface.SetMaterial(self.Icon)
				surface.SetDrawColor(self.Colors.Text)
				surface.DrawTexturedRect(5, 5, h - 10, h - 10)
			end

			local center = TEXT_ALIGN_CENTER
			draw.RoundedBox(0, h, 5, w - h - 5, 25, self.Colors.Foreground)
			draw.SimpleText(self.Setting.Text, "HUDLabel", h + (w - h) * 0.5, 5 + 12, self.Colors.Text, center, center)
		end
	},

	CheckBox = {
		Base = "DPanel",
		Height = 30,
		Setting = {},

		Init = function(self)
			self.Window = self:GetParent().Window
			self.Colors = self.Window.Colors
		end,

		BindTo = function(self, configTab, configKey)
			self.TogglePanel = vgui.CreateFromTable(ShowHidden.ConfigMenu.TogglePanel, self)
			self.TogglePanel.ConfigTable = configTab
			self.TogglePanel.ConfigKey = configKey
		end,

		Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, self.Colors.Foreground)
			draw.SimpleText("#showhidden.toggle", "HUDLabel", 5, self.Height * 0.5, self.Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	},

	TogglePanel = {
		Base = "DLabel",
		Size = {40, 20},
		SliderPadding = 3,
		SliderW = 10,
		ConfigTable = {},
		ConfigKey = "",
		LastChange = 0,
		TransitionTime = 0.1,
		
		Init = function(self)
			local parent = self:GetParent()
			local parentW, parentH = parent:GetSize()

			self.Window = parent.Window
			self.Colors = self.Window.Colors
			self.SliderH = self.Size[2] - 2 * self.SliderPadding
			self:SetSize( unpack(self.Size) )
			self:SetPos(parentW - 5 - self.Size[1], parentH * 0.5 - self.Size[2] * 0.5)
			self:SetText("")
			self:SetMouseInputEnabled(true)
		end,

		OnCursorEntered = function(self)
			self:SetCursor("hand")
		end,

		OnCursorExited = function(self)
			self:SetCursor("arrow")
		end,

		Paint = function(self, w, h)
			local enabled = self.ConfigTable[self.ConfigKey]
			local ellapsed = CurTime() - self.LastChange
			local progress = 1
			if ellapsed < self.TransitionTime then progress = ellapsed / self.TransitionTime end
			if not enabled then progress = 1 - progress end

			local enabled = self.ConfigTable[self.ConfigKey]
			draw.RoundedBox(0, 0, 0, w, h, self.Colors.Background)
			local important = self.Colors.Important
			important = Color(important.r, important.g, important.b, 120 * progress)
			draw.RoundedBox(0, 0, 0, w, h, important)

			local minX, maxX = self.SliderPadding, w - self.SliderPadding - self.SliderW
			local x = minX + (maxX - minX) * progress
			draw.RoundedBox(0, x, self.SliderPadding, self.SliderW, self.SliderH, self.Colors.Text)
		end,

		DoClick = function(self)
			self.ConfigTable[self.ConfigKey] = not self.ConfigTable[self.ConfigKey]
			self.ConfigTable:Apply()
			self.LastChange = CurTime()
		end
	},

	StyleChoice = {
		Base = "DComboBox",
		Height = 30,
		Setting = {},
		Arrow = nil,
		BindedTo = "",

		Init = function(self)
			self.Window = self:GetParent().Window
			self.Colors = self.Window.Colors
			self.StylesNames = {}
			self.StylesIcons = {}
			self:SetHeight(self.Height)
			self:SetSortItems(false)
			self.Arrow = Material("showhidden/arrow.png")

			local openMenuEnv = {DermaMenu = self.CustomDermaMenu}
			setmetatable(openMenuEnv, {__index = _G, __newindex = _G})
			setfenv(self.OpenMenu, openMenuEnv)

			self.JustCreated = true
			timer.Simple(0, function() self.JustCreated = false end)
		end,

		BindTo = function(self, setting, configKey)
			self.Setting = setting
			self.BindedTo = configKey

			for _, style in ipairs(ShowHidden.ConfigMenu.ChoicesFor[configKey]) do
				if configKey == "Material" and style.Value == 1 then 
					self.StylesIcons[style.Value] = Material(setting.Type == "brush" and BRUSH_TEXTURE_NAME[setting.BrushType] or "tools/toolstrigger")
				elseif style.Icon then
					self.StylesIcons[style.Value] = Material("showhidden/" .. style.Icon)
				end
				self.StylesNames[style.Value] = style.Text
				self:AddChoice(style.Text, style.Value, style.Value == setting[configKey], iconPath)
			end

			self.DropButton:SetVisible(false)
		end,

		Think = function(self)
			self:SetText("")
		end,

		Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, self.Colors.Foreground)
			if self.Hovered or self.Depressed or self:IsMenuOpen() then
				local important = self.Colors.Important
				important = Color(important.r, important.g, important.b, 120)
				draw.RoundedBox(0, 0, 0, w, h, important)
			end

			local icon = self.StylesIcons[ self.Setting[self.BindedTo] ]
			if icon then
				surface.SetDrawColor(self.Colors.Text)
				surface.SetMaterial(icon)
				surface.DrawTexturedRect(5, 5, h - 2 * 5, h - 2 * 5)
			elseif self.BindedTo == "Color" then
				draw.RoundedBox(0, 5, 5, h - 2 * 5, h - 2 * 5, self.Setting[self.BindedTo])
			end
			
			local text = self.BindedTo == "Color" and language.GetPhrase("showhidden.color") or language.GetPhrase("showhidden.material")
			if  self.BindedTo == "Material" and self.StylesNames[ self.Setting[self.BindedTo] ] then
				local matName = language.GetPhrase(self.StylesNames[ self.Setting[self.BindedTo] ])
				text = text:format( matName:lower() )
			end
			draw.SimpleText(text, "HUDLabel", h + 5, h * 0.5, self.Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			
			if self.Arrow then
				surface.SetDrawColor(self.Colors.Text)
				surface.SetMaterial(self.Arrow)
				surface.DrawTexturedRect(w - 5 - 10, 10, 10, 10)
			end
		end,

		CustomDermaMenu = function(parentmenu, parent)
			if not parentmenu then CloseDermaMenus() end
			local dmenu = vgui.CreateFromTable(ShowHidden.ConfigMenu.ScrollingMenu, parent)
			return dmenu
		end,

		OnMenuOpened = function(self, menu)
			local x, y = self:LocalToScreen(-5, self:GetTall())
			menu:SetMinimumWidth(self:GetWide() + 10)
			menu:SetPos(x, y)

			if self.BindedTo == "Color" then
				local container = menu:AddSliderContainer()
				local slider = vgui.CreateFromTable(ShowHidden.ConfigMenu.AlphaSlider, container)
				slider.Colors = self.Colors
				slider:BindTo(self.Setting)
				menu:AddSpacer()
			end
		end,

		OnSelect = function(self, index, value, data)
			self.Setting[self.BindedTo] = IsColor(data) and table.Copy(data) or data
			if not self.JustCreated then
				self.Setting:Apply()
			end
		end
	},

	ScrollingMenu = {
		Base = "DMenu",
		OptionsCount = 0,

		Init = function(self)
			self.Colors = self:GetParent().Colors
		end,

		AddOption = function(self, strText, funcFunction)
			if self.OptionsCount == 0 then
				self:AddSpacer()
			end
			self.OptionsCount = self.OptionsCount + 1

			local pnl = vgui.Create("DMenuOption", self)
			pnl.Text = strText
			pnl.OptionID = OptionsCount
			pnl.Value = self:GetParent().Data[self.OptionsCount]
			pnl.Colors = self.Colors
			if isnumber(pnl.Value) then
				pnl.Icon = self:GetParent().StylesIcons[pnl.Value]
			end

			pnl:SetMenu(self)
			pnl:SetText("")
			pnl:SetTextColor(self.Colors.Text)
			pnl:SetHeight(30 + 5)
			pnl:SetFont("HUDLabel")
			pnl.Paint = self.OptionPaint
			pnl.PerformLayout = self.OptionLayout
			if funcFunction then pnl.DoClick = funcFunction end
		
			self:AddPanel(pnl)
			self:AddSpacer()

			return pnl
		end,
	
		OptionPaint = function(panel, w, h)
			surface.SetDrawColor(panel.Colors.Foreground)
			surface.DrawRect(5, 0, w - 5 * 2, h)
			if ( panel.m_bBackground && ( panel.Hovered || panel.Highlight) ) then
				local important = panel.Colors.Important
				surface.SetDrawColor(important.r, important.g, important.b, 120)
				surface.DrawRect(5, 0, w - 5 * 2, h)
			end

			if panel.Icon then
				surface.SetDrawColor(panel.Colors.Text)
				surface.SetMaterial(panel.Icon)
				surface.DrawTexturedRect(5 + 5, 5, h - 2 * 5, h - 2 * 5)
			elseif IsColor(panel.Value) then 
				draw.RoundedBox(0, 5 + 5, 5, h - 2 * 5, h - 2 * 5, panel.Value)
			end

			draw.SimpleText(panel.Text, "HUDLabel", h + 5 + 5, h * 0.5, panel.Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end,

		OptionLayout = function(self, w, h)
			self:SizeToContents()
			self:SetWide(self:GetWide() + 30)
		
			local w = math.max( self:GetParent():GetWide(), self:GetWide() )
			self:SetSize(w, 30)
		
			if IsValid(self.SubMenuArrow)then
				self.SubMenuArrow:SetSize( 15, 15 )
				self.SubMenuArrow:CenterVertical()
				self.SubMenuArrow:AlignRight( 4 )
			end
		
			DButton.PerformLayout(self, w, h)
		end,
	
		AddSpacer = function(self, strText, funcFunction)
			local pnl = vgui.Create("DPanel", self)
			pnl.Paint = function(p, w, h) end
		
			pnl:SetTall(5)
			self:AddPanel(pnl)
		
			return pnl
		end,

		AddSliderContainer = function(self)
			local pnl = vgui.Create("DPanel", self)
			pnl.Paint = function(p, w, h) end
		
			pnl:SetWide( self:GetWide() )
			pnl:SetTall(ShowHidden.ConfigMenu.AlphaSlider.Height)
			self:AddPanel(pnl)
		
			return pnl
		end,
	
		Paint = function(self, w, h)
			surface.SetDrawColor(self.Colors.Background) 
			surface.DrawRect(0, 0, w, h)
		end
	},

	AlphaSlider = {
		Base = "DPanel",
		Height = 55,
		TextY = 15,
		NumBoxSize = {40, 20},
		Setting = {},

		Init = function(self)
			self:SetPos(5, 0)
			self:SetSize(self:GetParent():GetWide(), self.Height)
		end,

		BindTo = function(self, setting)
			self.Setting = setting
			self.SliderPanel = vgui.CreateFromTable(ShowHidden.ConfigMenu.SliderPanel, self)
			self.SliderPanel.Range = {0, 255}
			self.SliderPanel.Setting = setting
		end,

		Paint = function(self, w, h)
			local center = TEXT_ALIGN_CENTER	
			draw.RoundedBox(0, 0, 0, w, h, self.Colors.Foreground)
			draw.SimpleText("#showhidden.alpha", "HUDLabel", 5, self.TextY, self.Colors.Text, TEXT_ALIGN_LEFT, center)

			local nBoxW, nBoxH = unpack(self.NumBoxSize)
			draw.RoundedBox(0, 5, h - nBoxH - 5, w - 5 * 3 - nBoxW, nBoxH, self.Colors.Background)
			draw.RoundedBox(0, w - nBoxW - 5, h - nBoxH - 5, nBoxW, nBoxH, self.Colors.Background)
			draw.SimpleText(tostring(self.Setting.Color.a), "HUDLabel", w - nBoxW * 0.5 - 5, h - nBoxH * 0.5 - 5, self.Colors.Text, center, center)
		end
	},

	SliderPanel = {
		Base = "DSlider",
		SliderPadding = 3,
		SliderW = 10,
		Setting = {},
		Range = {0, 1},

		Init = function(self)
			local parent = self:GetParent()
			local parentW, parentH = parent:GetSize()
			local nBoxW, nBoxH = unpack(parent.NumBoxSize)

			self.Colors = parent.Colors
			self.SliderH = nBoxH - 2 * self.SliderPadding

			self:SetSize(parentW - 5 * 3 - 10 * 2 - nBoxW, nBoxH)
			self:SetPos(5 + 10, parentH - nBoxH - 5)

			self.Knob:SetSize(self.SliderW, nBoxH - self.SliderPadding * 2)
			self.Knob.Paint = self.PaintKnob
			self.Knob.Colors = self.Colors
			
			timer.Simple(0, function()
				local min, max = unpack(self.Range)
				local frac = (self.Setting.Color.a - min) / (max - min)
				self:SetSlideX(frac)
			end)
		end,

		Think = function(self)
			if not self.Knob.Depressed then 
				if self.Knob.WasDepressed then
					self.Knob.WasDepressed = false
					self.Setting:Apply()
				end
				return 
			end

			self.Knob.WasDepressed = true
			local setting = self.Setting
			local min, max = unpack(self.Range)
			setting.Color.a = math.Round( min + self:GetSlideX() * (max - min) )

			local enabled = setting.Enabled
			local displaySettings = ShowHidden.GetDisplaySettings()
			local displaySetting
			
			if setting.Type == "brush" then
				displaySetting = displaySettings.brushes[setting.BrushType] or {}
			elseif setting.Type == "trigger" then
				displaySetting = displaySettings.triggers[setting.TriggerType] or {}
			elseif setting.Type == "prop" then 
				displaySettings.props = displaySetting
			end

			displaySetting.color = setting.Color

			if setting.Type == "brush" then
				ShowHidden.UpdateBrushMaterial(setting.BrushType, displaySetting.material, displaySetting.color)
			elseif setting.Type == "prop" then
				ShowHidden.UpdatePropsMaterial(displaySetting.material, displaySetting.color)
			elseif setting.Type == "trigger" then 
				ShowHidden.UpdateVisibleTriggers()
			end
		end,

		Paint = function(self, w, h) end,

		PaintKnob = function(knob, w, h)
			draw.RoundedBox(0, 0, 0, w, h, knob.Depressed and knob.Colors.Important or knob.Colors.Text)
		end
	}
}

ShowHidden.ConfigMenu:Init()
concommand.Add("showhidden", function() ShowHidden.ConfigMenu:Open() end, nil, "Open PlayerClips and ShowTriggers settings menu")