local UnitBuff = UnitBuff --luacheck: ignore 113
local UnitDebuff = UnitDebuff --luacheck: ignore 113
local GridFrame
local GridTooltip2
if (IsAddOnLoaded("Plexus")) then --luacheck: ignore 113
    GridFrame = Plexus:GetModule("PlexusFrame") --luacheck: ignore 113
    GridTooltip2 = Plexus:NewModule("GridTooltip2") --luacheck: ignore 113
end
if (IsAddOnLoaded("Grid")) then --luacheck: ignore 113
    GridFrame = Grid:GetModule("GridFrame") --luacheck: ignore 113
    GridTooltip2 = Grid:NewModule("GridTooltip2") --luacheck: ignore 113
end

GridTooltip2.defaultDB = {
    enabledIndicators = {
        icon = true,
    },
}

GridTooltip2.options = {
    name = "GridTooltip2",
    desc = "Options for GridTooltip2.",
    order = 2,
    type = "group",
    childGroups = "tab",
    disabled = InCombatLockdown, --luacheck: ignore 113
    args = {
    }
}

local lastMouseOverFrame

local function FindTooltipDebuff(unit, texture, index)
    local index = index or 1 --luacheck: ignore 412
    local i = 0
    --search from the last index the texture was found to the left and right for the texture
    local name, icon, _, _, _, _, _, _, _, spellId = UnitDebuff(unit, index) --luacheck: ignore 631
    while name or index - i > 1 do
        if icon == texture then
            return index + i, spellId
        end
        i = i + 1
        _, icon, _, _, _, _, _, _, _, spellId = UnitDebuff(unit, index - i) --luacheck: ignore 631
        if icon == texture then
            return index - i, spellId
        end
        name, icon, _, _, _, _, _, _, _, spellId = UnitDebuff(unit, index + i) --luacheck: ignore 631
    end

    return nil
end

local function FindTooltipBuff(unit, texture, index)
    local index = index or 1 --luacheck: ignore 412
    local i = 0
    local name, icon, _, _, _, _, _, _, _, spellId = UnitBuff(unit, index) --luacheck: ignore 631
    while name or index - i > 1 do
        if icon == texture then
            return index + i, spellId
        end
        i = i + 1
        _, icon, _, _, _, _, _, _, _, spellId = UnitBuff(unit, index - i) --luacheck: ignore 631
        if icon == texture then
            return index - i, spellId
        end
        name, icon, _, _, _, _, _, _, _, spellId = UnitBuff(unit, index + i) --luacheck: ignore 631
    end

    return nil
end

function GridTooltip2.SetIndicator(frame, indicator, _, _, _, _, texture, _, _, _)
    if texture and GridTooltip2.db.profile.enabledIndicators[indicator] then
        if frame.unit and UnitExists(frame.unit)then --luacheck: ignore 113
            frame.ToolTip = texture
            if lastMouseOverFrame then
                GridTooltip2.OnEnter(lastMouseOverFrame)
            end
        end
    end
end



function GridTooltip2.ClearIndicator(frame, indicator)
    if GridTooltip2.db.profile.enabledIndicators[indicator] then
        frame.ToolTip = nil
        frame.ToolTipIndex = nil
    end
end

function GridTooltip2.CreateFrames(_, frame)
    frame:HookScript("OnEnter", GridTooltip2.OnEnter)
    frame:HookScript("OnLeave", GridTooltip2.OnLeave)
end

function GridTooltip2.OnEnter(frame)
    local unitid = frame.unit
    if not unitid then return end
    lastMouseOverFrame = frame

    if not frame.ToolTip then return end

    local debuff
    local buff
    if FindTooltipDebuff(unitid, frame.ToolTip, frame.ToolTipIndex) then
        frame.ToolTipIndex = FindTooltipDebuff(unitid, frame.ToolTip, frame.ToolTipIndex)
        debuff = true
    end
    if FindTooltipBuff(unitid, frame.ToolTip, frame.ToolTipIndex) then
        frame.ToolTipIndex = FindTooltipBuff(unitid, frame.ToolTip, frame.ToolTipIndex)
        buff = true
    end


    if debuff then
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent) --luacheck: ignore 113
        GameTooltip:SetUnitDebuff(unitid, frame.ToolTipIndex) --luacheck: ignore 113
        GameTooltip:Show() --luacheck: ignore 113
    end

    if buff then
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent) --luacheck: ignore 113
        GameTooltip:SetUnitBuff(unitid, frame.ToolTipIndex) --luacheck: ignore 113
        GameTooltip:Show() --luacheck: ignore 113
    end
end

function GridTooltip2.OnLeave(iconFrame)
    GameTooltip:Hide() --luacheck: ignore 113
    if lastMouseOverFrame == iconFrame then
        lastMouseOverFrame = nil
    end
end

function GridTooltip2:OnInitialize()
    if not self.db then
        self.db = Grid.db:RegisterNamespace(self.moduleName, { profile = self.defaultDB or { } }) --luacheck: ignore 113
    end

    GridTooltip2.knownIndicators = {}

    GridFrame:RegisterIndicator("tooltip", "Tooltip dummy. Do not use!",
        function(frame)
            GridTooltip2.CreateFrames(nil, frame)
            return {}
        end,

        function(self) --luacheck: ignore 432
            local indicators = self.__owner.indicators
            for id, _ in pairs(indicators) do
                if not GridTooltip2.knownIndicators[id] then
                    GridTooltip2.options.args[id] = {
                        name = id,
                        desc = "Display tooltip for indicator: "..GridFrame.indicators[id].name,
                        order = 60, width = "double",
                        type = "toggle",
                        get = function()
                            return GridTooltip2.db.profile.enabledIndicators[id]
                        end,
                        set = function(_, v)
                            GridTooltip2.db.profile.enabledIndicators[id] = v
                        end,
                    }
                    GridTooltip2.knownIndicators[id] = true
                end
            end
        end,

        function()
        end,
        function()
        end
    )
    hooksecurefunc(GridFrame.prototype, "SetIndicator", GridTooltip2.SetIndicator) --luacheck: ignore 113
    hooksecurefunc(GridFrame.prototype, "ClearIndicator", GridTooltip2.ClearIndicator) --luacheck: ignore 113
end

function GridTooltip2:OnEnable() --luacheck: ignore 212
end

function GridTooltip2:OnDisable() --luacheck: ignore 212
end

function GridTooltip2:Reset(frame) --luacheck: ignore 212
end