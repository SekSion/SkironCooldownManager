local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM
local AceGUI = LibStub("AceGUI-3.0")


function CDMOptions.CreateCooldownTabSettings(iconSettingsTabs, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)

	local hideCountdownNumbers = AceGUI:Create("CheckBox")
	hideCountdownNumbers:SetRelativeWidth(0.5)
	hideCountdownNumbers:SetValue(iconConfig.hideCountdownNumbers)
	hideCountdownNumbers:SetLabel("Hide Timer Text")
	hideCountdownNumbers:SetCallback("OnValueChanged", function(self, event, value)
		iconConfig.hideCountdownNumbers = value or nil
		CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
	end)
	iconSettingsTabs:AddChild(hideCountdownNumbers)

	if buttonData.iconType ~= "timer" then
		local expCooldownThing = AceGUI:Create("CheckBox")
		expCooldownThing:SetLabel("Experimental Anchoring")
		expCooldownThing:SetRelativeWidth(0.5)
		expCooldownThing:SetValue(iconConfig.expCooldownThing)
		expCooldownThing:SetCallback("OnValueChanged", function(self, event, value)
			iconConfig.expCooldownThing = value or nil
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
		end)
		iconSettingsTabs:AddChild(expCooldownThing)

		if buttonData.isCustom then
			local showGCD = AceGUI:Create("CheckBox")
			showGCD:SetLabel("Show GCD")
			showGCD:SetRelativeWidth(0.5)
			showGCD:SetValue(iconConfig.showGCD)
			showGCD:SetCallback("OnValueChanged", function(self, event, value)
				iconConfig.showGCD = value or nil
				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)
			iconSettingsTabs:AddChild(showGCD)
		else
			local forceActiveSwipe = AceGUI:Create("CheckBox")
			forceActiveSwipe:SetLabel("Force Active Swipe")
			forceActiveSwipe:SetRelativeWidth(0.5)
			forceActiveSwipe:SetValue(iconConfig.forceActiveSwipe)
			forceActiveSwipe:SetCallback("OnValueChanged", function(self, event, value)
				iconConfig.forceActiveSwipe = value or nil
				CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
			end)
			iconSettingsTabs:AddChild(forceActiveSwipe)
		end
	end
end