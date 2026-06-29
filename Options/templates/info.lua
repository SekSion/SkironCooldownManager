local addonName, SCM = ...

local AceGUI = LibStub("AceGUI-3.0")
local Templates = SCM.Templates

function Templates.AddInfoLabel(parent, text, options)
	options = options or {}

	local label = AceGUI:Create("Label")
	label:SetRelativeWidth(options.relativeWidth or 1.0)
	label:SetHeight(options.height or 24)
	label:SetJustifyH(options.justifyH or "CENTER")
	label:SetJustifyV(options.justifyV or "MIDDLE")
	label:SetText(text)
	label:SetFontObject(options.fontObject or "Game12Font")
	parent:AddChild(label)

	return label
end
