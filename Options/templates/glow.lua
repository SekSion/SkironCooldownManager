local addonName, SCM = ...

local AceGUI = LibStub("AceGUI-3.0")
local Templates = SCM.Templates

local function DoLayouts(widget, options)
	widget:DoLayout()

	if not options or type(options.layoutParents) ~= "table" then
		return
	end

	for _, parent in ipairs(options.layoutParents) do
		if parent and parent.DoLayout then
			parent:DoLayout()
		end
	end
end

function Templates.AddGlowOffsetOptions(dynamicGlowSettingsGroup, glowTypeOptions)
	local xOffset = AceGUI:Create("Slider")
	xOffset:SetRelativeWidth(0.33)
	xOffset:SetValue(glowTypeOptions.xOffset or 0)
	xOffset:SetLabel("X Offset")
	xOffset:SetSliderValues(-30, 30, 1)
	xOffset:SetCallback("OnValueChanged", function(_, _, value)
		glowTypeOptions.xOffset = value
	end)
	dynamicGlowSettingsGroup:AddChild(xOffset)

	local yOffset = AceGUI:Create("Slider")
	yOffset:SetRelativeWidth(0.33)
	yOffset:SetValue(glowTypeOptions.yOffset or 0)
	yOffset:SetLabel("Y Offset")
	yOffset:SetSliderValues(-30, 30, 1)
	yOffset:SetCallback("OnValueChanged", function(_, _, value)
		glowTypeOptions.yOffset = value
	end)
	dynamicGlowSettingsGroup:AddChild(yOffset)
end

function Templates.AddGlowColorOption(dynamicGlowSettingsGroup, glowTypeOptions)
	local glowColor = AceGUI:Create("ColorPicker")
	glowColor:SetRelativeWidth(0.33)
	glowColor:SetLabel("Glow Color")
	glowColor:SetHasAlpha(true)
	glowColor:SetColor(unpack(glowTypeOptions.glowColor or {1, 1, 1, 1}))
	glowColor:SetCallback("OnValueChanged", function(_, _, r, g, b, a)
		glowTypeOptions.glowColor = { r, g, b, a }
	end)
	dynamicGlowSettingsGroup:AddChild(glowColor)
end

function Templates.AddCustomGlowOptions(dynamicGlowSettingsGroup, config)
	dynamicGlowSettingsGroup:ReleaseChildren()

	config.glowType = config.glowType or "Pixel"
	config.glowTypeOptions = config.glowTypeOptions or {}
	config.glowTypeOptions[config.glowType] = config.glowTypeOptions[config.glowType] or {}
	local glowTypeOptions = config.glowTypeOptions[config.glowType]
	if config.glowType == "Proc" then
		local startAnim = AceGUI:Create("CheckBox")
		startAnim:SetRelativeWidth(0.33)
		startAnim:SetValue(glowTypeOptions.startAnim)
		startAnim:SetLabel("Start Animation")
		startAnim:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.startAnim = value
		end)
		dynamicGlowSettingsGroup:AddChild(startAnim)

		Templates.AddGlowOffsetOptions(dynamicGlowSettingsGroup, glowTypeOptions)
		Templates.AddGlowColorOption(dynamicGlowSettingsGroup, glowTypeOptions)
	elseif config.glowType == "Autocast" then
		--color,numParticles,frequency,scale,xOffset,yOffset

		local numParticles = AceGUI:Create("Slider")
		numParticles:SetRelativeWidth(0.33)
		numParticles:SetValue(glowTypeOptions.numParticles or 4)
		numParticles:SetLabel("Particles")
		numParticles:SetSliderValues(1, 30, 1)
		numParticles:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.numParticles = value
		end)
		dynamicGlowSettingsGroup:AddChild(numParticles)

		local frequency = AceGUI:Create("Slider")
		frequency:SetRelativeWidth(0.33)
		frequency:SetValue(glowTypeOptions.frequency or 0.125)
		frequency:SetLabel("Frequency")
		frequency:SetSliderValues(-3, 3, 0.05)
		frequency:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.frequency = value
		end)
		dynamicGlowSettingsGroup:AddChild(frequency)

		local scale = AceGUI:Create("Slider")
		scale:SetRelativeWidth(0.33)
		scale:SetValue(glowTypeOptions.scale or 1)
		scale:SetLabel("Scale")
		scale:SetSliderValues(0.01, 5, 0.1)
		scale:SetIsPercent(true)
		scale:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.scale = value
		end)
		dynamicGlowSettingsGroup:AddChild(scale)

		Templates.AddGlowOffsetOptions(dynamicGlowSettingsGroup, glowTypeOptions)
		Templates.AddGlowColorOption(dynamicGlowSettingsGroup, glowTypeOptions)
	elseif config.glowType == "Pixel" then
		--color,numLines,frequency,length,thickness,xOffset,yOffset,border

		local numLines = AceGUI:Create("Slider")
		numLines:SetRelativeWidth(0.33)
		numLines:SetValue(glowTypeOptions.numLines or 8)
		numLines:SetLabel("Lines")
		numLines:SetSliderValues(1, 30, 1)
		numLines:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.numLines = value
		end)
		dynamicGlowSettingsGroup:AddChild(numLines)

		local frequency = AceGUI:Create("Slider")
		frequency:SetRelativeWidth(0.33)
		frequency:SetValue(glowTypeOptions.frequency or 0.25)
		frequency:SetLabel("Frequency")
		frequency:SetSliderValues(-3, 3, 0.05)
		frequency:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.frequency = value
		end)
		dynamicGlowSettingsGroup:AddChild(frequency)

		local length = AceGUI:Create("Slider")
		length:SetRelativeWidth(0.33)
		length:SetValue(glowTypeOptions.length or 2)
		length:SetLabel("Length")
		length:SetSliderValues(1, 15, 0.05)
		length:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.length = value
		end)
		dynamicGlowSettingsGroup:AddChild(length)

		local thickness = AceGUI:Create("Slider")
		thickness:SetRelativeWidth(0.33)
		thickness:SetValue(glowTypeOptions.thickness or 2)
		thickness:SetLabel("Thickness")
		thickness:SetSliderValues(1, 15, 0.05)
		thickness:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.thickness = value
		end)
		dynamicGlowSettingsGroup:AddChild(thickness)

		Templates.AddGlowOffsetOptions(dynamicGlowSettingsGroup, glowTypeOptions)
		Templates.AddGlowColorOption(dynamicGlowSettingsGroup, glowTypeOptions)

		local border = AceGUI:Create("CheckBox")
		border:SetRelativeWidth(0.33)
		border:SetValue(glowTypeOptions.border)
		border:SetLabel("Border")
		border:SetCallback("OnValueChanged", function(self, event, value)
			glowTypeOptions.border = value
		end)
		dynamicGlowSettingsGroup:AddChild(border)
	end
end

function Templates.AddGlowOptions(widget, config, options)
	options = options or {}
	config.glowType = config.glowType or "Pixel"

	local glowType = AceGUI:Create("Dropdown")
	glowType:SetRelativeWidth(0.5)
	glowType:SetLabel("Custom Glow Type")
	glowType:SetList({
		["Pixel"] = "Pixel Glow",
		["Autocast"] = "Autocast Glow",
		["Proc"] = "Proc Glow",
	})
	widget:AddChild(glowType)

	local dynamicGlowSettingsGroup = AceGUI:Create("InlineGroup")
	dynamicGlowSettingsGroup:SetLayout("flow")
	dynamicGlowSettingsGroup:SetFullWidth(true)
	widget:AddChild(dynamicGlowSettingsGroup)
	glowType:SetCallback("OnValueChanged", function(_, _, value)
		config.glowType = value
		if options.onGlowTypeChanged then
			options.onGlowTypeChanged(value, config)
		end

		Templates.AddCustomGlowOptions(dynamicGlowSettingsGroup, config)
		DoLayouts(widget, options)
	end)

	glowType:SetValue(config.glowType)
	Templates.AddCustomGlowOptions(dynamicGlowSettingsGroup, config)
	DoLayouts(widget, options)
end
