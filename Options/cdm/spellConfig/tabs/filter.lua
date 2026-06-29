local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM
local AceGUI = LibStub("AceGUI-3.0")

function CDMOptions.CreateFilterTabSettings(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, buttonConfig, anchorIndex, mode, isGlobal, isBuffBar)
	local function GetCustomItemDisplay(itemID)
		local itemName = C_Item.GetItemNameByID(itemID)
		local itemTexture = C_Item.GetItemIconByID(itemID)
		local isLoaded = itemName ~= nil and itemTexture ~= nil
		itemTexture = itemTexture or 134400
		return ("|T%s:30:30:5:0:30:30:3:27:3:27|t  %s"):format(itemTexture, itemName or ("Item ID " .. itemID)), isLoaded
	end

	buttonConfig.filterItems = buttonConfig.filterItems or {}
	buttonConfig.filterItemsArray = buttonConfig.filterItemsArray or {}

	local listContainer = AceGUI:Create("SimpleGroup")
	listContainer:SetLayout("flow")
	listContainer:SetFullWidth(true)

	local RefreshList

	local pendingItemLoads = {}
	local function RequestCustomItemLoad(itemID)
		if pendingItemLoads[itemID] then
			return
		end

		pendingItemLoads[itemID] = true
		local item = Item:CreateFromItemID(itemID)
		item:ContinueOnItemLoad(function()
			pendingItemLoads[itemID] = nil
			if listContainer.frame and listContainer.frame:IsShown() then
				RefreshList()
			end
		end)
	end

	RefreshList = function()
		listContainer:ReleaseChildren()

		for i, itemID in ipairs(buttonConfig.filterItemsArray) do
			itemID = tonumber(itemID)
			if itemID then
				local row = AceGUI:Create("SimpleGroup")
				row:SetLayout("flow")
				row:SetFullWidth(true)
				listContainer:AddChild(row)

				local label = AceGUI:Create("Label")
				local text, isLoaded = GetCustomItemDisplay(itemID)
				label:SetText(text)
				label:SetRelativeWidth(0.8)
				label:SetFontObject(GameFontHighlight)
				label:SetHeight(38)
				label:SetJustifyV("MIDDLE")
				row:AddChild(label)

				if not isLoaded then
					RequestCustomItemLoad(itemID)
				end

				local removeBtn = AceGUI:Create("Button")
				removeBtn:SetText("Delete")
				removeBtn:SetRelativeWidth(0.15)
				removeBtn:SetCallback("OnClick", function()
					buttonConfig.filterItems[itemID] = nil
					table.remove(buttonConfig.filterItemsArray, i)
					RefreshList()
					ApplyIconConfigUpdate()
				end)
				row:AddChild(removeBtn)
			end
		end

		listContainer:DoLayout()
		parentWidget:DoLayout()
		scrollFrame:DoLayout()
	end

	local addItemButton = AceGUI:Create("EditBox")
	addItemButton:SetRelativeWidth(0.8)
	addItemButton:SetLabel("Add Filter Item IDs")
	addItemButton:SetCallback("OnEnterPressed", function(self, _, value)
		local itemID = value and tonumber(value)
		if itemID and itemID > 0 and not buttonConfig.filterItems[itemID] then
			buttonConfig.filterItems[itemID] = value
			tinsert(buttonConfig.filterItemsArray, itemID)

			self:SetText("")
			RefreshList()
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
		end
	end)
	parentWidget:AddChild(addItemButton)
	parentWidget:AddChild(listContainer)

	RefreshList()
end
