local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM
local AceGUI = LibStub("AceGUI-3.0")

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

function CDMOptions.CreateLoadTabSettings(iconSettingsTabs, iconSettings, scrollFrame, buttonFrame, buttonData, buttonConfig, anchorIndex, mode, isGlobal, isBuffBar)
	if buttonData.isCustom then
		if isGlobal then
			local useLoadClass = AceGUI:Create("CheckBox")
			useLoadClass:SetLabel("Class")
			useLoadClass:SetRelativeWidth(0.5)
			useLoadClass:SetValue(buttonConfig.useLoadClass)
			iconSettingsTabs:AddChild(useLoadClass)

			local loadClass = AceGUI:Create("Dropdown")
			loadClass:SetRelativeWidth(0.5)
			loadClass:SetLabel("Classes")
			loadClass:SetList(SCM.Utils.GetClassList(false))
			loadClass:SetMultiselect(true)
			loadClass:SetDisabled(not buttonConfig.useLoadClass)
			loadClass:SetCallback("OnValueChanged", function(_, _, key, value)
				buttonConfig.loadClasses = buttonConfig.loadClasses or GetDefaultCustomIconLoadClasses()
				buttonConfig.loadClasses[key] = value
				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)

			if not buttonConfig.loadClasses then
				buttonConfig.loadClasses = GetDefaultCustomIconLoadClasses()
			end

			for key, value in pairs(buttonConfig.loadClasses) do
				loadClass:SetItemValue(key, value)
			end

			useLoadClass:SetCallback("OnValueChanged", function(self, event, value)
				buttonConfig.useLoadClass = value or nil
				loadClass:SetDisabled(not value)
				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)

			iconSettingsTabs:AddChild(loadClass)

			local useLoadRole = AceGUI:Create("CheckBox")
			useLoadRole:SetLabel("Role")
			useLoadRole:SetRelativeWidth(0.5)
			useLoadRole:SetValue(buttonConfig.useLoadRole)
			iconSettingsTabs:AddChild(useLoadRole)

			local loadRole = AceGUI:Create("Dropdown")
			loadRole:SetRelativeWidth(0.5)
			loadRole:SetLabel("Roles")
			loadRole:SetList(SCM.Constants.Roles)
			loadRole:SetMultiselect(true)
			loadRole:SetDisabled(not buttonConfig.useLoadRole)
			loadRole:SetCallback("OnValueChanged", function(_, _, key, value)
				buttonConfig.loadRoles = buttonConfig.loadRoles or {}
				buttonConfig.loadRoles[key] = value
				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)

			if not buttonConfig.loadRoles then
				buttonConfig.loadRoles = { ["TANK"] = false, ["HEALER"] = false, ["DAMAGER"] = false }
			end

			for key, value in pairs(buttonConfig.loadRoles) do
				loadRole:SetItemValue(key, value)
			end

			useLoadRole:SetCallback("OnValueChanged", function(self, event, value)
				buttonConfig.useLoadRole = value or nil
				loadRole:SetDisabled(not value)
				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)

			iconSettingsTabs:AddChild(loadRole)

			local useLoadRace = AceGUI:Create("CheckBox")
			useLoadRace:SetLabel("Race")
			useLoadRace:SetRelativeWidth(0.5)
			useLoadRace:SetValue(buttonConfig.useLoadRace)
			iconSettingsTabs:AddChild(useLoadRace)

			local loadRaces = AceGUI:Create("Dropdown")
			loadRaces:SetRelativeWidth(0.5)
			loadRaces:SetLabel("Races")
			loadRaces:SetList(GetDefaultLoadRaceNames())
			loadRaces:SetMultiselect(true)
			loadRaces:SetDisabled(not buttonConfig.useLoadRace)
			loadRaces:SetCallback("OnValueChanged", function(_, _, key, value)
				buttonConfig.loadRaces = buttonConfig.loadRaces or CustomIcons.GetDefaultLoadRaces()
				buttonConfig.loadRaces[key] = value

				if type(Constants.Races[key]) == "number" then
					buttonConfig.loadRaces[Constants.Races[key]] = value
				end

				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)

			if not buttonConfig.loadRaces then
				buttonConfig.loadRaces = CustomIcons.GetDefaultLoadRaces()
			end

			for key, value in pairs(buttonConfig.loadRaces) do
				loadRaces:SetItemValue(key, value)
			end

			useLoadRace:SetCallback("OnValueChanged", function(self, event, value)
				buttonConfig.useLoadRace = value or nil
				loadRaces:SetDisabled(not value)
				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)

			iconSettingsTabs:AddChild(loadRaces)

			local useSpellKnown = AceGUI:Create("CheckBox")
			useSpellKnown:SetLabel(buttonConfig.useSpellKnown == nil and "|cFFFF0000Spell Not Known" or "Spell Known")
			useSpellKnown:SetRelativeWidth(0.5)
			useSpellKnown:SetValue(buttonConfig.useSpellKnown)
			useSpellKnown:SetTriState(true)
			iconSettingsTabs:AddChild(useSpellKnown)

			local loadSpellKnown = AceGUI:Create("EditBox")
			loadSpellKnown:SetRelativeWidth(0.5)
			loadSpellKnown:SetLabel("SpellID")
			loadSpellKnown:SetText(buttonConfig.spellKnownSpellID and tostring(buttonConfig.spellKnownSpellID) or "")
			loadSpellKnown:SetDisabled(buttonConfig.useSpellKnown == false)
			loadSpellKnown:SetCallback("OnEnterPressed", function(_, _, value)
				buttonConfig.spellKnownSpellID = tonumber(value)
				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)

			useSpellKnown:SetCallback("OnValueChanged", function(self, event, value)
				buttonConfig.useSpellKnown = value

				if buttonConfig.useSpellKnown == nil then
					useSpellKnown:SetLabel("|cFFFF0000Spell Not Known")
				else
					useSpellKnown:SetLabel("Spell Known")
				end

				loadSpellKnown:SetDisabled(buttonConfig.useSpellKnown == false)
				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)

			iconSettingsTabs:AddChild(loadSpellKnown)

			iconSettings:DoLayout()
			scrollFrame:DoLayout()
			return
		end
	end

	local label = AceGUI:Create("Label")
	label:SetRelativeWidth(1.0)
	label:SetHeight(24)
	label:SetJustifyH("CENTER")
	label:SetJustifyV("MIDDLE")
	label:SetText("|TInterface\\common\\help-i:40:40:0:0|tLoad conditions are only available for global custom icons (for now).")
	label:SetFontObject("Game12Font")
	iconSettingsTabs:AddChild(label)
end
