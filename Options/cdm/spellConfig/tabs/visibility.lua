local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM
local AceGUI = LibStub("AceGUI-3.0")


function CDMOptions.CreateVisibilityTabSettings(iconSettingsTabs, iconSettings, parentScrollFrame, buttonFrame, buttonData, iconConfig, anchorIndex, mode, isGlobal, isBuffBar)
	local options = SCM.db.profile.options

	local alwaysShow, showWhileInactive
	if buttonFrame.data.isBuffIcon or buttonData.isCustom then
		alwaysShow = AceGUI:Create("CheckBox")
		alwaysShow:SetLabel("Show Always")
		alwaysShow:SetRelativeWidth(0.5)
		alwaysShow:SetValue(iconConfig.alwaysShow)
		alwaysShow:SetDisabled((not buttonData.isCustom and not options.hideBuffsWhenInactive) or iconConfig.showWhileInactive)
		SCM.Utils.SetDisabledTooltip(alwaysShow, "Enable \"Disable 'Hide Inactive Auras'\" in Global Settings > General > Auras first or disable 'Show While Inactive'.")
		iconSettingsTabs:AddChild(alwaysShow)
		alwaysShow:SetCallback("OnValueChanged", function(self, event, value)
			iconConfig.alwaysShow = value

			if showWhileInactive then
				showWhileInactive:SetDisabled(value)
			end

			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
		end)
	end

	if buttonFrame.data.isBuffIcon then
		showWhileInactive = AceGUI:Create("CheckBox")
		showWhileInactive:SetLabel("Show While Inactive")
		showWhileInactive:SetRelativeWidth(0.5)
		showWhileInactive:SetValue(iconConfig.showWhileInactive)
		showWhileInactive:SetDisabled(not options.hideBuffsWhenInactive or iconConfig.alwaysShow)
		SCM.Utils.SetDisabledTooltip(showWhileInactive, "Enable \"Disable 'Hide Inactive Auras'\" in Global Settings > General > Auras first or disable 'Show Always'.")
		iconSettingsTabs:AddChild(showWhileInactive)
		showWhileInactive:SetCallback("OnValueChanged", function(self, event, value)
			iconConfig.showWhileInactive = value
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)

			if alwaysShow then
				alwaysShow:SetDisabled(value)
			end
		end)

		local hideWhileMounted = AceGUI:Create("CheckBox")
		hideWhileMounted:SetRelativeWidth(0.5)
		hideWhileMounted:SetValue(iconConfig.hideWhileMounted)
		hideWhileMounted:SetLabel("Hide While Mounted")
		hideWhileMounted:SetDisabled(not options.hideWhileMounted)
		hideWhileMounted:SetCallback("OnValueChanged", function(self, event, value)
			iconConfig.hideWhileMounted = value or nil
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
		end)
		iconSettingsTabs:AddChild(hideWhileMounted)
	elseif buttonData.iconType ~= "timer" then
		local hideWhileReady = AceGUI:Create("CheckBox")
		hideWhileReady:SetLabel("Hide While Ready")
		hideWhileReady:SetRelativeWidth(0.5)
		hideWhileReady:SetValue(iconConfig.hideWhenNotOnCooldown)
		hideWhileReady:SetCallback("OnValueChanged", function(self, event, value)
			iconConfig.hideWhenNotOnCooldown = value or nil
			CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
		end)
		iconSettingsTabs:AddChild(hideWhileReady)
	end
end
