HelpMenu = {

	Colors = {
		Background = Color(35, 35, 35),
		Foreground = Color(42, 42, 42),
		Text = Color(255, 255, 255),
		Expressions = {
			Important = function(self) return _C.ImportantColor end
		}
	},
	API = "https://api.dotshark.ovh/",
	Gamemode = _C.GameType,
	Language = GetConVar("gmod_language"),

	Menu = HelpMenu and HelpMenu.Menu or false,
	Opened = HelpMenu and HelpMenu.Opened or false,
	IsLoading = HelpMenu and HelpMenu.IsLoading or false,
	Pages = {},

	Init = function(self)
		setmetatable(self, {__index = _G})
		for k, f in pairs(self) do
			if isfunction(f) then setfenv(f, self) end
		end

		for k, panel in pairs(self) do
			if not (istable(panel) and panel.IsPanel) then continue end
			for k, f in pairs(panel) do
				if isfunction(f) then setfenv(f, self) end
			end
		end

		local colorsMeta = {
			__index = function(t, k)
				if t.Expressions[k] then
					return t.Expressions[k](t)
				end
			end
		}
		setmetatable(self.Colors, colorsMeta)

		if self.Opened then 
			self.Menu:Close()
			self.Opened = false
		end

		hook.Add("Move", "HelpMenu", self.CheckForKey)
	end,

	GUI = function(...) 
		return vgui.CreateFromTable(...)
	end,

	CheckForKey = function(cmd)
		if input.WasKeyPressed(KEY_F1) then
			Toggle()
		end
	end,

	Toggle = function()
		if IsLoading then return end

		if Opened then
			Menu:Close()
		else
			local lang = Language:GetString()
			Menu = GUI(Window)
			IsLoading = true

			http.Fetch(API .. Gamemode .. "/menu/" .. lang, function(body)
				IsLoading = false
				local data = util.JSONToTable(body)

				if not Menu then return end
				if (not data) then
					Link:Print("Général", "Impossible d'ouvrir le menu")
					Menu:Close()
					return
				end

				local buttons = data.Buttons
				Pages = data.Pages
				
				Menu:CreateSideMenu()
					:CreatePagesContainer()
					:CreateButtons(buttons)
					:SetTextPage(buttons[1].Name)
			end,
			function() Menu:Close() end)
		end
	end,

	Window = {
		IsPanel = true,
		Base = "DPanel",
		Size = {800, 600},
		SideMenu = false,
		PagesContainer = false,

		Init = function(self)
			local w, h = unpack(self.Size)
			local sW, sH = ScrW(), ScrH()
			local x = (sW * 0.5) - (w * 0.5)
			local y = (sH * 0.5) - (h * 0.5)

			self:SetSize(w, h)
			self:SetPos(x, y)
			self:SetClickable(true)
			
			Menu = self
			Opened = true
		end,

		CreateSideMenu = function(self)
			self.SideMenu = GUI(SideMenu, Menu)
			return self
		end,

		CreatePagesContainer = function(self)
			self.PagesContainer = GUI(PagesContainer, Menu)
			return self
		end,

		CreateButtons = function(self, buttonsData)
			local sideMenu = self.SideMenu
			sideMenu.Buttons = {}
			local buttons = sideMenu.Buttons

			for i, bData in pairs(buttonsData) do
				bData.Index = i
				buttons[i] = GUI(Button, sideMenu):Setup(bData)
			end

			return self
		end,

		Paint = function(self, w, h)
			surface.SetDrawColor(Colors.Background)
			surface.DrawRect(0, 0, w, h)
		end,

		SetClickable = function(self, enable)
			gui.EnableScreenClicker(enable)
		end,

		Think = function(self)
			if not vgui.CursorVisible() then
				self:SetClickable(true)
			end
		end,

		SetTextPage = function(self, page)
			self.PagesContainer:SetTextPage(page)
			self.SideMenu:SelectButton(page)
		end,

		SetServersPage = function(self, page)
			self.PagesContainer:SetServersPage(page)
			self.SideMenu:SelectButton(page)
		end,

		OpenURL = function(self, name, url)
			gui.OpenURL(url)
		end,

		Close = function(self)
			self:SetVisible(false)
			self:Remove()
			self:SetClickable(false)

			Menu = false
			Opened = false
		end
	},

	SideMenu = {
		IsPanel = true,
		Base = "DPanel",
		Size = {200, false},
		Margin = {5, 5},
		Buttons = {},

		Init = function(self)
			local pW, pH = self:GetParent():GetSize()
			local w, h = unpack(self.Size)
			w, h = w or pW, h or pH
			x, y = unpack(self.Margin)
			w, h = w - x * 2, h - y * 2

			self:SetPos(x, y)
			self:SetSize(w, h)
		end,

		SelectButton = function(self, name)
			local buttons = self.Buttons
			local nButtons = #buttons
			for i = 1, nButtons do
				local button = buttons[i]
				button.Selected = button.Text == name
			end
		end,

		Paint = function(self, w, h)
			surface.SetDrawColor(Colors.Foreground)
			surface.DrawRect(0, 0, w, h)
		end
	},

	PagesContainer = {
		IsPanel = true,
		Base = "DPanel",
		Size = {600, false},
		Margin = {200, 5},
		Current = "",
		Tabs = {},

		Init = function(self)
			local pW, pH = self:GetParent():GetSize()
			local w, h = unpack(self.Size)
			w, h = w or pW, h or pH
			x, y = unpack(self.Margin)
			w, h = w - y, h - 2 * y

			self.Tabs = {}
			self:SetPos(x, y)
			self:SetSize(w, h)
		end,

		Paint = function(self, w, h)
			surface.SetDrawColor(Colors.Foreground)
			surface.DrawRect(0, 0, w, h)
		end,

		SetTextPage = function(self, page)
			if not self:ChangePage(page) then 
				local tab = GUI(TextPage, self)
					:SetupPage(Pages[page])
				self.Tabs[page] = tab
			end
			self.Current = page
		end,

		SetServersPage = function(self, page)
			if not self:ChangePage(page) then 
				local tab = GUI(ServersPage, self)
				for _, server in pairs(Pages[page] or {}) do
					tab:AddServer(server)
				end
				self.Tabs[page] = tab
			end
			self.Current = page
		end,

		ChangePage = function(self, page)
			local tabs = self.Tabs
			local previousTab = tabs[self.Current]
			currentTab = tabs[page]

			if previousTab then 
				previousTab:SetVisible(false)
			end
			if currentTab then
				currentTab:SetVisible(true)
				return true
			end
		end
	},

	Button = {
		IsPanel = true,
		Base = "DLabel",
		Font = "HUDLabel",
		Text = "",
		Size = {false, 30},
		Margin = {5, 5},
		Padding = {3, 3},
		Color = Color(0, 0, 0),
		Highlighted = false,
		Selected = false,

		Setup = function(self, data)
			self:SetText("")
			self.Text = data.Name
			self.Color = Colors.Background
			self.URL = data.URL

			if data.Color then
				self.Color = data.Color
			end

			self:SetMouseInputEnabled(true)
			local func = data.ClickFunction
			self.DoClick = isfunction(func) and func or function(self)
				Menu[func](Menu, data.Name, data.URL)
			end

			local pW, pH = self:GetParent():GetSize()
			local w, h = unpack(self.Size)
			w, h = w or pW, h or pH

			if data.Pos == "Top" then
				x, y = unpack(self.Margin)
				y = y + (data.Index - 1) * (h + y)
				w = w - x * 2
			elseif data.Pos == "Bottom" then
				x = self.Margin[1]
				y = pH - self.Margin[2] - h
				w = w - x * 2
			elseif data.Pos == "Right" and data.Wide then
				if data.Wide then w = data.Wide end
				x = pW - w - x
				y = pH * 0.5 - h * 0.5
			end

			self:SetPos(x, y)
			self:SetSize(w, h)

			return self
		end,

		OnCursorEntered = function(self)
			self.Highlighted = true
			self:SetCursor("hand")
		end,

		OnCursorExited = function(self)
			self.Highlighted = false
			self:SetCursor("arrow")
		end,

		Paint = function(self, w, h)
			local col = Colors.Important
			if self.Selected then
				col = Color(col.r, col.g, col.b, 255)
			elseif self.Highlighted then
				col = Color(col.r, col.g, col.b, 150)
			else
				col = Color(0, 0, 0, 0)
			end

			local center = TEXT_ALIGN_CENTER
			local mX, mY = unpack(self.Padding)

			surface.SetDrawColor(self.Color)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(col)
			surface.DrawRect(mX, mY, w - mX * 2, h - mY * 2)

			draw.SimpleText(self.Text, self.Font, w * 0.5, h * 0.5, Colors.Text, center, center)
		end
	},

	TextPage = {
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
			local pW, pH = self:GetParent():GetSize()
			local w, h = unpack(self.Size)
			w, h = w or pW, h or pH
			x, y = unpack(self.Margin)
			w, h = w - 2 * x, h - 2 * y

			self:SetPos(x, y)
			self:SetSize(w, h)

			local scrollbar = self:GetVBar()
			scrollbar:SetHideButtons(true)
			scrollbar:SetSize(12, 12)

			scrollbar.Paint = function(pnl, w, h)
				surface.SetDrawColor(Colors.Foreground)
				surface.DrawRect(0, 0, w, h)
			end

			scrollbar.btnGrip.Paint = function(pnl, w, h)
				local padding, col = self.ScrollPadding
				
				if pnl.Depressed then
					col = Colors.Important
				elseif pnl.Hovered then
					local important = Colors.Important
					col = Color(important.r, important.g, important.b, 150)
				else
					col = Colors.Background
				end

				surface.SetDrawColor(col)
				surface.DrawRect(padding, padding, w - 2 * padding, h - 2 * padding)
			end
		end,

		Paint = function(self, w, h)
			surface.SetDrawColor(Colors.Foreground)
			surface.DrawRect(0, 0, w, h)
		end,

		LoadPage = function(self, url)
			http.Fetch(url, function(body)
				local data = util.JSONToTable(body)
				self:SetupPage(data)
			end)
		end,

		SetupPage = function(self, data)
			if not data[1] then return end
			if not istable(data[1]) then data = {data} end 

			local y = 0

			local nCats = #data
			for n, cat in pairs(data) do
				for i, text in pairs(cat) do
					local font = i == 1 and self.TitleFont or self.Font
					local margin = i == 1 and 0 or self.ListMargin
					local spacing = i == 1 and self.TitleSpacing or self.LineSpacing

					local h = GUI(TextPanel, self)
						:SetData {
							Text = text,
							Margin = {margin, y},
							Font = font,
							List = i > 1
						}
						:GetTall()
					y = y + h + spacing
				end

				y = y + self.TitleSpacing
			end

			GUI(TextPanel, self)
				:SetData {
					Text = "",
					Margin = {0, y},
					Font = self.Font
				}
			return self
		end
	},

	TextPanel = {
		IsPanel = true,
		Base = "DPanel",
		Size = {false, 30},
		Margin = {10, 10},
		Padding = {0, 0},
		List = false,
		Font = false,
		ScrollbarWidth = 10,

		Init = function(self)
			local pW, pH = self:GetParent():GetParent():GetSize()
			local w, h = unpack(self.Size)
			w, h = w or pW, h or pH
			x, y = unpack(self.Margin)
			w, h = w - 2 * x, h - 2 * y

			self:SetPos(x, y)
			self:SetSize(w, h)
		end,

		Paint = function(self, w, h)
			if not self.List then return end
			draw.SimpleText("•", self.Font, 0, 0, Colors.Text)
		end,

		SetData = function(self, data)
			local pW, pH = self:GetSize()
			self.List = data.List
			self.Font = data.Font
			self:SetPos(self.Margin[1] + data.Margin[1], self.Margin[2] + data.Margin[2])
			self:SetSize(pW - data.Margin[1], pH)

			local padding = 0
			if self.List then
				surface.SetFont(self.Font)
				padding = surface.GetTextSize("• ")
			end

			local maxWidth = pW - data.Margin[1] - padding - 10 - self.ScrollbarWidth
			local text, finalText = data.Text, ""
			if isstring(text) then
				finalText = self:AddLineBreaks(data.Text, maxWidth)
			elseif istable(text) then
				local lText = #text
				for i, line in pairs(text) do
					local lineBreak = (i == lText) and "" or "\n"
					finalText = finalText .. self:AddLineBreaks(line, maxWidth) .. lineBreak
				end
			end
			
			local textPanel = vgui.Create("DLabel", self)
			textPanel:SetText(finalText)
			textPanel:SetFont(data.Font)
			textPanel:SetColor(Colors.Text)
			textPanel:SetPos(padding, 0)
			textPanel:SizeToContents()

			self:SetTall( textPanel:GetTall() )
			return self
		end,

		AddLineBreaks = function(self, text, maxWidth)
			surface.SetFont(self.Font)
			local words = string.Explode(" ", text)
			local lWords = #words
			local finalText = words[1]

			local i = 2
			while i <= lWords do
				local testText = finalText.." "..words[i]
				local w = surface.GetTextSize(testText)
				if w > maxWidth then
					testText = words[i]
					for i2 = i + 1, lWords do testText = testText.." "..words[i2] end
					finalText = finalText .. "\n" .. self:AddLineBreaks(testText, maxWidth)
					break
				else
					finalText = testText
					i = i + 1
				end
			end

			return finalText
		end
	},

	ServersPage = {
		IsPanel = true,
		Base = "DPanel",
		Size = {false, false},
		Margin = {0, 0},
		Elements = 0,

		Init = function(self)
			local pW, pH = self:GetParent():GetSize()
			local w, h = unpack(self.Size)
			w, h = w or pW, h or pH
			x, y = unpack(self.Margin)
			w, h = w - 2 * y, h - 2 * y

			self:SetPos(x, y)
			self:SetSize(w, h)
		end,

		Paint = function(self, w, h)
			surface.SetDrawColor(Colors.Foreground)
			surface.DrawRect(0, 0, w, h)
		end,

		AddServer = function(self, data)
			GUI(ServerPanel, self)
				:SetData(data)
			self.Elements = self.Elements + 1
			return self
		end
	},

	ServerPanel = {
		IsPanel = true,
		Base = "DPanel",
		Font = "HUDLabel",
		Size = {false, 60},
		Margin = {5, 5},
		Padding = {3, 3},
		Name = "",
		URL = "",
		Format = "",
		Infos = "",
		Image = false,
		NextCheck = 0,
		
		Init = function(self)
			local pW, pH = self:GetParent():GetSize()
			local w, h = unpack(self.Size)
			w, h = w or pW, h or pH
			x, y = unpack(self.Margin)
			w, h = w - 2 * y, h - 2 * y
			y = y + self:GetParent().Elements * (h + y)

			self:SetPos(x, y)
			self:SetSize(w, h)
		end,

		Paint = function(self, w, h)
			surface.SetDrawColor(Colors.Background)
			surface.DrawRect(0, 0, w, h)

			local pX, pY = unpack(self.Padding)
			surface.SetDrawColor(Colors.Foreground)
			surface.DrawRect(pX, pY, h - pX * 2, h - pY * 2)

			if self.Image then
				surface.SetDrawColor(255, 255, 255)
				surface.SetMaterial(self.Image)
				surface.DrawTexturedRect(pX, pY, h - pX * 2, h - pY * 2)
			end

			local left, center = TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
			local offset = self.Margin[1] + h
			draw.SimpleText(self.Name, self.Font, offset, h / 4, Colors.Text, left, center)
			draw.SimpleText(self.Infos, self.Font, offset, h * (3 / 4), Colors.Text, left, center)
		end,

		SetData = function(self, data)
			self.Name = data.Name
			self.URL = API .. data.ID.. "/infos"
			self.Format = data.Format
			self.Infos = "Chargement..."

			local clickFunction
			if data.ServerIP then
				self.ServerIP = data.ServerIP
				clickFunction = self.ServerConnect
			elseif data.DiscordURL then
				self.DiscordURL = data.DiscordURL
				clickFunction = self.DiscordConnect
			end
			
			GUI(Button, self)
				:Setup {
					Name = data.Interaction,
					ClickFunction = clickFunction,
					Pos = "Right",
					Wide = 200,
					Color = Colors.Foreground
				}

			http.Fetch(API .. data.ID .. ".png", function(body, l, headers)
				if not file.Exists("ds_menu", "DATA") then
					file.CreateDir("ds_menu")
				end

				local path = "ds_menu/" .. data.ID .. ".png"
				file.Write(path, body)
				self.Image = Material("../data/" .. path)
			end)
		end,

		ServerConnect = function(self)
			RunConsoleCommand("connect", self:GetParent().ServerIP)
		end,

		DiscordConnect = function(self)
			gui.OpenURL(self:GetParent().DiscordURL)
		end,

		Think = function(self)
			if not self.URL then return end

			local ct = CurTime()
			if ct < self.NextCheck then return end
			self.NextCheck = ct + 10

			http.Fetch(self.URL, function(body)
				self:FormatInfos(body)
			end)
		end,

		FormatInfos = function(self, json)
			local infos = util.JSONToTable(json) or {}
			local strInfos = self.Format
			for k, v in pairs(infos) do
				strInfos = string.Replace( strInfos, "$"..k, tostring(v) )
			end
			self.Infos = strInfos
		end
	}

}

HelpMenu:Init()