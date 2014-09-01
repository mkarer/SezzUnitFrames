--[[

	s:UI Unit Frame Element: Leader/Assistant Icon

	Martin Karer / Sezz, 2014
	http://www.sezz.at

--]]

local MAJOR, MINOR = "Sezz:UnitFrameElement:Leader-0.1", 1;
local APkg = Apollo.GetPackage(MAJOR);
if (APkg and (APkg.nVersion or 0) >= MINOR) then return; end

local Element = APkg and APkg.tPackage or {};
local log, UnitFrameController;

-- Lua API
local setmetatable = setmetatable;

-- WildStar API
local Apollo = Apollo;

-----------------------------------------------------------------------------

function Element:Update()
	if (not self.bEnabled) then return; end

	local unit = self.tUnitFrame.unit;
	local wndLeader = self.tUnitFrame.tControls.Leader;

	if (unit.bIsLeader) then
		wndLeader:SetSprite("SezzUF_Leader");
	elseif (unit.bRaidAssistant) then
		wndLeader:SetSprite("SezzUF_Assistant");
	else
		wndLeader:SetSprite(nil);
	end
end

function Element:OnGroupLeaderChanged(nIndex)
	local unit = self.tUnitFrame.unit;

	if (unit.nMemberIdx and unit.nMemberIdx == nIndex) then
		self:Update();
	end
end

function Element:Enable()
	-- Register Events
	if (not self.tUnitFrame.unit.nMemberIdx) then
		return self:Disable();
	elseif (self.bEnabled) then
		-- Update on unit changes
		return self:Update();
	end

	self.bEnabled = true;
	Apollo.RegisterEventHandler("Sezz_GroupLeaderChanged", "OnGroupLeaderChanged", self);
	self:Update();
end

function Element:Disable(bForce)
	-- Unregister Events
	if (not self.bEnabled and not bForce) then return; end

	self.bEnabled = false;
	Apollo.RemoveEventHandler("Sezz_GroupLeaderChanged", self);
end

local IsSupported = function(tUnitFrame)
	local bSupported = (tUnitFrame.tControls.Leader ~= nil);
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
