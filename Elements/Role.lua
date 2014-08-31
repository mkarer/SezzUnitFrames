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

	if (strRole == nil) then
		strRole = unit:GetRole();
	end

	if (not strRole or strRole == "DAMAGER") then
		wndrole:SetSprite(nil);
	elseif (strRole == "HEALER") then
		wndrole:SetSprite("SezzUF_RoleHealer");
	elseif (strRole == "TANK") then
		wndrole:SetSprite("SezzUF_RoleTank");
	end
end

function Element:OnGroupUnitRoleChanged(nIndex)
	local unit = self.tUnitFrame.unit;

	if (unit.nMemberIdx and unit.nMemberIdx == nIndex) then
		self:Update(unit:GetRole());
	end
end

function Element:Enable()
	-- Register Events
	if (not self.tUnitFrame.unit.nMemberIdx) then
		return self:Disable();
	end

	if (self.bEnabled) then
		-- Update on unit changes
		return self:Update();
	end

	self.bEnabled = true;
	Apollo.RegisterEventHandler("Sezz_GroupUnitRoleChanged", "OnGroupUnitRoleChanged", self);
	self:Update();
end

function Element:Disable(bForce)
	-- Unregister Events
	if (not self.bEnabled and not bForce) then return; end

	self.bEnabled = false;
	Apollo.RemoveEventHandler("Sezz_GroupUnitRoleChanged", self);
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
