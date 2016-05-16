local me,ns=...
ns.Configure()
local addon=addon --#addon
--local holdEvents,releaseEvents=addon.holdEvents,addon.releaseEvents
local type=type
local select=select
local pairs=pairs
local tonumber=tonumber
local tinsert=tinsert
local tcontains=tContains
local wipe=wipe
local GARRISON_CURRENCY=GARRISON_CURRENCY
local GARRISON_SHIP_OIL_CURRENCY=GARRISON_SHIP_OIL_CURRENCY
local GARRISON_FOLLOWER_MAX_LEVEL=GARRISON_FOLLOWER_MAX_LEVEL
local LE_FOLLOWER_TYPE_GARRISON_6_0=_G.LE_FOLLOWER_TYPE_GARRISON_6_0
local LE_FOLLOWER_TYPE_SHIPYARD_6_2=_G.LE_FOLLOWER_TYPE_SHIPYARD_6_2
local GMF=GMF
local GSF=GSF
local GMFMissions=GMFMissions
local GSFMissions=GSFMissions
local newcache=true
local rushOrders="interface\\icons\\inv_scroll_12.blp"
local rawget=rawget
local time=time
local tostring,GetSpecializationInfo,GetSpecialization=tostring,GetSpecializationInfo,GetSpecialization
local empty={}
local index={}
local classes
-- Mission caching is a bit different fron follower caching mission appears and disappears on a regular basis
local module=addon:NewSubClass('MissionCache') --#module
local GetAuctionBuyout=GetAuctionBuyout
if type(GetAuctionBuyout)=="function" then
	function addon:GetMarketValue(item)
		local rc,price=pcall(GetAuctionBuyout,item)
		print(item,rc,price)
		if not rc then
--@debug@
			print("Error calling buyout for",item,":",price)
--@end-debug@
		end
		price=tonumber(price) or 0
		if price>0 then
			print(item,price,true)
			return price,true
		else
			print(item,tonumber(select(11,GetItemInfo(item))) or 0,false)
			return tonumber(select(11,GetItemInfo(item))) or 0,false
		end
	end
else
	function addon:GetMarketValue(item)
		return tonumber(select(11,GetItemInfo(item))) or 0
	end
end
function addon:GetContainedItems(itemID,spec)
	spec=spec or GetSpecializationInfo(GetSpecialization())
	itemID=tostring(itemID)
	local rc,data=false,allRewards[itemID]
	if type(data)=="string" then
		rc,data=self:Deserialize(data) -- Deserialize wants a string
		if rc then
			allRewards[itemID]=data
		else
			data=false
		end
	end
	if type(data)=="table" then
		data=data[tostring(spec)] or data['*'] or false
	end
	--@debug@
	if (data) then
		print("Internal for itemID",itemID)
		--DevTools_Dump(data)
	end
	--@end-debug@
	return data
end
function module:OnInitialized()
--@debug@
	print("OnInitialized")
--@end-debug@

end
local function scan(t,s)
	if type(t)=="table" then
		for i=1,#t do
			index[t[i].missionID]=format("%s@%d",s,i)
		end
	end
end
function module:GetMission(id,noretry)
	local mission
	if index[id] then
		local type,ix=strsplit("@",index[id])
		ix=tonumber(ix)
		if type=="a" then
			mission=GMFMissions.availableMissions[ix]
			if mission and mission.missionID==id then return mission end
		elseif type=="p" then
			mission=GMFMissions.inProgressMissions[ix]
			if mission and mission.missionID==id then return mission end
		elseif type=="s" then
			mission=GSFMissions.missions[ix]
			if mission and mission.missionID==id then return mission end
		end
	end
	if noretry then return end
	wipe(index)
	scan(GMFMissions.availableMissions,'a')
	scan(GMFMissions.inProgressMissions,'p')
	scan(GSFMissions.missions,'s')
	return self:GetMission(id,true)
end
function module:AddExtraData(mission)
	--print(mission.missionID,mission.creates)
	if mission.class then return end
	local rewards=mission.rewards
	if not rewards then
		rewards=G.GetMissionRewardInfo(mission.missionID)
	end
	for i=1,#classes do
		mission[classes[i].key]=0
	end
	local spec=GetSpecializationInfo(GetSpecialization())
	mission.numrewards=0
	mission.xpBonus=0
	mission.moreClasses=mission.moreClasses or {}
	wipe(mission.moreClasses)
	mission.class=nil
--@debug@
	local dbg=461
--@end-debug@
	if mission.missionID == dbg then print("Extradata loading for ",mission.name) end
	for k,v in pairs(rewards) do
		if k==615 and v.followerXP then mission.xpBonus=mission.xpBonus+v.followerXP end
		mission.numrewards=mission.numrewards+1
		if mission.missionID == dbg then DevTools_Dump(v) end
		for i,c in ipairs(classes) do
			--@debug@
			if mission.missionID == dbg then print("Checking for class",c.key) end
			--@end-debug@
			local value=c.func(c,k,v)
			--@debug@
			if mission.missionID == dbg then print("Returned:",value) end
			--@end-debug@
			if value then
				if not mission.class  then
					mission[c.key]=mission[c.key]+value
					mission.class=c.key
					mission.maxable=c.maxable
					mission.mat=c.mat
				elseif mission.class ~= c.key  and c.key ~= "other" then
					mission.moreClasses[c.key]=tonumber(mission.moreClasses[c.key] or 0) + value
				end
				if spec and v.itemID then
					local sellvalue=0
					local data=self:GetContainedItems(v.itemID,spec)
					if data then
						mission.bestItemID=v.itemID
						local count=0
						for i=1,#data do
							local c,k,l=strsplit('@',data[i])
							c=tonumber(c) or 1
							k=tonumber(k)
							if (tonumber(c) or 1) >= count then
								local val,auction=self:GetMarketValue(k)
								if count<c or (val and val > sellvalue) then
									count=c
									sellvalue=val
									mission.bestItemID=k
									mission.bestItemIDAuction=auction
								end
							end
						end
					else
						sellvalue=self:GetMarketValue(v.itemID)
					end
					--@debug@
					if mission.missionID == dbg then print("Market value",sellvalue) end
					--@end-debug@
					if not tonumber(sellvalue) then
						print(mission.missionID,"sellvalue for",v.itemID,"was non numeric:",sellvalue)
						sellvalue=0
					end
					if sellvalue > 0 then
						mission.moreClasses.gold=(mission.moreClasses.gold or 0) + sellvalue * (v.quantity)
					end
				end
				--@debug@
				if mission.missionID == dbg then print("Current gold",mission.gold,"moreclass gold",mission.moreClasses.gold) end
				--@end-debug@
				break
			end
		end
	end
	for k,v in pairs(mission.moreClasses) do
		if not mission.class then mission.class=k end
		mission[k]=mission[k]+v
	end
--@debug@
	if mission.missionID == dbg then print("Final gold",mission.gold) DevTools_Dump(mission.moreClasses)end
--@end-debug@
	if not mission.class then mission.class="other" end
end
function module:GetMissionIterator(followerType)
	local list
	if followerType==LE_FOLLOWER_TYPE_SHIPYARD_6_2 then
		list=GSFMissions.missions
	else
		list=GMFMissions.availableMissions
	end

--@debug@
print("Iterator called, list is",list)
--@end-debug@
	return function(sorted,i)
		i=i+1
		if type(sorted[i])=="table" then
			return i,sorted[i].missionID
		end
	end,list,0
end
function module:OnAllGarrisonMissions(func,inProgress,missionType)
	local list=inProgress and GMFMissions.inProgressMissions or GMFMissions.availableMissions
	if type(list)=='table' then
		for i=1,#list do
			func(list[i].missionID)
		end
	end
end

-- Old cache to be removed


local Mbase = GMFMissions

-- self=Mbase
--	C_Garrison.GetInProgressMissions(self.inProgressMissions);
--	C_Garrison.GetAvailableMissions(self.availableMissions);
local Index={}
local sorted={}
local function keyToIndex(key)
	local idx=Index[key]
	if (idx and idx <= #Mbase.availableMissions) then
		if Mbase.availableMissions[idx].missionID==key then
			return idx
		else
			idx=nil
		end
	end
	wipe(Index)
	wipe(sorted)
	for i=1,#Mbase.availableMissions do
		Index[Mbase.availableMissions[i].missionID]=i
		tinsert(sorted,i)
		if Mbase.availableMissions[i].missionID==key then
			idx=i
		end
	end
	return idx
end

function addon:GetMissionData(missionID,key,default)
	local mission=module:GetMission(missionID)
	if mission and not mission.class then
			self:AddExtraData(mission)
	end
	if not mission then
		local good,mc=pcall(self.GetModule,self,"MissionCompletion")
		if good then
			mission=mc:GetMission(missionID)
--@debug@
		else
			print(missionID,mc)

--@end-debug@
		end
		if mission then
			if type(mission.improvedDurationSeconds)~='number' then
				mission.improvedDurationSeconds=mission.durationSeconds
			end
			mission.improvedDurationSeconds=mission.isMissionTimeImproved and mission.improvedDurationSeconds/2 or mission.improvedDurationSeconds
		end
	end
	if not mission then
		mission=G.GetMissionInfo(missionID)
	end
	if not mission then

--@debug@
print("Could not find info for mission",missionID,G.GetMissionName(missionID))
--@end-debug@
		return default
	end
	if (key==nil) then
		if (mission.class=="retry" or not mission.globalXp or key=="globalXp") then
			self:AddExtraData(mission)
		end
		return mission
	end
	if not mission then
		return default
	end
	if (type(mission[key])~='nil') then
		return mission[key]
	end
	if key=='improvedDurationSeconds' then
		if type(mission.durationSeconds) ~= 'number' then return default end
		if self:GetParty(missionID,'isMissionTimeImproved') then
			return mission.durationSeconds/2
		else
			return mission.durationSeconds
		end
	end
	if (key=='rank') then
		mission.rank=mission.level < GARRISON_FOLLOWER_MAX_LEVEL and mission.level or mission.iLevel
		return mission.rank or default
	elseif(key=='basePerc') then
		mission.basePerc=select(4,G.GetPartyMissionInfo(missionID))
		return mission.basePerc or default
	else
		--AddExtraData(mission)
		if type(default)=="number" and type(mission[key])~="number" then return default end
		return mission[key] or default
	end
end
function addon:AddExtraData(mission)
	return module:AddExtraData(mission)
end

function addon:OnAllGarrisonMissions(func,inProgress)
	return module:OnAllGarrisonMissions(func,inProgress)
end
local sorters={}

function addon:GetMissionIterator(followerType,func)
	return module:GetMissionIterator(followerType,func)
end
local function inList(self,id,reward)
	if self.key=='xp'  then
		if reward.followerXP then return reward.followerXP end
	elseif self.key=='followerUpgrade' then
		if not reward.itemID then return false end
		local level=addon:IsFollowerUpgrade(reward.itemID)
		if level then
			return tonumber(level) or 0
		end
	elseif self.key=='itemLevel' then
		if not reward.itemID then return false end
		local quality,level,minLevel=select(3,GetItemInfo(reward.itemID))
		if quality then
			level=addon:GetTrueLevel(reward.itemID,level)
			if (level > 500 and minLevel >=90) or level >654 then
				return level
			end
		else
			return -1
		end
	elseif self.key=='other' then
		return reward.quantity or 0
	elseif reward.currencyID and tContains(self.list,-reward.currencyID) then
		return reward.quantity or 1
	elseif reward.itemID and tContains(self.list,reward.itemID) then
		return reward.quantity or 1
	end
	return false
end
local function isOilMission(self,id,reward)
	if reward.currencyID and reward.currencyID==GARRISON_SHIP_OIL_CURRENCY then
		return reward.quantity or 1
	elseif reward.itemID and tContains(self.list,reward.itemID) then
		return reward.quantity or 1
	else
		return false
	end
end
local function isGearToken(self,id,reward)
end
local function isValid(self)
	print(self.key,self.t)
	for i=1,#self.list do
		local id=self.list[i]
		if id < 10000 then
			print(GetCurrencyInfo(id))
		else
			print(GetItemInfo(id))
		end
	end
end
local c={}
local function newMissionType(key,name,icon,maxable,mat,func,...)
	return{
		key=key,
		t=name,
		func=func or inList,
		list={...},
		i='Interface\\Icons\\' .. icon,
		maxable=maxable,
		mat=mat,
		validate=isValid
	}
end
classes={
	newMissionType('xp',L['Follower experience'],'XPBonus_icon',false,false,nil,0),
	newMissionType('resources',GetCurrencyInfo(GARRISON_CURRENCY),'inv_garrison_resource',true,true,nil,-GARRISON_CURRENCY),
	newMissionType('oil',GetCurrencyInfo(GARRISON_SHIP_OIL_CURRENCY),'garrison_oil',true,true,isOilMission,128316),
	newMissionType('rush',L['Rush orders'],'INV_Scroll_12',false,false,nil,122595,122594,122596,122592,122590,122593,122591,122576),
	newMissionType('apexis',GetCurrencyInfo(823),'inv_apexis_draenor',false,false,nil,-823),
	newMissionType('seal',GetCurrencyInfo(994),'ability_animusorbs',false,false,nil,-994),
	newMissionType('gold',BONUS_ROLL_REWARD_MONEY,'inv_misc_coin_01',false,false,nil,0),
	newMissionType('followerUpgrade',L['Follower equipment set or upgrade'],'Garrison_ArmorUpgrade',false,false,nil,0),
	newMissionType('primalspirit',L['Reagents'],'6BF_Explosive_shard',false,false,nil,118472,120945,113261,113262,113263,113264),
	newMissionType('ark',L['Archaelogy'],'achievement_character_orc_male',false,false,nil,-829,-828,-821,108439,109585,109584), -- Fragments and completer
	newMissionType('training',L['Follower Training'],'Spell_Holy_WeaponMastery',false,false,nil,123858,118354,118475,122582,122583,122580,122584,118474),
	newMissionType('legendary',L['Legendary Items'],'INV_Relics_Runestone',false,false,nil,115510,115280,128693,115981),
	newMissionType('toys',L['Toys and Mounts'],'INV_LesserGronnMount_Red',false,false,nil,128310,127748,128311),
	newMissionType('reputation',L['Reputation Items'],'Spell_Shadow_DemonicCircleTeleport',false,false,nil,117492,128315),
	newMissionType('itemLevel',L['Item Tokens'],'INV_Bracer_Cloth_Reputation_C_01',false,false,nil,0),
	newMissionType('other',L['Other rewards'],'INV_Box_02',false,false,nil,0),
}
function addon:GetRewardClasses()
	return classes
end
function addon:TestMissionExtra(id)
	local data={missionID=id}
	module:AddExtraData(data)
	return data
end
