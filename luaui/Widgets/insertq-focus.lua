function widget:GetInfo()
	return {
		name = "Insert Queue Focus",
		desc = "Nanos focus queue inserted units in factories",
		author = "Amojini",
		date = "2023-11-18",
		layer = 0,
		enabled = true,
		license = "GNU GPL, v2 or later",
	}
end

local CMD_REPAIR = CMD.REPAIR

local GetUnitPosition = Spring.GetUnitPosition
local GetUnitsInSphere = Spring.GetUnitsInSphere
local GiveOrderToUnit = Spring.GiveOrderToUnit
local GetMyTeamID = Spring.GetMyTeamID
local GetUnitDefID = Spring.GetUnitDefID
local GetFactoryCommands = Spring.GetFactoryCommands
local GetSpectatingState = Spring.GetSpectatingState
local GetGameFrame = Spring.GetGameFrame
local IsReplay = Spring.IsReplay

local gameStarted = false
local myTeam = GetMyTeamID()
local nanoDefs = {}
local factoryDefs = {}

for unitDefID, unitDef in pairs(UnitDefs) do
	if unitDef.isBuilder and not unitDef.canMove and not unitDef.isFactory then
		nanoDefs[unitDefID] = unitDef.buildDistance
	end

	if unitDef.isFactory then
		factoryDefs[unitDefID] = true
	end
end

local function maybeRemoveSelf()
	if GetSpectatingState() and (GetGameFrame() > 0 or gameStarted) then
		widgetHandler:RemoveWidget()
	end
end

function widget:PlayerChanged()
	maybeRemoveSelf()
	myTeam = GetMyTeamID()
end

function widget:GameStart()
	gameStarted = true
	maybeRemoveSelf()
end

function widget:Initialize()
	if IsReplay() or GetGameFrame() > 0 then
		maybeRemoveSelf()
	end
end

function widget:UnitCreated(unitID, _, unitTeam, builderID)
	if unitTeam ~= myTeam then
		return
	end

	if builderID == nil then
		return
	end

	if not factoryDefs[GetUnitDefID(builderID)] then
		return
	end

	local cmds = GetFactoryCommands(builderID, 1)

	if #cmds <= 0 then
		return
	end

	local isAlt = cmds[1].options.alt

	if not isAlt then
		return
	end

	local pos = { GetUnitPosition(unitID) }
	local unitsNear = GetUnitsInSphere(pos[1], pos[2], pos[3], 400) -- hardcoded to nano range - do naval nanos have longer range

	for _, id in ipairs(unitsNear) do
		if nanoDefs[GetUnitDefID(id)] ~= nil then
			GiveOrderToUnit(id, CMD_REPAIR, unitID, {})
		end
	end
end
