local SCM = select(2, ...)
local States = SCM.States

function States.InitializeState(child)
    if not child.SCMState then
        child.SCMState = {}
    end

    return child.SCMState
end

function States.SetCooldownState(child, isOnCooldown)
    local state = States.InitializeState(child)

    state.Changed = state.Changed or state.Cooldown ~= isOnCooldown
    state.Cooldown = isOnCooldown
end

function States.SetActiveState(child, isActive)
    local state = States.InitializeState(child)

    state.Active = state.Changed or state.Cooldown ~= isActive
    state.Active = isActive
end
