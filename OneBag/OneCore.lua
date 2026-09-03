--$Id: OneCore.lua 8409 2006-08-19 02:27:30Z kaelten $
OneCore = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceModuleCore-2.0", "AceHook-2.0")

local L = AceLibrary("AceLocale-2.0"):new("OneBag")

function OneCore:OnInitialize()
	self:Hook("BankFrame_OnEvent", function(event) 
		LoadAddOn("OneBank")
		local module = self:HasModule("OneBank") and self:GetModule("OneBank")
		if module and module:IsActive() then
			-- OneBank handles the bank UI; suppress default BankFrame
			if event == "BANKFRAME_OPENED" then
				if BankFrame then BankFrame:Hide() end
				if module.frame then module.frame:Show() end
			elseif event == "BANKFRAME_CLOSED" then
				if module.frame then module.frame:Hide() end
			end
			return
		end
		self.hooks.BankFrame_OnEvent.orig(event)
	end)
    
    self.defaults = {
		cols = 10,
		scale = 1,
		alpha = 1,
		colors = {
			mouseover 	= {r = 0, g = .7, b = 1},
			ammo 		= {r = 1, g = 1, b = 0},
			soul 		= {r = .5, g = .5, b = 1}, 
			prof 		= {r = 1, g = 0, b = 1},
            bground     = {r = 0, g = 0, b = 0, a = .45},
            glow        = false,
			rarity 		= false,
		},
		show = {
			['*'] = true,
			bagBar = true,
		},
		strata = 2,
        locked = false,
        clamped = true,
        bagBreak = false,
        vAlign = L"Top",
		point = false,
		compactSlots = false,
		padding = 2,
		optionsScale = 0.85,
		bagTypes = {
			[1] = "auto",
			[2] = "auto",
			[3] = "auto",
			[4] = "auto",
		},
	}
    
    
    self.modulePrototype.colWidth  		= 39
    self.modulePrototype.rowHeight 		= 39
    self.modulePrototype.topBorder 		= 40
    self.modulePrototype.bottomBorder 	= 28
    self.modulePrototype.rightBorder    = 8
    self.modulePrototype.leftBorder     = 8 
    
    self.modulePrototype.stratas = {
        "LOW",
        "MEDIUM",
        "HIGH",
        "DIALOG",
        "FULLSCREEN",
        "FULLSCREEN_DIALOG",
        "TOOLTIP",
    }

end

function OneCore:GetFreshOptionsTable(module)
    local self = module
    return {
		type="group", 
		args = {
            frame = {
				name = L"Frame", type = 'group',
				desc = L"Frame Options", order = 2,
				args = {
                    cols = { 
                        name = L"Columns", type = "range", step = 1,
                        desc = L"Sets the number of columns to use", 
                        get  = function() return self.db.profile.cols end, 
                        set  = function(num) 
                            self.db.profile.cols = num
                            self:OrganizeFrame(true)
                        end, 
                        min  = 5, max  = 20,
                    },
                    scale = { 
                        name = L"Scale", type = "range", 
                        desc = L"Sets the scale of the frame", 
                        get  = function() return self.db.profile.scale end, 
                        set  = function(num) 
                            self.db.profile.scale = num
                            self.frame:SetScale(num)
                            if self.frame.bagFrame then
                                self.frame.bagFrame:SetScale(num)
                                if KEYRING_CONTAINER and not self.isBank then
                                    local shownContainerID = IsBagOpen(KEYRING_CONTAINER)
                                    if shownContainerID then
                                        local frame = getglobal("ContainerFrame"..shownContainerID)
                                        if frame then frame:SetScale(num) end
                                    end
                                end
                            end
                        end, 
                        min  = .2, max  = 2,
                        isPercent = true,
                    },
                    strata = { 
                        name = L"Strata", type = "range", 
                        desc = L"Sets the strata of the frame", 
                        get  = function() return self.db.profile.strata end, 
                        set  = function(num) 
                            self.db.profile.strata = num
                            self.frame:SetFrameStrata(self.stratas[num])
                            if self.frame.bagFrame then
                                self.frame.bagFrame:SetFrameStrata(self.stratas[num])
                            end
                            StackSplitFrame:SetFrameStrata(self.stratas[num+1])
                        end, 
                        min  = 1, max  = 5, step = 1,
                    },
                    bagbreak = { 
                        name = L"Bag Break", type = "toggle",
                        desc = L"Sets wether to start a new row at the beginning of a bag.", 
                        get  = function() return self.db.profile.bagBreak end, 
                        set  = function(value) 
                            self.db.profile.bagBreak = value
                            self:OrganizeFrame(true)
                        end, 
                    },
                    valign = { 
                        name = L"Vertical Alignment", type = "text",
                        desc = L"Sets wether to have the extra spaces on the top or bottom.", 
                        get  = function() return self.db.profile.vAlign end, 
                        set  = function(value) 
                            self.db.profile.vAlign = value
                            self:OrganizeFrame(true)
                        end,
                        validate = {L"Top", L"Bottom"}
                    },
                    alpha = { 
                        name = L"Alpha", type = "range", 
                        desc = L"Sets the alpha of the frame", 
                        get  = function() return self.db.profile.alpha end, 
                        set  = function(num) 
                            self.db.profile.alpha = num
                            self.frame:SetAlpha(num)
                            if self.frame.bagFrame then
                                self.frame.bagFrame:SetAlpha(num)
                                if KEYRING_CONTAINER and not self.isBank then
                                    local shownContainerID = IsBagOpen(KEYRING_CONTAINER)
                                    if shownContainerID then
                                        local frame = getglobal("ContainerFrame"..shownContainerID)
                                        if frame then frame:SetAlpha(num) end
                                    end
                                end
                            end
                        end, 
                        min  = .05, max  = 1,
                        isPercent = true,
                    },
                    locked = {
                        name = L"Locked", 
                        type = 'toggle',
                        desc = L"Toggles the ability to move the frame",
                        get = function() return self.db.profile.locked end,
                        set = function(v) 
                            self.db.profile.locked = v 
                        end,
                    },
                    clamped = {
                        name = L"Clamped",
                        type = 'toggle',
                        desc = L"Toggles the ability to drag the frame off screen.",
                        get = function() return self.db.profile.clamped end,
                        set = function(v) 
                            self.db.profile.clamped = v 
                            self.frame:SetClampedToScreen(v)
                            if self.frame.bagFrame then
                                self.frame.bagFrame:SetClampedToScreen(v)
                            end
                        end,
                    }, 
                }
            },
			show = {
				name = L"Show", type = 'group', order = 3,
				desc = L"Various Display Options",
				args = {
                     counts = {
						name = L"Counts",
                        type = 'toggle', order = 1,
						desc = L"Toggles showing the counts for special bags.",
						get = function() return self.db.profile.show.counts end,
						set = function(v) 
							self.db.profile.show.counts = v 
                            if self.DoBankSlotCounts then
                                self:DoBankSlotCounts()
                                self:DoInventorySlotCounts()
                            else
                                self:DoSlotCounts()
                            end
						end,
					},
                    direction = {
						cmdName = L"Direction", guiName = L"Forward",
                        type = 'toggle', order = 2,
						desc = L"Toggles direction the bags are shown",
						get = function() return self.db.profile.show.direction end,
						set = function(v) 
							self.db.profile.show.direction = v 
							self:OrganizeFrame(true)
						end,
                        map = { [false] = L"|cffff0000Reverse|r", [true] = L"|cff00ff00Forward|r" }
					},
                    ammo = {
						name = L"Ammo Bag", type = 'toggle', order = 3,
						desc = L"Turns display of ammo bags on and off.",
						get = function() return self.db.profile.show.ammo end,
						set = function(v) 
							self.db.profile.show.ammo = v 
							self:OrganizeFrame(true)
						end,
					},
					soul = {
						name = L"Soul Bag", type = 'toggle', order = 4,
						desc = L"Turns display of soul bags on and off.",
						get = function() return self.db.profile.show.soul end,
						set = function(v) 
							self.db.profile.show.soul = v 
							self:OrganizeFrame(true)
						end,
					},
					prof = {
						name = L"Profession Bag", type = 'toggle', order = 4.5,
						desc = L"Turns display of profession bags on and off.",
						get = function() return self.db.profile.show.prof end,
						set = function(v) 
							self.db.profile.show.prof = v 
							self:OrganizeFrame(true)
						end,
					},
				}
			},
			colors = {
				name = L"Colors", type = 'group', order = 1,
				desc = L"Different color code settings.",
				args = {
					mouseover = {
						name = L"Mouseover Color", type = "color", order = 1,
						desc = L"Changes the highlight color for when you mouseover a bag slot.",
						get = function()
							local color = self.db.profile.colors.mouseover
							return color.r, color.g, color.b
						end,
						set = function(r, g, b) self.db.profile.colors.mouseover = {r = r, g = g, b = b} end,
					},
					ammo = {
						name = L"Ammo Bag Color", type = "color", order = 2,
						desc = L"Changes the highlight color for Ammo Bags.",
						get = function() 
							local color = self.db.profile.colors.ammo
							return color.r, color.g, color.b
						end, 
						set = function(r, g, b) 
							self.db.profile.colors.ammo = {r = r, g = g, b = b} 
							for k, bag in pairs(self.fBags) do
                                if self.frame.bags[bag] then
                                    for k, v in ipairs(self.frame.bags[bag]) do 
                                        self:SetBorderColor(v)
                                    end
                                end
							end
						end,
					},
					soul = {
						name = L"Soul Bag Color", type = "color", order = 3,
						desc = L"Changes the highlight color for Soul Bags.",
						get = function()
							local color = self.db.profile.colors.soul
							return color.r, color.g, color.b
						end,
						set = function(r, g, b) 
							self.db.profile.colors.soul = {r = r, g = g, b = b} 
							for k, bag in pairs(self.fBags) do
                                if self.frame.bags[bag] then
                                    for k, v in ipairs(self.frame.bags[bag]) do 
                                        self:SetBorderColor(v)
                                    end
                                end
							end
						end,
					},
					prof = {
						name = L"Profession Bag Color", type = "color", order = 4,
						desc = L"Changes the highlight color for Profession Bags.",
						get = function()
							local color = self.db.profile.colors.prof
							return color.r, color.g, color.b
						end,
						set = function(r, g, b) 
							self.db.profile.colors.prof = {r = r, g = g, b = b} 
							for k, bag in pairs(self.fBags) do
                                if self.frame.bags[bag] then
                                    for k, v in ipairs(self.frame.bags[bag]) do 
                                        self:SetBorderColor(v)
                                    end
                                end
							end
						end,
					},
                    background = {
						name = L"Background Color", type = "color", order = 5,
						desc = L"Changes the background color for the frame.",
						get = function()
							local color = self.db.profile.colors.bground
							return color.r, color.g, color.b, color.a
						end,
						set = function(r, g, b, a) 
							self.db.profile.colors.bground = {r = r, g = g, b = b, a = a} 
							self.frame:SetBackdropColor(r, g, b, a)
                            if self.frame.bagFrame then
                                self.frame.bagFrame:SetBackdropColor(r, g, b, a)
                            end
						end,
                        hasAlpha = true,
					},
                    glow = {
						name = L"Highlight Glow", type = 'toggle', order = 6,
						desc = L"Turns hightlight glow on and off.",
						get = function() return self.db.profile.colors.glow end,
						set = function(v) 
							self.db.profile.colors.glow = v 
                            for k, bag in pairs(self.fBags) do
								if self.frame.bags[bag] then
									for k, v in ipairs(self.frame.bags[bag]) do 
										self:SetBorderColor(v)
									end
								end
							end
						end,
                    },
					rarity = {
						name = L"Rarity Coloring", type = 'toggle', order = 7,
						desc = L"Turns rarity coloring on and off.",
						get = function() return self.db.profile.colors.rarity end,
						set = function(v) 
							self.db.profile.colors.rarity = v 
							for k, bag in pairs(self.fBags) do
								if self.frame.bags[bag] then
									for k, v in ipairs(self.frame.bags[bag]) do 
										self:SetBorderColor(v)
									end
								end
							end
						end,
                    },
                    reset = {
                        name = L'Reset', type = 'group', order = -1,
                        desc = L"Reset the different colors.",
                        args = {
                            mouseover = {
                                name = L"Mouseover Color", type = "execute",
                                desc = L"Returns your mouseover color to the default.",
                                func = function() 
                                    self.db.profile.colors.mouseover = {r = 0, g = .7, b = 1}
                                end,
                                order = 1
                            },
                            ammo = {
                                name = L"Ammo Slot Color", type = "execute",
                                desc = L"Returns your ammo slot color to the default.",
                                func = function() 
                                    self.db.profile.colors.ammo = {r = 1, g = 1, b = 0}
                                    for k, bag in pairs(self.fBags) do
                                        if self.frame.bags[bag] then
                                            for k, v in ipairs(self.frame.bags[bag]) do 
                                                self:SetBorderColor(v)
                                            end
                                        end
                                    end
                                end,
                                order = 2
                            },
                            soul = {
                                name = L"Soul Slot Color", type = "execute",
                                desc = L"Returns your soul slot color to the default.",
                                func = function() 
                                    self.db.profile.colors.soul = {r = .5, g = .5, b = 1}
                                    for k, bag in pairs(self.fBags) do
                                        if self.frame.bags[bag] then
                                            for k, v in ipairs(self.frame.bags[bag]) do 
                                                self:SetBorderColor(v)
                                            end
                                        end
                                    end
                                end,
                                order = 3
                            },
                            prof = {
                                name = L"Profession Slot Color", type = "execute",
                                desc = L"Returns your profession slot color to the default.",
                                func = function() 
                                    self.db.profile.colors.prof = {r = 1, g = 0, b = 1}
                                    for k, bag in pairs(self.fBags) do
                                        if self.frame.bags[bag] then
                                            for k, v in ipairs(self.frame.bags[bag]) do 
                                                self:SetBorderColor(v)
                                            end
                                        end
                                    end
                                end,
                                order = 4
                            },
                            background = {
                                name = L"Background", type = "execute",
                                desc = L"Returns your frame background to the default.",
                                func = function() 
                                    self.db.profile.colors.bground = {r = 0, g = 0, b = 0, a = .45}  
                                    self.frame:SetBackdropColor(0, 0, 0, .45)
                                    if self.frame.bagFrame then
                                        self.frame.bagFrame:SetBackdropColor(0, 0, 0, .45)
                                    end
                                end,
                                order = 5
                            }
                        }
					}
				}
			}
		}
	}   
end

function OneCore:LoadOptionalCommands(baseArgs, module)
    local self = module
    if IsAddOnLoaded("MrPlow") then
        baseArgs.args.plow = {
			name = L"Plow!", type = "execute",
			desc = L"Organizes your bags.",
			func = function() self:MrPlow() end,
            order = -5,
            notes = L"- Note: This option only appears if you have MrPlow installed"
		}
	end
end

function OneCore:CopyTable(from, into)
    if type(into) ~= "table" then into = {} end
    
	for key, val in from do
		if( type(val) == "table" ) then
			into[key] = self:CopyTable(val)
		else
			into[key] = val
		end
	end
	
	if (getn(from)) then
		table.setn(into, getn(from))		
	end

	return into
end

local module = OneCore.modulePrototype

function module:BuildFrame()
	debugprofilestart()
	-- Ensure layout metrics exist before creating/sizing buttons (fixes first-open overflow)
	if not self.btnSize then
		self:ApplyLayoutMetrics()
	end
	if self.isBank then
		local bankId = BANK_CONTAINER or -1
		if not self.frame.bags[bankId] then 
			self.frame.bags[bankId] = CreateFrame("Frame", "BBankFrame", self.frame)
			self.frame.bags[bankId]:SetID(bankId)
			self.frame.bags[bankId].size = 24
			for slot = 1, 24 do
				local tmpl = "ContainerFrameItemButtonTemplate"
				if getglobal("OneBankItemButtonTemplate") then
					tmpl = "OneBankItemButtonTemplate"
				elseif getglobal("BankItemButtonGenericTemplate") then
					tmpl = "BankItemButtonGenericTemplate"
				end
				local btn = CreateFrame("Button", self.frame.bags[bankId]:GetName().."Item"..slot, self.frame.bags[bankId], tmpl)
				btn:SetID(slot)
				local sz = self.btnSize or 37
				btn:SetWidth(sz)
				btn:SetHeight(sz)
				btn:SetNormalTexture("")
				local nt = btn:GetNormalTexture()
				if nt then nt:Hide() end
				local fill = btn:CreateTexture(nil, "BACKGROUND")
				fill:SetTexture("Interface\ChatFrame\ChatFrameBackground")
				fill:SetVertexColor(0.05, 0.05, 0.05, 0.85)
				fill:SetAllPoints(btn)
				btn.obSlotFill = fill
				local bg = btn:CreateTexture(nil, "BORDER")
				bg:SetTexture("Interface\Buttons\UI-Quickslot2")
				local bgSize = sz * (64 / 37)
				bg:SetWidth(bgSize)
				bg:SetHeight(bgSize)
				bg:SetPoint("CENTER", btn, "CENTER", 0, 0)
				btn.obSlotBg = bg
				local icon = getglobal(btn:GetName().."IconTexture")
				if icon then
					local iw = sz * (32 / 37)
					icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
					icon:SetWidth(iw)
					icon:SetHeight(iw)
					icon:ClearAllPoints()
					icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
				end
				self.frame.bags[bankId][slot] = btn
			end
			self.needToOrganize = true
		end
	end
	
	for k, bag in pairs(self.fBags) do		
		local size = GetContainerNumSlots(bag) or 0
		-- Main bank is always 24 slots while at the banker; never let it collapse to 0
		if self.isBank and bag == (BANK_CONTAINER or -1) then
			if size < 24 then size = 24 end
		end
		for slot = 1, size do
			if not self.frame.bags[bag] then 
				self.frame.bags[bag] = CreateFrame("Frame", tostring(self)..bag, self.frame)
				self.frame.bags[bag]:SetID(bag)
			end
			if not self.frame.bags[bag][slot] then
				local tmpl = "OneBagItemButtonTemplate"
				-- Fall back if custom XML template failed to load (common on Emberveil)
				if not getglobal("OneBagItemButtonTemplate") then
					tmpl = "ContainerFrameItemButtonTemplate"
				end
				local btn = CreateFrame("Button", tostring(self)..bag.."Item"..slot, self.frame.bags[bag], tmpl)
				btn:SetID(slot)
				local sz = self.btnSize or 37
				btn:SetWidth(sz)
				btn:SetHeight(sz)
				-- Kill the template NormalTexture that draws the center square on Emberveil
				btn:SetNormalTexture("")
				local nt = btn:GetNormalTexture()
				if nt then
					nt:SetTexture(nil)
					nt:Hide()
				end
				-- Dark fill so empty slots are visible on the bag background
				local fill = btn:CreateTexture(nil, "BACKGROUND")
				fill:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
				fill:SetVertexColor(0.05, 0.05, 0.05, 0.85)
				fill:SetAllPoints(btn)
				btn.obSlotFill = fill
				-- Border outline (sized to current scale)
				local bg = btn:CreateTexture(nil, "BORDER")
				bg:SetTexture("Interface\\Buttons\\UI-Quickslot2")
				local bgSize = sz * (64 / 37)
				bg:SetWidth(bgSize)
				bg:SetHeight(bgSize)
				bg:SetPoint("CENTER", btn, "CENTER", 0, 0)
				btn.obSlotBg = bg
				local icon = getglobal(btn:GetName().."IconTexture")
				if icon then
					local iw = sz * (32 / 37)
					icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
					icon:SetWidth(iw)
					icon:SetHeight(iw)
					icon:ClearAllPoints()
					icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
				end
				self.frame.bags[bag][slot] = btn
				self.needToOrganize = true
			end
		end
		if self.frame.bags[bag] then
			local curBag = self.frame.bags[bag]
			local isAmmo, isSoul, isProf = self:GetBagTypes(bag)
			if curBag.size ~= size or curBag.isAmmo ~= isAmmo or curBag.isSoul ~= isSoul or curBag.isProf ~= isProf then
				self.needToOrganize = true
			end
			curBag.size, curBag.isAmmo, curBag.isSoul, curBag.isProf = size, isAmmo, isSoul, isProf
		end
	end
	self:Debug(L"%s ran in %s", "BuildFrame", debugprofilestop())
end

function module:OrganizeFrame(needs)
	debugprofilestart()
	if not self.needToOrganize and not needs then return end
	self.needToOrganize = false
	
	local cols, curCol, curRow, justinc = self.db.profile.cols, 1, 1, false
	
	self.soulSlots, self.ammoSlots, self.profSlots, self.slotCount, self.totalCount = 0, 0, 0, 0, 0
	
	for k, bag in pairs(self.fBags) do 
		if self.frame.bags[bag] then
			for k2, v2 in ipairs(self.frame.bags[bag]) do 
				v2:Hide()
			end
            self.totalCount = self.totalCount + (self.frame.bags[bag].size or 0)
        end
	end
	
    if self.db.profile.vAlign == L"Bottom" then
        curCol = math.mod(self.totalCount, cols) > 0 and cols - math.mod(self.totalCount, cols) + 1 or 1
        if self.db.profile.bagBreak then
            for k, bag in pairs(self.fBags) do 
                if self.frame.bags[bag] and self.frame.bags[bag].size then curCol = curCol - 1 end
            end
            curCol = curCol + 1
        end
    end
    
    
	for k, bag in pairs(self.db.profile.show.direction and self.fBags or self.rBags) do
		local curBag = self.frame.bags[bag]
        
		if curBag and curBag.size and curBag.size > 0 then
            if bag > 0 and math.mod(self.frame.bags[bag-1] and self.frame.bags[bag-1].size or 0, cols) ~= 0 and self.db.profile.bagBreak then 
                curCol = curCol + 1
                if curCol > cols then curCol, curRow, justinc = 1, curRow + 1, true  end
            end
			if curBag.isAmmo then
				self.ammoSlots = self.ammoSlots + curBag.size
			elseif curBag.isSoul then
				self.soulSlots = self.soulSlots + curBag.size
			elseif curBag.isProf then
				self.profSlots = self.profSlots + curBag.size
			else
				self.slotCount = self.slotCount + curBag.size
			end
			if self:ShouldShow(bag, curBag.isAmmo, curBag.isSoul, curBag.isProf) then
				for slot = 1, curBag.size do
                    justinc = false
					curBag[slot]:ClearAllPoints()
					-- curRow starts at 1; use (curRow-1) so the first row sits under the title bar
					curBag[slot]:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.leftBorder + (self.colWidth * (curCol - 1)), 0 - self.topBorder - (self.rowHeight * (curRow - 1)))
					local sz = self.btnSize or 37
					curBag[slot]:SetWidth(sz)
					curBag[slot]:SetHeight(sz)
					curBag[slot]:Show()
					curCol = curCol + 1
					if curCol > cols then curCol, curRow, justinc = 1, curRow + 1, true end
				end
			end
		end
	end
	self:Debug("CurrentRow: %s", curRow)
	
	if  not justinc then curRow = curRow + 1 end
	self.frame:SetHeight(curRow * self.rowHeight + self.bottomBorder + self.topBorder) 
	self.frame:SetWidth(cols * self.colWidth + self.leftBorder + self.rightBorder)
	
	self:Debug(L"%s ran in %s", "OrganizeFrame", debugprofilestop())
	
end

function module:SetBorderColor(slot)
	if not slot then return end
	local bag = slot:GetParent()
	if not bag then return end

	-- Size edges to the button (slightly inset so they never stick outside)
	local bw = slot:GetWidth() or self.btnSize or 37
	local bh = slot:GetHeight() or self.btnSize or 37
	if bw < 4 then bw = self.btnSize or 37 end
	if bh < 4 then bh = self.btnSize or 37 end
	local edgeThick = 2
	local inset = 1
	local ew = bw - (inset * 2)
	local eh = bh - (inset * 2)
	if ew < 4 then ew = bw end
	if eh < 4 then eh = bh end

	if not slot.obEdges then
		slot.obEdges = {}
		local function edge(point, w, h)
			local t = slot:CreateTexture(nil, "OVERLAY")
			t:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
			t:SetWidth(w)
			t:SetHeight(h)
			t:SetPoint(point, slot, point, 0, 0)
			t:Hide()
			return t
		end
		slot.obEdges.top = edge("TOP", ew, edgeThick)
		slot.obEdges.bottom = edge("BOTTOM", ew, edgeThick)
		slot.obEdges.left = edge("LEFT", edgeThick, eh)
		slot.obEdges.right = edge("RIGHT", edgeThick, eh)
	else
		if slot.obEdges.top then slot.obEdges.top:SetWidth(ew) end
		if slot.obEdges.bottom then slot.obEdges.bottom:SetWidth(ew) end
		if slot.obEdges.left then slot.obEdges.left:SetHeight(eh) end
		if slot.obEdges.right then slot.obEdges.right:SetHeight(eh) end
	end

	local color = nil
	if bag.isAmmo and self.db.profile.colors.ammo then
		color = self.db.profile.colors.ammo
	elseif bag.isSoul and self.db.profile.colors.soul then
		color = self.db.profile.colors.soul
	elseif bag.isProf and self.db.profile.colors.prof then
		color = self.db.profile.colors.prof
	elseif self.db.profile.colors.rarity then
		local link = GetContainerItemLink(bag:GetID(), slot:GetID())
		local _, _, hex = strfind(link or "", "(|cff%x%x%x%x%x%x)")
		if hex and ITEM_QUALITY_COLORS then
			for k, v in ipairs(ITEM_QUALITY_COLORS) do
				if hex == v.hex and k > 1 then
					color = v
					break
				end
			end
		end
	end

	if slot.obSlotFill then
		slot.obSlotFill:SetVertexColor(0.05, 0.05, 0.05, 0.85)
	end
	if slot.obColorBorder then
		slot.obColorBorder:Hide()
	end

	if color then
		local r, g, b = color.r or 1, color.g or 1, color.b or 1
		for _, e in pairs(slot.obEdges) do
			e:SetVertexColor(r, g, b)
			e:SetAlpha(1)
			e:Show()
		end
	else
		for _, e in pairs(slot.obEdges) do
			e:Hide()
		end
	end
end

function module:GetBagTypes(bag)
	if bag <= 0 then return end

	-- Manual override (needed on Emberveil when bag item info is unavailable)
	local override = self.db and self.db.profile and self.db.profile.bagTypes and self.db.profile.bagTypes[bag]
	if override == "ammo" then return true, false, false end
	if override == "soul" then return false, true, false end
	if override == "prof" then return false, false, true end
	if override == "normal" then return false, false, false end

	-- Bags 1-4 are inventory slots 20-23 on 1.12
	local inv = (ContainerIDToInventoryID and ContainerIDToInventoryID(bag)) or (bag + 19)
	local link = GetInventoryItemLink("player", inv)
	if not link then return end
	local _, _, id = strfind(link, "item:(%d+)")
	if not id then return end

	local name, _, _, _, itemType, subType = GetItemInfo(tonumber(id) or id)
	local t = string.lower(tostring(itemType or ""))
	local s = string.lower(tostring(subType or ""))
	local n = string.lower(tostring(name or ""))

	local isAmmo = (t == "quiver")
		or string.find(t, "quiver", 1, true)
		or string.find(s, "quiver", 1, true)
		or string.find(s, "ammo", 1, true)
		or string.find(n, "quiver", 1, true)
		or string.find(n, "ammo pouch", 1, true)
		or string.find(n, "shot pouch", 1, true)
		or string.find(n, "ammo", 1, true)

	local isSoul = (s == "soul bag")
		or string.find(s, "soul", 1, true)
		or string.find(n, "soul bag", 1, true)
		or string.find(n, "soul pouch", 1, true)

	local isProf = false
	if not isAmmo and not isSoul then
		if t == "container" and s ~= "" and s ~= "bag" then
			isProf = true
		elseif string.find(n, "enchanting", 1, true)
			or string.find(n, "herb", 1, true)
			or string.find(n, "mining", 1, true)
			or string.find(n, "gem", 1, true)
			or string.find(n, "engineering", 1, true)
			or string.find(n, "leatherworking", 1, true) then
			isProf = true
		end
	end

	return isAmmo or false, isSoul or false, isProf or false
end

function module:HighlightBagSlots(bag)
	if not self.frame or not self.frame.bags or not self.frame.bags[bag] then return end
	local color = (self.db and self.db.profile and self.db.profile.colors and self.db.profile.colors.mouseover) or {r=1, g=1, b=0}
	for k, v in ipairs(self.frame.bags[bag]) do
		if v and v.IsVisible and v:IsVisible() then
			if not v.obHighlight then
				local h = v:CreateTexture(nil, "OVERLAY")
				h:SetTexture("Interface\\Buttons\\CheckButtonHilight")
				h:SetBlendMode("ADD")
				h:SetAllPoints(v)
				v.obHighlight = h
			end
			v.obHighlight:SetVertexColor(color.r or 1, color.g or 1, color.b or 0)
			v.obHighlight:Show()
		end
	end
end

function module:UnhighlightBagSlots(bag)
	if not self.frame or not self.frame.bags or not self.frame.bags[bag] then return end
	for k, v in ipairs(self.frame.bags[bag]) do
		if v and v.obHighlight then
			v.obHighlight:Hide()
		end
	end
end

function module:UpdateBag(bag)
	debugprofilestart()
	if not self.frame.bags[bag] then return end
	
	self:BuildFrame()
	self:OrganizeFrame()
	
	if not self.frame.bags[bag].colorLocked then
		for k, v in ipairs(self.frame.bags[bag]) do 
			self:SetBorderColor(v)
		end
	end
	
	if self.frame.bags[bag].size and self.frame.bags[bag].size > 0 then
		ContainerFrame_Update(self.frame.bags[bag])
		local sz = self.btnSize or 37
		local iw = sz * (32 / 37)
		local bgSize = sz * (64 / 37)
		-- Keep outlines; kill the square NormalTexture; force icon size after update
		for slot = 1, self.frame.bags[bag].size do
			local v = self.frame.bags[bag][slot]
			if v then
				v:SetWidth(sz)
				v:SetHeight(sz)
				v:SetNormalTexture("")
				local nt = v:GetNormalTexture()
				if nt then nt:Hide() end
				local icon = getglobal(v:GetName().."IconTexture")
				if icon then
					icon:SetWidth(iw)
					icon:SetHeight(iw)
					icon:ClearAllPoints()
					icon:SetPoint("CENTER", v, "CENTER", 0, 0)
					icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
				end
				if not v.obSlotFill then
					local fill = v:CreateTexture(nil, "BACKGROUND")
					fill:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
					fill:SetVertexColor(0.05, 0.05, 0.05, 0.85)
					fill:SetAllPoints(v)
					v.obSlotFill = fill
				end
				v.obSlotFill:SetAllPoints(v)
				v.obSlotFill:Show()
				if not v.obSlotBg then
					local bg = v:CreateTexture(nil, "BORDER")
					bg:SetTexture("Interface\\Buttons\\UI-Quickslot2")
					bg:SetPoint("CENTER", v, "CENTER", 0, 0)
					v.obSlotBg = bg
				end
				v.obSlotBg:SetWidth(bgSize)
				v.obSlotBg:SetHeight(bgSize)
				v.obSlotBg:Show()
			end
		end
	end
	
	self:DoSlotCounts()
	self:Debug(L"%s ran in %s", "UpdateBag", debugprofilestop())
end

function module:DoSlotCounts()
	local usedSlots, usedAmmoSlots, usedSoulSlots, usedProfSlots, ammoQuantity = 0, 0, 0, 0, 0 
	
	for k, bag in pairs(self.fBags) do
		if self.frame.bags[bag] then
			local tmp, qty = 0, 0
			for slot = 1, GetContainerNumSlots(bag) do
				local texture, itemCount = GetContainerItemInfo(bag, slot);
				if( texture) then 
					tmp = tmp + 1 
					qty = qty + itemCount
				end
			end
			
			if self.frame.bags[bag].isAmmo then
				usedAmmoSlots = usedAmmoSlots + tmp
				ammoQuantity = ammoQuantity + qty
			elseif self.frame.bags[bag].isSoul then
				usedSoulSlots = usedSoulSlots + tmp
			elseif self.frame.bags[bag].isProf then
				usedProfSlots = usedProfSlots + tmp
			else
				usedSlots = usedSlots + tmp
			end
		end
	end
	
	self:Debug(L"Normal used: %s, Soul used: %s, Prof used: %s, Ammo used %s, Ammo quantity %s.", usedSlots, usedSoulSlots, usedProfSlots, usedAmmoSlots, ammoQuantity)
	
	local name = self.frame:GetName() .. "Info"

	-- Single line inside the bag (bottom-left). No text floating outside the frame.
	if not getglobal(name.."1") then
		local fs = self.frame:CreateFontString(name.."1", "OVERLAY", "GameFontNormalSmall")
		fs:SetJustifyH("LEFT")
		fs:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 10, 8)
	end
	for i = 2, 4 do
		local fs = getglobal(name..i)
		if fs then
			fs:SetText("")
			fs:Hide()
		end
	end

	local totalUsed = usedSlots + usedAmmoSlots + usedSoulSlots + usedProfSlots
	local totalSlots = (self.slotCount or 0) + (self.ammoSlots or 0) + (self.soulSlots or 0) + (self.profSlots or 0)
	local text = format("%s/%s Slots", totalUsed, totalSlots)
	if self.ammoSlots and self.ammoSlots > 0 then
		text = text .. format("  %s Ammo", ammoQuantity)
	end
	if self.soulSlots and self.soulSlots > 0 then
		text = text .. format("  %s/%s Soul", usedSoulSlots, self.soulSlots)
	end

	local fs1 = getglobal(name.."1")
	if fs1 then
		fs1:SetText(text)
		fs1:Show()
	end
end

function module:ShouldShow(bag, isAmmo, isSoul, isProf) 
	local show = true
	-- nil means show (AceDB ['*'] can miss numeric key -1 for the bank)
	local bagShow = self.db.profile.show[bag]
	if bagShow == nil then bagShow = true end
	show = show and bagShow

	if isAmmo then
		show = show and (self.db.profile.show.ammo ~= false)
	elseif isSoul then
		show = show and (self.db.profile.show.soul ~= false)
	elseif isProf then
		show = show and (self.db.profile.show.prof ~= false)
	end
	return show or (self.frame.bags[bag] and self.frame.bags[bag].colorLocked)
end

function module:OpenMenu()
	if self.optionsFrame and self.optionsFrame:IsVisible() then
		self.optionsFrame:Hide()
		return
	end
	self:ShowOptionsFrame()
end

function module:ApplyLayoutMetrics()
	-- Scale icons + padding + window together in pixel space (frame SetScale stays 1)
	local scale = (self.db and self.db.profile and self.db.profile.scale) or 1
	local pad = (self.db and self.db.profile and self.db.profile.padding) or 2
	if pad < 0 then pad = 0 end
	if pad > 12 then pad = 12 end
	if self.db and self.db.profile then self.db.profile.padding = pad end

	local base = 37
	self.btnSize = base * scale
	self.colWidth = (base + pad) * scale
	self.rowHeight = (base + pad) * scale
	self.topBorder = 40 * scale
	self.bottomBorder = 28 * scale
	self.leftBorder = 8 * scale
	self.rightBorder = 8 * scale

	if self.frame then
		self.frame:SetScale(1)
		if self.frame.bags then
			-- Iterate this module's bags only (inventory or bank)
			local bagList = self.fBags or {0,1,2,3,4}
			for _, bag in pairs(bagList) do
				local bagFrame = self.frame.bags[bag]
				if bagFrame and bagFrame.size then
					for slot = 1, bagFrame.size do
						local btn = bagFrame[slot]
						if btn and btn.SetWidth then
							btn:SetWidth(self.btnSize)
							btn:SetHeight(self.btnSize)
							local icon = getglobal(btn:GetName().."IconTexture")
							if icon then
								local iw = self.btnSize * (32 / 37)
								icon:SetWidth(iw)
								icon:SetHeight(iw)
								icon:ClearAllPoints()
								icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
							end
							if btn.obEdges then
								if btn.obEdges.top then btn.obEdges.top:SetWidth(self.btnSize) end
								if btn.obEdges.bottom then btn.obEdges.bottom:SetWidth(self.btnSize) end
								if btn.obEdges.left then btn.obEdges.left:SetHeight(self.btnSize) end
								if btn.obEdges.right then btn.obEdges.right:SetHeight(self.btnSize) end
							end
							if btn.obSlotBg then
								local s = self.btnSize * (64 / 37)
								btn.obSlotBg:SetWidth(s)
								btn.obSlotBg:SetHeight(s)
							end
							if btn.obSlotFill then
								btn.obSlotFill:SetAllPoints(btn)
							end
						end
					end
				end
			end
		end
	end
end

function module:RefreshAllBags()
	-- Update every bag this module owns (inventory 0-4 OR bank -1,5-10)
	if not self.fBags then return end
	for _, bag in pairs(self.fBags) do
		self:UpdateBag(bag)
	end
end

function module:ApplyScale(scale)
	self.db.profile.scale = scale
	self:ApplyLayoutMetrics()
	self:OrganizeFrame(true)
	self:RefreshAllBags()
end

function module:ApplySlotSpacing(compact)
	self.db.profile.compactSlots = compact and true or false
	if compact then
		self.db.profile.padding = 0
	end
	self:ApplyPadding(self.db.profile.padding or 2)
end

function module:ApplyPadding(pad)
	pad = tonumber(pad) or 2
	if pad < 0 then pad = 0 end
	if pad > 12 then pad = 12 end
	self.db.profile.padding = pad
	self:ApplyLayoutMetrics()
	self:OrganizeFrame(true)
	self:RefreshAllBags()
end

function module:OpenColorPicker(colorKey, opacity)
	local c = self.db.profile.colors[colorKey]
	if not c then return end
	local sm = self
	if self.optionsFrame then self.optionsFrame:Hide() end

	-- Clickable color wheel / palette (Emberveil can't use Blizzard ColorPicker)
	if self.colorFrame then
		self.colorFrame:Hide()
		self.colorFrame = nil
	end

	local f = CreateFrame("Frame", "OneBagColorFrame", UIParent)
	f:SetWidth(300)
	f:SetHeight(340)
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetMovable(true)
	f:EnableMouse(true)
	f:SetClampedToScreen(true)
	f:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 }
	})
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function() this:StartMoving() end)
	f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
	tinsert(UISpecialFrames, "OneBagColorFrame")

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOP", f, "TOP", 0, -14)
	title:SetText("Click a color")
	f.title = title

	local preview = f:CreateTexture(nil, "ARTWORK")
	preview:SetWidth(36)
	preview:SetHeight(36)
	preview:SetPoint("TOP", f, "TOP", 0, -36)
	preview:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	preview:SetVertexColor(c.r or 1, c.g or 1, c.b or 1)
	f.preview = preview

	local function applyColor(r, g, b)
		preview:SetVertexColor(r, g, b)
		if sm.db.profile.colors[colorKey] then
			sm.db.profile.colors[colorKey].r = r
			sm.db.profile.colors[colorKey].g = g
			sm.db.profile.colors[colorKey].b = b
			if colorKey == "bground" and sm.frame then
				sm.frame:SetBackdropColor(r, g, b, sm.db.profile.colors.bground.a or 0.45)
			end
			-- Force bag type refresh + recolor
			sm.needToOrganize = true
			sm:BuildFrame()
			sm:OrganizeFrame(true)
			sm:RefreshAllBags()
		end
	end

	-- Dense color wheel (multiple rings) so it looks like a continuous circle
	local function hsvToRgb(h, s, v)
		local h6 = h * 6
		local hi = math.floor(h6)
		local fpart = h6 - hi
		local p = v * (1 - s)
		local q = v * (1 - fpart * s)
		local t = v * (1 - (1 - fpart) * s)
		if hi == 0 or hi == 6 then return v, t, p
		elseif hi == 1 then return q, v, p
		elseif hi == 2 then return p, v, t
		elseif hi == 3 then return p, q, v
		elseif hi == 4 then return t, p, v
		else return v, p, q end
	end

	local cx, cy = 140, -155
	local rings = 8
	local segments = 36
	for ring = 1, rings do
		local sat = ring / rings
		local radius = 18 + ring * 10
		for i = 0, segments - 1 do
			local angle = (i / segments) * 6.28318530718
			local hue = i / segments
			local r, g, b = hsvToRgb(hue, sat, 1)
			local btn = CreateFrame("Button", nil, f)
			btn:SetWidth(12)
			btn:SetHeight(12)
			local x = cx + math.cos(angle) * radius - 6
			local y = cy + math.sin(angle) * radius - 6
			btn:SetPoint("TOPLEFT", f, "TOPLEFT", x, y)
			local tex = btn:CreateTexture(nil, "ARTWORK")
			tex:SetAllPoints(btn)
			tex:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
			tex:SetVertexColor(r, g, b)
			local rr, gg, bb = r, g, b
			btn:SetScript("OnClick", function()
				applyColor(rr, gg, bb)
			end)
		end
	end
	-- Center neutrals on TOP of the wheel so black is easy to click
	local neutrals = {
		{1, 1, 1},
		{0.75, 0.75, 0.75},
		{0.5, 0.5, 0.5},
		{0.25, 0.25, 0.25},
		{0.05, 0.05, 0.05}, -- same as slot fill
		{0, 0, 0},          -- pure black
	}
	for i, col in ipairs(neutrals) do
		local btn = CreateFrame("Button", nil, f)
		btn:SetWidth(18)
		btn:SetHeight(18)
		btn:SetFrameLevel(f:GetFrameLevel() + 5)
		btn:SetPoint("TOPLEFT", f, "TOPLEFT", cx - 9, cy - 9 - (i - 3.5) * 18)
		local tex = btn:CreateTexture(nil, "ARTWORK")
		tex:SetAllPoints(btn)
		tex:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
		tex:SetVertexColor(col[1], col[2], col[3])
		-- light border so black is visible on dark UI
		local border = btn:CreateTexture(nil, "OVERLAY")
		border:SetTexture("Interface\\Buttons\\WHITE8X8")
		if not border.SetTexture then
			border:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
		end
		border:SetVertexColor(0.6, 0.6, 0.6)
		border:SetPoint("TOPLEFT", btn, "TOPLEFT", -1, 1)
		border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 1, -1)
		border:SetDrawLayer("BACKGROUND")
		local rr, gg, bb = col[1], col[2], col[3]
		btn:SetScript("OnClick", function()
			applyColor(rr, gg, bb)
		end)
	end

	-- Default colors for reset
	local defaultColors = {
		ammo = {r = 1, g = 1, b = 0},
		soul = {r = 0.5, g = 0.5, b = 1},
		prof = {r = 1, g = 0, b = 1},
		bground = {r = 0, g = 0, b = 0, a = 0.45},
		mouseover = {r = 0, g = 0.7, b = 1},
	}

	local blackBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	blackBtn:SetWidth(70)
	blackBtn:SetHeight(22)
	blackBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 16)
	blackBtn:SetText("Black")
	blackBtn:SetScript("OnClick", function()
		applyColor(0, 0, 0)
	end)

	local defBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	defBtn:SetWidth(90)
	defBtn:SetHeight(22)
	defBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 16)
	defBtn:SetText("Default")
	defBtn:SetScript("OnClick", function()
		local d = defaultColors[colorKey]
		if d then
			applyColor(d.r, d.g, d.b)
			if colorKey == "bground" and sm.db.profile.colors.bground then
				sm.db.profile.colors.bground.a = d.a or 0.45
			end
		end
	end)

	local ok = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	ok:SetWidth(70)
	ok:SetHeight(22)
	ok:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 16)
	ok:SetText("Done")
	ok:SetScript("OnClick", function() f:Hide() end)

	f.colorKey = colorKey
	f:ClearAllPoints()
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	f:Show()
	self.colorFrame = f
end

function module:ShowOptionsFrame()
	local mod = self
	local prefix = mod.isBank and "OneBank" or "OneBag"
	local frameName = prefix .. "OptionsFrame"
	if not mod.optionsFrame then
		local f = CreateFrame("Frame", frameName, UIParent)
		f:SetWidth(300)
		f:SetHeight(780)
		f:SetFrameStrata("HIGH")
		f:SetMovable(true)
		f:EnableMouse(true)
		f:SetClampedToScreen(true)
		f:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true, tileSize = 32, edgeSize = 32,
			insets = { left = 8, right = 8, top = 8, bottom = 8 }
		})
		tinsert(UISpecialFrames, frameName)

		-- Dedicated drag bar (children would otherwise eat mouse events)
		local dragBar = CreateFrame("Button", nil, f)
		dragBar:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -8)
		dragBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -32, -8)
		dragBar:SetHeight(28)
		dragBar:RegisterForDrag("LeftButton")
		dragBar:SetScript("OnDragStart", function() f:StartMoving() end)
		dragBar:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

		local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		title:SetPoint("TOP", f, "TOP", 0, -14)
		title:SetText(mod.isBank and "OneBank Options" or "OneBag Options")

		local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)

		local y = -40
		-- Menu scale (so the options window fits on smaller screens)
		local menuScaleLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		menuScaleLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 25, y)
		menuScaleLabel:SetText("Menu scale: "..floor(((self.db.profile.optionsScale or 0.85) * 100)).."%")
		y = y - 16
		local menuScaleSlider = CreateFrame("Slider", prefix.."MenuScaleSlider", f, "OptionsSliderTemplate")
		menuScaleSlider:SetPoint("TOPLEFT", f, "TOPLEFT", 25, y)
		menuScaleSlider:SetWidth(250)
		menuScaleSlider:SetMinMaxValues(60, 100)
		menuScaleSlider:SetValueStep(5)
		menuScaleSlider:SetValue((mod.db.profile.optionsScale or 0.85) * 100)
		getglobal(prefix.."MenuScaleSliderLow"):SetText("60%")
		getglobal(prefix.."MenuScaleSliderHigh"):SetText("100%")
		getglobal(prefix.."MenuScaleSliderText"):SetText("")
		menuScaleSlider:SetScript("OnValueChanged", function()
			if mod._ignoreSliders then return end
			local v = floor(this:GetValue() + 0.5)
			mod.db.profile.optionsScale = v / 100
			menuScaleLabel:SetText("Menu scale: "..v.."%")
			-- Do NOT SetScale while dragging — that causes the slider to fight the mouse
		end)
		local function applyMenuScale()
			local s = mod.db.profile.optionsScale or 0.85
			f:SetScale(s)
		end
		menuScaleSlider:SetScript("OnMouseUp", applyMenuScale)
		menuScaleSlider:SetScript("OnLeave", function()
			-- if user released outside the thumb
			applyMenuScale()
		end)
		y = y - 36
		f.menuScaleSlider = menuScaleSlider
		f.menuScaleLabel = menuScaleLabel

		local function tip(widget, titleText, body)
			widget:SetScript("OnEnter", function()
				GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
				GameTooltip:SetText(titleText, 1, 1, 1)
				if body then
					GameTooltip:AddLine(body, 0.8, 0.8, 0.8, 1)
				end
				GameTooltip:Show()
			end)
			widget:SetScript("OnLeave", function() GameTooltip:Hide() end)
		end

		local function addCheck(label, desc, getFn, setFn)
			local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
			cb:SetPoint("TOPLEFT", f, "TOPLEFT", 20, y)
			cb:SetWidth(24)
			cb:SetHeight(24)
			local text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
			text:SetText(label)
			cb:SetScript("OnShow", function() this:SetChecked(getFn() and 1 or 0) end)
			cb:SetScript("OnClick", function()
				setFn(this:GetChecked() and true or false)
			end)
			tip(cb, label, desc)
			y = y - 28
			return cb
		end

		local function addButton(label, desc, onClick)
			local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
			btn:SetWidth(250)
			btn:SetHeight(22)
			btn:SetPoint("TOPLEFT", f, "TOPLEFT", 25, y)
			btn:SetText(label)
			btn:SetScript("OnClick", onClick)
			tip(btn, label, desc)
			y = y - 28
			return btn
		end

		addCheck("Show bag buttons", "Shows the individual bag icons under the bag/bank window.",
			function()
				if mod.db.profile.show.bagBar == nil then return true end
				return mod.db.profile.show.bagBar and true or false
			end,
			function(v)
				mod.db.profile.show.bagBar = v and true or false
				local bar = mod.frame and mod.frame.bagBar
				if not bar and mod.SetupFrames then
					mod:SetupFrames()
					bar = mod.frame and mod.frame.bagBar
				end
				if bar then
					bar:SetFrameLevel((mod.frame:GetFrameLevel() or 1) + 5)
					if v then bar:Show() else bar:Hide() end
				else
					DEFAULT_CHAT_FRAME:AddMessage("|cffff6666OneBag: bag bar missing — reload UI.|r")
				end
			end)

		addCheck("Lock frame", "Prevents dragging. Hold Alt and drag to move even while locked.",
			function() return self.db.profile.locked end,
			function(v) self.db.profile.locked = v end)

		addCheck("Clamp to screen", "Keeps the bag window from being dragged off screen.",
			function() return self.db.profile.clamped end,
			function(v)
				self.db.profile.clamped = v
				if self.frame then self.frame:SetClampedToScreen(v) end
			end)

		addCheck("Bag break (new row per bag)", "Starts a new row at the beginning of each bag.",
			function() return self.db.profile.bagBreak end,
			function(v)
				self.db.profile.bagBreak = v
				self:OrganizeFrame(true)
			end)

		addCheck("Show ammo bags", "Include quiver / ammo pouch slots in the combined bag.",
			function() return self.db.profile.show.ammo end,
			function(v)
				self.db.profile.show.ammo = v
				self:OrganizeFrame(true)
				self:RefreshAllBags()
			end)

		addCheck("Show soul bags", "Include soul bag slots in the combined bag.",
			function() return self.db.profile.show.soul end,
			function(v)
				self.db.profile.show.soul = v
				self:OrganizeFrame(true)
				self:RefreshAllBags()
			end)

		addCheck("Show profession bags", "Include profession bag slots in the combined bag.",
			function() return self.db.profile.show.prof end,
			function(v)
				self.db.profile.show.prof = v
				self:OrganizeFrame(true)
				self:RefreshAllBags()
			end)

		addCheck("Reverse bag order", "Shows bags in reverse order (bag 4 first instead of backpack first).",
			function() return self.db.profile.show.direction end,
			function(v)
				self.db.profile.show.direction = v
				self:OrganizeFrame(true)
			end)

		-- Manual bag type (Emberveil can't always detect ammo/soul/prof bags)
		if not self.db.profile.bagTypes then
			self.db.profile.bagTypes = {[1]="auto",[2]="auto",[3]="auto",[4]="auto"}
		end
		local typeNames = {auto = "Auto", normal = "Normal", ammo = "Ammo", soul = "Soul", prof = "Prof"}
		local typeOrder = {"auto", "normal", "ammo", "soul", "prof"}
		for bagId = 1, 4 do
			addButton("Bag "..bagId.." type: "..(typeNames[self.db.profile.bagTypes[bagId] or "auto"] or "Auto"),
				"Click to cycle this bag's type so coloring works (set your ammo bag to Ammo).",
				function()
					local cur = self.db.profile.bagTypes[bagId] or "auto"
					local nextType = "auto"
					for i, t in ipairs(typeOrder) do
						if t == cur then
							nextType = typeOrder[math.mod(i, 5) + 1]
							break
						end
					end
					self.db.profile.bagTypes[bagId] = nextType
					this:SetText("Bag "..bagId.." type: "..(typeNames[nextType] or nextType))
					self.needToOrganize = true
					self:BuildFrame()
					self:OrganizeFrame(true)
					self:RefreshAllBags()
				end)
		end

		addCheck("Color by rarity", "Tint slots based on item quality (green/blue/purple borders).",
			function() return self.db.profile.colors.rarity end,
			function(v)
				self.db.profile.colors.rarity = v
				self:RefreshAllBags()
			end)

		y = y - 4
		addButton("Ammo bag color...", "Highlight color for ammo / quiver slots.", function()
			self:OpenColorPicker("ammo")
		end)
		addButton("Soul bag color...", "Highlight color for soul bag slots.", function()
			self:OpenColorPicker("soul")
		end)
		addButton("Profession bag color...", "Highlight color for profession bag slots.", function()
			self:OpenColorPicker("prof")
		end)
		addButton("Background color...", "Bag window background color.", function()
			self:OpenColorPicker("bground", true)
		end)

		y = y - 10
		-- Columns slider
		local colsLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		colsLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 25, y)
		colsLabel:SetText("Columns: "..(self.db.profile.cols or 10))
		y = y - 18
		local colsSlider = CreateFrame("Slider", prefix.."ColsSlider", f, "OptionsSliderTemplate")
		colsSlider:SetPoint("TOPLEFT", f, "TOPLEFT", 25, y)
		colsSlider:SetWidth(250)
		colsSlider:SetMinMaxValues(5, 20)
		colsSlider:SetValueStep(1)
		colsSlider:SetValue(self.db.profile.cols or 10)
		getglobal(prefix.."ColsSliderLow"):SetText("5")
		getglobal(prefix.."ColsSliderHigh"):SetText("20")
		getglobal(prefix.."ColsSliderText"):SetText("")
		colsSlider:SetScript("OnValueChanged", function()
			if self._ignoreSliders then return end
			local v = floor(this:GetValue() + 0.5)
			self.db.profile.cols = v
			colsLabel:SetText("Columns: "..v)
			self:OrganizeFrame(true)
		end)
		colsSlider:SetScript("OnEnter", function()
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
			GameTooltip:SetText("Columns", 1, 1, 1)
			GameTooltip:AddLine("How many item slots per row.", 0.8, 0.8, 0.8, 1)
			GameTooltip:Show()
		end)
		colsSlider:SetScript("OnLeave", function() GameTooltip:Hide() end)
		y = y - 40

		-- Scale slider
		local scaleLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		scaleLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 25, y)
		scaleLabel:SetText("Scale: "..floor((self.db.profile.scale or 1) * 100).."%")
		y = y - 18
		local scaleSlider = CreateFrame("Slider", prefix.."ScaleSlider", f, "OptionsSliderTemplate")
		scaleSlider:SetPoint("TOPLEFT", f, "TOPLEFT", 25, y)
		scaleSlider:SetWidth(250)
		scaleSlider:SetMinMaxValues(50, 150)
		scaleSlider:SetValueStep(5)
		scaleSlider:SetValue((self.db.profile.scale or 1) * 100)
		getglobal(prefix.."ScaleSliderLow"):SetText("50%")
		getglobal(prefix.."ScaleSliderHigh"):SetText("150%")
		getglobal(prefix.."ScaleSliderText"):SetText("")
		scaleSlider:SetScript("OnValueChanged", function()
			if self._ignoreSliders then return end
			local v = floor(this:GetValue() + 0.5)
			scaleLabel:SetText("Scale: "..v.."%")
			self:ApplyScale(v / 100)
		end)
		scaleSlider:SetScript("OnEnter", function()
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
			GameTooltip:SetText("Scale", 1, 1, 1)
			GameTooltip:AddLine("Overall size of the bag window.", 0.8, 0.8, 0.8, 1)
			GameTooltip:Show()
		end)
		scaleSlider:SetScript("OnLeave", function() GameTooltip:Hide() end)
		y = y - 40

		-- Padding slider
		local padLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		padLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 25, y)
		padLabel:SetText("Padding: "..(self.db.profile.padding or 2))
		y = y - 18
		local padSlider = CreateFrame("Slider", prefix.."PadSlider", f, "OptionsSliderTemplate")
		padSlider:SetPoint("TOPLEFT", f, "TOPLEFT", 25, y)
		padSlider:SetWidth(250)
		padSlider:SetMinMaxValues(0, 12)
		padSlider:SetValueStep(1)
		padSlider:SetValue(self.db.profile.padding or 2)
		getglobal(prefix.."PadSliderLow"):SetText("0")
		getglobal(prefix.."PadSliderHigh"):SetText("12")
		getglobal(prefix.."PadSliderText"):SetText("")
		padSlider:SetScript("OnValueChanged", function()
			if self._ignoreSliders then return end
			local v = floor(this:GetValue() + 0.5)
			padLabel:SetText("Padding: "..v)
			self:ApplyPadding(v)
		end)
		padSlider:SetScript("OnEnter", function()
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
			GameTooltip:SetText("Padding", 1, 1, 1)
			GameTooltip:AddLine("Space between item slots. 0 = tight, higher = more gap.", 0.8, 0.8, 0.8, 1)
			GameTooltip:Show()
		end)
		padSlider:SetScript("OnLeave", function() GameTooltip:Hide() end)
		y = y - 40

		f.colsSlider = colsSlider
		f.scaleSlider = scaleSlider
		f.padSlider = padSlider
		f.colsLabel = colsLabel
		f.scaleLabel = scaleLabel
		f.padLabel = padLabel

		mod.optionsFrame = f
	end

	mod.optionsFrame:Hide()
	mod.optionsFrame:Show()
	mod.optionsFrame:ClearAllPoints()
	mod.optionsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	mod.optionsFrame:SetScale(mod.db.profile.optionsScale or 0.85)
	mod._ignoreSliders = true
	if mod.optionsFrame.menuScaleSlider then
		local ms = (mod.db.profile.optionsScale or 0.85) * 100
		mod.optionsFrame.menuScaleSlider:SetValue(ms)
		if mod.optionsFrame.menuScaleLabel then
			mod.optionsFrame.menuScaleLabel:SetText("Menu scale: "..floor(ms).."%")
		end
	end
	if self.optionsFrame.colsSlider then
		self.optionsFrame.colsSlider:SetValue(self.db.profile.cols or 10)
		if self.optionsFrame.colsLabel then
			self.optionsFrame.colsLabel:SetText("Columns: "..(self.db.profile.cols or 10))
		end
	end
	if self.optionsFrame.scaleSlider then
		local s = (self.db.profile.scale or 1) * 100
		self.optionsFrame.scaleSlider:SetValue(s)
		if self.optionsFrame.scaleLabel then
			self.optionsFrame.scaleLabel:SetText("Scale: "..floor(s).."%")
		end
	end
	if self.optionsFrame.padSlider then
		local p = self.db.profile.padding or 2
		self.optionsFrame.padSlider:SetValue(p)
		if self.optionsFrame.padLabel then
			self.optionsFrame.padLabel:SetText("Padding: "..p)
		end
	end
	self._ignoreSliders = false
end

function module:MrPlow()
	MrPlow:Works(self.isBank and "bank" or nil)
end

function module:OnBaseShow()
	local f = this or self.frame
	if not f or not self.db or not self.db.profile then return end
	-- Layout scale is applied via btnSize/colWidth (not SetScale)
	f:SetScale(1)
    f:SetAlpha(self.db.profile.alpha or 1)
	if self.stratas and self.db.profile.strata then
		f:SetFrameStrata(self.stratas[self.db.profile.strata] or "MEDIUM")
		if StackSplitFrame then
			StackSplitFrame:SetFrameStrata(self.stratas[self.db.profile.strata+1] or "DIALOG")
		end
	end
    local color = self.db.profile.colors and self.db.profile.colors.bground
	if color then
		f:SetBackdropColor(color.r or 0, color.g or 0, color.b or 0, color.a or 0.45)
	end
	f:SetClampedToScreen(self.db.profile.clamped or false)
end

function module:UpdateMoney()
	if not self.frame then return end
	local mf = self.frame.moneyFrame
	if not mf then return end
	local money = GetMoney and GetMoney() or 0
	local gold = floor(money / 10000)
	local silver = floor((money - gold * 10000) / 100)
	local copper = mod(money, 100)

	-- Layout right-to-left on one horizontal line: 5g 9s 30c
	local x = 0
	local y = 0
	local iconW = 13
	local gap = 6

	local function putIcon(icon)
		icon:ClearAllPoints()
		icon:SetPoint("RIGHT", mf, "RIGHT", x, y)
		icon:Show()
		x = x - iconW
	end

	local function putText(fs, value)
		fs:SetText(tostring(value))
		local w = fs:GetStringWidth() or 8
		fs:ClearAllPoints()
		fs:SetPoint("RIGHT", mf, "RIGHT", x - 1, y)
		fs:Show()
		x = x - w - 1
	end

	-- copper
	putIcon(mf.copperIcon)
	putText(mf.copperText, copper)
	x = x - gap

	-- silver
	if gold > 0 or silver > 0 then
		putIcon(mf.silverIcon)
		putText(mf.silverText, silver)
		x = x - gap
	else
		mf.silverIcon:Hide()
		mf.silverText:Hide()
	end

	-- gold
	if gold > 0 then
		putIcon(mf.goldIcon)
		putText(mf.goldText, gold)
	else
		mf.goldIcon:Hide()
		mf.goldText:Hide()
	end
end

function module:OnShow()
    self:OnBaseShow()
    self:OnCustomShow()
    PlaySound("igBackPackOpen")
    
    -- Emberveil: do not restore the old side bag panel
    if self.frame.bagFrame then
        self.frame.bagFrame:Hide()
        self.frame.bagFrame.wasShown = false
    end

	self:ApplyLayoutMetrics()
    
    self:BuildFrame()
    self:OrganizeFrame()
	-- bag bar visibility for this module only
	do
		local bar = self.frame and self.frame.bagBar
		if bar then
			local showBar = true
			if self.db and self.db.profile and self.db.profile.show and self.db.profile.show.bagBar == false then
				showBar = false
			end
			if showBar then bar:Show() else bar:Hide() end
		end
	end
    for k, i in pairs(self.fBags) do
        self:UpdateBag(i)     
    end
    
    if self.frame.bags[-1] and (not self.frame.bags[-1].colorLocked) then
        for k, v in ipairs(self.frame.bags[-1]) do 
            self:SetBorderColor(v)
        end
    end
    
    self:DoSlotCounts()
	self:UpdateMoney()
end

function module:OnCustomShow() end -- Meant to be overridden

function module:OnBaseHide()
    if self.dewdrop and self.dewdrop:IsOpen(getglobal(self.frame:GetName() .. "ConfigButton")) then
		self.dewdrop:Close()
	end
end

function module:OnHide()
    self:OnBaseHide()
    self:OnCustomHide()
    PlaySound("igBackPackClose")
    if self.frame.bagFrame and self.frame.bagFrame:IsVisible() then
        self.frame.bagFrame:Hide()
        self.frame.bagFrame.wasShown = true
    end
end

function module:OnCustomHide() end -- Meant to be overridden


function module:RegisterDewdrop(baseArgs)
	if not self.frame then return end
    self.dewdrop = AceLibrary("Dewdrop-2.0")
	self.dewdrop:Register(self.frame,
			'children', baseArgs,
			'point', function(parent)
				if parent:GetTop() < GetScreenHeight() / 2 then
					return "BOTTOMRIGHT", "TOPRIGHT"
				else
					return "TOPRIGHT", "BOTTOMRIGHT"
				end
			end,
			'dontHook', true
		)
end