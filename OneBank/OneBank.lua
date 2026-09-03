-- OneBank for Emberveil / Unreal Azeroth 1.12.1
-- Pure Lua frame (XML templates often fail to load)

OneBank = OneCore:NewModule("OneBank", "AceEvent-2.0", "AceHook-2.0", "AceDebug-2.0", "AceConsole-2.0", "AceDB-2.0")
local L = AceLibrary("AceLocale-2.0"):new("OneBank")

-- Always confirm before spending gold on a bank slot
StaticPopupDialogs["ONEBANK_CONFIRM_BUY_BANK_SLOT"] = {
	-- No %s here: StaticPopup formats this string and errors if args are missing
	text = "Purchase a bank bag slot?",
	button1 = YES or "Yes",
	button2 = NO or "No",
	OnAccept = function()
		if PurchaseSlot then PurchaseSlot() end
	end,
	OnShow = function()
		local purchased = 0
		if GetNumBankSlots then purchased = GetNumBankSlots() or 0 end
		local cost = (GetBankSlotCost and GetBankSlotCost(purchased)) or 0
		local gold = math.floor(cost / 10000)
		local sil = math.floor((cost - gold * 10000) / 100)
		local cop = math.mod(cost, 100)
		local moneyText = gold.."g "..sil.."s "..cop.."c"
		local fs = getglobal(this:GetName().."Text")
		if fs then
			fs:SetText("Purchase a bank bag slot for "..moneyText.."?\n\nClick Yes to buy, or No to cancel.")
		end
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	showAlert = 1,
}


local function SetupBankFrame(self)
	if self.frame and self.frame.GetName then
		return
	end

	local frame = CreateFrame("Frame", "OneBankFrame", UIParent)
	frame:SetWidth(400)
	frame:SetHeight(400)
	frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
	frame:SetFrameStrata("HIGH")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 5, right = 5, top = 5, bottom = 5 }
	})
	frame:SetBackdropColor(0, 0, 0, 0.45)
	frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
	frame:Hide()

	local titleBar = CreateFrame("Button", "OneBankFrameTitleBar", frame)
	titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -80, 0)
	titleBar:SetHeight(28)
	local function savePos()
		if OneBank.db and OneBank.db.profile then
			local left, top = frame:GetLeft(), frame:GetTop()
			if left and top then
				OneBank.db.profile.point = { left = left, top = top }
			end
		end
	end
	local function canMove()
		if IsAltKeyDown and IsAltKeyDown() then return true end
		if OneBank.db and OneBank.db.profile and OneBank.db.profile.locked then
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
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function()
		if canMove() then frame:StartMoving() end
	end)
	frame:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		savePos()
	end)

	frame:SetScript("OnShow", function()
		if OneBank and OneBank.OnShow then OneBank:OnShow() end
	end)
	frame:SetScript("OnHide", function()
		if OneBank and OneBank.OnBaseHide then OneBank:OnBaseHide() end
		if OneBank and OneBank.OnCustomHide then OneBank:OnCustomHide() end
	end)

	local title = frame:CreateFontString("OneBankFrameName", "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -8)
	title:SetText((UnitName("player") or "Player") .. (L and L"'s Bank Bags" or "'s Bank Bags"))

	local close = CreateFrame("Button", "OneBankFrameCloseButton", frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
	close:SetScript("OnClick", function()
		frame:Hide()
		if CloseBankFrame then CloseBankFrame() end
	end)

	local menuBtn = CreateFrame("Button", "OneBankFrameConfigButton", frame, "UIPanelButtonTemplate")
	menuBtn:SetWidth(60)
	menuBtn:SetHeight(20)
	menuBtn:SetPoint("RIGHT", close, "LEFT", 0, 0)
	menuBtn:SetText("Menu")
	menuBtn:SetScript("OnClick", function()
		if OneBank and OneBank.OpenMenu then OneBank:OpenMenu() end
	end)

	-- Simple money / slot info
	local info = frame:CreateFontString("OneBankFrameInfo1", "OVERLAY", "GameFontNormalSmall")
	info:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 8)
	info:SetJustifyH("LEFT")
	frame.moneyText = info

	-- Bank bag buttons under the frame (main bank + bags 5-10)
	local bagBar = CreateFrame("Frame", "OneBankBagBar", frame)
	bagBar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 4, -4)
	bagBar:SetWidth(280)
	bagBar:SetHeight(36)
	frame.bagBar = bagBar

	-- Do not SetID(-1); use .bagId instead
	local bankBags = {-1, 5, 6, 7, 8, 9, 10}
	for idx, bagId in ipairs(bankBags) do
		local b = CreateFrame("Button", "OneBankBagBarBtn"..idx, bagBar)
		b:SetWidth(34)
		b:SetHeight(34)
		b.bagId = bagId
		if bagId >= 0 then b:SetID(bagId) end
		b:SetPoint("LEFT", bagBar, "LEFT", (idx - 1) * 38, 0)

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

		if bagId == -1 then
			-- Always-visible base so the slot is never blank
			local base = b:CreateTexture(nil, "ARTWORK")
			base:SetWidth(30)
			base:SetHeight(30)
			base:SetPoint("CENTER", b, "CENTER", 0, 0)
			base:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
			base:SetVertexColor(0.75, 0.55, 0.1, 1)
			b.bankBase = base
			-- Try a real icon on top (paths use \\ so Lua stores single \)
			icon:SetTexture("Interface\\Buttons\\Button-Backpack-Up")
			icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
			-- Letter label as a final readable marker
			local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
			fs:SetPoint("CENTER", b, "CENTER", 0, 0)
			fs:SetText("B")
			fs:SetTextColor(1, 0.9, 0.4)
			b.bankLabel = fs
		else
			icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		end

		local hl = b:CreateTexture(nil, "HIGHLIGHT")
		hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
		hl:SetBlendMode("ADD")
		hl:SetAllPoints(b)

		b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
b:SetScript("OnClick", function()
			local bag = this.bagId
			-- Unpurchased bank bag slots: buy like the default bank UI
			if bag >= 5 and bag <= 10 then
				local purchased = 0
				if GetNumBankSlots then
					purchased = GetNumBankSlots() or 0
				end
				local slotIndex = bag - 4
				if slotIndex > purchased then
					if slotIndex == purchased + 1 then
						-- Always ask first — never purchase immediately
						if StaticPopup_Show then
							StaticPopup_Show("ONEBANK_CONFIRM_BUY_BANK_SLOT")
						else
							DEFAULT_CHAT_FRAME:AddMessage("|cffffff00OneBank: confirmation UI missing; bank slot was NOT purchased.|r")
						end
					else
						DEFAULT_CHAT_FRAME:AddMessage("|cffff6666OneBank: buy bank bag slots in order. Next is slot "..(purchased + 1)..".|r")
					end
					return
				end
			end
			if CursorHasItem() then
				if PutItemInBag then PutItemInBag(bag) end
				return
			end
			if OneBank.db and OneBank.db.profile and OneBank.db.profile.show then
				local cur = OneBank.db.profile.show[bag]
				if cur == nil then cur = true end
				OneBank.db.profile.show[bag] = not cur
				OneBank:OrganizeFrame(true)
				if OneBank.RefreshAllBags then
					OneBank:RefreshAllBags()
				else
					for _, id in pairs(OneBank.fBags or {}) do
						OneBank:UpdateBag(id)
					end
				end
			end
		end)
		b:SetScript("OnEnter", function()
			local bag = this.bagId
			if OneBank and OneBank.HighlightBagSlots then
				OneBank:HighlightBagSlots(bag)
			end
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
			if bag == -1 then
				GameTooltip:SetText("Main Bank")
				GameTooltip:AddLine("Click to show/hide main bank slots", 0.7, 0.7, 0.7)
			elseif bag >= 5 and bag <= 10 then
				local purchased = 0
				if GetNumBankSlots then purchased = GetNumBankSlots() or 0 end
				local slotIndex = bag - 4
				if slotIndex > purchased then
					GameTooltip:SetText(BANK_BAG_PURCHASE or "Purchase Bank Slot")
					if slotIndex == purchased + 1 then
						GameTooltip:AddLine("Click to purchase this bank bag slot", 0.7, 0.7, 0.7)
						local cost = (GetBankSlotCost and GetBankSlotCost(purchased)) or 0
						if cost > 0 then
							local gold = math.floor(cost / 10000)
							local sil = math.floor((cost - gold * 10000) / 100)
							local cop = math.mod(cost, 100)
							GameTooltip:AddLine("Cost: "..gold.."g "..sil.."s "..cop.."c", 1, 1, 1)
						end
					else
						GameTooltip:AddLine("Purchase earlier bank slots first", 1, 0.3, 0.3)
					end
				else
					local inv = ContainerIDToInventoryID and ContainerIDToInventoryID(bag)
					if not inv or not GameTooltip:SetInventoryItem("player", inv) then
						GameTooltip:SetText("Bank Bag "..slotIndex)
					end
					GameTooltip:AddLine("Click to show/hide this bag in OneBank", 0.7, 0.7, 0.7)
				end
			end
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function()
			local bag = this.bagId
			if OneBank and OneBank.UnhighlightBagSlots then
				OneBank:UnhighlightBagSlots(bag)
			end
			GameTooltip:Hide()
		end)
		b:SetScript("OnUpdate", function()
			local bag = this.bagId
			local purchased = 0
			if GetNumBankSlots then purchased = GetNumBankSlots() or 0 end
			if bag ~= -1 then
				local slotIndex = bag - 4
				local tex
				if slotIndex <= purchased and ContainerIDToInventoryID then
					tex = GetInventoryItemTexture("player", ContainerIDToInventoryID(bag))
				end
				if this.icon then
					this.icon:SetTexture(tex or "Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")
					if slotIndex > purchased then
						this.icon:SetVertexColor(1, 0.1, 0.1)
					else
						local dim = 1
						if OneBank and OneBank.db and OneBank.db.profile and OneBank.db.profile.show then
							local shown = OneBank.db.profile.show[bag]
							if shown == nil then shown = true end
							if not shown then dim = 0.4 end
						end
						this.icon:SetVertexColor(dim, dim, dim)
					end
				end
			else
				local dim = 1
				if OneBank and OneBank.db and OneBank.db.profile and OneBank.db.profile.show then
					local shown = OneBank.db.profile.show[bag]
					if shown == nil then shown = true end
					if not shown then dim = 0.4 end
				end
				if this.icon then this.icon:SetVertexColor(dim, dim, dim) end
				if this.bankBase then this.bankBase:SetVertexColor(0.75 * dim, 0.55 * dim, 0.1 * dim, 1) end
				if this.bankLabel then this.bankLabel:SetTextColor(1 * dim, 0.9 * dim, 0.4 * dim) end
			end
		end)
	end

		self.frame = frame
	self.frame.handler = self
	self.frame.bags = {}
	self.frame.bagFrame = nil
end

function OneBank:OnInitialize()
	local baseArgs = OneCore:GetFreshOptionsTable(self)

	local customArgs = {
		["5"] = {
			name = L"First Bag", type = 'toggle', order = 5,
			desc = L"Turns display of your first bag on and off.",
			get = function() return self.db.profile.show[5] end,
			set = function(v)
				self.db.profile.show[5] = v
				self:OrganizeFrame(true)
			end,
		},
		["6"] = {
			name = L"Second Bag", type = 'toggle', order = 6,
			desc = L"Turns display of your second bag on and off.",
			get = function() return self.db.profile.show[6] end,
			set = function(v)
				self.db.profile.show[6] = v
				self:OrganizeFrame(true)
			end,
		},
		["7"] = {
			name = L"Third Bag", type = 'toggle', order = 7,
			desc = L"Turns display of your third bag on and off.",
			get = function() return self.db.profile.show[7] end,
			set = function(v)
				self.db.profile.show[7] = v
				self:OrganizeFrame(true)
			end,
		},
		["8"] = {
			name = L"Fourth Bag", type = 'toggle', order = 8,
			desc = L"Turns display of your fourth bag on and off.",
			get = function() return self.db.profile.show[8] end,
			set = function(v)
				self.db.profile.show[8] = v
				self:OrganizeFrame(true)
			end,
		},
		["9"] = {
			name = L"Fifth Bag", type = 'toggle', order = 9,
			desc = L"Turns display of your fifth bag on and off.",
			get = function() return self.db.profile.show[9] end,
			set = function(v)
				self.db.profile.show[9] = v
				self:OrganizeFrame(true)
			end,
		},
		["10"] = {
			name = L"Sixth Bag", type = 'toggle', order = 10,
			desc = L"Turns display of your sixth bag on and off.",
			get = function() return self.db.profile.show[10] end,
			set = function(v)
				self.db.profile.show[10] = v
				self:OrganizeFrame(true)
			end,
		},
	}

	OneCore:CopyTable(customArgs, baseArgs.args.show.args)
	OneCore:LoadOptionalCommands(baseArgs, self)

	self:RegisterDB("OneBankDB")
	self:RegisterDefaults('profile', OneCore.defaults)
	self:RegisterChatCommand({"/obb", "/OneBank"}, baseArgs, string.upper(self.title))

	self.fBags = {-1, 5, 6, 7, 8, 9, 10}
	self.rBags = {10, 9, 8, 7, 6, 5, -1}
	self.lastCounts = {}
	self.isBank = true

	SetupBankFrame(self)

	-- If XML somehow created a frame, prefer our pure Lua one if XML failed
	if not self.frame then
		self.frame = getglobal("OneBankFrame")
	end

	if self.frame then
		self.frame.handler = self
		if not self.frame.bags then self.frame.bags = {} end
	end
end

function OneBank:OnEnable()
	-- Ensure we never reuse a stale shared options UI
	self.optionsFrame = nil
	if not self.frame then
		SetupBankFrame(self)
	end
	if not self.frame then return end

	self.frame:SetClampedToScreen(true)

	self:RegisterEvent("BAG_UPDATE", function()
		if arg1 and (arg1 == -1 or (arg1 >= 5 and arg1 <= 10)) then
			self:UpdateBag(arg1)
		end
	end)
	self:RegisterEvent("BAG_UPDATE_COOLDOWN", function()
		if arg1 and (arg1 == -1 or (arg1 >= 5 and arg1 <= 10)) then
			self:UpdateBag(arg1)
		end
	end)

	self:RegisterEvent("BANKFRAME_OPENED", function()
		-- Hide default Blizzard bank
		if BankFrame then BankFrame:Hide() end
		for i = 1, 12 do
			local f = getglobal("ContainerFrame"..i)
			if f then f:Hide() end
		end
		if not self.frame then SetupBankFrame(self) end
		if self.ApplyLayoutMetrics then self:ApplyLayoutMetrics() end
		if self.frame then
			self:BuildFrame()
			self:OrganizeFrame(true)
			for _, bag in pairs(self.fBags) do
				self:UpdateBag(bag)
			end
			self.frame:Show()
		end
	end)

	self:RegisterEvent("BANKFRAME_CLOSED", function()
		if self.frame then self.frame:Hide() end
	end)

	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED", function()
		if self.frame and self.frame.bags and self.frame.bags[-1] and not self.frame.bags[-1].colorLocked then
			for k, v in ipairs(self.frame.bags[-1]) do
				self:SetBorderColor(v)
			end
		end
		self:UpdateBag(-1)
	end)

	if CT_oldPurchaseSlot then PurchaseSlot = CT_oldPurchaseSlot end
	if PurchaseSlot then
		self:Hook("PurchaseSlot", function()
			self.hooks.PurchaseSlot.orig()
			self.bagPurchased = true
		end)
	end

	self:BuildFrame()
end

function OneBank:OnUpdate()
	local total, bagChanged = 0, false

	for i, k in pairs(self.fBags) do
		local count = GetContainerNumSlots(k) or 0
		if self.lastCounts[k] ~= count then
			self.lastCounts[k] = count
			bagChanged = true
		end
		total = total + count
	end

	if self.lastCount ~= total or bagChanged then
		self:BuildFrame()
		self:OrganizeFrame(true)
		self:DoSlotCounts()
		self.lastCount = total
	end
end

function OneBank:StartOnUpdate()
	if self.ScheduleRepeatingEvent then
		self:ScheduleRepeatingEvent(self.title, self.OnUpdate, 0.25, self)
	end
	self:UpdateBag(-1)
end

function OneBank:StopOnUpdate()
	if self.CancelScheduledEvent then
		self:CancelScheduledEvent(self.title)
	end
end

function OneBank:UpdateBagSlotStatus()
	-- Purchase UI optional; skip if XML frames missing
	return
end

function OneBank:OnCustomShow()
	local f = self.frame
	if not f then return end

	local point = self.db and self.db.profile and self.db.profile.point
	if point and point.left and point.top then
		f:ClearAllPoints()
		f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", point.left, point.top)
	else
		f:ClearAllPoints()
		if OneBag and OneBag.frame and OneBag.frame:IsVisible() then
			f:SetPoint("BOTTOMLEFT", OneBag.frame, "TOPLEFT", 0, 25)
		else
			f:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
		end
	end

	-- Hide default bank UI while ours is open
	if BankFrame then BankFrame:Hide() end

	self:StartOnUpdate()
	self:BuildFrame()
	self:OrganizeFrame(true)
	for _, bag in pairs(self.fBags) do
		self:UpdateBag(bag)
	end
	-- Bag bar visibility
	if self.frame and self.frame.bagBar then
		local showBar = true
		if self.db and self.db.profile and self.db.profile.show and self.db.profile.show.bagBar == false then
			showBar = false
		end
		if showBar then self.frame.bagBar:Show() else self.frame.bagBar:Hide() end
	end
end

function OneBank:OnCustomHide()
	if CloseBankFrame then CloseBankFrame() end
	self:StopOnUpdate()
end
