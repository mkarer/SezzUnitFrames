--[[

	s:UI Unit Frame Element: Role Icon

	Martin Karer / Sezz, 2014
	http://www.sezz.at

--]]

local MAJOR, MINOR = "Sezz:UnitFrameElement:Role-0.1", 1;
local APkg = Apollo.GetPackage(MAJOR);
if (APkg and (APkg.nVersion or 0) >= MINOR) then return; end

local Element = APkg and APkg.tPackage or {};
local log, UnitFrameController;

-- Lua API
local setmetatable = setmetatable;

-- WildStar API
local Apollo, GroupLib = Apollo, GroupLib;

-----------------------------------------------------------------------------

function Element:Update(strRole)
	if (not self.bEnabled) then return; end

	local unit = self.tUnitFrame.unit;
	local wndrole = self.tUnitFrame.tControls.Role;

	if ((strRole and strRole == "HEALER") or unit.bHealer) then
		wndrole:SetSprite("SezzUF_RoleHealer");
	elseif ((strRole and strRole == "TANK") or unit.bTank or unit.bMainTank) then
		wndrole:SetSprite("SezzUF_RoleTank");
	else
		wndrole:SetSprite(nil);
	end
end

function Element:OnGroupMemberFlagsChanged(nIndex)
	local unit = self.tUnitFrame.unit;

	if (unit.nMemberIdx and unit.nMemberIdx == nIndex) then
		-- tChangedFlags (3rd event argument) has old and new role enabled, this is useless and pretty sure a bug.
		local tFlags = GroupLib.GetGroupMember(nIndex);
		self:Update((tFlags.bTank or tFlags.bMainTank) and "TANK" or tFlags.bHealer and "HEALER" or "DAMAGER");
	end
end

--[[
function Element:OnGroupOperationResult(strName, eResult)
	local unit = self.tUnitFrame.unit;

	if (unit:GetName() == strName and eResult == GroupLib.ActionResult.MemberFlagsSuccess) then
		self:Update();
	end
end
--]]

function Element:Enable()
	-- Register Events
	if (not self.tUnitFrame.unit.nMemberIdx) then
		return self:Disable();
	end
	if (self.bEnabled) then return; end

	self.bEnabled = true;
	Apollo.RegisterEventHandler("Group_MemberFlagsChanged", "OnGroupMemberFlagsChanged", self);
--	Apollo.RegisterEventHandler("Group_Operation_Result", "OnGroupOperationResult", self);
	self:Update();
end

function Element:Disable(bForce)
	-- Unregister Events
	if (not self.bEnabled and not bForce) then return; end

	self.bEnabled = false;
	Apollo.RemoveEventHandler("Group_MemberFlagsChanged", self);
--	Apollo.RemoveEventHandler("Group_Operation_Result", self);
end

local IsSupported = function(tUnitFrame)
	local bSupported = (tUnitFrame.tControls.Role ~= nil);
--	log:debug("Unit %s supports %s: %s", tUnitFrame.strUnit, NAME, string.upper(tostring(bSupported)));

	return bSupported;
end

-----------------------------------------------------------------------------
-- Constructor
-----------------------------------------------------------------------------

function Element:New(tUnitFrame)
	if (not IsSupported(tUnitFrame)) then return; end

	local self = setmetatable({ tUnitFrame = tUnitFrame }, { __index = Element });

	-- Properties
	self.bUpdateOnUnitFrameFrameCount = false;

	-- Done
	self:Disable(true);

	return self;
end

-----------------------------------------------------------------------------
-- Apollo Registration
-----------------------------------------------------------------------------

function Element:OnLoad()
	local GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2") and Apollo.GetAddon("GeminiConsole") and Apollo.GetPackage("Gemini:Logging-1.2").tPackage;
	if (GeminiLogging) then
		log = GeminiLogging:GetLogger({
			level = GeminiLogging.DEBUG,
			pattern = "%d %n %c %l - %m",
			appender ="GeminiConsole"
		});
	else
		log = setmetatable({}, { __index = function() return function(self, ...) local args = #{...}; if (args > 1) then Print(string.format(...)); elseif (args == 1) then Print(tostring(...)); end; end; end });
	end

	UnitFrameController = Apollo.GetPackage("Sezz:UnitFrameController-0.2").tPackage;
	UnitFrameController:RegisterElement(MAJOR);
end

function Element:OnDependencyError(strDep, strError)
	return false;
end

-----------------------------------------------------------------------------

Apollo.RegisterPackage(Element, MAJOR, MINOR, { "Sezz:UnitFrameController-0.2" });
