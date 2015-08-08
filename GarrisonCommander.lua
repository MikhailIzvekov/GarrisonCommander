local me, ns = ...
ns.Configure()
local _G=_G
local HD=false
local tremove=tremove
local setmetatable=setmetatable
local getmetatable=getmetatable
local type=type
local GetAddOnMetadata=GetAddOnMetadata
local CreateFrame=CreateFrame
local wipe=wipe
local format=format
local tostring=tostring
local collectgarbage=collectgarbage
--@debug@
local collectgarbage=function() end
--@end-debug@
local GMM=false
local MP=false
local MPGoodGuy=false
local MPSwitch
local dbg=false
local trc=false
local pin=false
local baseHeight
local minHeight
local addon=addon --#self
local LE_FOLLOWER_TYPE_GARRISON_6_0=LE_FOLLOWER_TYPE_GARRISON_6_0
local LE_FOLLOWER_TYPE_SHIPYARD_6_2=LE_FOLLOWER_TYPE_SHIPYARD_6_2
ns.bigscreen=true
local tprint=print
local backdrop = {
		--bgFile="Interface\\TutorialFrame\\TutorialFrameBackground",
		bgFile="Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
		tile=true,
		tileSize=16,
		edgeSize=16,
		insets={bottom=7,left=7,right=7,top=7}
}
local dialog = {
	bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
	tile=true,
	tileSize=32,
	edgeSize=32,
	insets={bottom=5,left=5,right=5,top=5}
}
local function tcopy(obj, seen)
	if type(obj) ~= 'table' then return obj end
	if seen and seen[obj] then return seen[obj] end
	local s = seen or {}
	local res = setmetatable({}, getmetatable(obj))
	s[obj] = res
	for k, v in pairs(obj) do res[tcopy(k, s)] = tcopy(v, s) end
	return res
end

local parties


local lastTab
local new, del, copy =ns.new,ns.del,ns.copy

local function capitalize(s)
	s=tostring(s)
	return strupper(s:sub(1,1))..strlower(s:sub(2))
end
--- upvalues
--
--local AVAILABLE=AVAILABLE -- "Available"
local BUTTON_INFO=GARRISON_MISSION_TOOLTIP_NUM_REQUIRED_FOLLOWERS.. " " .. GARRISON_MISSION_PERCENT_CHANCE
--local ENVIRONMENT_SUBHEADER=ENVIRONMENT_SUBHEADER -- "Environment"
local G=C_Garrison
--local GARRISON_BUILDING_SELECT_FOLLOWER_TITLE=GARRISON_BUILDING_SELECT_FOLLOWER_TITLE -- "Select a Follower";
--local GARRISON_BUILDING_SELECT_FOLLOWER_TOOLTIP=GARRISON_BUILDING_SELECT_FOLLOWER_TOOLTIP -- "Click here to assign a Follower";
--local GARRISON_FOLLOWERS=GARRISON_FOLLOWERS -- "Followers"
--local GARRISON_FOLLOWER_CAN_COUNTER=GARRISON_FOLLOWER_CAN_COUNTER -- "This follower can counter:"
--local GARRISON_FOLLOWER_EXHAUSTED=GARRISON_FOLLOWER_EXHAUSTED -- "Recovering (1 Day)"
--local GARRISON_FOLLOWER_INACTIVE=GARRISON_FOLLOWER_INACTIVE --"Inactive"
--local GARRISON_FOLLOWER_IN_PARTY=GARRISON_FOLLOWER_IN_PARTY
--local GARRISON_FOLLOWER_ON_MISSION=GARRISON_FOLLOWER_ON_MISSION -- "On Mission"
--local GARRISON_FOLLOWER_WORKING=GARRISON_FOLLOWER_WORKING -- "Working
local GARRISON_MISSION_PERCENT_CHANCE="%d%%"-- GARRISON_MISSION_PERCENT_CHANCE
--local GARRISON_MISSION_SUCCESS=GARRISON_MISSION_SUCCESS -- "Success"
--local GARRISON_MISSION_TOOLTIP_NUM_REQUIRED_FOLLOWERS=GARRISON_MISSION_TOOLTIP_NUM_REQUIRED_FOLLOWERS -- "%d Follower mission";
--local GARRISON_PARTY_NOT_FULL_TOOLTIP=GARRISON_PARTY_NOT_FULL_TOOLTIP -- "You do not have enough followers on this mission."
--local GARRISON_MISSION_CHANCE=GARRISON_MISSION_CHANCE -- Chanche
--local GARRISON_FOLLOWER_BUSY_COLOR=GARRISON_FOLLOWER_BUSY_COLOR
--local GARRISON_FOLLOWER_INACTIVE_COLOR=GARRISON_FOLLOWER_INACTIVE_COLOR
--local GARRISON_CURRENCY=GARRISON_CURRENCY  --824
--local GARRISON_FOLLOWER_MAX_UPGRADE_QUALITY=GARRISON_FOLLOWER_MAX_UPGRADE_QUALITY -- 4
--local GARRISON_FOLLOWER_MAX_LEVEL=GARRISON_FOLLOWER_MAX_LEVEL -- 100

local GARRISON_CURRENCY=GARRISON_CURRENCY
local GetMoneyString=GetMoneyString
local SHORTDATE=SHORTDATE.. " %s"
local LEVEL=LEVEL -- Level
local MISSING=ADDON_MISSING
local NOT_COLLECTED=NOT_COLLECTED -- not collected
local GMF=GMF
local GSF=GSF
-- Frames shortcut
local GMFRewardPage=								GMF.MissionComplete
local GMFMissions=									GMF.MissionTab.MissionList
local GMFRewardSplash=								GMF.MissionTab.MissionList.CompleteDialog
local GMFMissionsListScrollFrame=					GMF.MissionTab.MissionList.listScroll
local GMFMissionListButtons=						GMF.MissionTab.MissionList.listScroll.buttons
local GMFMissionsListScrollFrameScrollChild=		GMF.MissionTab.MissionList.listScroll.scrollChild
local GMFFollowers=									GMF.FollowerTab.followerList
local GMFMissionFrameFollowers=						GMF.FollowerTab.followerList
local GMFFollowersListScrollFrame=					GMF.FollowerTab.followerList.listScroll
local GMFFollowersListScrollFrameScrollChild=		GMF.FollowerTab.followerList.listScroll.scrollChild
local GMFMissionPage=								GMF.MissionTab.MissionPage
--dictionary
local IGNORE_UNAIVALABLE_FOLLOWERS=IGNORE.. ' ' .. UNAVAILABLE
local IGNORE_UNAIVALABLE_FOLLOWERS_DETAIL= GARRISON_FOLLOWER_ON_MISSION ..',' .. GARRISON_FOLLOWER_WORKING .. ' ' .. GARRISON_FOLLOWERS .. '. ' .. GARRISON_FOLLOWER_INACTIVE .. " are always ignored"
local PARTY=PARTY -- "Party"
local SPELL_TARGET_TYPE1_DESC=capitalize(SPELL_TARGET_TYPE1_DESC) -- any
local SPELL_TARGET_TYPE4_DESC=capitalize(SPELL_TARGET_TYPE4_DESC) -- party member
local ANYONE='('..SPELL_TARGET_TYPE1_DESC..')'
local UNKNOWN_CHANCE=GARRISON_MISSION_PERCENT_CHANCE:gsub('%%d%%%%',UNKNOWN)
IGNORE_UNAIVALABLE_FOLLOWERS=capitalize(IGNORE_UNAIVALABLE_FOLLOWERS)
IGNORE_UNAIVALABLE_FOLLOWERS_DETAIL=capitalize(IGNORE_UNAIVALABLE_FOLLOWERS_DETAIL)
local UNKNOWN=UNKNOWN -- Unknown
local TYPE=TYPE -- Type
local ALL=ALL -- All
local MAXMISSIONS=8
local MINPERC=20
local BUSY_MESSAGE_FORMAT=L["Only first %1$d missions with over %2$d%% chance of success are shown"]
local BUSY_MESSAGE=format(BUSY_MESSAGE_FORMAT,MAXMISSIONS,MINPERC)
local LE_FOLLOWER_TYPE_GARRISON_6_0=_G.LE_FOLLOWER_TYPE_GARRISON_6_0
local LE_FOLLOWER_TYPE_SHIPYARD_6_2=_G.LE_FOLLOWER_TYPE_SHIPYARD_6_2

local function splitFormat(base)
	local i,s=base:find("|4.*:.*;")
	if (not i) then
		return base,base
	end
	local m0,m1=base:match("|4(.*):(.*);")
	local G=base
	local G1=G:sub(1,i-1)..m0..G:sub(s+1)
	local G2=G:sub(1,i-1)..m1..G:sub(s+1)
	return G1,G2
end
local function ShowTT(this)
	GameTooltip:SetOwner(this, "ANCHOR_TOPRIGHT")
	GameTooltip:SetText(this.tooltip)
	GameTooltip:Show()
end

local GARRISON_DURATION_DAY,GARRISON_DURATION_DAYS=splitFormat(GARRISON_DURATION_DAYS) -- "%d |4day:days;";
local GARRISON_DURATION_DAY_HOURS,GARRISON_DURATION_DAYS_HOURS=splitFormat(GARRISON_DURATION_DAYS_HOURS) -- "%d |4day:days; %d hr";
local GARRISON_DURATION_HOURS=GARRISON_DURATION_HOURS -- "%d hr";
local GARRISON_DURATION_HOURS_MINUTES=GARRISON_DURATION_HOURS_MINUTES -- "%d hr %d min";
local GARRISON_DURATION_MINUTES=GARRISON_DURATION_MINUTES -- "%d min";
local GARRISON_DURATION_SECONDS=GARRISON_DURATION_SECONDS -- "%d sec";
local AGE_HOURS="Expires in " .. GARRISON_DURATION_HOURS_MINUTES
local AGE_DAYS="Expires in " .. GARRISON_DURATION_DAYS_HOURS
-- Panel sizes
local BIGSIZEW=1220
local BIGSIZEH=662
local SIZEW=950
local SIZEH=662
local SIZEV
local GCSIZE=700
local FLSIZE=400
local BIGBUTTON=BIGSIZEW-GCSIZE
local SMALLBUTTON=BIGSIZEW-GCSIZE
local GCF
local GCFMissions
local GCFBusyStatus
local GameTooltip=GameTooltip
-- Want to know what I call!!
local GetItemInfo=GetItemInfo
local type=type
local ITEM_QUALITY_COLORS=ITEM_QUALITY_COLORS
function addon:GetDifficultyColors(perc,usePurple)
	local q=self:GetDifficultyColor(perc,usePurple)
	return q.r,q.g,q.b
end
function addon:GetQualityColor(n)
	local c=ITEM_QUALITY_COLORS[n]
	if c then
		return c.r,c.g,c.b,1
	else
		return 1,1,1,1
	end
end
function addon:GetDifficultyColor(perc,usePurple)
	if(perc >90) then
		return QuestDifficultyColors['standard']
	elseif (perc >74) then
		return QuestDifficultyColors['difficult']
	elseif(perc>49) then
		return QuestDifficultyColors['verydifficult']
	elseif(perc >20) then
		return QuestDifficultyColors['impossible']
	else
		return not usePurple and C.Silver or C.Fuchsia
	end
end
----- Local variables
--
-- Forces a table to countain other tables,
local t1={
	__index=function(t,k) if k then rawset(t,k,{}) return t[k] end end
}
local t2={
	__index=function(t,k) if k then rawset(t,k,setmetatable({},t1)) return t[k] end end
}
local followersCache={}
local followersCacheIndex={}
local dirty=false
local chardb
local db
local n=setmetatable({},{
	__index = function(t,k)
		local name=addon:GetFollowerData(k,'fullname')
		if (name and k) then rawset(t,k,name) return name else return k end
	end
})

-- Counter system
local function cleanicon(stringa)
	return (stringa:lower():gsub("%.blp$",""))
end
local counters=setmetatable({},t2)
local counterThreatIndex=setmetatable({},t2)
local counterFollowerIndex=setmetatable({},t2)


--generic table scan

local function inTable(table, value)
	if (type(table)~='table') then return false end
	if (#table > 0) then
		for i=1,#table do
			if (value==table[i]) then return true end
		end
	else
		for k,v in pairs(table) do
			if v == value then
				return true
			end
		end
	end
	return false
end



--

-- These local will became conf var
-- locally upvalued, doing my best to not interfere with other sorting modules,
-- First time i am called to verride it I save it, so I give other modules a chance to hook it, too
-- Could even do a trick and secureHook it at the expense of a double sort...
local sorters={} --#Sorters
sorters.EndTime=function (mission1, mission2)
	if type(mission1)~="table" or type(mission2) ~="table" then return true end
	local rc1,p1=pcall(G.GetFollowerMissionTimeLeftSeconds,mission1.followers[1])
	if not rc1 then p1 = mission1.durationSeconds end
	local rc2,p2=pcall(G.GetFollowerMissionTimeLeftSeconds,mission2.followers[1])
	if not rc2 then p2 = mission2.durationSeconds end
	if (p1==p2) then
		return strcmputf8i(mission1.name, mission2.name) < 0
	else
		return p1 < p2
	end
end
sorters.Chance=function (mission1, mission2)
	if type(mission1)~="table" or type(mission2) ~="table" then return end
	local p1=addon:GetParty(mission1.missionID)
	local p2=addon:GetParty(mission2.missionID)
	if (p2.full and not p1.full) then return false end
	if (p1.full and not p2.full) then return true end
	if (p1.perc==p2.perc) then
		return strcmputf8i(mission1.name, mission2.name) < 0
	else
		return p1.perc > p2.perc
	end
end
sorters.Duration=function (mission1, mission2)
	if type(mission1)~="table" or type(mission2) ~="table" then return end
	local p1=addon:GetMissionData(mission1.missionID,'improvedDurationSeconds',0)
	local p2=addon:GetMissionData(mission2.missionID,'improvedDurationSeconds',0)
	if (p1==p2) then
		return strcmputf8i(mission1.name, mission2.name) < 0
	else
		return p1 < p2
	end
end
sorters.Age=function (mission1, mission2)
	if type(mission1)~="table" or type(mission2) ~="table" then return end
	local p1=addon:GetMissionData(mission1.missionID,'offerEndTime',0)
	local p2=addon:GetMissionData(mission2.missionID,'offerEndTime',0)
	if (p1==p2) then
		return strcmputf8i(mission1.name, mission2.name) < 0
	else
		return p1 < p2
	end
end
sorters.Class=function(mission1,mission2)
	if type(mission1)~="table" or type(mission2) ~="table" then return end
	local p1=addon:GetMissionData(mission1.missionID,'class','other')
	local p2=addon:GetMissionData(mission2.missionID,'class','other')
	if (p1==p2) then
		return strcmputf8i(mission1.name, mission2.name) < 0
	else
		return p1 < p2
	end
end
sorters.Followers=function(mission1, mission2)
	if type(mission1)~="table" or type(mission2) ~="table" then return end
	local p1=addon:GetMissionData(mission1.missionID,'numFollowers',1)
	local p2=addon:GetMissionData(mission2.missionID,'numFollowers',1)
	if (p1==p2) then
		return strcmputf8i(mission1.name, mission2.name) < 0
	else
		return p1 < p2
	end
end
sorters.Xp=function (mission1, mission2)
	if type(mission1)~="table" or type(mission2) ~="table" then return end

	local p1=addon:GetMissionData(mission1.missionID,'globalXp',0)
	local p2=addon:GetMissionData(mission2.missionID,'globalXp',0)
	if (p1==p2) then
		return strcmputf8i(mission1.name, mission2.name) < 0
	else
		return p2 < p1
	end
end
addon.Garrison_SortMissions_Original=_G.Garrison_SortMissions
local Garrison_SortMissions=_G.Garrison_SortMissions
_G.Garrison_SortMissions= function(missionsList)
	if GMF:IsVisible() then
		Garrison_SortMissions(missionsList)
	end
end
function addon.Garrison_SortMissions_Chance(missionsList)
	addon:RefreshParties()
	table.sort(missionsList, sorters.Chance);
end
function addon.Garrison_SortMissions_Age(missionsList)
	--addon:RefreshParties()
	table.sort(missionsList, sorters.Age);
end
function addon.Garrison_SortMissions_Duration(missionsList)
	addon:RefreshParties()
	table.sort(missionsList, sorters.Duration);
end
function addon.Garrison_SortMissions_Followers(missionsList)
	addon:RefreshParties()
	table.sort(missionsList, sorters.Followers);
end
function addon.Garrison_SortMissions_Xp(missionsList)
	addon:RefreshParties()
	table.sort(missionsList, sorters.Xp);
end
function addon.Garrison_SortMissions_Class(missionsList)
	--addon:RefreshParties()
	table.sort(missionsList, sorters.Class);
end
function addon:ApplyMSORT(value)
	local func=self[value]
	if (type(func)=="function") then
		Garrison_SortMissions=self[value]
	else
--@debug@
		print("Could not found ",value," in addon")
--@end-debug@
	end
	self:RefreshMissions()
end

function addon:OnInitialized()
--@debug@
print("Initialize")
--@end-debug@
	self:SafeRegisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE")
	self:SafeRegisterEvent("GARRISON_MISSION_NPC_CLOSED")
	self:SafeRegisterEvent("GARRISON_MISSION_STARTED")
	for _,b in ipairs(GMF.MissionTab.MissionList.listScroll.buttons) do
		local scale=0.8
		local f,h,s=b.Title:GetFont()
		b.Title:SetFont(f,h*scale,s)
		local f,h,s=b.Summary:GetFont()
		b.Summary:SetFont(f,h*scale,s)
		addon:SafeRawHookScript(b,"OnEnter","ScriptGarrisonMissionButton_OnEnter")
		addon:SafeSecureHookScript(b,"OnClick","ScriptGarrisonMissionButton_OnClick")
	end
	self:CreatePrivateDb()
	db=self.db.global
	db.seen=nil -- Removed in 2.6.9
	db.abilities=nil -- Removed in 2.6.9
	db.lifespan=nil -- Removed in 2.6.9
	db.traits=nil -- Removed in 2.6.9
	db.types=nil -- Removed in 2.6.9
	if type(dbGAC)== "table " and type(dbGAC.namespaces)=="table" then
		dbGAC.namespaces.missionscache=nil  -- Removed in 2.6.9
		dbGAC.namespaces=nil
	end
	self:AddLabel("Appearance")
	self:AddToggle("MOVEPANEL",true,L["Unlock Panel"],L["Makes main mission panel movable"])
	self:AddToggle("BIGSCREEN",true,L["Use big screen"],L["Disabling this will give you the interface from 1.1.8, given or taken. Need to reload interface"])
	self:AddToggle("PIN",true,L["Show Garrison Commander menu"],L["Disable if you dont want the full Garrison Commander Header."])
	self:AddLabel("Mission Panel")
	self:AddToggle("IGM",true,IGNORE_UNAIVALABLE_FOLLOWERS,IGNORE_UNAIVALABLE_FOLLOWERS_DETAIL)
	self:AddToggle("IGP",true,L['Ignore "maxed"'],L["Level 100 epic followers are not used for xp only missions."])
	self:AddToggle("NOFILL",false,L["No mission prefill"],L["Disables automatic population of mission page screen. You can also press control while clicking to disable it for a single mission"])
	self:AddSelect("MSORT","Garrison_SortMissions_Original",
	{
		Garrison_SortMissions_Original=L["Original method"],
		Garrison_SortMissions_Chance=L["Success Chance"],
		Garrison_SortMissions_Followers=L["Number of followers"],
		Garrison_SortMissions_Age=L["Expiration Time"],
		Garrison_SortMissions_Xp=L["Global approx. xp reward"],
		Garrison_SortMissions_Duration=L["Duration Time"],
		Garrison_SortMissions_Class=L["Reward type"],
	},
	L["Sort missions by:"],L["Original sort restores original sorting method, whatever it was (If you have another addon sorting mission, it should kick in again)"])
	self:AddToggle("USEFUL",true,L["Enhance tooltip"],L["Adds a list of other useful followers to tooltip"])
	self:AddToggle("MAXRES",true,L["Maximize result"],L["Allows a lower success percentage for resource missions. Use /gac gui to change percentage. Default is 80%"])
	self:AddSlider("MAXRESCHANCE",80,50,100,L["Minum needed chance"],L["Applied when maximise result is enabled. Default is 80%"])
	ns.bigscreen=self:GetBoolean("BIGSCREEN")
	self:AddLabel("Followers Panel")
	self:AddSlider("MAXMISSIONS",5,1,8,L["Mission shown for follower"],nil,1)
	self:AddSlider("MINPERC",50,0,100,L["Minimun chance success under which ignore missions"],nil,5)
	self:AddToggle("ILV",true,L["Show weapon/armor level"],L["When checked, show on each follower button weapon and armor level for maxed followers"])
	self:AddToggle("IXP",true,L["Show xp to next level"],L["When checked, show on each follower button missing xp to next level"])
	self:AddToggle("UPG",true,L["Show upgrade options"],L["Only meaningful upgrades are shown"])
	self:AddToggle("NOCONFIRM",true,L["Don't ask for confirmation"],L["If checked, clicking an upgrade icon will consume the item and upgrade the follower\n|cFFFF0000NO QUESTION ASKED|r"])
	self:AddToggle("SWAPBUTTONS",false,L["Swap upgrades position"],L["IF checked, shows armors on the left and weapons on the right "])
	self:AddLabel("Buildings Panel")
	self:AddToggle("HF",false,L["Hide followers"],L["Do not show follower icon on plots"])
--@debug@
	self:AddLabel("Developers options")
	self:AddToggle("DBG",false, "Enable Debug")
	self:AddToggle("TRC",false, "Enable Trace")
	self:AddOpenCmd("show","showdata","Prints a mission score")
--@end-debug@
	self:Trigger("MSORT")
	LoadAddOn("GarrisonCommander-Broker")
--@debug@
--	assert(self:GetAgeColor(1/0))
--	assert(self:GetAgeColor(0/0))
--	assert(self:GetAgeColor(GetTime()+100))
--	assert(type(1/0)==nil)
--	assert(type(0/0)==nil)
--	assert("stringa"~=nil)
--	assert("stringa"==nil or true)
--	assert(pcall(format,"%03d %03d",tonumber(1/0) or 1,tonumber(0/0) or 2))
--@end-debug@
	self:SafeSecureHookScript("GarrisonMissionFrame","OnShow","Setup")
	return true
end
function addon:showdata(fullargs,action,missionid)
	self:Print(fullargs,",",missionid)
	missionid=tonumber(missionid)
	if missionid then
		if action=="score" then
			self:Print(self:GetMissionData(missionid,'name'),self:MissionScore(self:GetMissionData(missionid)))
		elseif action=="mission" then
			self:DumpMission(missionid)
		elseif action=="match" then
			self:TestMission(missionid)
		end
	end
end

function addon:CheckMP()
	if (IsAddOnLoaded("MasterPlan")) then
		MP=true
		ns.MP=true
		MPSwitch=true
	end
end
function addon:CheckGMM()
	if (IsAddOnLoaded("GarrisonMissionManager")) then
		GMM=true
		self:RefreshParties()
		self:RefreshMissions()
	end
end
function addon:ApplyIGM(value)
	if not GMF:IsVisible() then return end
	self:RefreshParties()
	self:RefreshMissions()
end
function addon:ApplyMAXRES(value)
	if not GMF:IsVisible() then return end
	self:RefreshParties()
	self:RefreshMissions()
end
function addon:ApplyCKMP(value)
	if (MasterPlanMissionList) then
		if (value) then
			MasterPlanMissionList:Hide()
		else
			MasterPlanMissionList:Show()
		end
	end
	self:RefreshMissions()
end
function addon:ApplyDBG(value)
	dbg=value
end
function addon:ApplyPIN(value)
	pin=value
end
function addon:ApplyTRC(value)
	trc=value
end
function addon:ApplyBIGSCREEN(value)
		if (value) then
			wipe(chardb.ignored) -- we no longer have an interface to change this settings
		end
		self:Popup(L["Must reload interface to apply"],0,
			function(this)
				addon:SetBoolean("BIGSCREEN",value)
				ReloadUI()
			end
		)
end
function addon:ApplyIGP(value)
	if not GMF:IsVisible() then return end
	self:RefreshParties()
	self:RefreshMissions()
end
function addon:ApplyMAXMISSIONS(value)
	MAXMISSIONS=value
	BUSY_MESSAGE=format(BUSY_MESSAGE_FORMAT,MAXMISSIONS,MINPERC)
end
function addon:ApplyMINPERC(value)
	MINPERC=value
	BUSY_MESSAGE=format(BUSY_MESSAGE_FORMAT,MAXMISSIONS,MINPERC)
end

function addon:IsIgnored(followerID,missionID)
	if (chardb.ignored[missionID][followerID]) then return true end
	if (chardb.totallyignored[followerID]) then return true end
end
function addon:GetAllCounters(missionID,threat,table)
	wipe(table)
	if type(counterThreatIndex[missionID]) == "table" then
		local index=counterThreatIndex[missionID][cleanicon(tostring(threat))]
		if (type(index)=="table") then
			for i=1,#index do
				tinsert(table,counters[missionID][index[i]].followerID)
			end
		end
	end
end
function addon:GetCounterBias(missionID,threat)
	local bias=-1
	local who=""
	local index=counterThreatIndex[missionID]
	local data=counters[missionID]
	if (type(index)=="table" and type(counters)=="table") then
		index=index[cleanicon(tostring(threat))]
		if (type(index) == "table") then
			local members=self:GetParty(missionID,'members',empty)
			for i=1,#index do
				local follower=data[index[i]]
				if ((tonumber(follower.bias) or -1) > bias) then
					if (tContains(members,follower.followerID)) then
						if (dbg) then
--@debug@
							print("   Choosen",self:GetFollowerData(follower.followerID,'fullname'))
--@end-debug@
						end
						bias=follower.bias
						who=follower.name
					end
				end
			end
		end
	end
	return bias,who
end
function addon:AddLine(name,status)
	local r2,g2,b2=C.Red()
	if (status==AVAILABLE) then
		r2,g2,b2=C.Green()
	elseif (status==GARRISON_FOLLOWER_WORKING) then
		r2,g2,b2=C.Orange()
	end
	GameTooltip:AddDoubleLine(name, status,nil,nil,nil,r2,g2,b2)
end
function addon:SetThreatColor(obj,threat)
	if type(threat)=="string" then
		local _,_,bias,follower,name=strsplit(":",threat)
		local color=self:GetBiasColor(tonumber(bias) or -1,nil,"Green")
		local c=C[color]
		obj.Border:SetVertexColor(c())
		return (tonumber(bias)or -1)>-1
	else
		obj.Border:SetVertexColor(C.red())
	end

end

function addon:HookedGarrisonMissionButton_AddThreatsToTooltip(missionID)
	if (ns.ns.GMC:IsVisible()) then return end
	return self:RenderTooltip(missionID)
end
function addon:AddIconsToFollower(missionID,useful,followers,members,followerTypeID)
	for followerID,icons in pairs(followers) do
		if self:GetFollowerType(followerID) == followerTypeID then
			if not tContains(members,followerID)  then
				local bias=self:GetBiasColor(followerID,missionID)
				if (not useful[followerID]) then
					local rank=self:GetAnyData(followerTypeID,followerID,'rank')
					if rank then
						useful[followerID]=format("%04d%s %s ",
							1000-rank,
							C(rank,bias),
							self:GetAnyData(followerTypeID,followerID,'coloredname')
						)
					end
				end
				for i=1,#icons do
					if (useful[followerID]) then
						useful[followerID]=format("%s |T%s:0|t",useful[followerID],icons[i].icon)
					end
				end
			end
		end
	end

end
function addon:AddFollowersToTooltip(missionID,followerTypeID)
	--local f=GarrisonMissionListTooltipThreatsFrame
	-- Adding All available followers
	if not GMF:IsVisible() and not GSF:IsVisible() then return end
	local party=self:GetParty(missionID)
	local cost=self:GetMissionData(missionID,'cost')
	local currency=self:GetMissionData(missionID,'costCurrencyTypesID')
	if cost and currency then
		local _,available,texture=GetCurrencyInfo(currency)
		GameTooltip:AddDoubleLine(TABARDVENDORCOST,format("%d |T%s:0|t",cost,texture),nil,nil,nil,C[cost>available and 'Red' or 'Green']())
	end
	local members=party.members
	if followerTypeID == LE_FOLLOWER_TYPE_SHIPYARD_6_2 then
		GameTooltip:AddLine(GARRISON_FOLLOWER_IN_PARTY)
		for _,followerID in ipairs(members) do
			GameTooltip:AddLine(self:GetShipData(followerID,'fullname'))
		end
	end
	if self:GetBoolean("USEFUL") then
		local useful=new()
		local traited=G.GetFollowersTraitsForMission(missionID)
		local buffed=G.GetBuffedFollowersForMission(missionID)
		if (type(traited)=='table') then
			self:AddIconsToFollower(missionID,useful,traited,members,followerTypeID)
		end
		if (type(buffed)=='table') then
			self:AddIconsToFollower(missionID,useful,buffed,members,followerTypeID)
		end
		if next(useful) then
			table.sort(useful)
			GameTooltip:AddDoubleLine(L["Other useful followers"],L["(Ignores low bias ones)"])
			local inactive=C(GARRISON_FOLLOWER_INACTIVE,'Red')
			for followerID,data in pairs(useful) do
				local status=self:GetFollowerStatus(followerID,true,true)
				if status ~=inactive then
					GameTooltip:AddDoubleLine(data:sub(5),status)
				end
			end
		end
		del(useful)
	end
	local perc=party.perc
	local q=self:GetDifficultyColor(perc)
	GameTooltip:AddDoubleLine(GARRISON_MISSION_SUCCESS,format(GARRISON_MISSION_PERCENT_CHANCE,perc),nil,nil,nil,q.r,q.g,q.b)
	for _,i in pairs (chardb.ignored[missionID]) do
		GameTooltip:AddLine(L["You have ignored followers"],C.Orange())
		break;
	end
	if party.goldMultiplier>1 and party.class=='gold' then
		GameTooltip:AddDoubleLine(L["Gold incremented!"],party.goldMultiplier..'x',C.Green())
	end
	if type(party.materialMultiplier)=="table" then
		for k,v in pairs(party.materialMultiplier) do
			GameTooltip:AddDoubleLine((GetCurrencyInfo(k)),v..'x',C.Green())
		end
	end
	if party.xpBonus>0 then
		GameTooltip:AddDoubleLine(L["Xp incremented!"],'+'..party.xpBonus,C.Green())
	end
	if party.isMissionTimeImproved then
		GameTooltip:AddLine(L["Mission time reduced!"],C.Green())
	end

	if (chardb.history[missionID]) then
		local tot,success=0,0
		for d,r in pairs(chardb.history[missionID]) do
			tot,success=tot+1,success + (r.success and 1 or 0)
		end
		if (tot > 0) then
			local ratio=floor(success/tot*100)
			GameTooltip:AddDoubleLine(format(L["You performed this mission %d times with a win ratio of"],tot),ratio..'%',0,1,0,self:GetDifficultyColors(ratio))
			return
		end
	end
	GameTooltip:AddLine(L["You never performed this mission"],1,0,0)
end

local function switch(flag)
	if (GCF[flag]) then
		local b=GCF[flag]
		if (b:GetChecked()) then
			b.text:SetTextColor(C.Green())
		else
			b.text:SetTextColor(C.Silver())
		end
	end
end
function addon:RefreshParties()
	addon:OnAllGarrisonMissions(function(missionID) addon:MatchMaker(missionID) end)
end
function addon:RefreshMissions(missionID)
	if (GMF:IsVisible()) then
		--@debug@
		print("Mission Refresh")
		--@end-debug@
		GarrisonMissionList_UpdateMissions()
		--GMF.MissionTab.MissionList.listScroll:update()
		print("Mission Refreshed")
	end
end

--[[
GARRISON_DURATION_DAYS = "%d |4day:days;"; changed to dual form
GARRISON_DURATION_DAYS_HOURS = "%d |4day:days; %d hr"; changed to dual form
GARRISON_DURATION_HOURS = "%d hr";
GARRISON_DURATION_HOURS_MINUTES = "%d hr %d min";
GARRISON_DURATION_MINUTES = "%d min";
GARRISON_DURATION_SECONDS = "%d sec";
--]]
local function GarrisonTimeStringToSeconds(text)
	local s = D.Deformat(text,GARRISON_DURATION_SECONDS)
	if (s) then return s end
	local m  = D.Deformat(text,GARRISON_DURATION_MINUTES)
	if m then return m end
	local h,m= D.Deformat(text,GARRISON_DURATION_HOURS_MINUTES)
	if (h) then return h*3600+m*60 end
	local h= D.Deformat(text,GARRISON_DURATION_HOURS)
	if (h) then return h*3600 end
	local d,h=D:Deformat(GARRISON_DURATION_DAY_HOURS)
	if (d) then return d*3600*24 + h*3600 end
	local d,h=D:Deformat(GARRISON_DURATION_DAYS_HOURS)
	if (d) then return d*3600*24 + h*3600 end
	local d=D:Deformat(GARRISON_DURATION_DAYS)
	if (d) then return d*3600*24 end
	local d=D:Deformat(GARRISON_DURATION_DAY)
	if (d) then return d*3600*24 end
	return 3600*24

end
function addon:SetDbDefaults(default)
	default.global=default.global or {}
	default.global["*"]={}
end
function addon:CreatePrivateDb()
	self.privatedb=self:RegisterDatabase(
		GetAddOnMetadata(me,"X-Database")..'perChar',
		{
			profile={
				ignored={
					["*"]={
					}
				},
				totallyignored={
				},
				history={
					['*']={
					}
				},
				missionControl={
					version=1,
					allowedRewards = {
						followerUpgrade=true,
						gold=true,
						itemLevel=true,
						resources=true,
						xp=true,
						scroll=true,
						apexis=true,
						oil=true,
						other=true
					},
					rewardChance={
						followerUpgrade=100,
						gold=100,
						itemLevel=100,
						resources=100,
						xp=100,
						scroll=100,
						apexis=100,
						oil=100,
						seal=100,
						other=100
					},
					rewardOrder={1,2,3,4,5,6,7,8,9,10},
					useOneChance=true,
					minimumChance = 100,
					minDuration = 0,
					maxDuration = 24,
					epicExp = false,
					skipRare=true,
					skipEpic=not addon:HasSalvageYard()
				}
			}
		},
		true)
	chardb=self.privatedb.profile

end
function addon:SetClean()
	dirty=false
end
function addon:HasSalvageYard()
	local buildings=G.GetBuildings()
	for i =1,#buildings do
		local building=buildings[i]
		if building.texPrefix=="GarrBuilding_SalvageYard_1_A" then return true end
	end
end

function addon:WipeMission(missionID)
	counters[missionID]=nil
	parties[missionID]=nil
	--collectgarbage("step")
end


function addon:EventGARRISON_MISSION_NPC_CLOSED(event,...)
--@debug@
print("NPC CLOSED")
--@end-debug@
	if (GCF) then
		self:RemoveMenu()
		GCF:Hide()
	end
end
---
--@param #string event GARRISON_MISSION_STARTED
--@param #number missionID Numeric mission id
-- After this events fires also GARRISON_MISSION_LIST_UPDATE and GARRISON_FOLLOWER_LIST_UPDATE

function addon:EventGARRISON_MISSION_STARTED(event,missionID,...)
--@debug@
	print(event,missionID,...)
--@end-debug@
	self:RefreshFollowerStatus()
	if (not GMF:IsVisible()) then
		-- Shipyard
		return
	end
	wipe(chardb.ignored[missionID])
	local party=self:GetParty(missionID)
	wipe(party.members) -- I remove preset party, so PartyCache will refill it with the ones from the actual mission
	if GMF:IsVisible() then
		self:RefreshParties()
		self:RefreshMissions()
	end
end
---
--@param #string event GARRISON_MISSION_FINISHED
--@param #number missionID Numeric mission id
-- Thsi is just a notification, nothing get really changed
-- GetMissionINfo still returns data
-- but GetPartyMissionInfo does no longer return followers.
-- Also timeleft is false
--

---
--@param #number missionID mission identifier
--@param #boolean completed I suppose it always be true...
--@oaram #boolean success Mission was succesfull
--Mission complete Sequence is:
--GARRISON_MISSION_COMPLETE_RESPONSE
--GARRISON_MISSION_BONUS_ROLL_LOOT missionID true
--GARRISON_FOLLOWER_XP_CHANGED (1 or more times
--GARRISON_MISSION_NPC_OPENED ??
--GARRISON_MISSION_BONUS_ROLL_LOOY missionID nil
--
function addon:EventGARRISON_MISSION_COMPLETE_RESPONSE(event,missionID,completed,rewards)
	chardb.history[missionID][time()]={result=100,success=rewards}
end
-----------------------------------------------------
-- Coroutines data and clock management
-----------------------------------------------------
local coroutines={
	Timers={
		func=false,
		elapsed=60,
		interval=60,
		paused=false
	},
}
function addon:ActivateButton(button,OnClick,Tooltiptext,persistent)
	button:SetScript("OnClick",function(...) self[OnClick](self,...) end )
	if (Tooltiptext) then
		button.tooltip=Tooltiptext
		button:SetScript("OnEnter",ShowTT)
		if persistent then
			button:SetScript("OnLeave",ns.OnLeave)
		else
			button:SetScript("OnLeave",ns.OnLeave)
		end
	else
		button:SetScript("OnEnter",nil)
		button:SetScript("OnLeave",nil)
	end
end

function addon:Shrink(button)
	local f=button.Toggle
	local name=f:GetName() or "Unnamed"
	if (f:GetHeight() > 200) then
		f.savedHeight=f:GetHeight()
		f:SetHeight(200)
	else
		f:SetHeight(f.savedHeight)
	end
end
do
	local s=setmetatable({},{__index=function(t,k) return 0 end})
	local FOLLOWER_STATUS_FORMAT=(ns.bigscreen and L["Followers status "] or "" )..
								C(AVAILABLE..':%d ','green') ..
								C(GARRISON_FOLLOWER_WORKING .. ":%d ",'cyan') ..
								C(GARRISON_FOLLOWER_ON_MISSION .. ":%d ",'red') ..
								C(GARRISON_FOLLOWER_INACTIVE .. ":%d","silver")
	function addon:RefreshFollowerStatus()

		wipe(s)
		for _,followerID in self:GetFollowersIterator() do
			local status=self:GetFollowerStatus(followerID)
			s[status]=s[status]+1
		end
		if (GMF.FollowerStatusInfo) then
			GMF.FollowerStatusInfo:SetWidth(0)
			GMF.FollowerStatusInfo:SetFormattedText(
				FOLLOWER_STATUS_FORMAT,
				s[AVAILABLE],
				s[GARRISON_FOLLOWER_WORKING],
				s[GARRISON_FOLLOWER_ON_MISSION],
				s[GARRISON_FOLLOWER_INACTIVE]
				)
		end
	end
	function addon:GetTotFollowers(status)
		return s[status] or 0
	end
end

local helpwindow -- pseudo static
function addon:ShowHelpWindow(button)
	if (not helpwindow) then
		helpwindow=CreateFrame("Frame",nil,GCF)
		helpwindow:EnableMouse(true)
		helpwindow:SetBackdrop(backdrop)
		helpwindow:SetBackdropColor(1,1,1,1)
		helpwindow:SetFrameStrata("TOOLTIP")
		helpwindow:Show()
		local html=CreateFrame("SimpleHTML",nil,helpwindow)
		html:SetFontObject('h1',MovieSubtitleFont);
		local f=GameFontNormalLarge
		html:SetFontObject('h2',f);
		html:SetFontObject('h3',f);
		html:SetFontObject('p',f);
		html:SetTextColor('h1',C.Blue())
		html:SetTextColor('h2',C.Orange())
		html:SetTextColor('h3',C.Red())
		html:SetTextColor('p',C.Yellow())
		local text=[[<html><body>
<h1 align="center">Garrison Commander Help</h1>
<br/>
<p align="center">GC enhances standard Garrison UI by adding a Menu header and useful information in mission button and tooltip.
Since 2.0.2, the "big screen" mode became optional. If you choosed to disable it, some feature described here will not be available
</p>
<br/>
<h2>  Button list:</h2>
<p>
* Success percent with the current followers selection guidelines<br/>
* Time since the first time we saw this mission in log<br/>
* A "Good" party composition. on each member countered mechanics are shown.<br/>
*** Green border means full counter, Orange border low level counter<br/>
</p>
<h2>Tooltip:</h2>
<p>
* Overall mission status<br/>
* All members which can possibly play a role in the mission<br/>
</p>
<h2>Button enhancement:</h2>
<p>
* In rewards, actual quantity is shown (xp, money and resources) ot iLevel (item rewards)<br/>
* Countered status<br/>
</p>
<h2>Menu Header:</h2>
<p>
* Quick selection of which follower ignore for match making<br/>
* Quick mission list order selection<br/>
</p>
<h2>Mission Control:</h2>
<p>Thanks to Motig which donated the code, we have an auto lancher for mission<br/>
You specify some criteria mission should satisfy (success chance, rewards type etc) and matching missions will be autosubmitted<br/>
</p>
]]
if (MP) then
text=text..[[
<p><br/></p>
<h3>Master Plan 0.20 or above detected</h3>
<p>Master Plan hides Garrison Commander interface for available missions<br/>
You can still use Garrison Commander Mission Control<br/>
You can switch between MP and GC interface for missions checking and unchecking "Use GC Interface" checkbox. It usually works :)
</p>
]]
end
if (GMM) then
text=text..[[
<p><br/></p>
<h3>Garrison Mission Manager Detected</h3>
<p>Garrison Mission Manager and Garrison Commander plays reasonably well together.<br/>
The red button to the right of rewards is from GMM. It spills out of button, Yes, it's designed this way. Dunno why. Ask GMM author :)<br/>
Same thing for the three red buttons in mission page.
</p>
]]
end
text=text.."</body></html>"
		--html:SetTextColor('h1',C.Red())
		--html:SetTextColor('h2',C.Orange())
		helpwindow:SetWidth(800)
		helpwindow:SetHeight(590 + (MP and 160 or 0) + (GMM and 120 or 0))
		helpwindow:SetPoint("TOPRIGHT",button,"TOPLEFT",0,0)
		html:ClearAllPoints()
		html:SetWidth(helpwindow:GetWidth()-20)
		html:SetHeight(helpwindow:GetHeight()-20)
		html:SetPoint("TOPLEFT",helpwindow,"TOPLEFT",10,-10)
		html:SetPoint("BOTTOMRIGHT",helpwindow,"BOTTOMRIGHT",-10,10)
		html:SetText(text)
		helpwindow:Show()
		return
	end
	if (helpwindow:IsVisible()) then helpwindow:Hide() else helpwindow:Show() end
end
function addon:Toggle(button)
	local f=button.Toggle
	local name=f:GetName() or "Unnamed"
	--@debug@
	print(name,f:IsShown())
	--@end-debug@
	if (f:IsShown()) then  f:Hide() else  f:Show() end
	if (button.SetChecked) then
		button:SetChecked(f:IsShown())
	end
end

function addon:CreateOptionsLayer(...)
	local o=AceGUI:Create("SimpleGroup") -- a transparent frame
	o:SetLayout("Flow")
	o:SetCallback("OnClose",function(widget) widget:Release() end)
	local totsize=0
	for i=1,select('#',...) do
		totsize=totsize+self:AddOptionToOptionsLayer(o,select(i,...))
	end
	return o,totsize
end
function addon:AddOptionToOptionsLayer(o,flag,maxsize)
--@debug@
	print("Adding option",flag)
--@end-debug@
	maxsize=tonumber(maxsize) or 140
	if (not flag) then return 0 end
	local info=self:GetVarInfo(flag)
	if (info) then
		local data={option=info}
		local widget
		if (info.type=="toggle") then
			widget=AceGUI:Create("CheckBox")
			local value=self:GetBoolean(flag)
			widget:SetValue(value)
			local color=value and "Green" or "Silver"
			widget:SetLabel(C(info.name,color))
			widget:SetWidth(max(widget.text:GetStringWidth(),maxsize))
		elseif(info.type=="select") then
			widget=AceGUI:Create("Dropdown")
			widget:SetValue(self:GetVar(flag))
			widget:SetLabel(info.name)
			widget:SetText(info.values[self:GetVar(flag)])
			widget:SetList(info.values)
			widget:SetWidth(maxsize)
		elseif (info.type=="execute") then
			widget=AceGUI:Create("Button")
			widget:SetText(info.name)
			widget:SetWidth(maxsize)
			widget:SetCallback("OnClick",function(widget,event,value)
				self[info.func](self,data,value)
			end)
		else
			widget=AceGUI:Create("Label")
			widget:SetText(info.name)
			widget:SetWidth(maxsize)
		end
		widget:SetCallback("OnValueChanged",function(widget,event,value)
			if (type(value=='boolean')) then
				local color=value and "Green" or "Silver"
				widget:SetLabel(C(info.name,color))
			end
			self[info.set](self,data,value)
		end)
		widget:SetCallback("OnEnter",function(widget)
			GameTooltip:SetOwner(widget.frame,"ANCHOR_CURSOR")
			GameTooltip:AddLine(info.desc)
			GameTooltip:Show()
		end)
		widget:SetCallback("OnLeave",function(widget)
			GameTooltip:FadeOut()
		end)
		o:AddChildren(widget)
	end
	return maxsize
end

function addon:CreateHeader()
	-- Main Garrison Commander Header
	GCF=CreateFrame("Frame","GCF",UIParent,"GarrisonCommanderTitle")
	local signature=me .. " " .. self.version
	GCF.Signature:SetText(signature)
--@alpha@
	GCF.Warning:SetText("Alpha Version")
--@end-alpha@
	-- Removing wood corner. I do it here to not derive an xml frame. This shoud play better with ui extensions
	GCF.CloseButton:Hide()
	for _,f in pairs({GCF:GetRegions()}) do
		if (f:GetObjectType()=="Texture" and f:GetAtlas()=="Garr_WoodFrameCorner") then f:Hide() end
	end
	GCF:SetFrameStrata(GMF:GetFrameStrata())
	GCF:SetFrameLevel(GMF:GetFrameLevel()-2)
	if (not ns.bigscreen) then GCF:SetHeight(GCF:GetHeight()+35) end
	baseHeight=GCF:GetHeight()
	minHeight=47
	GCF.CloseButton:SetScript("OnClick",nil)
	GCF.Pin:SetAllPoints(GCF.CloseButton)
	GCF:SetWidth(BIGSIZEW)
	GCF:SetPoint("TOP",UIParent,0,-60)
	if (self:GetBoolean("PIN")) then
		GCF.Pin:SetChecked(true)
	else
		GCF.Pin:SetChecked(false)
	end

	do
		local baseHeight=baseHeight
		local minHeight=minHeight
		local baseStrata=GCF:GetFrameStrata()
		local baseLevel=GCF:GetFrameStrata()
		local speed=3
		local function shrink(this)
			addon:RemoveMenu()
			this:SetScript("OnUpdate",function(me,ts)
				local h=me:GetHeight()
				if (h<=45) then
					me:SetHeight(45)
					me:SetScript("OnUpdate",nil)
					GCF.tooltip=L["You can open the menu clicking on the icon in top right corner"]
				else
					me:SetHeight(h-2)
				end
			end)
		end
		local function grow(this)
			this:SetScript("OnUpdate",function(me,ts)
				local h=me:GetHeight()
				if (h>=baseHeight) then
					me:SetScript("OnUpdate",nil)
					me:SetHeight(baseHeight)
					if (not me.Menu) then addon:AddMenu() end
					GCF.tooltip=nil
					me.Menu:DoLayout()
				else
					me:SetHeight(h+2)
				end
			end)
		end
		GCF.Pin.tooltip=L["Toggles Garrison Commander Menu Header on/off"]
		GCF.Pin:SetScript("OnEnter",ShowTT)
		GCF.Pin:SetScript("OnClick",function(this)
			local value=this:GetChecked()
			this:SetChecked(value)
			addon:SetBoolean("PIN",value)
			if (value) then grow(GCF) else shrink(GCF) end
		end)
	end
	GCF:EnableMouse(true)
	GCF:SetMovable(true)
	GCF:RegisterForDrag("LeftButton")
	GCF:SetScript("OnDragStart",function(frame)if (self:GetBoolean("MOVEPANEL")) then frame:StartMoving() end end)
	GCF:SetScript("OnDragStop",function(frame) frame:StopMovingOrSizing() end)
	if (ns.bigscreen) then
		-- Mission list on follower panels
		local ml=CreateFrame("Frame","GCFMissions",GMFFollowers,"GarrisonCommanderFollowerMissionList")
		ml:SetPoint("TOPLEFT",GMFFollowers,"TOPRIGHT")
		ml:SetPoint("BOTTOMLEFT",GMFFollowers,"BOTTOMRIGHT")
		--ml:SetWidth(450)
		ml:Show()
		GCFMissions=ml
		local fs=GMFFollowers:CreateFontString(nil, "BACKGROUND", "GameFontNormalHugeBlack")
		fs:SetPoint("TOPLEFT",GMFFollowers,"TOPRIGHT")
		fs:SetText(AVAILABLE)
		fs:SetWidth(250)
		fs:Show()
		GCFBusyStatus=fs
	end
	self:Trigger("MOVEPANEL")
	self.CreateHeader=function() end
end

function addon:ScriptTrace(hook,frame,...)
--@debug@
	print("Triggered " .. C(hook,"red").." script on",C(frame,"Azure"),...)
--@end-debug@
end
function addon:IsProgressMissionPage()
	return GMF:IsVisible() and GMF.MissionTab and GMF.MissionTab.MissionList.showInProgress
end
function addon:IsAvailableMissionPage()
	return GMF:IsVisible() and GMF.MissionTab:IsVisible() and not GMF.MissionTab.MissionList.showInProgress
end
function addon:IsFollowerList()
	return GMF:IsVisible() and GMFFollowers:IsVisible()
end
--GMFMissions.CompleteDialog
function addon:IsRewardPage()
	return GMF:IsVisible() and GMFMissions.CompleteDialog:IsVisible()

end
function addon:IsMissionPage()
	return GMF:IsVisible() and GMFMissionPage:IsVisible()
end
---
function addon:HookedGarrisonFollowerTooltipTemplate_SetGarrisonFollower(...)
	if not self:IsMissionPage() then
		local g=GameTooltip
		g:SetOwner(GarrisonFollowerTooltip, "ANCHOR_NONE")
		g:SetPoint("TOPLEFT",GarrisonFollowerTooltip,"BOTTOMLEFT")
		g:AddLine(L["Left Click to see available missions"],C.Green())
		g:AddLine(L["Left Click to see available missions"],C.Green())
		g:SetWidth(GarrisonFollowerTooltip:GetWidth())
		g:Show()
	end
end
function addon:HookedGarrisonFollowerButton_UpdateCounters(...)
	return self:RenderFollowerPageFollowerButton(select(2,...))
end
function addon:RenderFollowerPageFollowerButton(frame,follower,showCounters)

	if not frame.GCWep then
		frame.GCWep=frame:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
		frame.GCWep:SetPoint("BOTTOMLEFT",frame.Name,"TOPLEFT",0,2)
		frame.GCArm=frame:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
		frame.GCArm:SetPoint("TOPLEFT",frame.GCWep,"TOPRIGHT")
		frame.GCXp=frame:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
	end
	if not frame.isCollected then
		frame.GCXp:Hide()
		frame.GCWep:Hide()
		frame.GCArm:Hide()
		return
	end
	if self:GetToggle("IXP") then
		if (follower.level < GARRISON_FOLLOWER_MAX_LEVEL or follower.quality < GARRISON_FOLLOWER_MAX_UPGRADE_QUALITY) then
			frame.GCXp:SetFormattedText(L["To go: %d"],follower.levelXP-follower.xp)
			frame.GCXp:Show()
		else
			frame.GCXp:Hide()
		end
	end
	if self:GetToggle("ILV") then
		if (follower.level >= GARRISON_FOLLOWER_MAX_LEVEL) then
			local c1=ITEM_QUALITY_COLORS[self:GetFollowerData(follower.followerID,"weaponQuality" ,1)]
			local c2=ITEM_QUALITY_COLORS[self:GetFollowerData(follower.followerID,"armorQuality" ,1)]
			frame.GCWep:SetFormattedText("W:%3d",self:GetFollowerData(follower.followerID,"weaponItemLevel",600))
			frame.GCArm:SetFormattedText("A:%3d",self:GetFollowerData(follower.followerID,"armorItemLevel",600))
			frame.GCWep:SetTextColor(c1.r,c1.g,c1.b)
			frame.GCArm:SetTextColor(c2.r,c2.g,c2.b)
			frame.GCWep:Show()
			frame.GCArm:Show()
			frame.GCXp:SetPoint("LEFT",frame.GCArm,"RIGHT",2,0)
		else
			frame.GCWep:Hide()
			frame.GCArm:Hide()
			frame.GCXp:SetPoint("LEFT",frame.Name,"LEFT",0,20)
		end
	end
end
function addon:HookedGarrisonFollowerListButton_OnClick(frame,button)
--@debug@
print("Click")
--@end-debug@
	if (frame.info.isCollected) then
		if (button=="LeftButton") then
			if (ns.bigscreen and frame and frame.info and frame.info.followerID)  then
				self:HookedGarrisonFollowerPage_ShowFollower(frame.info,frame.info.followerID)
			end
		end
		self:ScheduleTimer("HookedGarrisonFollowerButton_UpdateCounters",0.2,GMF,frame,frame.info,false)
		self:ShowUpgradeButtons()
	end
end
-- Shamelessly stolen from Blizzard Code
-- Appears when hovering on menaces in mission button
function addon.ClonedGarrisonMissionMechanic_OnEnter(this)
	local tip=GameTooltip
	local button=this:GetParent()
	tip:SetOwner(button, "ANCHOR_CURSOR_RIGHT");
	tip:AddLine(this.Name,C.White())
	tip:AddTexture(this.texture)
	tip:AddLine(this.Description,C.Orange())
	if (this.countered) then
		if this.IsEnv then
			local t=G.GetFollowersTraitsForMission(this.missionID)
			for followerID,k in pairs(t) do
				for i=1,#k do
					if k[i].icon==this.texture then
						tip:AddDoubleLine(addon:GetFollowerData(followerID,'fullname'),this.Name)
					end
				end
			end
		else
			local t=G.GetBuffedFollowersForMission(this.missionID)
			for followerID,k in pairs(t) do
				for i=1,#k do
					if k[i].name==this.Name then
						tip:AddDoubleLine(addon:GetFollowerData(followerID,'fullname'),k[i].counterName)
					end
				end
			end
		end
	end
	tip:Show()
end
function addon:HookedGarrisonFollowerPage_ShowFollower(frame,followerID,force)
	return self:RenderFollowerPageMissionList(frame,followerID,force)
end
do
	local Busystatusmessage
	local lastFollowerID=""
	local ml=nil
	local tContains=tContains
	local function MissionOnClick(this,...)

--@debug@
print(this.frame,this.frame:GetName())
--@end-debug@
		GMF:OnClickMission(this.frame.info)
		if (PanelTemplates_GetSelectedTab(GMF) ~= 1) then
			addon:OpenMissionsTab()
		end
		addon:ScriptGarrisonMissionButton_OnClick(this.frame,"Leftup")
		lastTab=2
	end
	function addon:RenderFollowerPageMissionList(frame,followerID,force)
		print(ns.bigscreen,GMFFollowers:IsVisible())
		if not ns.bigscreen then return end
		if not GMFFollowers:IsVisible() then return end
		if (not ml) then
			ml=AceGUI:Create("GMCLayer")
			ml:SetTitle("Ninso")
			ml:SetTitleColor(C.Orange())
			ml:SetTitleHeight(40)
			ml:SetParent(GMFFollowers)
			ml:Show()
			ml:ClearAllPoints()
			ml:SetWidth(200)
			ml:SetHeight(600)
			ml:SetPoint("TOP",GCFMissions.Header,"BOTTOM")
			ml:SetPoint("LEFT",GMFFollowers,"RIGHT")
			ml:SetPoint("RIGHT",GMF.FollowerTab,"LEFT")
			ml:SetPoint("BOTTOM",GMF,0,25)
		end
		self:RenderFollowerButton(GCFMissions.Header,followerID)
		ml:ClearChildren()
		if (type(frame.followerID)=="number") then
			ml:SetTitle(NOT_COLLECTED)
			ml:SetTitleColor(C.Silver())
			return
		end
		local status=self:GetFollowerStatus(followerID,true)
		ml:SetTitle(status)
		if (status==GARRISON_FOLLOWER_WORKING) then
			ml:SetTitleColor(C.Cyan())
			return
		elseif (status==AVAILABLE) then
			ml:SetTitleColor(C.Green())
		else
			ml:SetTitleColor(C.Red())
			return
		end
		local partyIndex=new()
		local parties=self:GetParty()
		for missionID,party in pairs(parties) do
			if (tContains(party.members,followerID)) then tinsert(partyIndex,missionID) end
		end
		table.sort(partyIndex,function(a,b) return parties[a].perc > parties[b].perc end)
		for i=1,#partyIndex do
			local missionID=partyIndex[i]
			local party=parties[missionID]
			local mission=self:GetMissionData(missionID)
			if mission and party and #party.members >= G.GetMissionMaxFollowers(missionID) then
				local mb=AceGUI:Create("GMCMissionButton")
				mb:SetScale(0.6)
				ml:PushChild(mb,missionID)
				mb:SetFullWidth(true)
				mb:SetMission(mission,party,false,"followers")
				mb:SetCallback("OnClick",MissionOnClick)
			end
		end
		del(partyIndex)
	end
end
---
--Initial one time setup
function addon:Setup(...)
--@debug@
print("Setup")
--@end-debug@
	SIZEV=GMF:GetHeight()
	self:CheckMP()
	if MP then self:AddToggle("CKMP",true,L["Use GC Interface"],L["GCMPSWITCH"]) end
	self:CheckGMM()
	self:CreateHeader()
	local tabMC=CreateFrame("CheckButton",nil,GMF,"SpellBookSkillLineTabTemplate")
	GMF.tabMC=tabMC
	tabMC.tooltip="Open Garrison Commander Mission Control"
	tabMC:SetNormalTexture("Interface\\ICONS\\ACHIEVEMENT_GUILDPERK_WORKINGOVERTIME.blp")
	self:MarkAsNew(tabMC,'MissionControl','New in 2.2.0! Try automatic mission management!')
	tabMC:Show()
	GMF.FollowerStatusInfo=GMF:CreateFontString(nil, "BORDER", "GameFontNormal")
	GMF.FollowerStatusInfo:SetPoint("TOPRIGHT",-30,-5)
	local tabCF=CreateFrame("Button",nil,GMF,"SpellBookSkillLineTabTemplate")
	GMF.tabCF=tabCF
	tabCF.tooltip="Open Garrison Commander Configuration Screen"
	tabCF:SetNormalTexture("Interface\\ICONS\\Trade_Engineering.blp")
	tabCF:SetPushedTexture("Interface\\ICONS\\Trade_Engineering.blp")
	tabCF:Show()
	local tabHP=CreateFrame("Button",nil,GMF,"SpellBookSkillLineTabTemplate")
	GMF.tabHP=tabHP
	tabHP.tooltip="Open Garrison Commander Help"
	tabHP:SetNormalTexture("Interface\\ICONS\\INV_Misc_QuestionMark.blp")
	tabHP:SetPushedTexture("Interface\\ICONS\\INV_Misc_QuestionMark.blp")
	tabHP:Show()
	tabMC:SetScript("OnClick",function(this,...) addon:OpenMissionControlTab() end)
	tabCF:SetScript("OnClick",function(this,...) addon:Gui() end)
	tabHP:SetScript("OnClick",function(this,button) addon:ShowHelpWindow(this,button) end)
	tabHP:SetPoint('TOPLEFT',GCF,'TOPRIGHT',0,-10)
	tabCF:SetPoint('TOPLEFT',GCF,'TOPRIGHT',0,-60)
	tabMC:SetPoint('TOPLEFT',GCF,'TOPRIGHT',0,-110)
	local ref=GMFMissions.CompleteDialog.BorderFrame.ViewButton
	local bt = CreateFrame('BUTTON',nil, ref, 'UIPanelButtonTemplate')
	bt:SetWidth(300)
	bt:SetText(L["Garrison Comander Quick Mission Completion"])
	bt:SetPoint("CENTER",0,-50)
	bt.missionType=LE_FOLLOWER_TYPE_GARRISON_6_0
	addon:ActivateButton(bt,"MissionComplete",L["Complete all missions without confirmation"])
	self:SafeSecureHookScript("GarrisonMissionFrame","OnShow")
	self:Trigger("MSORT")
	local parties=self:GetParties()
	if #parties==0 then
		self:OnAllGarrisonMissions(function(missionID) addon:MatchMaker(missionID) end)
	end
	return self:ScriptGarrisonMissionFrame_OnShow()
	--collectgarbage("step",10)
--/Interface/FriendsFrame/UI-Toast-FriendOnlineIcon
end

function addon:AddMenu()
--@debug@
print("Adding Menu")
--@end-debug@
	if GCF.Menu then
		return
	end
	local menu,size=self:CreateOptionsLayer(MP and 'CKMP' or nil,'BIGSCREEN','IGM','IGP','NOFILL','MSORT','MAXRES','USEFUL')
--@debug@
	self:AddOptionToOptionsLayer(menu,'DBG')
	self:AddOptionToOptionsLayer(menu,'TRC')
--@end-debug@
	local frame=menu.frame
	frame:Show()
	frame:SetParent(GCF)
	frame:SetFrameStrata(GCF:GetFrameStrata())
	frame:SetFrameLevel(GCF:GetFrameLevel()+2)
	menu:ClearAllPoints()
	menu:SetPoint("TOPLEFT",GCF,"TOPLEFT",25,-18)
	menu:SetWidth(GCF:GetWidth()-50)
	menu:SetHeight(GCF:GetHeight()-50)
	menu:DoLayout()
	GCF.Menu=menu
end
function addon:RemoveMenu()
--@debug@
print("Removing menu")
--@end-debug@
	if (GCF.Menu) then
		local rc,message=pcall(GCF.Menu.Release,GCF.Menu)
		--@debug@
		print("Removed menu",rc,message)
		--@end-debug@
		GCF.Menu=nil
	end
end
function addon:AddMissionId(b)
	if (b.info and b.info.missionID) then
		GameTooltip:AddDoubleLine("MissionID",b.info.missionID)
		GameTooltip:Show()
	end
end
---
-- Additional setup
-- This method is called every time garrison mission panel is open because
-- when it closes, I remove most of used hooks
function addon:ScriptGarrisonMissionFrame_OnShow(...)
--@debug@
	print("GMF OnShow")
--@end-debug@
	self:GrowPanel()
	if (self:GetBoolean("PIN")) then
		GCF:SetHeight(baseHeight)
		self:AddMenu()
	else
		GCF:SetHeight(minHeight)
	end
	self:PermanentEvents()
	--self:SafeSecureHook("GarrisonMissionButton_AddThreatsToTooltip")
	self:SafeSecureHook("GarrisonFollowerListButton_OnClick") -- used both to update follower mission list and itemlevel display
	if (ns.bigscreen) then
		self:SafeSecureHook("GarrisonFollowerTooltipTemplate_SetGarrisonFollower")
	end
	for i =1,9 do
		local hook="GarrisonMissionFrameTab" ..i
		if (_G[hook]) then
			self:SafeHookScript(hook,"OnClick","HookedClickOnTabs")
		end
	end
	-- GarrisonMissionList_SetTab is overrided

	self:SafeHookScript(GMFMissions,"OnShow",true)--,"GrowPanel")
	self:SafeHookScript(GMFFollowers,"OnShow",true)--,"GrowPanel")
	self:SafeHookScript(GCF,"OnHide","CleanUp",true)
	self:SafeHookScript(GMF.FollowerTab,"OnShow","OnShow_FollowerPage",true)

	-- Mission management
	self:SafeHookScript(GMF.MissionComplete.NextMissionButton,"OnClick","OnClick_GarrisonMissionFrame_MissionComplete_NextMissionButton",true)
	self:SafeHookScript(GMFMissions.CompleteDialog,"OnShow","RaiseCompleteDialog")
	if (GMFMissions.CompleteDialog:IsVisible()) then
		self:RaiseCompleteDialog()
	end
	self:RefreshFollowerStatus()
	self:Trigger("MSORT")
	self:Trigger("CKMP")
	self:FollowerPageStartUp()
	return self:RefreshMissions()
end
function addon:RaiseCompleteDialog()
	local f=GMFMissions.CompleteDialog
	if f:GetFrameLevel() < 80 then
		f:SetFrameLevel(80)
	end
	--print("Dialog:",GMFMissions.CompleteDialog:GetFrameLevel())
	--C_Timer.After(0.1,function() local f=GMFMissions.CompleteDialog print("Dialog:",f:GetFrameLevel()) if f:GetFrameLevel() < 45 then f:SetFrameLevel(45) end print("Dialog:",f:GetFrameLevel()) end)
end

function addon:MarkAsNew(obj,key,message)
	if (not db.news[key]) then
		local f=CreateFrame("Frame",nil,obj,"GarrisonCommanderWhatsNew")
		f.tooltip=message
		f:SetPoint("BOTTOMLEFT",obj,"TOPRIGHT")
		f:Show()
	end
end

function addon:PermanentEvents()
	-- Follower button enhancement in follower list
	self:SafeSecureHook("GarrisonFollowerButton_UpdateCounters")
end
function addon:checkHandler(handler)
	assert (type(handler)=='function' or type(self[handler])=='function',format("Unable to validate hander '%s'",tostring(handler)))
end
function addon:SafeRegisterEvent(event,handler)
	handler=handler or "Event"..event
	self:checkHandler(handler)
	return self:RegisterEvent(event,handler)
end
function addon:SafeRawHook(object,method,handler)
	return self:SafeHook(object,method,handler or 'raw','raw')
end
function addon:SafeSecureHook(object,method,handler)
	return self:SafeHook(object,method,handler or 'secure','secure')
end
function addon:SafeHook(object,method,handler,hookType)
	if (self:IsHooked(object,method)) then return end
	if type(object) == "string" then
		method, handler, hookType , object = object, method, handler,nil
	end
	handler=handler or "Hooked"..method
	self:checkHandler(handler)
	if hookType=="post" or hookType=="secure" then
		self:SecureHook(object,method,handler)
	elseif hookType=="raw" then
		self:RawHook(object,method,handler,true)
	else
		self:Hook(object,method,handler)
	end
end
function addon:SafeSecureHookScript(frame,method,handler)
	return self:SafeHookScript(frame,method,handler,"secure")
end
function addon:SafeRawHookScript(frame,method,handler)
	return self:SafeHookScript(frame,method,handler,"raw")
end
function addon:SafeHookScript(frame,method,handler,hookType)
	local name="Unknown"
	if (type(frame)=="string") then
		name=frame
		frame=_G[frame]
	else
		if (frame and frame.GetName) then
			name=frame:GetName()
		end
	end
	if (frame) then
		if not handler then
			handler=format('Script%s_%s',name,method)
		elseif type(handler)=="boolean" then
--@debug@
			do
			local method=method
			handler=function(...) print(name,method,...) end
			end
--@end-debug@
--[===[@non-debug@
			return -- Trace only hook are not for public
--@end-non-debug@]===]

		end
		self:checkHandler(handler)
		if hookType and type(hookType)=="boolean" then hookType="post" end
	--This allow to change a method, for example to substitute an one time init with the standard routine
		if (self:IsHooked(frame,method)) then self:Unhook(frame,method)	end
		if hookType=="post" or hookType=="secure" then
			self:SecureHookScript(frame,method,handler)
		elseif (hookType=="raw") then
			self:RawHookScript(frame,method,handler)
		else
			self:HookScript(frame,method,handler)
		end

	end
end
local converter=CreateFrame("Frame"):CreateTexture()
local shipconv=CreateFrame("Frame",nil,nil,"GarrisonShipMissionCompleteFollowerTemplate")
function addon:GetFollowerTexture(followerID,followerType)
	followerType=followerType or LE_FOLLOWER_TYPE_GARRISON_6_0
	if (followerType==LE_FOLLOWER_TYPE_GARRISON_6_0) then
		local rc,iconID=pcall(self.GetAnyData,self,followerType,followerID,"portraitIconID")
		if rc then
			if iconID then
				converter:SetToFileData(iconID)
				return converter:GetTexture()
			end
		end
	else
		local rc,texPrefix=pcall(self.GetAnyData,self,followerType,followerID,"texPrefix")

--@debug@
print(rc,texPrefix)
--@end-debug@
		if rc then
			if texPrefix then
				shipconv.Portrait:SetAtlas(texPrefix.."-List")

--@debug@
print(shipconv.Portrait:GetTexture())
--@end-debug@
				return shipconv.Portrait:GetTexture()
			end
		end
	end
		return followerType==LE_FOLLOWER_TYPE_GARRISON_6_0 and "Interface\\Garrison\\Portraits\\FollowerPortrait_NoPortrait"
				or "Interface\\Garrison\\Portraits\\Ships_CargoShip-Portrait"
end

function addon:CleanUp()
--@debug@
	print("Cleaning up")
--@end-debug@
	self:RemoveMenu()
	if (GarrisonFollowerTooltip.fs) then
		GarrisonFollowerTooltip.fs:Hide()
	end
	GMFMissions.CompleteDialog:Hide()
	self:GetModule("MissionCompletion"):CloseReport()
	--collectgarbage("collect")
end

function addon:IsFollowerAvailableForMission(followerID,skipbusy)
	if self:GMCBusy(followerID) then
		return false
	end
	if (not skipbusy) then
		return self:GetFollowerStatus(followerID) ~= GARRISON_FOLLOWER_WORKING
	else
		return self:GetFollowerStatus(followerID) == AVAILABLE
	end
end

function addon:GetFollowerStatus(followerID,withTime,colored)
	--C_Garrison.GetFollowerMissionTimeLeftSeconds(follower.followerID)
	if (not followerID) then return UNAVAILABLE end
	local rc,status=pcall(G.GetFollowerStatus,followerID)
	if (not rc) then
--@debug@
		print("WARNING:",followerID,status)
		ns.raised=true
--@end-debug@
		return UNAVAILABLE
	end
	ns.raised=nil
	if (status and status== GARRISON_FOLLOWER_ON_MISSION and withTime) then
		status=G.GetFollowerMissionTimeLeft(followerID)
	end
-- The only case a follower appears in party is after a refused mission due to refresh triggered before GARRISON_FOLLOWER_LIST_UPDATE
	if (status and status~=GARRISON_FOLLOWER_IN_PARTY) then
		return colored and C(status,"Red") or status
	else
		return colored and C(AVAILABLE,"Green") or AVAILABLE
	end
end
local GARRISON_MISSION_AVAILABILITY1=GARRISON_MISSION_AVAILABILITY..'\n %s'
local GARRISON_MISSION_AVAILABILITY2=GARRISON_MISSION_ENVIRONMENT:sub(1,10)..GARRISON_MISSION_AVAILABILITY..':|r %s'
local GARRISON_MISSION_ID=GARRISON_MISSION_ENVIRONMENT:sub(1,10)..'MissionID:|r |cffffffff%s|r'
local fakeinfo={followerID=false}
local fakeframe={}

function addon:FillMissionPage(missionInfo)
	--@debug@
	print("FillMissionPage",missionInfo)
	--@end-debug@
	if type(missionInfo)=="number" then missionInfo=self:GetMissionData(missionInfo) end
	if not missionInfo then return end
	local missionType=missionInfo.followerTypeID
	if missionType==LE_FOLLOWER_TYPE_SHIPYARD_6_2 and not missionInfo.canStart then return end
	local stage=missionType==LE_FOLLOWER_TYPE_GARRISON_6_0 and  GMF.MissionTab.MissionPage.Stage or GSF.MissionTab.MissionPage.Stage
	if not stage.MissionSeen then
		if not stage.expires then
			stage.expires=stage:CreateFontString()
			stage.expires:SetFontObject(stage.MissionEnv:GetFontObject())
			stage.expires:SetDrawLayer(stage.MissionEnv:GetDrawLayer())
			stage.expires:SetPoint("TOPLEFT",stage.MissionEnv,"BOTTOMLEFT")
		end
		stage.expires:SetFormattedText(GARRISON_MISSION_AVAILABILITY2,missionInfo.offerTimeRemaining or "")
		stage.expires:SetTextColor(self:GetAgeColor(missionInfo.offerEndTime))
	else
		stage.expires=stage.MissionSeen -- In order to anchor missionId
	end
--@debug@
	if not stage.missionid then
		stage.missionid=stage:CreateFontString()
		stage.missionid:SetFontObject(stage.MissionEnv:GetFontObject())
		stage.missionid:SetDrawLayer(stage.MissionEnv:GetDrawLayer())
		stage.missionid:SetPoint("TOPLEFT",stage.expires,"BOTTOMLEFT")
	end
	stage.missionid:SetFormattedText(GARRISON_MISSION_ID,missionInfo.missionID)
--@end-debug@
	if( IsControlKeyDown()) then self:Print("Shift key, ignoring mission prefill") return end
	if (self:GetBoolean("NOFILL")) then return end
	local missionID=missionInfo.missionID
--@debug@
	print("UpdateMissionPage for",missionID,missionInfo.name,missionInfo.numFollowers)
--@end-debug@
	holdEvents()
	local main=missionInfo.followerTypeID==LE_FOLLOWER_TYPE_GARRISON_6_0 and GMF or GSF
	local missionpage=main.MissionTab.MissionPage
	main:ClearParty()
	local party=self:GetParty(missionID)
	if (party) then
		local members=party.members
		for i=1,missionInfo.numFollowers do
			local followerframe=missionpage.Followers[i]
			local followerID=members[i]
			if (followerID) then
				main:AssignFollowerToMission(followerframe,self:GetAnyData(missionInfo.followerTypeID,followerID))
				--	local rc,error=pcall(GarrisonMissionPage_AddFollower,followerID)
				--	if (not rc) then
				--		print("fillmissinopage",error)
				--	end
			end
		end
	else

--@debug@
print("No martini no party")
--@end-debug@
	end
	main:UpdateMissionParty(main.MissionTab.MissionPage.Followers)
	main:UpdateMissionData(main.MissionTab.MissionPage)
	--self:Dump(GMF.MissionTab.MissionPage.Followers,"Selected followers")
	--GarrisonMissionPage_UpdateEmptyString()
	releaseEvents()
end
local firstcall=true

---@function GrowPanel
-- Enforce the new panel sizes
--
function addon:GrowPanel()
	GCF:Show()
	if (ns.bigscreen) then
--		GMF:ClearAllPoints()
--		GMF:SetPoint("TOPLEFT",GCF,"BOTTOMLEFT")
--		GMF:SetPoint("TOPRIGHT",GCF,"BOTTOMRIGHT")
		GMFRewardSplash:ClearAllPoints()
		GMFRewardSplash:SetPoint("TOPLEFT",GCF,"BOTTOMLEFT")
		GMFRewardSplash:SetPoint("TOPRIGHT",GCF,"BOTTOMRIGHT")
		GMFRewardPage:ClearAllPoints()
		GMFRewardPage:SetPoint("TOPLEFT",GCF,"BOTTOMLEFT")
		GMFRewardPage:SetPoint("TOPRIGHT",GCF,"BOTTOMRIGHT")
		GMF:SetHeight(BIGSIZEH)
		GMFMissions:SetPoint("BOTTOMRIGHT",GMF,-25,35)
		GMFFollowers:SetPoint("BOTTOMLEFT",GMF,-35,65)
		GMFMissionsListScrollFrameScrollChild:ClearAllPoints()
		GMFMissionsListScrollFrameScrollChild:SetPoint("TOPLEFT",GMFMissionsListScrollFrame)
		GMFMissionsListScrollFrameScrollChild:SetPoint("BOTTOMRIGHT",GMFMissionsListScrollFrame)
		GMFFollowersListScrollFrameScrollChild:SetPoint("BOTTOMLEFT",GMFFollowersListScrollFrame,-35,35)
		GMF.MissionCompleteBackground:SetWidth(BIGSIZEW)
	else
		GCF:SetWidth(GMF:GetWidth())
--		GMF:ClearAllPoints()
--		GMF:SetPoint("TOPLEFT",GCF,"BOTTOMLEFT",0,-25)
--		GMF:SetPoint("TOPRIGHT",GCF,"BOTTOMRIGHT",0,-25)
	end
	GMF:ClearAllPoints()
	GMF:SetPoint("TOPLEFT",GCF,"BOTTOMLEFT",0,23)
	GMF:SetPoint("TOPRIGHT",GCF,"BOTTOMRIGHT",0,23)
end
---@function
-- Return bias color for follower and mission
-- @param #number bias bias as returned by blizzard interface [optional]
-- @param #string followerID
-- @param #number missionID
function addon:GetBiasColor(followerID,missionID,goodcolor)
	goodcolor=goodcolor or "White"
	local bias=followerID or 0
	if (missionID) then
		local rc,followerBias = pcall(G.GetFollowerBiasForMission,missionID,followerID)
		if (not rc) then
			return goodcolor
		else
			bias=followerBias
		end
	end
	if not tonumber(bias) then return "Yellow" end
	if (bias==-1) then
		return "Red"
	elseif (bias < 0) then
		return "Orange"
	end
	return goodcolor
end
function addon:RenderFollowerButton(frame,followerID,missionID,b,t)
	if (not frame) then return end
	if (frame.Threats) then
		for i=1,#frame.Threats do
			if (frame.Threats[i]) then frame.Threats[i]:Hide() end
		end
		frame.NotFull:Hide()
	end
	if (not followerID) then
		if (frame.Name) then
			frame.PortraitFrame.Empty:Show()
			frame.Name:Hide()
			frame.Class:Hide()
			frame.Status:Hide()
		else
			frame.PortraitFrame.Empty:Hide()
			frame.PortraitFrame.Portrait:Show()
			frame.PortraitFrame.LevelBorder:SetAtlas("GarrMission_PortraitRing_iLvlBorder");
			frame.PortraitFrame.LevelBorder:SetWidth(70);
			frame.PortraitFrame.Level:SetText(MISSING)
			frame.PortraitFrame.Level:SetTextColor(1,0,0,0.7)
		end
		frame.PortraitFrame.LevelBorder:SetAtlas("GarrMission_PortraitRing_LevelBorder");
		frame.PortraitFrame.LevelBorder:SetWidth(58);
		GarrisonFollowerPortrait_Set(frame.PortraitFrame.Portrait)
		frame.PortraitFrame.PortraitRingQuality:SetVertexColor(C.Silver());
		frame.PortraitFrame.LevelBorder:SetVertexColor(C.Silver());
		frame.info=nil
		return
	end
	frame:EnableMouse(true)
	frame.PortraitFrame.Level:SetTextColor(1,1,1,1)
	frame.PortraitFrame.Portrait:Show()
	local info=self:GetFollowerData(followerID)
	if (not info) then

--@debug@
print("Unable to find follower",followerID)
--@end-debug@
	return
	end
	frame.info=info
	frame.missionID=missionID
	if (frame.Name) then
		frame.Name:Show()
		frame.Name:SetText(info.name);
		local color=missionID and self:GetBiasColor(followerID,missionID,"White") or "Yellow"
		frame.Name:SetTextColor(C[color]())
		frame.Status:SetText(self:GetFollowerStatus(followerID,true,true))
		frame.Status:Show()
	end
	if (frame.Class) then
		frame.Class:Show();
		frame.Class:SetAtlas(info.classAtlas);
	end
	frame.PortraitFrame.Empty:Hide();

	local showItemLevel;
	if (info.level == GMF.followerMaxLevel ) then
		frame.PortraitFrame.LevelBorder:SetAtlas("GarrMission_PortraitRing_iLvlBorder");
		frame.PortraitFrame.LevelBorder:SetWidth(70);
		showItemLevel = true;
	else
		frame.PortraitFrame.LevelBorder:SetAtlas("GarrMission_PortraitRing_LevelBorder");
		frame.PortraitFrame.LevelBorder:SetWidth(58);
		showItemLevel = false;
	end
--[===[@non-debug@
	local rc,message= pcall(GarrisonMissionFrame_SetFollowerPortrait,frame.PortraitFrame, info, false);
--@end-non-debug@]===]
--@debug@
	GarrisonMissionFrame_SetFollowerPortrait(frame.PortraitFrame, info, false)
--@end-debug@
	-- Counters icon
	if (frame.Name and frame.Threats) then
		if (missionID and not GMFMissions.showInProgress) then
			local tohide=1
			if b and b[followerID] then
				for i=1,#b[followerID] do
					local th=frame.Threats[tohide]
					th.Icon:SetTexture(b[followerID][i].icon)
					th:Show()
					tohide=tohide+1
				end
			end
			if t and t[followerID] then
				for i=1,#t[followerID] do
					if tohide>#frame.Threats then break end
					local th=frame.Threats[tohide]
					th.Icon:SetTexture(t[followerID][i].icon)
					th:Show()
					tohide=tohide+1
				end
			end
		else
			frame.Status:Hide()
		end
	end
end
-- pseudo static
local scale=0.9

function addon:BuildFollowersButtons(button,bg,limit,bigscreen)
	if (bg.Party) then return end
	bg.Party={}
	for numMembers=1,3 do
		local f=CreateFrame("Button",nil,bg,bigscreen and "GarrisonCommanderMissionPageFollowerTemplate" or "GarrisonCommanderMissionPageFollowerTemplateSmall" )
		if (numMembers==1) then
			f:SetPoint("BOTTOMLEFT",button.Rewards[1],"BOTTOMRIGHT",10,0)
		else
			if (bigscreen) then
				f:SetPoint("LEFT",bg.Party[numMembers-1],"RIGHT",10,0)
			else
				f:SetPoint("LEFT",bg.Party[numMembers-1],"LEFT",65,0)
			end
		end
		tinsert(bg.Party,f)
		f:EnableMouse(true)
		f.missionID=button.info.missionID
		f:RegisterForClicks("AnyUp")
		f:SetScript("OnClick",function(...) self:OnClick_PartyMember(...) end)
		if (bigscreen) then
			for numThreats=1,4 do
				local threatFrame =f.Threats[numThreats];
				if ( not threatFrame ) then
					threatFrame = CreateFrame("Frame", nil, f, "GarrisonAbilityCounterTemplate");
					threatFrame:SetPoint("LEFT", f.Threats[numThreats - 1], "RIGHT", 10, 0);
					tinsert(f.Threats, threatFrame);
				end
				threatFrame:Hide()
			end
		end
	end
	for i=1,3 do bg.Party[i]:SetScale(0.9) end
	-- Making room for both GC and MP
	if (button.Expire) then
		button.Expire:ClearAllPoints()
		button.Expire:SetPoint("TOPRIGHT")
	end
	if (button.Threats and button.Threats[1]) then
		button.Threats[1]:ClearAllPoints()
		button.Threats[1]:SetPoint("TOPLEFT",165,0)
	end
end
function addon:BuildExtraButton(button,bigscreen)

end
function addon:OnShow_FollowerPage(frame)
	self:ShowUpgradeButtons()
	if not GCFMissions then return end
	if type(GCFMissions.Header.info)=="table" then
		self:HookedGarrisonFollowerPage_ShowFollower(frame,GCFMissions.Header.info.followerID,true)
--		local s =self:GetScroller("GFCMissions.Header")
--		self:cutePrint(s,GCFMissions.Header)
	end
end
--function addon:GarrisonMissionButtHeaderon_SetRewards(button,rewards,numrewards)
--end
do
	local menuFrame = CreateFrame("Frame", "GCFollowerDropDOwn", nil, "UIDropDownMenuTemplate")
	local func=function(...) addon:IgnoreFollower(...) end
	local func2=function(...) addon:UnignoreFollower(...) end
	local menu= {
	{ text=L["Follower"], notClickable=true,notCheckable=true,isTitle=true },
	{ text=L["Ignore for this mission"],checked=false, func=func, arg1=0, arg2="none"},
--	{ text=L["Ignore for all missions"],checked=false, func=func, arg1=0, arg2="none"},
	{ text=L["Consider again"], notClickable=true,notCheckable=true,isTitle=true },
	{ text=CLOSE, notClickable=true,notCheckable=true,isTitle=true },
	}
	function addon:OnClick_PartyMember(frame,button,down,...)
		local followerID=frame.info and frame.info.followerID or nil
		local missionID=frame.missionID
		if (not followerID) then return end
		if (addon:IsRewardPage()) then return end
		if (button=="LeftButton") then
			self:OpenFollowersTab()
			GMF.selectedFollower=followerID
			if (GMF.FollowerTab) then
				GMFFollowers:ShowFollower(followerID)
			end
		else
			menu[1].text=frame.info.name
			menu[2].arg1=missionID
			menu[2].arg2=followerID
			--menu[3].arg2=followerID
			local i=3
			for k,r in pairs(chardb.ignored[missionID]) do
				if (r) then
					i=i+1
					local v=menu[i] or {}
					v.text=self:GetFollowerData(k,'name')
					v.func=func2
					v.arg1=missionID
					v.arg2=k
					v.notCheckable=nil
					v.notClickable=nil
					v.checked=false
					v.isTitle=nil
					menu[i]=v
				else
					chardb.ignored[missionID][k]=nil
				end
			end
			if (i>3) then
				i=i+1
				menu[i]={text=ALL,func=func2,arg1=missionID,arg2='all'}
			end
			i=i+1
			if not menu[i] then
				menu[i]={ text=CLOSE,func=function() end, notCheckable=true }
			else
				menu[i].text=CLOSE
				menu[i].notCheckable=true
				menu[i].notClickable=nil
				menu[i].func=function() end
			end
			for x=#menu,i+1,-1 do tremove(menu) end
			EasyMenu(menu,menuFrame,"cursor",0,0,"MENU",5)
		end

	end
end
function addon:IgnoreFollower(table,missionID,followerID,flag)
	if (missionID==0) then
		chardb.totallyignored[followerID]=true
	else
		chardb.ignored[missionID][followerID]=true
	end
	-- full ignore disabled for now
	chardb.totallyignored[followerID]=nil
	self:RefreshMissions(missionID)
end
function addon:UnignoreFollower(table,missionID,followerID,flag)
	if (followerID=='all') then
		wipe(chardb.ignored[missionID])
	else
		chardb.ignored[missionID][followerID]=nil
	end
	self:RefreshMissions(missionID)
end
function addon:OpenLastTab()
	lastTab=lastTab or PanelTemplates_GetSelectedTab(GMF)
	if lastTab then
		if ns.GMC:IsVisible() then
			ns.GMC:Hide()
			GMF.tabMC:SetChecked(false)
			if lastTab==2 then
				GMF.FollowerTab:Show()
				GMF.FollowerList:Show()
				self:RefreshFollowerStatus()
			else
				GMF.MissionTab:Show()
			end
		end
		GMF:SelectTab(lastTab)
	else
		return self:OpenMissionsTab()
	end
end
function addon:OpenFollowersTab()
	lastTab=2
	return self:OpenLastTab()
end
function addon:OpenMissionsTab()
	lastTab=1
	return self:OpenLastTab()
end
function addon:OpenMissionControlTab()
	if (not ns.GMC:IsVisible()) then
		lastTab=PanelTemplates_GetSelectedTab(GMF)
		GMF.FollowerTab:Hide()
		GMF.FollowerList:Hide()
		GMF.MissionTab:Hide()
		GMF.TitleText:SetText(L["Garrison Commander Mission Control"])
		ns.GMC:Show()
		ns.GMC.startButton:Click()
		GMF.tabMC:SetChecked(true)
	else
		GMF.tabMC:SetChecked(false)
		self:OpenLastTab()
	end
end
function addon:OnClick_GarrisonMissionFrame_MissionComplete_NextMissionButton(this,button)
	local frame = GMF.MissionComplete
	if (not frame:IsVisible()) then
		self:Trigger("MSORT")
		self:RefreshFollowerStatus()
	end
end
function addon:ScriptGarrisonMissionButton_OnClick(tab,button)
	print("click",tab,tab.info)
	lastTab=1
	if (GMF.MissionTab.MissionList.showInProgress) then
		return
	end
	if (type(tab.info)~="table") then return end
	if (tab.fromFollowerPage) then
		self:OpenMissionsTab()
	end
	self:FillMissionPage(tab.info)
end
function addon:OnClick_GCMissionButton(frame,button)
	if (button=="RightButton") then
		self:HookedGarrisonMissionButton_SetRewards(frame:GetParent(),{},0)
	else
		frame.button:Click()
	end
end

--[[
addon.oldSetUp=addon.SetUp
function addon:ExperimentalSetUp()

end
addon.SetUp=addon.ExperimentalSetUp
--]]

function addon:HookedGarrisonMissionPageFollowerFrame_OnEnter(frame)
	if not frame.info then
		return;
	end

	GarrisonFollowerTooltip:ClearAllPoints();
	GarrisonFollowerTooltip:SetPoint("TOPLEFT", frame, "BOTTOMRIGHT");
	GarrisonFollowerTooltip_Show(frame.info.garrFollowerID,
		frame.info.isCollected,
		C_Garrison.GetFollowerQuality(frame.info.followerID),
		C_Garrison.GetFollowerLevel(frame.info.followerID),
		C_Garrison.GetFollowerXP(frame.info.followerID),
		C_Garrison.GetFollowerLevelXP(frame.info.followerID),
		C_Garrison.GetFollowerItemLevelAverage(frame.info.followerID),
		C_Garrison.GetFollowerAbilityAtIndex(frame.info.followerID, 1),
		C_Garrison.GetFollowerAbilityAtIndex(frame.info.followerID, 2),
		C_Garrison.GetFollowerAbilityAtIndex(frame.info.followerID, 3),
		C_Garrison.GetFollowerAbilityAtIndex(frame.info.followerID, 4),
		C_Garrison.GetFollowerTraitAtIndex(frame.info.followerID, 1),
		C_Garrison.GetFollowerTraitAtIndex(frame.info.followerID, 2),
		C_Garrison.GetFollowerTraitAtIndex(frame.info.followerID, 3),
		C_Garrison.GetFollowerTraitAtIndex(frame.info.followerID, 4),
		true,
		C_Garrison.GetFollowerBiasForMission(frame.missionID, frame.info.followerID) < 0.0
		);
end

function deleteGarrisonMissionFrame_SetFollowerPortrait(portraitFrame, followerInfo, forMissionPage)
	local color = ITEM_QUALITY_COLORS[followerInfo.quality];
	portraitFrame.PortraitRingQuality:SetVertexColor(color.r, color.g, color.b);
	portraitFrame.LevelBorder:SetVertexColor(color.r, color.g, color.b);
	if ( forMissionPage ) then
		local boosted = false;
		local followerLevel = followerInfo.level;
		if ( MISSION_PAGE_FRAME.mentorLevel and MISSION_PAGE_FRAME.mentorLevel > followerLevel ) then
			followerLevel = MISSION_PAGE_FRAME.mentorLevel;
			boosted = true;
		end
		if ( MISSION_PAGE_FRAME.showItemLevel and followerLevel == GarrisonMissionFrame.followerMaxLevel ) then
			local followerItemLevel = followerInfo.iLevel;
			if ( MISSION_PAGE_FRAME.mentorItemLevel and MISSION_PAGE_FRAME.mentorItemLevel > followerItemLevel ) then
				followerItemLevel = MISSION_PAGE_FRAME.mentorItemLevel;
				boosted = true;
			end
			portraitFrame.Level:SetFormattedText(GARRISON_FOLLOWER_ITEM_LEVEL, followerItemLevel);
			portraitFrame.LevelBorder:SetAtlas("GarrMission_PortraitRing_iLvlBorder");
			portraitFrame.LevelBorder:SetWidth(70);
		else
			portraitFrame.Level:SetText(followerLevel);
			portraitFrame.LevelBorder:SetAtlas("GarrMission_PortraitRing_LevelBorder");
			portraitFrame.LevelBorder:SetWidth(58);
		end
		local followerBias = C_Garrison.GetFollowerBiasForMission(MISSION_PAGE_FRAME.missionInfo.missionID, followerInfo.followerID);
		if ( followerBias == -1 ) then
			portraitFrame.Level:SetTextColor(1, 0.1, 0.1);
		elseif ( followerBias < 0 ) then
			portraitFrame.Level:SetTextColor(1, 0.5, 0.25);
		elseif ( boosted ) then
			portraitFrame.Level:SetTextColor(0.1, 1, 0.1);
		else
			portraitFrame.Level:SetTextColor(1, 1, 1);
		end
		portraitFrame.Caution:SetShown(followerBias < 0);

	else
		portraitFrame.Level:SetText(followerInfo.level);
	end
	if ( followerInfo.displayID ) then
		GarrisonFollowerPortrait_Set(portraitFrame.Portrait, followerInfo.portraitIconID);
	end
end

function addon:GarrisonMissionPageOnClose(self)
	GMF:ClearParty()
	GarrisonMissionFrame.MissionTab.MissionPage:Hide();
	GarrisonMissionFrame.followerCounters = nil;
	GarrisonMissionFrame.MissionTab.MissionPage.missionInfo = nil;
	if (lastTab) then
		if lastTab==1 then
			addon:OpenMissionsTab()
		else
			addon:OpenFollowersTab()
		end
	end
	-- I hooked this handler, so I dont want it to be called in the middle of cleanup operations
	GarrisonMissionFrame.MissionTab.MissionList:Show();
end
function addon:AddRewards(frame, rewards, numRewards)
	if (numRewards > 0) then
		local index = 1;
		local party=frame.party
		local mission=frame.info
		for id, reward in pairs(rewards) do
			if (not frame.Rewards[index]) then
				frame.Rewards[index] = CreateFrame("Frame", nil, frame, "GarrisonMissionListButtonRewardTemplate");
				frame.Rewards[index]:SetPoint("RIGHT", frame.Rewards[index-1], "LEFT", 0, 0);
			end
			local Reward = frame.Rewards[index];
			Reward.Quantity:Hide();
			Reward.itemID = nil;
			Reward.currencyID = nil;
			Reward.tooltip = nil;
			Reward.Quantity:SetTextColor(C.White())
			if (reward.itemID) then
				Reward.itemID = reward.itemID;
				GarrisonMissionFrame_SetItemRewardDetails(Reward);
				if ( reward.quantity > 1 ) then
					Reward.Quantity:SetText(reward.quantity);
					Reward.Quantity:Show();
				elseif reward.itemID==120205 then
					Reward.Quantity:SetText(frame.info.xp);
					Reward.Quantity:Show();
				else
					local name,link,quality,iLevel,level=GetItemInfo(reward.itemID)
					iLevel=addon:GetTrueLevel(reward.itemID,iLevel)
					if (name) then
						if (iLevel<500 and reward.quantity) then
							Reward.Quantity:SetText(reward.quantity);
						else
							Reward.Quantity:SetText(iLevel==1 and level or iLevel);
						end
						Reward.Quantity:SetTextColor(ITEM_QUALITY_COLORS[quality].r,ITEM_QUALITY_COLORS[quality].g,ITEM_QUALITY_COLORS[quality].b)
						Reward.Quantity:Show();
					end

				end
			else
				Reward.Icon:SetTexture(reward.icon);
				Reward.title = reward.title
				if (reward.currencyID and reward.quantity) then
					local multi=1
					if type(party.materialMultiplier)=="table" then
						if party.materialMultiplier[reward.currencyID] then
							multi=party.materialMultiplier[reward.currencyID]
						end
					else
						multi=party.materialMultiplier or 1
					end
					if (reward.currencyID == 0) then
						local multi=party.goldMultiplier or 1
						Reward.tooltip = GetMoneyString(reward.quantity);
						Reward.Quantity:SetText(reward.quantity/10000 *multi);
						Reward.Quantity:Show();
						if multi >1 then
							Reward.Quantity:SetTextColor(C:Green())
						else
							Reward.Quantity:SetTextColor(C:Gold())
						end
					else
						Reward.Quantity:SetText(reward.quantity * multi);
						Reward.Quantity:Show();
						if multi >1 then
							Reward.Quantity:SetTextColor(C:Green())
						else
							Reward.Quantity:SetTextColor(C:Gold())
						end
					end
				else
					if reward.followerXP then
						Reward.Quantity:SetText(reward.followerXP);
						Reward.Quantity:Show();
						if party.xpBonus and party.xpBonus > 0 then
							Reward.Quantity:SetTextColor(C:Green())
						else
							Reward.Quantity:SetTextColor(C:Gold())
						end
					end
					Reward.tooltip = reward.tooltip;
				end
			end
			Reward:Show();
			index = index + 1;
		end
	end

	for i = (numRewards + 1), #frame.Rewards do
		frame.Rewards[i]:Hide();
	end
end
function addon:HookedGarrisonMissionPageFollowerFrame_OnEnter(frame)
	if not frame.info then
		return;
	end
	if (addon:IsRewardPage()) then return end
	GarrisonFollowerTooltip:ClearAllPoints();
	GarrisonFollowerTooltip:SetPoint("TOPLEFT", frame, "BOTTOMRIGHT");
	GarrisonFollowerTooltip_Show(frame.info.garrFollowerID,
		frame.info.isCollected,
		C_Garrison.GetFollowerQuality(frame.info.followerID),
		C_Garrison.GetFollowerLevel(frame.info.followerID),
		C_Garrison.GetFollowerXP(frame.info.followerID),
		C_Garrison.GetFollowerLevelXP(frame.info.followerID),
		C_Garrison.GetFollowerItemLevelAverage(frame.info.followerID),
		C_Garrison.GetFollowerAbilityAtIndex(frame.info.followerID, 1),
		C_Garrison.GetFollowerAbilityAtIndex(frame.info.followerID, 2),
		C_Garrison.GetFollowerAbilityAtIndex(frame.info.followerID, 3),
		C_Garrison.GetFollowerAbilityAtIndex(frame.info.followerID, 4),
		C_Garrison.GetFollowerTraitAtIndex(frame.info.followerID, 1),
		C_Garrison.GetFollowerTraitAtIndex(frame.info.followerID, 2),
		C_Garrison.GetFollowerTraitAtIndex(frame.info.followerID, 3),
		C_Garrison.GetFollowerTraitAtIndex(frame.info.followerID, 4),
		true,
		frame.missionID and frame.info.followerID and
		C_Garrison.GetFollowerBiasForMission(frame.missionID, frame.info.followerID) < 0.0
		or false
		);
end
function addon:ScriptGarrisonMissionButton_OnEnter(this, button)
	if (this.info == nil) then
		return;
	end
	if (addon:IsRewardPage()) then return end
	collectgarbage("step",100)
	if (this.info == nil) then
		return;
	end

	GameTooltip:SetOwner(this, "ANCHOR_CURSOR_RIGHT");

	if(this.info.inProgress) then
		GarrisonMissionButton_SetInProgressTooltip(this.info);
	else
		GameTooltip:SetText(this.info.name);
		GameTooltip:AddLine(string.format(GARRISON_MISSION_TOOLTIP_NUM_REQUIRED_FOLLOWERS, this.info.numFollowers), 1, 1, 1);
		GarrisonMissionButton_AddThreatsToTooltip(this.info.missionID, GarrisonMissionFrame:GetFollowerType());
		GameTooltip:AddLine(GARRISON_MISSION_AVAILABILITY);
		GameTooltip:AddLine(this.info.offerTimeRemaining, 1, 1, 1);
		addon:AddFollowersToTooltip(this.info.missionID,LE_FOLLOWER_TYPE_GARRISON_6_0 or 0)
		if not C_Garrison.IsOnGarrisonMap() and not GMF:IsVisible() then
			GameTooltip:AddLine(" ");
			GameTooltip:AddLine(GARRISON_MISSION_TOOLTIP_RETURN_TO_START, nil, nil, nil, 1);
		end
	end
--@debug@
	GameTooltip:AddDoubleLine("MissionID",this.info.missionID)
	GameTooltip:AddDoubleLine("Class",this.info.class)
	GameTooltip:AddDoubleLine("TitleLen",this.Title:GetStringWidth())
	GameTooltip:AddDoubleLine("SummaryLen",this.Summary:GetStringWidth())
	GameTooltip:AddDoubleLine("Reward",this.Rewards[1]:GetWidth())
	GameTooltip:AddDoubleLine("Button",this:GetWidth())
	GameTooltip:AddDoubleLine("Button Scale",this:GetScale())
--@end-debug@
	GameTooltip:Show();
end
---@function
-- Main mission button draw routine.
-- @param source GarrisonMissionFrameMissions or nil.
-- @param button scrolllist element
-- @param progressing true if at second iteration of progress page
-- @param bigscreen enlarge button or not

function addon:DrawSingleButton(source,frame,progressing,bigscreen)
	if type(source)=="table" then source="blizzard" end
	frame:SetAlpha(1.0)
	local mission=frame.info
	if mission then
		local missionID=mission.missionID
		self:AddStandardDataToButton(source,frame,mission,missionID,bigscreen)
		self:AddIndicatorToButton(frame,mission,missionID,bigscreen)
		self:AddRewards(frame, mission.rewards, mission.numRewards);
		self:AddFollowersToButton(frame,mission,missionID,bigscreen)
		if source=="blizzard" and not self:IsRewardPage() and not progressing then
			self:AddThreatsToButton(frame,mission,missionID,bigscreen)
		end
		if progressing then
			if frame.Env then
				frame.Env:Hide()
			end
			if frame.GcThreats then
				for i=1,#frame.GcThreats do
					frame.GcThreats[i]:Hide()
				end
			end
		end
		frame:Show();

	else
		frame:Hide();
		frame.info=nil
	end
end
function addon:DrawSlimButton(source,frame,progressing,bigscreen)
	source=source or "Followers"
	local mission=frame.info
	if mission then
		local missionID=mission.missionID
		self:AddStandardDataToButton(false,frame,mission,missionID,bigscreen)
		self:AddRewards(frame, mission.rewards, mission.numRewards);
		if mission.followerTypeID==LE_FOLLOWER_TYPE_GARRISON_6_0 then
			self:AddFollowersToButton(frame,mission,missionID,bigscreen)
		else
			self:AddShipsToButton(frame,mission,missionID,bigscreen)
		end
		frame.Title:SetPoint("TOPLEFT",frame.Indicators,"TOPRIGHT",0,-5)
		frame.Success:SetPoint("LEFT",frame.Indicators,"RIGHT",0,0)
		frame.Failure:SetPoint("LEFT",frame.Indicators,"RIGHT",0,0)
		frame.Summary:ClearAllPoints()
		frame.Summary:SetPoint("TOPLEFT",frame.Title,"BOTTOMLEFT",0,-10)
		frame:Show();
	else
		frame:Hide();
		frame.info=nil
	end
end
function addon:AddStandardDataToButton(source,button,mission,missionID,bigscreen)
	if (bigscreen) then
		button.Rewards[1]:SetPoint("RIGHT",button,"RIGHT",-500 - (GMM and 40 or 0),0)
		local width=GMF.MissionTab.MissionList.showInProgress and BIGBUTTON or SMALLBUTTON
		button:SetWidth(width+600)
		button.Rewards[1]:SetPoint("RIGHT",button,"RIGHT",-500 - (GMM and 40 or 0),0)
	end
	button.MissionType:SetAtlas(mission.typeAtlas);
	if source=="blizzard" then return end
	if (mission.isRare) then
		button.RareOverlay:Show();
		button.RareText:Show();
		button.IconBG:SetVertexColor(0, 0.012, 0.291, 0.4)
	else
		button.RareOverlay:Hide();
		button.RareText:Hide();
		button.IconBG:SetVertexColor(0, 0, 0, 0.4)
	end
	if (mission.inProgress) then
		button.Overlay:Show();
		button.Summary:SetText(mission.timeLeft.." "..RED_FONT_COLOR_CODE..GARRISON_MISSION_IN_PROGRESS..FONT_COLOR_CODE_CLOSE);
	else
		button.Overlay:Hide();
	end

	button.Title:SetWidth(0);
	button.Title:SetText(mission.name)
	local seconds=self:GetMissionData(missionID,'improvedDurationSeconds')
	local duration=SecondsToTime(seconds)
	if ( seconds >= GARRISON_LONG_MISSION_TIME ) then
		button.Summary:SetFormattedText(PARENS_TEMPLATE, format(GARRISON_LONG_MISSION_TIME_FORMAT,duration))
	elseif (seconds<mission.durationSeconds) then
		button.Summary:SetFormattedText(PARENS_TEMPLATE, format("%s%s%s",GREEN_FONT_COLOR_CODE,duration,FONT_COLOR_CODE_CLOSE))
	else
		button.Summary:SetFormattedText(PARENS_TEMPLATE, duration);
	end
	if ( mission.locPrefix ) then
		button.LocBG:Show();
		button.LocBG:SetAtlas(mission.locPrefix.."-List");
	else
		button.LocBG:Hide();
	end
	self:AddLevel(source,button,mission,missionID,bigscreen)
	button:Enable();
	button.MissionType:SetPoint("TOPLEFT",5,-2)
	-- From here on, I am in my own buttons context
	-- Mission Control wide is 832, left for buttons is 305 source = "Control"
	-- Mission Contro narrow is 385 almost no space left source ="Control"
	-- Follower page is 267 2 rows here is mandatory source = "Followers"
	button.Summary:Show()
	if source=="control" then
		local extra=80*(button.info.numRewards-1) +  70 * (button.info.numFollowers-1)
		local allowed=ns.bigscreen and 305- extra or 0
		local needed=button.Title:GetStringWidth()+5+button.Summary:GetStringWidth()
		if (needed > allowed) then
			button.Title:SetPoint("TOPLEFT",button,"TOPLEFT",150,ns.bigscreen and -15 or -5)
			button.Summary:ClearAllPoints()
			button.Summary:SetPoint("TOPLEFT",button.Title,"BOTTOMLEFT",0,-15)
			return
		end
	elseif source=="followers" then
		button.Title:SetPoint("TOPLEFT",button,"TOPLEFT",155,-5)
		button.Summary:Hide()
		return
	elseif source=="report" then
		if GMF:IsVisible() then
			local extra=80*(button.info.numRewards-1) +  70 * (button.info.numFollowers-1)
			local allowed=350-  extra
			local needed=button.Title:GetStringWidth()+5+button.Summary:GetStringWidth()
			if (needed > allowed) then
				button.Title:SetPoint("TOPLEFT",button,"TOPLEFT",160,-10)
				button.Summary:ClearAllPoints()
				button.Summary:SetPoint("TOPLEFT",button.Title,"BOTTOMLEFT",0,-5)
				return
			end
		end
	end
	button.Title:SetPoint("TOPLEFT",button,"TOPLEFT",160,-30)

end
function addon:AddLevel(source,button,mission,missionID,bigscreen)
	button.Level:SetPoint("CENTER", button, "TOPLEFT", 40, -36);
	local level= (mission.level == GARRISON_FOLLOWER_MAX_LEVEL and mission.iLevel > 0) and mission.iLevel or mission.level
	local quality=1
	if level >=645 then
		quality=4
	elseif  level >=630 then
		quality=3
	elseif level>100 then
		quality=2
	end
	button.Level:SetText(level)
	button.Level:SetTextColor(self:GetQualityColor(quality))
	button.ItemLevel:Hide();

end
function addon:AddThreatsToButton(button,mission,missionID,bigscreen)
	local threatIndex=1
	if (not button.Threats) then -- I am a good guy. If MP present, I dont make my own threat indicator (Only MP <= 1.8)
		if (not button.Env) then
			button.Env=CreateFrame("Frame",nil,button,"GarrisonAbilityCounterTemplate")
			button.Env:SetWidth(20)
			button.Env:SetHeight(20)
			button.Env:SetPoint("BOTTOMLEFT",button,165,8)
			button.GcThreats={}
		end
		button.Env.missionID=missionID
		local party=button.party
		if not mission.typeIcon then
			mission.typeIcon=select(5,G.GetMissionInfo(missionID))
		end
		if mission.typeIcon then
			button.Env.IsEnv=true
			button.Env:Show()
			button.Env.Icon:SetTexture(mission.typeIcon)
			button.Env.texture=mission.typeIcon
			button.Env.countered=party.isEnvMechanicCountered
			if (party.isEnvMechanicCountered) then
				button.Env.Border:SetVertexColor(C.Green())
			else
				button.Env.Border:SetVertexColor(C.Red())
			end
			button.Env.Description=mission.typeDesc
			button.Env.Name=mission.type
			button.Env:SetScript("OnEnter",addon.ClonedGarrisonMissionMechanic_OnEnter)
			button.Env:SetScript("OnLeave",function() GameTooltip:Hide() end)
		else
			print("No typeIcon in",mission)
			button.Env:SetScript("OnEnter",nil)
			button.Env:Hide()
		end
		local enemies=mission.enemies or select(8,G.GetMissionInfo(missionID))
		local threats=self:GetParty(missionID,'threats')
		for i,enemy in ipairs(enemies) do
			for mechanicID, mechanic in pairs(enemy.mechanics) do
				local th=button.GcThreats[threatIndex]
				if (not th) then
					th=CreateFrame("Frame",nil,button,"GarrisonAbilityCounterTemplate")
					th:SetWidth(20)
					th:SetHeight(20)
					th:SetPoint("BOTTOMLEFT",button,165 + 35 * threatIndex,8)
					button.GcThreats[threatIndex]=th
				end
				th.countered=self:SetThreatColor(th,threats[threatIndex])
				th.Icon:SetTexture(mechanic.icon)
				th.texture=mechanic.icon
				th.Name=mechanic.name
				th.Description=mechanic.description
				th.missionID=missionID
				--GarrisonMissionButton_CheckTooltipThreat(th,missionID,mechanicID,counteredThreats)
				th:Show()
				th:SetScript("OnEnter",addon.ClonedGarrisonMissionMechanic_OnEnter)
				th:SetScript("OnLeave",function() GameTooltip:Hide() end)
				threatIndex=threatIndex+1
			end
		end
	end
	if (button.GcThreats) then
		for i=threatIndex,#button.GcThreats do
			button.GcThreats[i]:Hide()
		end
	end
end
function addon:GetAgeColor(age)
		age=tonumber(age) or 0
		if age>GetTime() then age=age-GetTime() end
		if age < 0 then age=0 end
		local hours=floor(age/3600)
		local q=self:GetDifficultyColor(hours+20,true)
		return q.r,q.g,q.b
end
function addon:AddIndicatorToButton(button,mission,missionID,bigscreen)
	if not button.gcINDICATOR then
		local indicators=CreateFrame("Frame",nil,button,"GarrisonCommanderIndicators")
		indicators:SetPoint("LEFT",70,0)
		button.gcINDICATOR=indicators
	end
	local panel=button.gcINDICATOR
	local perc=select(4,G.GetPartyMissionInfo(missionID))
	if button.party and button.party.perc > perc then perc=button.party.perc end
	if button.party.full then
		panel.Percent:SetFormattedText(GARRISON_MISSION_PERCENT_CHANCE,perc)
		panel.Percent:SetTextColor(self:GetDifficultyColors(perc))
	else
		panel.Percent:SetText("N/A")
		panel.Percent:SetTextColor(C:Silver())
	end
	panel.Percent:SetWidth(80)
	panel.Percent:Show()
	if (GMFMissions.showInProgress) then
		panel.Percent:SetJustifyV("CENTER")
		panel.Percent:SetJustifyH("RIGHT")
		panel.Age:Hide()
	else
		panel.Percent:SetJustifyV("BOTTOM")
		panel.Percent:SetJustifyH("RIGHT")
		panel.Age:SetFormattedText("Expires in \n%s",mission.offerTimeRemaining)
		panel.Age:SetTextColor(self:GetAgeColor(mission.offerEndTime))
		panel.Age:Show()
	end
-- XP display
	if (not GMFMissions.showInProgress) then
		if (not button.xp) then
			button.xp=button:CreateFontString(nil, "ARTWORK", "QuestMaprewardsFont")
			button.xp:SetPoint("TOP",button.Rewards[1],"TOP")
			button.xp:SetJustifyH("CENTER")
		end
		button.xp:SetWidth(0)
		print (self:GetMissionData(missionID,'xp',0),self:GetMissionData(missionID,'xpBonus',0),self:GetParty(missionID,'xpBonus',0) ,button.info.numFollowers)
		local xp=(self:GetMissionData(missionID,'xp',0)+self:GetMissionData(missionID,'xpBonus',0)+self:GetParty(missionID,'xpBonus',0) )*button.info.numFollowers
		button.xp:SetFormattedText("Xp: %d",xp)
		button.xp:SetTextColor(self:GetDifficultyColors(xp/3000*100))
		button.xp:Show()
	else
		if button.xp then
			button.xp:Hide()
		end
	end
end
function addon:AddShipsToButton(button,mission,missionID,bigscreen)
	if (not button.gcPANEL) then
		local bg=CreateFrame("Button",nil,button,"GarrisonCommanderMissionButton")
		bg:SetPoint("RIGHT")
		bg.button=button
		bg:SetScript("OnEnter",function(this) GarrisonMissionButton_OnEnter(this.button) end)
		bg:SetScript("OnLeave",function() GameTooltip:FadeOut() end)
		bg:RegisterForClicks("AnyUp")
		bg:SetScript("OnClick",function(...) self:OnClick_GCMissionButton(...) end)
		button.gcPANEL=bg
		if (not bg.Party) then self:BuildFollowersButtons(button,bg,3,bigscreen) end
	end
	for i=1,3 do
		local frame=button.gcPANEL.Party[i]
		frame:Hide()
	end
end
function addon:AddFollowersToButton(button,mission,missionID,bigscreen)
	if (not button.gcPANEL) then
		local bg=CreateFrame("Button",nil,button,"GarrisonCommanderMissionButton")
		bg:SetPoint("RIGHT")
		bg.button=button
		bg:SetScript("OnEnter",function(this) GarrisonMissionButton_OnEnter(this.button) end)
		bg:SetScript("OnLeave",function() GameTooltip:FadeOut() end)
		bg:RegisterForClicks("AnyUp")
		bg:SetScript("OnClick",function(...) self:OnClick_GCMissionButton(...) end)
		button.gcPANEL=bg
		if (not bg.Party) then self:BuildFollowersButtons(button,bg,3,bigscreen) end
	end
	local missionInfo=button.info
	local missionID=missionInfo.missionID
	local mission=missionInfo
	if not mission then
--@debug@
	print("Non ho la missione") return  -- something went wrong while refreshing
--@end-debug@
	end
	if (not bigscreen) then
		local index=mission.numFollowers+mission.numRewards-3
		local position=(index * -65) - 130
		button.gcPANEL.Party[1]:ClearAllPoints()
		button.gcPANEL.Party[1]:SetPoint("BOTTOMLEFT",button.Rewards[1],"BOTTOMLEFT", position,0)
	end
	local party=button.party
	local t,b
	if not GMFMissions.showInProgress then
		b=G.GetBuffedFollowersForMission(missionID)
		t=G.GetFollowersTraitsForMission(missionID)
	end
	for i=1,3 do
		local frame=button.gcPANEL.Party[i]
		if (i>mission.numFollowers) then
			frame:Hide()
		else
			if (mission.inProgress and mission.followers[i]) then
				self:RenderFollowerButton(frame,mission.followers[i],missionID,b,t)
				if (frame.NotFull) then frame.NotFull:Hide() end
			elseif (party.members[i]) then
				self:RenderFollowerButton(frame,party.members[i],missionID,b,t)
				if (frame.NotFull) then frame.NotFull:Hide() end
			else
				self:RenderFollowerButton(frame,false)
				if (frame.NotFull) then frame.NotFull:Show() end
			end
			frame:Show()
		end
	end
end
-- Switchs between active and availabla missions depending on tab object
function addon:HookedGarrisonMissionList_SetTab(tab)
	--@debug@
	print("Click su",tab:GetID())
	--@end-debug@
	-- I dont actually care wich page we are showing, I know I must redraw missions
	addon:RefreshFollowerStatus()
	for i=1,#GMFMissionListButtons do
		GMFMissionListButtons.lastMissionID=nil
	end
	if (HD) then addon:ResetSinks() end
end
function addon:HookedClickOnTabs(tab)
--@debug@
	print(tab)
--@end-debug@
	lastTab=tab
end
function addon:GarrisonMissionFrame_SelectTab(frame,tab)
--@debug@
	print(frame,tab)
--@end-debug@
	addon:RefreshFollowerStatus()
	for i=1,#GMFMissionListButtons do
		GMFMissionListButtons.lastMissionID=nil
	end
	lastTab=tab
	if (HD) then addon:ResetSinks() end
	if GMF.tabMC then
		GMF.tabMC:SetChecked(false)
		ns.GMC:Hide()
	end
end
function addon:HookedGarrisonMissionButton_SetRewards(frame,rewards,numRewards)
	collectgarbage("step",300)
	if not GMF:IsVisible() then return end
	if frame.info then
		if GMFMissions.showInProgress then
			frame.Title:SetPoint("TOPLEFT",frame,"TOPLEFT",160,-25)
		else
			local extra=80*(numRewards-1)
			if not ns.bigscreen then extra = extra + 70 * (frame.info.numFollowers-1) end
			local allowed=ns.bigscreen and 350- extra or 480 - extra
			local needed=frame.Title:GetStringWidth()+5+frame.Summary:GetStringWidth()
			if (needed > allowed) then
				frame.Title:SetPoint("TOPLEFT",frame,"TOPLEFT",160,-5)
				frame.Summary:ClearAllPoints()
				frame.Summary:SetPoint("TOPLEFT",frame.Title,"BOTTOMLEFT",0,-5)
			else
				frame.Title:SetPoint("TOPLEFT",frame,"TOPLEFT",160,-15)
			end
		end
		frame.MissionType:SetPoint("TOPLEFT",5,-2)
		frame.MissionType:SetAlpha(0.5)
		self:AddLevel(GMF,frame,frame.info,frame.info.missionID,ns.bigscreen)
		if GMFMissions.showInProgress and frame.lastID and frame.lastID == frame.info.missionID and frame.lastProgress then
			return
		end
		frame.lastID = frame.info.missionID
		frame.lastProgress = frame.info.inProgress
		frame.party=self:GetParty(frame.info.missionID)
		if not GMFMissions.showInProgress then
			self:MatchMaker(frame.info.missionID,frame.party)
		end
		--@debug@
		if not GMF:IsVisible() then print(debugstack()) end
		--@end-debug@
		self:DrawSingleButton(GMF,frame,GMFMissions.showInProgress,ns.bigscreen)
	end
end

function addon:HookedGMFMissionsListScroll_update(frame)
	if frame:GetParent().showInProgress then
		self:HookedGarrisonMissionList_Update(frame,true)
	else
		self:HookedGarrisonMissionList_Update(frame,false)
	end
end
do local lasttime=0
function addon:HookedGarrisonMissionList_Update(t,...)
	collectgarbage('step',200)
	if not GMFMissions.showInProgress then
		self.hooks.GarrisonMissionList_Update(t,...)
		lasttime=0
	else
		local missions=GMFMissions.inProgressMissions
		local now=time()
		local delay=120
		table.sort(missions,sorters.EndTime)
		if t then
			lasttime=0
		else
			delay=missions[1].missionEndTime-now
		end
		if (now-lasttime) > ((delay>65) and 30 or 0) then
--@debug@
			print("Aggiornamento",now,lasttime,delay,now-lasttime)
--@end-debug@
			self.hooks.GarrisonMissionList_Update(t,...)
			lasttime=now
		end
	end
end
end
--addon:SafeRawHook(GMF.MissionTab.MissionList.listScroll,"update","HookedGMFMissionsListScroll_update")
addon:SafeRawHook("GarrisonMissionList_Update")
addon:SafeSecureHook("GarrisonMissionButton_SetRewards")
addon:SafeRawHook("GarrisonMissionButton_OnEnter","ScriptGarrisonMissionButton_OnEnter")
addon:SafeRawHook("GarrisonMissionPageFollowerFrame_OnEnter")
addon:SafeSecureHook("GarrisonMissionList_SetTab")
addon:SafeSecureHook(GMF,"SelectTab","GarrisonMissionFrame_SelectTab")
addon:SafeRawHookScript(GMF.MissionTab.MissionPage.CloseButton,"OnClick","GarrisonMissionPageOnClose")

_G.GAC=addon