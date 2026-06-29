local SCM = select(2, ...)
local Options = SCM.Options
local CDMOptions = Options.CDM
local AceGUI = LibStub("AceGUI-3.0")

StaticPopupDialogs["SCM_CONFIRM_COPY_ANCHORS"] = {
	text = "Copy anchor configuration from |cFFFFFFFF%s|r?\n\nThis will overwrite the current anchor layout for |cFFFFFFFF%s|r.",
	button1 = "Copy",
	button2 = "Cancel",
	OnAccept = function(self, data)
		if data and data.callback then
			data.callback()
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

local function GetCopyClassList()
	return SCM.Utils.GetClassList(false)
end

local function GetCopySpecList(classFileName)
	return SCM.Utils.GetSpecList(classFileName)
end

function CDMOptions.CreateCopyAnchorTab(widget, frame, modeTabs)
	widget:ReleaseChildren()

	local currentClass = SCM.currentClass
	local currentSpecID = SCM.currentSpecID
	local _, currentSpecName = C_SpecializationInfo.GetSpecializationInfo(C_SpecializationInfo.GetSpecialization())
	local targetSpecDisplay = currentSpecName or tostring(currentSpecID)

	local classList = GetCopyClassList()

	local outerGroup = AceGUI:Create("SimpleGroup")
	outerGroup:SetFullWidth(true)
	outerGroup:SetLayout("flow")
	widget:AddChild(outerGroup)

	local targetLabel = AceGUI:Create("Label")
	targetLabel:SetFullWidth(true)
	targetLabel:SetText("|cFFAAAAAACopy Anchors To |r " .. (classList[currentClass] or currentClass) .. " - " .. targetSpecDisplay)
	targetLabel:SetJustifyH("CENTER")
	targetLabel:SetFont(STANDARD_TEXT_FONT, 15, "OUTLINE")
	outerGroup:AddChild(targetLabel)

	local infoLabel = AceGUI:Create("Label")
	infoLabel:SetFullWidth(true)
	infoLabel:SetText("This will only copy across anchors and their layout, spells / icons are not copied.")
	infoLabel:SetJustifyH("CENTER")
	infoLabel:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	outerGroup:AddChild(infoLabel)

	local copyFromGroup = AceGUI:Create("InlineGroup")
	copyFromGroup:SetFullWidth(true)
	copyFromGroup:SetTitle("Copy From")
	copyFromGroup:SetLayout("flow")
	outerGroup:AddChild(copyFromGroup)

	local selectedClass = nil
	local selectedSpecID = nil
	local selectedSpecDisplay = nil

	local copyBtn

	local function RefreshCopyButton()
		if not copyBtn then
			return
		end
		local isSelf = selectedClass == currentClass and selectedSpecID == currentSpecID
		local isValid = selectedClass ~= nil and selectedSpecID ~= nil and not isSelf
		copyBtn:SetDisabled(not isValid)
		if isSelf then
			copyBtn:SetText("Cannot Copy to the Same Specialization")
		else
			copyBtn:SetText("Copy Anchors")
		end
	end

	local specDropdown = AceGUI:Create("Dropdown")
	specDropdown:SetRelativeWidth(0.5)
	specDropdown:SetLabel("Specialization")
	specDropdown:SetList({})
	specDropdown:SetDisabled(true)
	specDropdown.text:SetJustifyH("LEFT")

	local classDropdown = AceGUI:Create("Dropdown")
	classDropdown:SetRelativeWidth(0.5)
	classDropdown:SetLabel("Class")
	classDropdown:SetList(classList)
	classDropdown.text:SetJustifyH("LEFT")
	classDropdown:SetCallback("OnValueChanged", function(_, _, value)
		selectedClass = value
		selectedSpecID = nil
		selectedSpecDisplay = nil
		local specList = GetCopySpecList(value)
		specDropdown:SetList(specList)
		specDropdown:SetValue(nil)
		specDropdown:SetDisabled(false)
		specDropdown.text:SetJustifyH("LEFT")
		RefreshCopyButton()
	end)
	copyFromGroup:AddChild(classDropdown)

	specDropdown:SetCallback("OnValueChanged", function(_, _, value)
		selectedSpecID = value
		local specList = GetCopySpecList(selectedClass)
		selectedSpecDisplay = specList[value]
		RefreshCopyButton()
	end)
	copyFromGroup:AddChild(specDropdown)

	copyBtn = AceGUI:Create("Button")
	copyBtn:SetText("Copy Anchors")
	copyBtn:SetFullWidth(true)
	copyBtn:SetDisabled(true)
	copyBtn:SetCallback("OnClick", function()
		StaticPopup_Show("SCM_CONFIRM_COPY_ANCHORS", selectedSpecDisplay or tostring(selectedSpecID), targetSpecDisplay, {
			callback = function()
				SCM:CopyAnchorConfig(selectedClass, selectedSpecID)
				modeTabs:SelectTab("spec")
			end,
		})
	end)
	copyFromGroup:AddChild(copyBtn)
end
