local GridFrame = Grid:GetModule("GridFrame")

GridTooltip = Grid:NewModule("GridTooltip")

GridTooltip.defaultDB = {
    enabledIndicators = {
        icon = true,
    },
}


GridTooltip.options = {
	name = "GridTooltip",
	desc = "Options for GridTooltip.",
	order = 2,
	type = "group",
	childGroups = "tab",
	disabled = InCombatLockdown,
	args = {
    }
}

local lastMouseOverFrame


local function FindTooltip(unit, texture, index)
    index = index or 1
    local i = 0
    --search from the last index the texture was found to the left and right for the texture
    local name, rank, icon, count, buffType, duration, expirationTime, source, isStealable, _, id = UnitDebuff(unit, index)
    while name or index - i > 1 do 
        if icon == texture then
            return index + i, id
        end
        i = i + 1
        name, rank, icon, count, buffType, duration, expirationTime, source, isStealable, _, id  = UnitDebuff(unit, index - i)
        if icon == texture then
            return index - i, id
        end
        name, rank, icon, count, buffType, duration, expirationTime, source, isStealable, _, id  = UnitDebuff(unit, index + i)
    end
    
    return nil
end

function GridTooltip.SetIndicator(frame, indicator, color, text, value, maxValue, texture, start, duration, stack)
	
	if texture and GridTooltip.db.profile.enabledIndicators[indicator] then
        if frame.unit and UnitExists(frame.unit)then
            frame.ToolTip = texture
            if lastMouseOverFrame then
                GridTooltip.OnEnter(lastMouseOverFrame)
            end            
        end
	end
end



function GridTooltip.ClearIndicator(frame, indicator)   
    if GridTooltip.db.profile.enabledIndicators[indicator] then
        frame.ToolTip = nil
        frame.ToolTipIndex = nil
    end
end

function GridTooltip.CreateFrames(gridFrameObj, frame)
    local f = frame
    frame:HookScript("OnEnter", GridTooltip.OnEnter)
	frame:HookScript("OnLeave", GridTooltip.OnLeave)
    --frame.IconBG.frame = frame --oh god!
end

function GridTooltip.OnEnter(frame)
    local unitid = frame.unit
    if not unitid then return end   
    lastMouseOverFrame = frame
    
    if not frame.ToolTip then return end 
    
    local id
    frame.ToolTipIndex, id = FindTooltip(unitid, frame.ToolTip, frame.ToolTipIndex)

    if frame.ToolTipIndex then
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        GameTooltip:SetUnitDebuff(unitid, frame.ToolTipIndex)        
        GameTooltip:Show()
    end
end

function GridTooltip.OnLeave(iconFrame)
    GameTooltip:Hide()
    if lastMouseOverFrame == iconFrame then
        lastMouseOverFrame = nil
    end
end

function GridTooltip:OnInitialize()
    if not self.db then
		self.db = Grid.db:RegisterNamespace(self.moduleName, { profile = self.defaultDB or { } })
	end
    
    GridTooltip.knownIndicators = {}
    
    GridFrame:RegisterIndicator("tooltip", "Tooltip dummy. Do not use!",
        function(frame) -- new method
            GridTooltip.CreateFrames(nil, frame)
            return {}
        end,
        
        function(self) --reset method
            local indicators = self.__owner.indicators
            for id, indicator in pairs(indicators) do
                if not GridTooltip.knownIndicators[id] then 
                    GridTooltip.options.args[id] = {
                        name = id,
                        desc = "Display tooltip for indicator: "..GridFrame.indicators[id].name,
                        order = 60, width = "double",
                        type = "toggle",
                        get = function()
                            return GridTooltip.db.profile.enabledIndicators[id]
                        end,
                        set = function(_, v)
                            GridTooltip.db.profile.enabledIndicators[id] = v
                        end,
                    }
                    GridTooltip.knownIndicators[id] = true
                end
            end
        end,
        function() end, function() end) --set and clear methods
    
    
    
    --hook the hell out of GridFrame :-)
    hooksecurefunc(GridFrame.prototype, "SetIndicator", GridTooltip.SetIndicator)
    hooksecurefunc(GridFrame.prototype, "ClearIndicator", GridTooltip.ClearIndicator)
end

function GridTooltip:OnEnable()
end

function GridTooltip:OnDisable()
end

function GridTooltip:Reset(frame)
end