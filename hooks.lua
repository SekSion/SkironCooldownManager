local SCM = select(2, ...)

local pendingCustomGlowChildren = {}
local function OnSpellAlertManagerShowAlert(_, child)
	local options = SCM.db.profile.options
	if not child.SCMConfig or not options.useCustomGlow or child.SCMActiveGlow then
		if child.SCMWidth and child.SCMHeight then
			local width = child.SCMWidth
			local height = child.SCMHeight

			local alert = child.SpellActivationAlert
			alert:SetSize(width * 1.4, height * 1.4)

			if alert.ProcStartFlipbook then
				alert.ProcStartFlipbook:SetSize((width / 42) * 150, (height / 42) * 150)
			end
		end
		return
	end

	child.SCMActiveGlow = true
	child.SpellActivationAlert:Hide()

	if pendingCustomGlowChildren[child] then
		pendingCustomGlowChildren[child]:Cancel()
		pendingCustomGlowChildren[child] = nil
	end

	-- The size of the glow is too large when you start the glow immediately if anyone is wondering why I do that
	pendingCustomGlowChildren[child] = C_Timer.NewTimer(0, function()
		SCM:StartCustomGlow(child)
	end)
end

local function OnSpellAlertManagerHideAlert(_, child)
	if child.SCMConfig and child.SCMActiveGlow then
		if pendingCustomGlowChildren[child] then
			pendingCustomGlowChildren[child]:Cancel()
			pendingCustomGlowChildren[child] = nil
		end

		child.SCMActiveGlow = nil
		SCM:StopCustomGlow(child)
	end
end

local function OnEssentialCooldownViewerLayout()
	SCM:ApplyEssentialCDManagerConfig()
end

local function OnUtilityCooldownViewerLayout()
	SCM:ApplyUtilityCDManagerConfig()
end

local function OnBuffCooldownViewerLayout(viewer)
	SCM:InvalidateViewerChildrenCache(viewer)
	SCM:ApplyBuffIconCDManagerConfig()
end

local function OnBuffBarViewerLayout(viewer)
	SCM:InvalidateViewerChildrenCache(viewer)
	SCM:ApplyBuffBarCDManagerConfig()
end

local function OnCooldownViewerSettingsRefreshLayout()
	SCM.RefreshCooldownViewerData(true)
end

function SCM.SetHooks()
	hooksecurefunc(EssentialCooldownViewer, "RefreshLayout", OnEssentialCooldownViewerLayout)
	hooksecurefunc(UtilityCooldownViewer, "RefreshLayout", OnUtilityCooldownViewerLayout)
	hooksecurefunc(BuffIconCooldownViewer, "RefreshLayout", OnBuffCooldownViewerLayout)
	hooksecurefunc(BuffBarCooldownViewer, "RefreshLayout", OnBuffBarViewerLayout)
	hooksecurefunc(CooldownViewerSettings, "RefreshLayout", OnCooldownViewerSettingsRefreshLayout)

	if ActionButtonSpellAlertManager then
		hooksecurefunc(ActionButtonSpellAlertManager, "ShowAlert", OnSpellAlertManagerShowAlert)
		hooksecurefunc(ActionButtonSpellAlertManager, "HideAlert", OnSpellAlertManagerHideAlert)
	end

	hooksecurefunc(UIParent, "SetScale", function()
		SCM.RefreshCooldownViewerData(true)
	end)
end