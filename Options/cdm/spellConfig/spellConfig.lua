local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM

function CDMOptions.ApplyIconConfigUpdate(buttonFrame, buttonData, anchorIndex, mode, isGlobal, isBuffBar)
	if buttonFrame.data.isCustom then
		SCM:CreateAllCustomIcons(buttonData.iconType)
		SCM:ApplyAnchorGroupCDManagerConfig(anchorIndex, isGlobal)
		return
	end
	Options.ApplyModeConfigUpdate(anchorIndex, mode)
end

function CDMOptions.CreateSpellConfig(self, widget, anchorOptions, parentWidget, scrollFrame, data, anchorIndex, mode, options, isProfileConfig)
	CDMOptions.CreateSpellConfigScrollFrame(anchorIndex, mode, self, anchorOptions, scrollFrame)
end
