--$Id: OneBag.lua 8277 2006-08-17 14:11:43Z kaelten $
OneBag = OneCore:NewModule("OneBag", "AceEvent-2.0", "AceHook-2.0", "AceDebug-2.0", "AceConsole-2.0", "AceDB-2.0")

local L = AceLibrary("AceLocale-2.0"):new("OneBag")

function OneBag:OnInitialize()
    local baseArgs = OneCore:GetFreshOptionsTable(self)

    local customArgs = {
        ["0"] = {
            name = L"Backpack", type = 'toggle', order = 5,
            desc = L"Turns display of your backpack on and off.",
            get = function() return self.db.profile.show[0] end,
            set = function(v) 
                self.db.profile.show[0] = v 
                self:OrganizeFrame(true)
            end,
        },
        ["1"] = {
            name = L"First Bag", type = 'toggle', order = 6,
            desc = L"Turns display of your first bag on and off.",
            get = function() return self.db.profile.show[1] end,
            set = function(v) 
                self.db.profile.show[1] = v 
                self:OrganizeFrame(true)
            end,
        },
        ["2"] = {
            name = L"Second Bag", type = 'toggle', order = 7,
            desc = L"Turns display of your second bag on and off.",
            get = function() return self.db.profile.show[2] end,
            set = function(v) 
                self.db.profile.show[2] = v 
                self:OrganizeFrame(true)
            end,
        },
        ["3"] = {
            name = L"Third Bag", type = 'toggle', order = 8,
            desc = L"Turns display of your third bag on and off.",
            get = function() return self.db.profile.show[3] end,
            set = function(v) 
                self.db.profile.show[3] = v 
                self:OrganizeFrame(true)
            end,
        },
        ["4"] = {
            name = L"Fourth Bag", type = 'toggle', order = 9,
            desc = L"Turns display of your fourth bag on and off.",
            get = function() return self.db.profile.show[4] end,
            set = function(v) 
                self.db.profile.show[4] = v 
                self:OrganizeFrame(true)
            end,
        },
    }
    
    OneCore:CopyTable(customArgs, baseArgs.args.show.args)
	
    OneCore:LoadOptionalCommands(baseArgs, self)
       
	self:RegisterDB("OneBagDB")
	self:RegisterDefaults('profile', OneCore.defaults)
	self:RegisterChatCommand({"/ob", "/OneBag"}, baseArgs, string.upper(self.title))
	
	--self:SetDebugging(true)
	-- Keyring: KEYRING_CONTAINER is -2 on TBC-style clients; Emberveil may define it
	local kr = KEYRING_CONTAINER or -2
	self.keyringBag = kr
	self.fBags			= {0, 1, 2, 3, 4, kr}
    self.rBags          = {kr, 4, 3, 2, 1, 0}
	
	self.frame = nil
	self._baseArgs = baseArgs
end


local function OneBag_KeyringId()
	if OneBag and OneBag.keyringBag then return OneBag.keyringBag end
	return KEYRING_CONTAINER or -2
end

local function OneBag_AddKeyringButton(bagBar)
	if not bagBar or getglobal("OneBagBagBarBtnKey") then return end
	bagBar:SetWidth(240)
	local kr = OneBag_KeyringId()
	local b = CreateFrame("Button", "OneBagBagBarBtnKey", bagBar)
	b:SetWidth(34)
	b:SetHeight(34)
	b.bagId = kr
	b:SetPoint("LEFT", bagBar, "LEFT", 5 * 38, 0)

	local border = b:CreateTexture(nil, "BACKGROUND")
	border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
	border:SetWidth(56)
	border:SetHeight(56)
	border:SetPoint("CENTER", b, "CENTER", 0, 0)

	local icon = b:CreateTexture(nil, "ARTWORK")
	icon:SetWidth(30)
	icon:SetHeight(30)
	icon:SetPoint("CENTER", b, "CENTER", 0, 0)
	icon:SetTexture("Interface\\ContainerFrame\\KeyRing-Bag-Icon")
	if not icon:GetTexture() then
		icon:SetTexture("Interface\\Buttons\\UI-Button-KeyRing")
	end
	if not icon:GetTexture() then
		icon:SetTexture("Interface\\Icons\\INV_Misc_Key_03")
	end
	b.icon = icon

	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
	hl:SetBlendMode("ADD")
	hl:SetAllPoints(b)

	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	b:SetScript("OnClick", function()
		local bag = this.bagId or OneBag_KeyringId()
		if CursorHasItem() then
			if PutKeyInKeyRing then
				PutKeyInKeyRing()
			elseif PutItemInBag then
				PutItemInBag(bag)
			end
			return
		end
		if OneBag.db and OneBag.db.profile and OneBag.db.profile.show then
			local cur = OneBag.db.profile.show[bag]
			if cur == nil then cur = true end
			OneBag.db.profile.show[bag] = not cur
			OneBag:OrganizeFrame(true)
			if OneBag.UpdateBag then OneBag:UpdateBag(bag) end
			if OneBag.RefreshAllBags then OneBag:RefreshAllBags() end
		end
	end)
	b:SetScript("OnEnter", function()
		local bag = this.bagId or OneBag_KeyringId()
		if OneBag and OneBag.HighlightBagSlots then
			OneBag:HighlightBagSlots(bag)
		end
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:SetText(KEYRING or "Keyring")
		GameTooltip:AddLine("Click to show/hide keys in OneBag", 0.7, 0.7, 0.7)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function()
		local bag = this.bagId or OneBag_KeyringId()
		if OneBag and OneBag.UnhighlightBagSlots then
			OneBag:UnhighlightBagSlots(bag)
		end
		GameTooltip:Hide()
	end)
	b:SetScript("OnUpdate", function()
		local bag = this.bagId or OneBag_KeyringId()
		if this.icon then
			local dim = 1
			if OneBag and OneBag.db and OneBag.db.profile and OneBag.db.profile.show then
				local shown = OneBag.db.profile.show[bag]
				if shown == nil then shown = true end
				if not shown then dim = 0.4 end
			end
			this.icon:SetVertexColor(dim, dim, dim)
		end
	end)
end

function OneBag:SetupFrames()
	-- Prefer pure Lua frame; if XML created OneBagFrame, still ensure our chrome exists
	local frame = self.frame or getglobal("OneBagFrame")
	local created = false
	if not frame then
		frame = CreateFrame("Frame", "OneBagFrame", UIParent)
		frame:SetFrameStrata("MEDIUM")
		frame:SetClampedToScreen(true)
		frame:SetMovable(true)
		frame:EnableMouse(true)
		frame:SetWidth(400)
		frame:SetHeight(300)
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		frame:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 5, right = 5, top = 5, bottom = 5 }
		})
		frame:SetBackdropColor(0, 0, 0, 0.45)
		frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
		frame:Hide()

		-- Title bar for dragging (item slots cover the main frame)
		local titleBar = CreateFrame("Button", "OneBagFrameTitleBar", frame)
		titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
		titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -80, 0)
		titleBar:SetHeight(28)
		local function savePos()
			if OneBag.db and OneBag.db.profile then
				local left, top = frame:GetLeft(), frame:GetTop()
				if left and top then
					OneBag.db.profile.point = { left = left, top = top }
				end
			end
		end
		local function canMove()
			-- Locked blocks normal drag; Alt+drag always works so you can never get stuck
			if IsAltKeyDown and IsAltKeyDown() then return true end
			if OneBag.db and OneBag.db.profile and OneBag.db.profile.locked then
				return false
			end
			return true
		end
		titleBar:RegisterForDrag("LeftButton")
		titleBar:SetScript("OnDragStart", function()
			if canMove() then frame:StartMoving() end
		end)
		titleBar:SetScript("OnDragStop", function()
			frame:StopMovingOrSizing()
			savePos()
		end)
		-- Also allow dragging from empty frame chrome
		frame:RegisterForDrag("LeftButton")
		frame:SetScript("OnDragStart", function()
			if canMove() then frame:StartMoving() end
		end)
		frame:SetScript("OnDragStop", function()
			frame:StopMovingOrSizing()
			savePos()
		end)

		frame:SetScript("OnShow", function()
			if OneBag and OneBag.OnShow then OneBag:OnShow() end
		end)
		frame:SetScript("OnHide", function()
			if OneBag and OneBag.OnBaseHide then OneBag:OnBaseHide() end
			if OneBag and OneBag.OnCustomHide then OneBag:OnCustomHide() end
		end)

		local title = frame:CreateFontString("OneBagFrameName", "OVERLAY", "GameFontNormal")
		title:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -8)
		title:SetText((UnitName("player") or "Player") .. (L and L"'s Bags" or "'s Bags"))

		local close = CreateFrame("Button", "OneBagFrameCloseButton", frame, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
		close:SetScript("OnClick", function() frame:Hide() end)

		local menuBtn = CreateFrame("Button", "OneBagFrameConfigButton", frame, "UIPanelButtonTemplate")
		menuBtn:SetWidth(60)
		menuBtn:SetHeight(20)
		menuBtn:SetPoint("RIGHT", close, "LEFT", 0, 0)
		menuBtn:SetText(ONEBAG_LOCALE_MENU or "Menu")
		menuBtn:SetScript("OnClick", function()
			-- Prefer slash options; Dewdrop is unreliable on Emberveil
			DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00OneBag:|r Type |cffffff00/ob|r for options (colors, frame, show, profile, etc.)")
			if OneBag.OpenMenu then OneBag:OpenMenu() end
		end)

		-- Money frame; UpdateMoney() places number+coin side by side each time
		local moneyFrame = CreateFrame("Frame", "OneBagMoneyFrame", frame)
		moneyFrame:SetWidth(180)
		moneyFrame:SetHeight(16)
		moneyFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 8)

		local function makeIcon(name, left, right)
			local icon = moneyFrame:CreateTexture(name, "OVERLAY")
			icon:SetWidth(13)
			icon:SetHeight(13)
			icon:SetTexture("Interface\\MoneyFrame\\UI-MoneyIcons")
			icon:SetTexCoord(left, right, 0, 1)
			return icon
		end
		local function makeText(name)
			local fs = moneyFrame:CreateFontString(name, "OVERLAY", "GameFontNormal")
			fs:SetJustifyH("RIGHT")
			return fs
		end

		moneyFrame.copperIcon = makeIcon("OneBagCopperIcon", 0.5, 0.75)
		moneyFrame.copperText = makeText("OneBagCopperText")
		moneyFrame.silverIcon = makeIcon("OneBagSilverIcon", 0.25, 0.5)
		moneyFrame.silverText = makeText("OneBagSilverText")
		moneyFrame.goldIcon = makeIcon("OneBagGoldIcon", 0, 0.25)
		moneyFrame.goldText = makeText("OneBagGoldText")
		frame.moneyFrame = moneyFrame

		-- Individual bag buttons under the frame (toggle via Menu)
		local bagBar = CreateFrame("Frame", "OneBagBagBar", frame)
		bagBar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 4, -4)
		bagBar:SetWidth(200)
		bagBar:SetHeight(36)
		frame.bagBar = bagBar
		for i = 0, 4 do
			local b = CreateFrame("Button", "OneBagBagBarBtn"..i, bagBar)
			b:SetWidth(34)
			b:SetHeight(34)
			b:SetID(i)
			b:SetPoint("LEFT", bagBar, "LEFT", i * 38, 0)
			-- Border sized correctly so no center square
			local border = b:CreateTexture(nil, "BACKGROUND")
			border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
			border:SetWidth(56)
			border:SetHeight(56)
			border:SetPoint("CENTER", b, "CENTER", 0, 0)
			local icon = b:CreateTexture(b:GetName().."Icon", "ARTWORK")
			icon:SetWidth(30)
			icon:SetHeight(30)
			icon:SetPoint("CENTER", b, "CENTER", 0, 0)
			b.icon = icon
			local hl = b:CreateTexture(nil, "HIGHLIGHT")
			hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
			hl:SetBlendMode("ADD")
			hl:SetAllPoints(b)
			b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			b:SetScript("OnClick", function()
				local bag = this:GetID()
				if CursorHasItem() then
					if bag == 0 then PutItemInBackpack() else PutItemInBag(bag) end
					return
				end
				if OneBag.db and OneBag.db.profile and OneBag.db.profile.show then
					local cur = OneBag.db.profile.show[bag]
					if cur == nil then cur = true end
					OneBag.db.profile.show[bag] = not cur
					OneBag:OrganizeFrame(true)
					for k = 0, 4 do OneBag:UpdateBag(k) end
				end
			end)
			b:SetScript("OnEnter", function()
				local bag = this:GetID()
				if OneBag and OneBag.HighlightBagSlots then
					OneBag:HighlightBagSlots(bag)
				end
				GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
				if bag == 0 then
					GameTooltip:SetText(BACKPACK_TOOLTIP or "Backpack")
				else
					local inv = ContainerIDToInventoryID and ContainerIDToInventoryID(bag)
					if not inv or not GameTooltip:SetInventoryItem("player", inv) then
						GameTooltip:SetText("Bag "..bag)
					end
				end
				GameTooltip:AddLine("Click to show/hide this bag in OneBag", 0.7, 0.7, 0.7)
				GameTooltip:Show()
			end)
			b:SetScript("OnLeave", function()
				local bag = this:GetID()
				if OneBag and OneBag.UnhighlightBagSlots then
					OneBag:UnhighlightBagSlots(bag)
				end
				GameTooltip:Hide()
			end)
			b:SetScript("OnUpdate", function()
				local bag = this:GetID()
				local tex
				if bag == 0 then
					tex = "Interface\\Buttons\\Button-Backpack-Up"
				elseif ContainerIDToInventoryID then
					tex = GetInventoryItemTexture("player", ContainerIDToInventoryID(bag))
				end
				if this.icon then
					this.icon:SetTexture(tex or "Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")
					local dim = 1
					if OneBag and OneBag.db and OneBag.db.profile and OneBag.db.profile.show then
						local shown = OneBag.db.profile.show[bag]
						if shown == nil then shown = true end
						if not shown then dim = 0.4 end
					end
					this.icon:SetVertexColor(dim, dim, dim)
				end
			end)
		end
		OneBag_AddKeyringButton(bagBar)
	end

	if getglobal("OneBagFrameName") then
		getglobal("OneBagFrameName"):SetText((UnitName("player") or "Player") .. (L and L"'s Bags" or "'s Bags"))
	end

	self.frame = frame
	self.frame.handler = self

	-- Ensure movable + drag always works
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	local titleBar = getglobal("OneBagFrameTitleBar")
	if not titleBar then
		titleBar = CreateFrame("Button", "OneBagFrameTitleBar", frame)
		titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
		titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -80, 0)
		titleBar:SetHeight(32)
	end
	titleBar:SetFrameLevel((frame:GetFrameLevel() or 1) + 20)
	titleBar:EnableMouse(true)
	titleBar:RegisterForDrag("LeftButton")
	local function savePos()
		if OneBag.db and OneBag.db.profile then
			local left, top = frame:GetLeft(), frame:GetTop()
			if left and top then
				OneBag.db.profile.point = { left = left, top = top }
			end
		end
	end
	local function canMove()
		if IsAltKeyDown and IsAltKeyDown() then return true end
		if OneBag.db and OneBag.db.profile and OneBag.db.profile.locked then return false end
		return true
	end
	titleBar:SetScript("OnDragStart", function()
		if canMove() then frame:StartMoving() end
	end)
	titleBar:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		savePos()
	end)
	-- Mouse down fallback (some clients ignore RegisterForDrag on nested buttons)
	titleBar:SetScript("OnMouseDown", function()
		if arg1 == "LeftButton" and canMove() then frame:StartMoving() end
	end)
	titleBar:SetScript("OnMouseUp", function()
		frame:StopMovingOrSizing()
		savePos()
	end)

	-- Ensure bottom bag bar exists
	if not frame.bagBar then
		local bagBar = CreateFrame("Frame", "OneBagBagBar", frame)
		bagBar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 4, -4)
		bagBar:SetWidth(200)
		bagBar:SetHeight(36)
		frame.bagBar = bagBar
		for i = 0, 4 do
			local b = CreateFrame("Button", "OneBagBagBarBtn"..i, bagBar)
			b:SetWidth(34)
			b:SetHeight(34)
			b:SetID(i)
			b:SetPoint("LEFT", bagBar, "LEFT", i * 38, 0)
			local border = b:CreateTexture(nil, "BACKGROUND")
			border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
			border:SetWidth(56)
			border:SetHeight(56)
			border:SetPoint("CENTER", b, "CENTER", 0, 0)
			local icon = b:CreateTexture(nil, "ARTWORK")
			icon:SetWidth(30)
			icon:SetHeight(30)
			icon:SetPoint("CENTER", b, "CENTER", 0, 0)
			b.icon = icon
			local hl = b:CreateTexture(nil, "HIGHLIGHT")
			hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
			hl:SetBlendMode("ADD")
			hl:SetAllPoints(b)
			b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			b:SetScript("OnClick", function()
				local bag = this:GetID()
				if CursorHasItem() then
					if bag == 0 then PutItemInBackpack() else PutItemInBag(bag) end
					return
				end
				if OneBag.db and OneBag.db.profile and OneBag.db.profile.show then
					local cur = OneBag.db.profile.show[bag]
					if cur == nil then cur = true end
					OneBag.db.profile.show[bag] = not cur
					OneBag:OrganizeFrame(true)
					if OneBag.RefreshAllBags then OneBag:RefreshAllBags() end
				end
			end)
			b:SetScript("OnEnter", function()
				local bag = this:GetID()
				if OneBag.HighlightBagSlots then OneBag:HighlightBagSlots(bag) end
				GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
				if bag == 0 then
					GameTooltip:SetText(BACKPACK_TOOLTIP or "Backpack")
				else
					local inv = ContainerIDToInventoryID and ContainerIDToInventoryID(bag)
					if not inv or not GameTooltip:SetInventoryItem("player", inv) then
						GameTooltip:SetText("Bag "..bag)
					end
				end
				GameTooltip:AddLine("Click to show/hide this bag", 0.7, 0.7, 0.7)
				GameTooltip:Show()
			end)
			b:SetScript("OnLeave", function()
				if OneBag.UnhighlightBagSlots then OneBag:UnhighlightBagSlots(this:GetID()) end
				GameTooltip:Hide()
			end)
			b:SetScript("OnUpdate", function()
				local bag = this:GetID()
				local tex
				if bag == 0 then
					tex = "Interface\\Buttons\\Button-Backpack-Up"
				elseif ContainerIDToInventoryID then
					tex = GetInventoryItemTexture("player", ContainerIDToInventoryID(bag))
				end
				if this.icon then
					this.icon:SetTexture(tex or "Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")
					local dim = 1
					if OneBag and OneBag.db and OneBag.db.profile and OneBag.db.profile.show then
						local shown = OneBag.db.profile.show[bag]
						if shown == nil then shown = true end
						if not shown then dim = 0.4 end
					end
					this.icon:SetVertexColor(dim, dim, dim)
				end
			end)
		end
		OneBag_AddKeyringButton(bagBar)
	end
	if frame.bagBar then
		OneBag_AddKeyringButton(frame.bagBar)
	end
	frame.bagBar:SetFrameLevel((frame:GetFrameLevel() or 1) + 5)
	frame.bagBar:Show()
	-- Old XML side bag strip (OBBagFram) — hide permanently; we use bottom bagBar instead
	self.frame.bagFrame = getglobal("OBBagFram")
	if self.frame.bagFrame then
		self.frame.bagFrame.handler = self
		self.frame.bagFrame:Hide()
		self.frame.bagFrame.Show = function() end -- prevent anything from showing it
	end
	-- Hide the arrow "BagButton" on the title bar that toggles the side strip
	local bagBtn = getglobal("OneBagFrameBagButton")
	if bagBtn then
		bagBtn:Hide()
		bagBtn:EnableMouse(false)
	end
	self.frame.bags = self.frame.bags or {}

	if self._baseArgs then
		self:RegisterDewdrop(self._baseArgs)
		self._baseArgs = nil
	end

	DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00OneBag: frame ready|r")
end

function OneBag:OnEnable()
	self:SetupFrames()
	if not self.frame then return end
	if self.db and self.db.profile then
		self.db.profile.locked = false
	end
	if self.ApplyLayoutMetrics then self:ApplyLayoutMetrics() end

	self:Hook("IsBagOpen")
	self:Hook("ToggleBag")
	self:Hook("OpenBag")
	self:Hook("CloseBag")
	self:Hook("OpenBackpack", "OpenBag")
	self:Hook("CloseBackpack", "CloseBag")
	self:Hook("ToggleBackpack", "ToggleBag")
	
	self:RegisterEvent("BAG_UPDATE",			  function() self:UpdateBag(arg1) end)
	self:RegisterEvent("BAG_UPDATE_COOLDOWN",	  function() self:UpdateBag(arg1) end)
	
	self:RegisterEvent("ITEM_LOCK_CHANGED",		  function() for i = 0, 4 do self:UpdateBag(i) end end)
	self:RegisterEvent("UPDATE_INVENTORY_ALERTS", function() for i = 0, 4 do self:UpdateBag(i) end end)
	
	self:RegisterEvent("AUCTION_HOUSE_SHOW", 	function() self:OpenBag() end)
	self:RegisterEvent("AUCTION_HOUSE_CLOSED", 	function() self:CloseBag() end)
	self:RegisterEvent("BANKFRAME_OPENED", 		function() self:OpenBag() end)
	self:RegisterEvent("BANKFRAME_CLOSED", 		function() self:CloseBag() end)
	self:RegisterEvent("MAIL_CLOSED", 			function() self:CloseBag() end)
	self:RegisterEvent("MERCHANT_SHOW", 		function() self:OpenBag() end)
	self:RegisterEvent("MERCHANT_CLOSED", 		function() self:CloseBag() end)
	self:RegisterEvent("TRADE_SHOW", 			function() self:OpenBag() end)
	self:RegisterEvent("TRADE_CLOSED", 			function() self:CloseBag() end)
	self:RegisterEvent("PLAYER_MONEY",			function() self:UpdateMoney() end)
end

function OneBag:OnDisable()
	for id=1, 12 do
		local frame = getglobal("ContainerFrame"..id)
		frame:ClearAllPoints()
		frame:SetScale(1)
		frame:SetAlpha(1)        
	end
end

function OneBag:OnKeyRingButtonClick()
	-- Guarded for Emberveil / custom 1.12.1 clients
	if not KEYRING_CONTAINER then return end

	if (CursorHasItem()) then
		PutKeyInKeyRing();
	else
		ToggleKeyRing();
	end
	local shownContainerID = IsBagOpen(KEYRING_CONTAINER)
	if ( shownContainerID ) then
		local frame = getglobal("ContainerFrame"..shownContainerID)
		if frame then
			frame:ClearAllPoints()
			frame:SetPoint("BOTTOMLEFT", this:GetParent():GetName() , "TOPLEFT", -9, 0)
			frame:SetScale(OneBag.db.profile.scale)
			frame:SetAlpha(OneBag.db.profile.alpha)
		end
	else
		for id=1, 12 do
			local frame = getglobal("ContainerFrame"..id)
			if frame then
				frame:ClearAllPoints()
				frame:SetScale(1)
				frame:SetAlpha(1)
			end
		end
	end
end

--Hook responses
function OneBag:ToggleBag(bag)
	if bag and (bag < 0 or bag > 4) then
		return self.hooks.ToggleBag.orig(bag)
	end
	
	if self.frame:IsVisible() then
		self.frame:Hide()
	else
		self.frame:Show()
	end
end

function OneBag:IsBagOpen(bag)
	self:Debug(L"Checking if bag %s is open", bag)
	if bag < 0 or bag > 4 then
		return self.hooks.IsBagOpen.orig(bag)
	end
	
	if self.frame:IsVisible() then
		return bag
	else
		return nil	
	end
end

function OneBag:OpenBag(bag)
	self:Debug(L"Opening bag %s", bag)
	if bag and (bag < 0 or bag > 4) then
		return self.hooks.OpenBag.orig(bag)
	end
	
	self.frame:Show()
end


function OneBag:CloseBag(bag)
	self:Debug(L"Closing bag %s", bag)
	if bag and (bag < 0 or bag > 4) then
		return self.hooks.CloseBag.orig(bag)
	end
	
	self.frame:Hide()
end

function OneBag:OnCustomShow()
	local f = self.frame
	if not f or not self.db or not self.db.profile then return end
	local point = self.db.profile.point
	if point and point.left and point.top then
		f:ClearAllPoints()
		f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", point.left, point.top)
	end
end

function OneBag:OnCustomHide()
	if KEYRING_CONTAINER then
		local shownContainerID = IsBagOpen(KEYRING_CONTAINER)
		if ( shownContainerID ) then
			local frame = getglobal("ContainerFrame"..shownContainerID)
			if frame then frame:Hide() end
		end
	end
	for id=1, 12 do
		local frame = getglobal("ContainerFrame"..id)
		if frame then
			frame:ClearAllPoints()
			frame:SetScale(1)
			frame:SetAlpha(1)
		end
	end
end