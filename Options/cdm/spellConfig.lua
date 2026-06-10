local SCM = select(2, ...)
local Options = SCM.Options
local Utils = SCM.Utils
local GetCooldownConfigKey = Utils.GetCooldownConfigKey

Options.SpellConfig = {}

local colorKnown = "ffffff"
local colorUnknown = "808080"
local colorDisabled = "ff0000"

local iconTypeTabs = {
	all = {
		{ value = "general", text = "General" },
		{ value = "glow", text = "Glow" },
		{ value = "load", text = "Load Conditions" },
	},
	spell = {},
	item = {
		{ value = "items", text = "Items" },
	},
	timer = {},
	slot = {
		{ value = "filter", text = "Filter" },
	},
}
for iconType, options in pairs(iconTypeTabs) do
	if iconType ~= "all" then
		for i = #iconTypeTabs.all, 1, -1 do
			tinsert(options, 1, iconTypeTabs.all[i])
		end
	end
end

local function GetDefaultLoadRaceNames()
	local dualFactionRaces = {}
	local loadedRaces = {}
	local raceIDs = {}

	local sortedIDs = {}
	for raceID in pairs(SCM.Constants.Races) do
		sortedIDs[#sortedIDs + 1] = raceID
	end
	table.sort(sortedIDs)

	for i = 1, #sortedIDs do
		local raceID = sortedIDs[i]
		local raceInfo = C_CreatureInfo.GetRaceInfo(raceID)

		if raceInfo and not dualFactionRaces[raceInfo.raceName] then
			dualFactionRaces[raceInfo.raceName] = true
			loadedRaces[raceID] = raceInfo.raceName
			tinsert(raceIDs, raceID)
		end
	end

	table.sort(raceIDs, function(raceIDA, raceIDB)
		return loadedRaces[raceIDA] < loadedRaces[raceIDB]
	end)

	return loadedRaces, raceIDs
end

local function SortByIndex(a, b)
	return a.dataIndex < b.dataIndex
end

local function ShowNumericInputPopup(key, title, callback)
	StaticPopupDialogs[key] = StaticPopupDialogs[key]
		or {
			text = title,
			button1 = ACCEPT,
			button2 = CANCEL,
			hasEditBox = true,
			timeout = 0,
			whileDead = true,
			preferredIndex = 3,
			OnAccept = function(self)
				local id = tonumber(self.EditBox:GetText() or "")
				local acceptCallback = self.data
				if id and id > 0 and type(acceptCallback) == "function" then
					acceptCallback(id)
				end
			end,
			hideOnEscape = true,
			EditBoxOnEnterPressed = function(self)
				if self:GetParent():GetButton1():IsEnabled() then
					self:GetParent():GetButton1():Click()
				end
			end,
		}
	StaticPopup_Show(key, nil, nil, callback)
end

local function BuildSpellIconData(spellID)
	local texture = C_Spell.GetSpellTexture(spellID)
	if not texture then
		return
	end

	return {
		texture = texture,
		spellID = spellID,
	}
end

local function BuildItemIconData(itemID)
	local texture = C_Item.GetItemIconByID(itemID)
	if not texture then
		return
	end

	return {
		texture = texture,
		spellID = 0,
		itemID = itemID,
	}
end

local function BuildSlotIconData(slotID)
	if slotID < 1 or slotID > 19 then
		return
	end

	return {
		texture = GetInventoryItemTexture("player", slotID) or 134400,
		spellID = 0,
		slotID = slotID,
	}
end

local function BuildEmptyIconData()
	return {
		texture = 134400,
	}
end

local customButtonConfigs = {
	{
		text = "Spell",
		popupKey = "SCM_CUSTOM_SPELL_ID",
		popupTitle = "Enter Spell ID",
		iconType = "spell",
		buildIconData = BuildSpellIconData,
	},
	{
		text = "Item",
		popupKey = "SCM_CUSTOM_ITEM_ID",
		popupTitle = "Enter Item ID",
		iconType = "item",
		buildIconData = BuildItemIconData,
	},
	{
		text = "Slot",
		popupKey = "SCM_SPEC_SLOT_ID",
		popupTitle = "Enter Slot ID",
		iconType = "slot",
		buildIconData = BuildSlotIconData,
	},
	{
		text = "Timer",
		popupKey = "SCM_TIMER_SPELL_ID",
		popupTitle = "Enter Spell ID",
		iconType = "timer",
		buildIconData = BuildSpellIconData,
		tooltip = function(tooltip, elementDescription)
			GameTooltip_SetTitle(tooltip, MenuUtil.GetElementText(elementDescription))
			GameTooltip_AddInstructionLine(tooltip, "Timers can only be created based on successful casts.")
		end,
	},
	{
		text = "Empty",
		iconType = "empty",
		buildIconData = BuildEmptyIconData,
	},
}

local function CreateCustomIconButton(rootDescription, scrollFrame, anchorIndex, isGlobal, buttonConfig)
	local button = rootDescription:CreateButton(buttonConfig.text, function()
		local function AddCustomIcon(configID)
			local iconData = buttonConfig.buildIconData(configID)
			if not iconData then
				return
			end

			iconData.iconType = buttonConfig.iconType
			iconData.isCustom = true

			local uniqueID = SCM:GetUniqueID(configID, buttonConfig.iconType, isGlobal)
			iconData.id = uniqueID
			local order, insertedData = scrollFrame:AddCustomIcon(iconData)

			uniqueID = SCM:AddCustomIcon(anchorIndex, buttonConfig.iconType, configID, order, uniqueID, isGlobal)
			if not uniqueID then
				scrollFrame:RemoveButton(insertedData)
				return
			end

			insertedData.id = uniqueID

			SCM:ApplyAnchorGroupCDManagerConfig(anchorIndex, isGlobal)
		end

		if buttonConfig.popupKey then
			ShowNumericInputPopup(buttonConfig.popupKey, buttonConfig.popupTitle, AddCustomIcon)
		elseif buttonConfig.iconType == "empty" then
			AddCustomIcon("")
		end
	end)

	if buttonConfig.tooltip then
		button:SetTooltip(buttonConfig.tooltip)
	end
end

local function CreateCustomIconButtons(rootDescription, scrollFrame, anchorIndex, isGlobal, buttonConfigs)
	for _, buttonConfig in ipairs(buttonConfigs) do
		CreateCustomIconButton(rootDescription, scrollFrame, anchorIndex, isGlobal, buttonConfig)
	end
end

local function GetSpellIDForCooldownInfo(cooldownInfo)
	if cooldownInfo then
		return cooldownInfo.linkedSpellID or cooldownInfo.overrideTooltipSpellID or cooldownInfo.overrideSpellID or cooldownInfo.spellID
	end
end

local function BuildScrollSpellData(data, configID)
	return {
		spellID = data.spellID,
		linkedSpellIDs = data.linkedSpellIDs,
		isKnown = data.isKnown,
		category = data.category,
		cooldownID = data.cooldownID,
		configID = configID,
	}
end

local function DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID)
	return scrollFrame.dataProvider:FindByPredicate(function(data)
		if data.isCustom or data.isAddButton then
			return false
		end

		if data.id == configID then
			return true
		end

		if cooldownID and data.cooldownID == cooldownID then
			return true
		end
	end)
end

local function GetDisplayDataForSpellConfig(defaultCooldownViewerConfig, sourceIndex, configID, config)
	local data = defaultCooldownViewerConfig[sourceIndex]
	if not data then
		return
	end

	local pairData = defaultCooldownViewerConfig[SCM.Constants.SourcePairs[sourceIndex]]
	local cooldownID = config.cooldownID or tonumber(tostring(configID):match("(%d+)$"))

	if cooldownID then
		return data.cooldownIDs[cooldownID] or (pairData and pairData.cooldownIDs[cooldownID])
	end
end

local function CreateAddSpellDropdown(owner, rootDescription, scrollFrame, anchorIndex, mode)
	rootDescription:CreateTitle("Add Icon")

	local dataProvider = CooldownViewerSettings:GetDataProvider()
	local cooldownInfoByID = dataProvider and dataProvider.displayData.cooldownInfoByID

	if mode == "global" then
		local customButton = rootDescription:CreateButton("Custom")
		CreateCustomIconButtons(customButton, scrollFrame, anchorIndex, true, customButtonConfigs)
		return
	end

	local function GetSortRank(info, data)
		if type(data.category) == "number" and data.category < 0 then
			return 4
		end
		if info.isKnown then
			return 1
		end

		return data.category
	end

	local function SortSpells(a, b)
		local rankA = GetSortRank(a.info, a.data)
		local rankB = GetSortRank(b.info, b.data)

		if rankA ~= rankB then
			return rankA < rankB
		end

		local nameA = C_Spell.GetSpellName(a.info.spellID)
		local nameB = C_Spell.GetSpellName(b.info.spellID)

		if nameA and nameB then
			return nameA < nameB
		end
	end

	local function ProcessAndCreateButtons(parentButton, items, isBuffIcon)
		table.sort(items, SortSpells)

		for _, item in ipairs(items) do
			local data = item.data
			local cooldownID = item.cooldownID
			local info = item.info
			local configID = GetCooldownConfigKey(cooldownID)
			if configID then
				info.cooldownID = item.cooldownID
				info.configID = configID
				info.isDisabled = type(data.category) == "number" and data.category < 0
				info.category = data.category

				local activeColor = (type(data.category) == "number" and data.category < 0 and colorDisabled) or (info.isKnown and colorKnown) or colorUnknown
				parentButton:CreateButton(
					string.format("|T%d:0|t |cff%s%s (%d)|r", C_Spell.GetSpellTexture(info.spellID), activeColor, C_Spell.GetSpellName(info.spellID), info.spellID),
					function(info)
						if not SCM:IsSpellInData(info.cooldownID, info.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, info.configID, info.cooldownID) then
							local dataIndex = scrollFrame:AddSpellBySpellID(info)
							SCM:AddSpellToConfig(anchorIndex, dataIndex, info, data, item.targetCategory, isBuffIcon)
							ApplyModeConfigUpdate(anchorIndex, mode)
						end
						return MenuResponse.Open
					end,
					info
				)
			end
		end
	end

	if mode == "buffbars" then
		local buffButton = rootDescription:CreateButton("Buff Bars")
		local buffItems = {}

		local cooldownIDs = C_CooldownViewer.GetCooldownViewerCategorySet(2, true)
		for _, cooldownID in ipairs(cooldownIDs) do
			local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
			local data = cooldownInfoByID[cooldownID]

			if info and data and type(data.category) == "number" and (data.category == 3 or data.category < 0) then
				local spellID = GetSpellIDForCooldownInfo(info)
				local configID = GetCooldownConfigKey(cooldownID)
				info.spellID = spellID

				if configID and not SCM:IsSpellInData(cooldownID, data.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID) then
					table.insert(buffItems, { info = info, data = data, cooldownID = cooldownID, targetCategory = 3 })
				end
			end
		end

		cooldownIDs = C_CooldownViewer.GetCooldownViewerCategorySet(3, true)
		for _, cooldownID in ipairs(cooldownIDs) do
			local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
			local data = cooldownInfoByID[cooldownID]

			if info and data and type(data.category) == "number" and (data.category == 3 or data.category < 0) then
				local spellID = GetSpellIDForCooldownInfo(info)
				local configID = GetCooldownConfigKey(cooldownID)
				info.spellID = spellID

				if configID and not SCM:IsSpellInData(cooldownID, data.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID) then
					table.insert(buffItems, { info = info, data = data, cooldownID = cooldownID, targetCategory = 3 })
				end
			end
		end

		buffButton:SetGridMode(MenuConstants.VerticalGridDirection, floor(#buffItems / 15) + 1)

		ProcessAndCreateButtons(buffButton, buffItems, false)

		return
	end

	local essentialButton = rootDescription:CreateButton("Essential")
	local utilityButton = rootDescription:CreateButton("Utility")
	local buffButton = rootDescription:CreateButton("Buff")

	local essentialItems = {}
	local cooldownIDs = C_CooldownViewer.GetCooldownViewerCategorySet(0, true)
	for _, cooldownID in ipairs(cooldownIDs) do
		local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
		local data = cooldownInfoByID[cooldownID]

		if info and data then
			local spellID = GetSpellIDForCooldownInfo(info)
			local configID = GetCooldownConfigKey(cooldownID)
			info.spellID = spellID

			if configID and not SCM:IsSpellInData(cooldownID, data.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID) then
				table.insert(essentialItems, { info = info, data = data, cooldownID = cooldownID, targetCategory = 0 })
			end
		end
	end

	essentialButton:SetGridMode(MenuConstants.VerticalGridDirection, floor(#essentialItems / 15) + 1)
	ProcessAndCreateButtons(essentialButton, essentialItems)

	local utilityItems = {}
	cooldownIDs = C_CooldownViewer.GetCooldownViewerCategorySet(1, true)
	for _, cooldownID in ipairs(cooldownIDs) do
		local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
		local data = cooldownInfoByID[cooldownID]

		if info and data then
			local spellID = GetSpellIDForCooldownInfo(info)
			local configID = GetCooldownConfigKey(cooldownID)
			info.spellID = spellID

			if configID and not SCM:IsSpellInData(cooldownID, data.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID) then
				table.insert(utilityItems, { info = info, data = data, cooldownID = cooldownID, targetCategory = 1 })
			end
		end
	end

	utilityButton:SetGridMode(MenuConstants.VerticalGridDirection, floor(#utilityItems / 15) + 1)

	ProcessAndCreateButtons(utilityButton, utilityItems)

	local buffItems = {}

	cooldownIDs = C_CooldownViewer.GetCooldownViewerCategorySet(2, true)
	for _, cooldownID in ipairs(cooldownIDs) do
		local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
		local data = cooldownInfoByID[cooldownID]

		if info and data then
			local spellID = GetSpellIDForCooldownInfo(info)
			local configID = GetCooldownConfigKey(cooldownID)
			info.spellID = spellID

			if configID and not SCM:IsSpellInData(cooldownID, data.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID) then
				table.insert(buffItems, { info = info, data = data, cooldownID = cooldownID, targetCategory = Enum.CooldownViewerCategory.TrackedBuff })
			end
		end
	end

	cooldownIDs = C_CooldownViewer.GetCooldownViewerCategorySet(3, true)
	for _, cooldownID in ipairs(cooldownIDs) do
		local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
		local data = cooldownInfoByID[cooldownID]

		if info and data and type(data.category) == "number" and data.category <= 3 then
			local spellID = GetSpellIDForCooldownInfo(info)
			local configID = GetCooldownConfigKey(cooldownID)
			info.spellID = spellID

			if configID and not SCM:IsSpellInData(cooldownID, data.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID) then
				table.insert(buffItems, { info = info, data = data, cooldownID = cooldownID, targetCategory = Enum.CooldownViewerCategory.TrackedBuff })
			end
		end
	end

	buffButton:SetGridMode(MenuConstants.VerticalGridDirection, floor(#buffItems / 15) + 1)

	ProcessAndCreateButtons(buffButton, buffItems, true)

	rootDescription:CreateDivider()

	local customButton = rootDescription:CreateButton("Custom")
	CreateCustomIconButtons(customButton, scrollFrame, anchorIndex, false, customButtonConfigs)

	if CreateCategoryObjectLookup and CooldownViewerSettingsDataProvider_GetCategories then
		local copyFromButton = rootDescription:CreateButton("Copy From")
		local lookup = CreateCategoryObjectLookup()

		for _, sourceCategory in ipairs(CooldownViewerSettingsDataProvider_GetCategories()) do
			local category = sourceCategory >= 0 and sourceCategory < 3 and lookup[sourceCategory]

			if category then
				copyFromButton:CreateButton(category.title, function()
					local dataProvider = CooldownViewerSettings:GetDataProvider()
					local displayData = dataProvider and dataProvider.displayData
					if not displayData then
						return
					end

					for _, cooldownID in ipairs(displayData.orderedCooldownIDs) do
						local data = displayData.cooldownInfoByID[cooldownID]
						local configID = data and data.category == sourceCategory and GetCooldownConfigKey(cooldownID)

						if configID and not SCM:IsSpellInData(cooldownID, data.category) and not DoesScrollFrameContainSpellConfig(scrollFrame, configID, cooldownID) then
							local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
							if info then
								info.spellID = GetSpellIDForCooldownInfo(info)
								info.cooldownID = cooldownID
								info.configID = configID
								info.isDisabled = false
								info.category = data.category

								local dataIndex = scrollFrame:AddSpellBySpellID(info)
								SCM:AddSpellToConfig(anchorIndex, dataIndex, info, data, sourceCategory)
							end
						end
					end

					ApplyModeConfigUpdate(anchorIndex, mode)
				end)
			end
		end
	end

	for _, customEntry in pairs(SCM.CustomEntries) do
		customEntry(rootDescription, scrollFrame, anchorIndex)
	end
end
