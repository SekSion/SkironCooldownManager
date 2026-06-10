local SCM = select(2, ...)
local Options = SCM.Options
local Utils = SCM.Utils

Options.RowConfig = {}

function SCM:AddRow(anchorIndex)
	local nextIndex = #SCM.anchorConfig[anchorIndex].rowConfig + 1
	self.anchorConfig[anchorIndex].rowConfig[nextIndex] = {
		size = 40,
		limit = 8,
	}

	return nextIndex
end

function SCM:RemoveRow(anchorIndex, rowIndex)
	if self.anchorConfig[anchorIndex].rowConfig[rowIndex] then
		tremove(self.anchorConfig[anchorIndex].rowConfig, rowIndex)
	end
end

local function SelectAdvancedRowSettings(self, tabGroup, rowConfig, rowIndex, anchorIndex, mode, options, data)
	self:ReleaseChildren()

	if tabGroup == "general" then
		local keepAspectRatio = AceGUI:Create("CheckBox")
		keepAspectRatio:SetLabel("Lock Aspect Ratio")
		keepAspectRatio:SetRelativeWidth(0.5)
		keepAspectRatio:SetValue(rowConfig.keepAspectRatio)
		keepAspectRatio:SetCallback("OnValueChanged", function(_, _, value)
			rowConfig.keepAspectRatio = value
		end)
		keepAspectRatio:SetCallback("OnEnter", function()
			GameTooltip:SetOwner(self.frame, "ANCHOR_CURSOR")
			GameTooltip:SetText("Lock Aspect Ratio", nil, nil, nil, nil, true)
			GameTooltip:AddLine("This will lock both Icon Width & Icon Height to be the same value.", 1, 1, 1, true)
			GameTooltip:Show()
		end)
		keepAspectRatio:SetCallback("OnLeave", function()
			GameTooltip:Hide()
		end)
		self:AddChild(keepAspectRatio)

		local hardLimit = AceGUI:Create("CheckBox")
		hardLimit:SetLabel("Hard Limit")
		hardLimit:SetRelativeWidth(0.5)
		hardLimit:SetValue(rowConfig.hardLimit)
		hardLimit:SetCallback("OnValueChanged", function(_, _, value)
			rowConfig.hardLimit = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		hardLimit:SetCallback("OnEnter", function()
			GameTooltip:SetOwner(self.frame, "ANCHOR_CURSOR")
			GameTooltip:SetText("Hard Limit", nil, nil, nil, nil, true)
			GameTooltip:AddLine("This option will ensure that only the set number of icons are displayed.", 1, 1, 1, true)
			GameTooltip:Show()
		end)
		hardLimit:SetCallback("OnLeave", function()
			GameTooltip:Hide()
		end)
		self:AddChild(hardLimit)

		if rowIndex == 1 then
			local fixedWidth
			local useFixedWidth = AceGUI:Create("CheckBox")
			useFixedWidth:SetLabel("Use Fixed Width")
			useFixedWidth:SetRelativeWidth(0.5)
			useFixedWidth:SetValue(rowConfig.useFixedWidth)
			useFixedWidth:SetDisabled(data.matchAnchorWidth)
			useFixedWidth:SetCallback("OnValueChanged", function(_, _, value)
				rowConfig.useFixedWidth = value
				ApplyModeConfigUpdate(anchorIndex, mode)

				if fixedWidth then
					rowConfig.fixedWidth = rowConfig.fixedWidth or 200
					fixedWidth:SetDisabled(not value)
				end
			end)
			useFixedWidth:SetCallback("OnEnter", function()
				GameTooltip:SetOwner(self.frame, "ANCHOR_CURSOR")
				GameTooltip:SetText("Use Fixed Width", nil, nil, nil, nil, true)
				GameTooltip:AddLine("This will make the row use a fixed width instead of calculating it based on the number of icons.", 1, 1, 1, true)
				GameTooltip:Show()
			end)
			useFixedWidth:SetCallback("OnLeave", function()
				GameTooltip:Hide()
			end)
			self:AddChild(useFixedWidth)

			fixedWidth = AceGUI:Create("Slider")
			fixedWidth:SetRelativeWidth(0.5)
			fixedWidth:SetSliderValues(100, 1000, 0.1)
			fixedWidth:SetLabel("Fixed Width")
			fixedWidth:SetValue(rowConfig.fixedWidth or 200)
			fixedWidth:SetDisabled(not rowConfig.useFixedWidth)
			fixedWidth:SetCallback("OnValueChanged", function(_, _, value)
				rowConfig.fixedWidth = value
				ApplyModeConfigUpdate(anchorIndex, mode)
			end)
			self:AddChild(fixedWidth)
		end
	elseif tabGroup == "charges" then
		local chargeRelativePoint = AceGUI:Create("Dropdown")
		chargeRelativePoint:SetRelativeWidth(0.5)
		chargeRelativePoint:SetLabel("Point")
		chargeRelativePoint:SetList(SCM.Constants.AnchorPoints)
		chargeRelativePoint:SetValue(rowConfig.chargePoint or options.chargePoint)
		chargeRelativePoint:SetCallback("OnValueChanged", function(_, _, value)
			rowConfig.chargePoint = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(chargeRelativePoint)

		local chargeRelativePoint = AceGUI:Create("Dropdown")
		chargeRelativePoint:SetRelativeWidth(0.5)
		chargeRelativePoint:SetLabel("Relative Point")
		chargeRelativePoint:SetList(SCM.Constants.AnchorPoints)
		chargeRelativePoint:SetValue(rowConfig.chargeRelativePoint or options.chargeRelativePoint)
		chargeRelativePoint:SetCallback("OnValueChanged", function(_, _, value)
			rowConfig.chargeRelativePoint = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(chargeRelativePoint)

		local xOffset = AceGUI:Create("Slider")
		xOffset:SetRelativeWidth(0.25)
		xOffset:SetSliderValues(-50, 50, 0.1)
		xOffset:SetLabel("X Offset")
		xOffset:SetValue(rowConfig.chargeXOffset or options.chargeXOffset)
		xOffset:SetCallback("OnValueChanged", function(self, event, value)
			rowConfig.chargeXOffset = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(xOffset)

		local yOffset = AceGUI:Create("Slider")
		yOffset:SetRelativeWidth(0.25)
		yOffset:SetSliderValues(-50, 50, 0.1)
		yOffset:SetLabel("Y Offset")
		yOffset:SetValue(rowConfig.chargeYOffset or options.chargeYOffset)
		yOffset:SetCallback("OnValueChanged", function(self, event, value)
			rowConfig.chargeYOffset = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(yOffset)

		local chargeFontSize = AceGUI:Create("Slider")
		chargeFontSize:SetRelativeWidth(0.25)
		chargeFontSize:SetLabel("Font Size")
		chargeFontSize:SetSliderValues(1, 50, 1)
		chargeFontSize:SetValue(rowConfig.chargeFontSize or options.chargeFontSize)
		chargeFontSize:SetCallback("OnValueChanged", function(self, event, value)
			rowConfig.chargeFontSize = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(chargeFontSize)

		local truncateWhenZero = AceGUI:Create("CheckBox")
		truncateWhenZero:SetLabel("Truncate When Zero")
		truncateWhenZero:SetRelativeWidth(0.25)
		truncateWhenZero:SetValue(rowConfig.chargeTruncateWhenZero)
		truncateWhenZero:SetCallback("OnValueChanged", function(_, _, value)
			rowConfig.chargeTruncateWhenZero = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(truncateWhenZero)
	elseif tabGroup == "applications" then
		local applicationsPoint = AceGUI:Create("Dropdown")
		applicationsPoint:SetRelativeWidth(0.5)
		applicationsPoint:SetLabel("Point")
		applicationsPoint:SetList(SCM.Constants.AnchorPoints)
		applicationsPoint:SetValue(rowConfig.applicationsPoint or options.chargePoint)
		applicationsPoint:SetCallback("OnValueChanged", function(_, _, value)
			rowConfig.applicationsPoint = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(applicationsPoint)

		local applicationsRelativePoint = AceGUI:Create("Dropdown")
		applicationsRelativePoint:SetRelativeWidth(0.5)
		applicationsRelativePoint:SetLabel("Relative Point")
		applicationsRelativePoint:SetList(SCM.Constants.AnchorPoints)
		applicationsRelativePoint:SetValue(rowConfig.applicationsRelativePoint or options.chargeRelativePoint)
		applicationsRelativePoint:SetCallback("OnValueChanged", function(_, _, value)
			rowConfig.applicationsRelativePoint = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(applicationsRelativePoint)

		local xOffset = AceGUI:Create("Slider")
		xOffset:SetRelativeWidth(0.33)
		xOffset:SetSliderValues(-50, 50, 0.1)
		xOffset:SetLabel("X Offset")
		xOffset:SetValue(rowConfig.applicationsXOffset or options.chargeXOffset)
		xOffset:SetCallback("OnValueChanged", function(self, event, value)
			rowConfig.applicationsXOffset = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(xOffset)

		local yOffset = AceGUI:Create("Slider")
		yOffset:SetRelativeWidth(0.33)
		yOffset:SetSliderValues(-50, 50, 0.1)
		yOffset:SetLabel("Y Offset")
		yOffset:SetValue(rowConfig.applicationsYOffset or options.chargeYOffset)
		yOffset:SetCallback("OnValueChanged", function(self, event, value)
			rowConfig.applicationsYOffset = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(yOffset)

		local fontSize = AceGUI:Create("Slider")
		fontSize:SetRelativeWidth(0.33)
		fontSize:SetLabel("Font Size")
		fontSize:SetSliderValues(1, 50, 1)
		fontSize:SetValue(rowConfig.applicationsFontSize or options.chargeFontSize)
		fontSize:SetCallback("OnValueChanged", function(self, event, value)
			rowConfig.applicationsFontSize = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(fontSize)
	elseif tabGroup == "cooldowns" then
		local fontSize = AceGUI:Create("Slider")
		fontSize:SetRelativeWidth(0.5)
		fontSize:SetSliderValues(1, 50, 1)
		fontSize:SetLabel("Font Size")
		fontSize:SetValue(rowConfig.cooldownFontSize or ((options.cooldownFontSize or 0.6) * (rowConfig.iconWidth or rowConfig.size)))
		fontSize:SetCallback("OnValueChanged", function(self, event, value)
			rowConfig.cooldownFontSize = value
			ApplyModeConfigUpdate(anchorIndex, mode)
		end)
		self:AddChild(fontSize)
	end
end

function Options.RowConfig.SelectRow(widget, rowWidget, parentWidget, scrollFrame, data, anchorIndex, rowIndex, rowTabsTbl, mode, options, isProfileConfig)
	widget:ReleaseChildren()

	local isGlobal = mode == "global"
	local isBuffBar = mode == "buffbars"
	local useDataRowConfig = isGlobal or isBuffBar or isProfileConfig

	if not data.rowConfig[rowIndex] then
		return
	end

	local rowConfig = data.rowConfig[rowIndex]
	local widthLabel = isBuffBar and "Bar Width" or "Icon Width"
	local heightLabel = isBuffBar and "Bar Height" or "Icon Height"
	local iconWidth = AceGUI:Create("Slider")
	iconWidth:SetRelativeWidth(0.33)
	iconWidth:SetSliderValues(10, isBuffBar and 500 or 200, 0.1)
	iconWidth:SetLabel(widthLabel)
	iconWidth:SetDisabled(data.matchAnchorWidth)
	iconWidth:SetValue(rowConfig.iconWidth or rowConfig.size)

	widget:AddChild(iconWidth)

	local iconHeight = AceGUI:Create("Slider")
	iconHeight:SetRelativeWidth(0.33)
	iconHeight:SetSliderValues(10, 200, 0.1)
	iconHeight:SetLabel(heightLabel)
	iconHeight:SetValue(rowConfig.iconHeight or rowConfig.size)
	iconHeight:SetCallback("OnValueChanged", function(self, event, value)
		if rowConfig.keepAspectRatio then
			local newWidth
			if (rowConfig.iconHeight or rowConfig.size) == (rowConfig.iconWidth or rowConfig.size) then
				newWidth = value
			else
				local ratio = (rowConfig.iconWidth or rowConfig.size) / (rowConfig.iconHeight or rowConfig.size)
				newWidth = ceil((ratio * value) * 10) / 10
			end

			rowConfig.iconWidth = newWidth
			iconWidth:SetValue(rowConfig.iconWidth)
		end

		rowConfig.iconHeight = value
		ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	iconWidth:SetCallback("OnValueChanged", function(self, event, value)
		if rowConfig.keepAspectRatio then
			local newHeight
			if (rowConfig.iconHeight or rowConfig.size) == (rowConfig.iconWidth or rowConfig.size) then
				newHeight = value
			else
				local ratio = (rowConfig.iconHeight or rowConfig.size) / (rowConfig.iconWidth or rowConfig.size)
				newHeight = ceil((ratio * value) * 10) / 10
			end

			rowConfig.iconHeight = newHeight
			iconHeight:SetValue(rowConfig.iconHeight)
		end
		rowConfig.iconWidth = value

		ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	widget:AddChild(iconHeight)

	local limit = AceGUI:Create("Slider")
	limit:SetRelativeWidth(0.33)
	limit:SetSliderValues(1, 20, 1)
	limit:SetLabel("Limit")
	limit:SetValue(rowConfig.limit)
	limit:SetCallback("OnValueChanged", function(self, event, value)
		rowConfig.limit = value
		ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	widget:AddChild(limit)

	local advancedRowSettings = AceGUI:Create("TabGroup")
	local advancedTabs = isBuffBar and { { value = "general", text = "General" }, { value = "applications", text = "Stacks (Alpha)" } }
		or { { value = "general", text = "General" }, { value = "charges", text = "Charges" }, { value = "applications", text = "Stacks" }, { value = "cooldowns", text = "Cooldowns" } }
	advancedRowSettings:SetAutoAdjustHeight(false)
	advancedRowSettings:SetHeight(150)
	advancedRowSettings:SetFullWidth(true)
	advancedRowSettings:SetLayout("flow")
	advancedRowSettings:SetTabs(advancedTabs)
	advancedRowSettings:SetCallback("OnGroupSelected", function(self, event, tabGroup)
		SelectAdvancedRowSettings(self, tabGroup, rowConfig, rowIndex, anchorIndex, mode, options, data)
	end)
	advancedRowSettings:SelectTab("general")
	widget:AddChild(advancedRowSettings)

	local buttonGroup = AceGUI:Create("SimpleGroup")
	buttonGroup:SetFullWidth(true)
	buttonGroup:SetLayout("flow")
	widget:AddChild(buttonGroup)

	local addRowButton = AceGUI:Create("Button")
	addRowButton:SetText("Add Row")
	addRowButton:SetRelativeWidth(0.5)
	addRowButton:SetDisabled(#rowTabsTbl >= 9)
	addRowButton:SetCallback("OnClick", function()
		local nextIndex = (useDataRowConfig and (#data.rowConfig + 1)) or SCM:AddRow(anchorIndex)
		if isGlobal then
			data.rowConfig[nextIndex] = { iconHeight = 40, iconWidth = 40, limit = 8 }
		elseif isBuffBar then
			data.rowConfig[nextIndex] = { iconHeight = 40, iconWidth = 150, limit = 8 }
		elseif isProfileConfig then
			data.rowConfig[nextIndex] = { iconHeight = 40, iconWidth = 40, limit = 8 }
		end

		tinsert(rowTabsTbl, { value = nextIndex, text = "Row " .. nextIndex })
		table.sort(rowTabsTbl, function(a, b)
			return a.value < b.value
		end)
		widget:SetTabs(rowTabsTbl)
		widget:SelectTab(nextIndex)
		ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	buttonGroup:AddChild(addRowButton)

	local deleteRowButton = AceGUI:Create("Button")
	deleteRowButton:SetText("Delete Row")
	deleteRowButton:SetRelativeWidth(0.5)
	deleteRowButton:SetDisabled(rowIndex == 1)
	deleteRowButton:SetCallback("OnClick", function()
		if useDataRowConfig then
			tremove(data.rowConfig, rowIndex)
		else
			SCM:RemoveRow(anchorIndex, rowIndex)
		end

		local removedIndex
		for i, tab in ipairs(rowTabsTbl) do
			if tab.value == rowIndex then
				removedIndex = i
				tremove(rowTabsTbl, i)
				break
			end
		end

		for i = removedIndex, #rowTabsTbl do
			rowTabsTbl[i].value = i
			rowTabsTbl[i].text = "Row " .. i
		end

		widget:SetTabs(rowTabsTbl)
		widget:SelectTab(#rowTabsTbl)
		ApplyModeConfigUpdate(anchorIndex, mode)
	end)
	buttonGroup:AddChild(deleteRowButton)
end
