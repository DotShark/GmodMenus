include("cl_jhud.lua")

local function JHUD_UpdateSettings()
	net.Start("JHUD_UpdateSettings")
	local settings = {
		JHUDEnabled = JHUD.HUD.Enabled,
		JHUDOpacity = JHUD.HUD.Opacity,
		JHUDOffset = JHUD.HUD.HeightOffset,
		StrafeTrainerEnabled = JHUD.Trainer.Enabled,
		StrafeTrainerDynColor = JHUD.Trainer.DynamicRectangleColor,
		StrafeTrainerRefreshRate = JHUD.Trainer.RefreshRate,
		StrafeTrainerW = JHUD.Trainer.Width,
		StrafeTrainerH = JHUD.Trainer.Height,
		StrafeTrainerOffset = JHUD.Trainer.HeightOffset
	}
	local json = util.TableToJSON(settings)
	net.WriteString(json)
	net.SendToServer()
end

local JHUD_MENU = {
	FR = {
		Title = "Réglages du JHUD",
		Settings = {
			{Var = "HUD.Enabled", Type = "bool", Text = "Afficher le JHUD"},
			{Var = "HUD.Opacity", Type = "number", Range = {0, 255}, Text = "Opacité du JHUD"},
			{Var = "HUD.HeightOffset", Type = "number", Range = {- ScrH() / 2, ScrH() / 2}, Text = "Position du JHUD"},
			{Var = "Trainer.Enabled", Type = "bool", Text = "Afficher le Strafe Trainer"},
			{Var = "Trainer.DynamicRectangleColor", Type = "bool", Text = "Couleur dynamique sur le Strafe Trainer"},
			{Var = "Trainer.RefreshRate", Type = "number", Range = {1, 20}, Text = "Fréquence d'actualisation"},
			{Var = "Trainer.Width", Type = "number", Range = {200, 800}, Text = "Largeur du Strafe Trainer"},
			{Var = "Trainer.Height", Type = "number", Range = {20, 100}, Text = "Hauteur du Strafe Trainer"},
			{Var = "Trainer.HeightOffset", Type = "number", Range = {- ScrH() / 2, ScrH() / 2}, Text = "Position du Strafe Trainer"},
			{Var = "Trainer.RectangleColor", Type = "color", Text = "Couleur du fond du Strafe Trainer"},
			{Var = "Trainer.TextColor", Type = "color", Text = "Couleur du texte du Strafe Trainer"}
		}
	},
	EN = {
		Title = "JHUD Settings",
		Settings = {
			{Var = "HUD.Enabled", Type = "bool", Text = "Show JHUD"},
			{Var = "HUD.Opacity", Type = "number", Range = {0, 255}, Text = "JHUD Opacity"},
			{Var = "HUD.HeightOffset", Type = "number", Range = {- ScrH() / 2, ScrH() / 2}, Text = "JHUD offset"},
			{Var = "Trainer.Enabled", Type = "bool", Text = "Show Strafe Trainer"},
			{Var = "Trainer.DynamicRectangleColor", Type = "bool", Text = "Dynamic color on Strafe Trainer"},
			{Var = "Trainer.RefreshRate", Type = "number", Range = {1, 20}, Text = "Strafe Trainer refresh rate"},
			{Var = "Trainer.Width", Type = "number", Range = {200, 800}, Text = "Strafe Trainer Width"},
			{Var = "Trainer.Height", Type = "number", Range = {20, 100}, Text = "Strafe Trainer Height"},
			{Var = "Trainer.HeightOffset", Type = "number", Range = {- ScrH() / 2, ScrH() / 2}, Text = "Strafe Trainer offset"},
			{Var = "Trainer.RectangleColor", Type = "color", Text = "Strafe Trainer background color"},
			{Var = "Trainer.TextColor", Type = "color", Text = "Strafe Trainer text color"}
		}
	},

	Colors = {
		Background = Color(35, 35, 35),
		Foreground = Color(42, 42, 42),
		Text = Color(255, 255, 255),
		Expressions = {
			Important = function(self) return _C.ImportantColor end
		}
	},

	SettingPanelFor = {
		bool = "CheckBox",
		number = "NumSlider",
		-- color = "ColorSliders"
	},

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
		local window = vgui.CreateFromTable(self.Window)
		window.Colors = self.Colors

		local menuLanguage = GetConVar("gmod_language"):GetString() == "fr" and "FR" or "EN"
		for k, v in pairs(self[menuLanguage]) do
			self[k] = v
			window[k] = v
		end

		window.TitlePart = vgui.CreateFromTable(self.TitlePart, window)
			window.TitlePart.Close = vgui.CreateFromTable(self.CloseButton, window.TitlePart)
		window.SettingsPart = vgui.CreateFromTable(self.SettingsPart, window)
		for _, setting in ipairs(self.Settings) do
			local panelType = self.SettingPanelFor[setting.Type]
			if not panelType then continue end
			local panel = vgui.CreateFromTable(self[panelType], window.SettingsPart)
			panel.TogglePanel = self.TogglePanel
			panel.SliderPanel = self.SliderPanel
			panel.Setting = setting
			window.SettingsPart:Add(panel)
		end
	end,

	Window = {
		Base = "DPanel",
		Size = {400, 520},

		Init = function(self)
			self:SetSize( unpack(self.Size) )
			self:Center()
			self:SetX(ScrW() / 6)
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
			JHUD_UpdateSettings()
		end
	},

	SettingsPart = {
		Base = "DIconLayout",

		Init = function(self)
			self.Window = self:GetParent()
			self.Colors = self.Window.Colors
			local tpHeight = self.Window.TitlePart.Height
			self:SetPos(10, 5 + tpHeight + 5)
			self:SetSize(self.Window:GetWide() - 20, self.Window:GetTall() - tpHeight - 10 - 5)
			self:SetSpaceY(5)
		end
	},

	CheckBox = {
		Base = "DPanel",
		Height = 30,
		Setting = {},

		Init = function(self)
			self.Window = self:GetParent().Window
			self.Colors = self.Window.Colors
			self:SetSize(self.Window:GetWide() - 10, self.Height)

			timer.Simple(0, function()
				self.TogglePanel = vgui.CreateFromTable(self.TogglePanel, self)
				local var = string.Explode(".", self.Setting.Var)
				self.TogglePanel.ConfigTable = JHUD[ var[1] ]
				self.TogglePanel.ConfigKey = var[2]
			end)
		end,

		Paint = function(self, w, h)
			draw.RoundedBox(0, 0, 0, w, h, self.Colors.Background)
			draw.SimpleText(self.Setting.Text, "HUDLabel", 5, self.Height * 0.5, self.Colors.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
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
			self:SetPos(parentW - 10 - 5 - self.Size[1], parentH * 0.5 - self.Size[2] * 0.5)
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
			draw.RoundedBox(0, 0, 0, w, h, self.Colors.Foreground)
			local important = self.Colors.Important
			important = Color(important.r, important.g, important.b, 120 * progress)
			draw.RoundedBox(0, 0, 0, w, h, important)

			local minX, maxX = self.SliderPadding, w - self.SliderPadding - self.SliderW
			local x = minX + (maxX - minX) * progress
			draw.RoundedBox(0, x, self.SliderPadding, self.SliderW, self.SliderH, self.Colors.Text)
		end,

		DoClick = function(self)
			self.ConfigTable[self.ConfigKey] = not self.ConfigTable[self.ConfigKey]
			self.LastChange = CurTime()
		end
	},

	NumSlider = {
		Base = "DPanel",
		Height = 55,
		TextY = 15,
		NumBoxSize = {40, 20},
		Setting = {},
		ConfigTable = {},
		ConfigKey = {},

		Init = function(self)
			self.Window = self:GetParent().Window
			self.Colors = self.Window.Colors
			self:SetSize(self.Window:GetWide() - 10, self.Height)

			timer.Simple(0, function()
				local var = string.Explode(".", self.Setting.Var)
				self.ConfigTable = JHUD[ var[1] ]
				self.ConfigKey = var[2]

				self.SliderPanel = vgui.CreateFromTable(self.SliderPanel, self)
				self.SliderPanel.ConfigTable = JHUD[ var[1] ]
				self.SliderPanel.ConfigKey = var[2]
				self.SliderPanel.Range = self.Setting.Range
			end)
		end,

		Paint = function(self, w, h)
			local center = TEXT_ALIGN_CENTER	
			draw.RoundedBox(0, 0, 0, w, h, self.Colors.Background)
			draw.SimpleText(self.Setting.Text, "HUDLabel", 5, self.TextY, self.Colors.Text, TEXT_ALIGN_LEFT, center)

			local nBoxW, nBoxH = unpack(self.NumBoxSize)
			draw.RoundedBox(0, 5, h - nBoxH - 5, w - 5 * 3 - 10 - nBoxW, nBoxH, self.Colors.Foreground)
			draw.RoundedBox(0, w - nBoxW - 5 - 10, h - nBoxH - 5, nBoxW, nBoxH, self.Colors.Foreground)
			draw.SimpleText(tostring(self.ConfigTable[self.ConfigKey]), "HUDLabel", w - nBoxW * 0.5 - 5 - 10, h - nBoxH * 0.5 - 5, self.Colors.Text, center, center)
		end
	},

	SliderPanel = {
		Base = "DSlider",
		SliderPadding = 3,
		SliderW = 10,
		ConfigTable = {},
		ConfigKey = "",
		Range = {0, 1},

		Init = function(self)
			local parent = self:GetParent()
			local parentW, parentH = parent:GetSize()
			local nBoxW, nBoxH = unpack(parent.NumBoxSize)

			self.Window = parent.Window
			self.Colors = self.Window.Colors
			self.SliderH = nBoxH - 2 * self.SliderPadding

			self:SetSize(parentW - 5 * 3 - 10 * 3 - nBoxW, nBoxH)
			self:SetPos(5 + 10, parentH - nBoxH - 5)

			self.Knob:SetSize(self.SliderW, nBoxH - self.SliderPadding * 2)
			self.Knob.Paint = self.PaintKnob
			self.Knob.Colors = self.Colors
			
			timer.Simple(0, function()
				local min, max = unpack(self.Range)
				local frac = (self.ConfigTable[self.ConfigKey] - min) / (max - min)
				self:SetSlideX(frac)
			end)
		end,

		Think = function(self)
			if not self.Knob.Depressed then return end
			local min, max = unpack(self.Range)
			self.ConfigTable[self.ConfigKey] = math.Round( min + self:GetSlideX() * (max - min) )
		end,

		Paint = function(self, w, h) end,

		PaintKnob = function(knob, w, h)
			draw.RoundedBox(0, 0, 0, w, h, knob.Depressed and knob.Colors.Important or knob.Colors.Text)
		end
	}
}

JHUD_MENU:Init()

net.Receive( "JHUD_OpenSettings", function() 
	JHUD_MENU:Open()
end )

hook.Add("PlayerDataLoaded", "RetrieveJHUDSettings", function(data)
	if data.JHUDEnabled then JHUD.HUD.Enabled = data.JHUDEnabled end
	if data.JHUDOpacity then JHUD.HUD.Opacity = data.JHUDOpacity end
	if data.JHUDOffset then JHUD.HUD.HeightOffset = data.JHUDOffset end
	if data.StrafeTrainerEnabled then JHUD.Trainer.Enabled = data.StrafeTrainerEnabled end
	if data.StrafeTrainerDynColor then JHUD.Trainer.DynamicRectangleColor = data.StrafeTrainerDynColor end
	if data.StrafeTrainerRefreshRate then JHUD.Trainer.RefreshRate = data.StrafeTrainerRefreshRate end
	if data.StrafeTrainerW then JHUD.Trainer.Width = data.StrafeTrainerW end
	if data.StrafeTrainerH then JHUD.Trainer.Height = data.StrafeTrainerH end
	if data.StrafeTrainerOffset then JHUD.Trainer.HeightOffset = data.StrafeTrainerOffset end
end)