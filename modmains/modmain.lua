local pp = require "pphandle"
local _G = GLOBAL
local rawget = _G.rawget
local TheNet = _G.TheNet
local STRINGS = _G.STRINGS

--Text Hooker codes from Russification Pack
--credit for Cunning fox and his team
--Special thanks for 'Yukari' of DC DST Gallery for Sketch & Blueprint code
LoadPOFile("ko.po", "ko")
po = _G.LanguageTranslator.languages["ko"]
SpeechHashTbl={}
mod_phrases = {}
mod_announce = {}

function GetFromSpeechesHash(message, char)
	local function GetMentioned(message,char)
		if not (message and SpeechHashTbl[char] and SpeechHashTbl[char]["mentioned_class"] and type(SpeechHashTbl[char]["mentioned_class"])=="table") then return nil end
		for i,v in pairs(SpeechHashTbl[char]["mentioned_class"]) do
			local pattern = string.gsub(i,"%%s","(.*)")
			pattern = string.gsub(pattern,"{([^%s]*)}","(.*)")
			local mentions={string.match(message,"^"..pattern.."$")}
			if mentions and #mentions>0 then
				return v, mentions --formatting reference for translation
			end
		end
		return nil
	end
	local mentions
	if not char then char = "GENERIC" end
	if message and SpeechHashTbl[char] then
		local msg = SpeechHashTbl[char][message] or SpeechHashTbl["GENERIC"][message]
		
		if not msg then msg, mentions = GetMentioned(message,char) end
		if not msg then msg, mentions = GetMentioned(message,"GENERIC") end
		message = msg or message
		
		message = (type(message)=="table") and _G.GetRandomItem(message) or message
		if char=="WATHGRITHR" and _G.Profile:IsWathgrithrFontEnabled() then
			message = message:gsub("о","ö"):gsub("О","Ö") or message
		end
	end
	return message, mentions
end

-- splits a string by separator. ex: split("asd/f","/") -> "asd", "f"
local function split(str,sep)
	local fields, first = {}, 1
	str=str..sep
	for i=1,#str do
		if string.sub(str,i,i+#sep-1)==sep then
			fields[#fields+1]=(i<=first) and "" or string.sub(str,first,i-1)
			first=i+#sep
		end
	end
	return fields
end

-- work in progress. related to Mumsy speech. Not sure if it works
local function GetMentioned1(message)
	for i,v in pairs(SpeechHashTbl.GOATMUM_CRAVING_HINTS.Tr) do
		local regex=string.gsub(i,"%.","%%.")
		regex=string.gsub(regex,"{craving}","(.-)")
		regex=string.gsub(regex,"{part2}","(.+)")
		-- print(regex)
		local mentions={string.match(message,"^"..(regex).."$")}
		if mentions and #mentions>0 and  string.find(mentions[1],'%.%.%.')==nil then
			 print(v,mentions[1])
			 if #mentions>1 then print(mentions[2]) end
			return v, mentions --возвращаем перевод (с незаменёнными %s) и список отсылок
		end
	end
	return nil
end

function KOTranslater(message, entity)
	if not (entity and entity.prefab and entity.components.talker and type(message)=="string") then return message end
	
	local new_line = string.find(message,"\n",1,true)
	if new_line ~= nil then
		local mess1 = message:sub(1, new_line - 1)
		if mod_phrases[mess1] then
			local mess2 = message:sub(new_line)
			return mod_phrases[mess1] .. mess2
		end
	elseif mod_phrases[message] then
		return mod_phrases[message]
	end
	
	if entity.prefab == 'quagmire_goatmum' then
		if SpeechHashTbl.GOATMUM_WELCOME_INTRO.Tr[message] then
			return SpeechHashTbl.GOATMUM_WELCOME_INTRO.Tr[message]
		end
		
		local NotTranslated=message
		local msg, mentions=GetMentioned1(message)
		message=msg or message
		
		if NotTranslate==message then return end
		local part2
		local craving
		if mentions and #mentions>0 and mentions[1] then
			craving=SpeechHashTbl.GOATMUM_CRAVING_MAP.Tr[mentions[1]]
			if #mentions>1 then
				part2=SpeechHashTbl.GOATMUM_CRAVING_HINTS_PART2.Tr[mentions[2]] or SpeechHashTbl.GOATMUM_CRAVING_HINTS_PART2_IMPATIENT.Tr[mentions[2]]
			end
			message = pp.replacePP(message,"{craving}",craving)
			if #mentions==1 and craving then
				message=string.format(message,craving)
			elseif #mentions==2 and craving and part2 then
				message=string.format(message,craving,part2)
			end
		end
		return message
	end
	if entity:HasTag("Playerghost") then
		message=string.gsub(message,"ohh","오")
		message=string.gsub(message,"oh","우")
		message=string.gsub(message,"h","")
		message=string.gsub(message,"O","우")
		message=string.gsub(message,"o","오")
		
		return message
	end
	
	if SpeechHashTbl.EPITAPHS[message] then
		return SpeechHashTbl.EPITAPHS[message]
	end
	
	local ent=entity
	entity=entity.prefab:upper()
	if entity=="WILSON" then entity="GENERIC" end
	if entity=="MAXWELL" then entity="WAXWELL" end
	if entity=="WIGFRID" then entity="WATHGRITHR" end
	local function TranslateMessage(message)
		--Получаем перевод реплики и список отсылок %s, если они есть в реплике
		if not message then return end
		local NotTranslated=message
		local msg, mentions=GetFromSpeechesHash(message,entity)
		message=msg or message

		local killerkey
		if mentions then
			if #mentions>1 then
				killerkey=SpeechHashTbl.NAMES.Key[mentions[2]] --Получаем ключ имени убийцы
				if not killerkey and entity=="WX78" then --тут только полный перебор, т.к. он говорит всё в верхнем регистре
					for eng, key in pairs(SpeechHashTbl.NAMES.Key) do
						if eng:upper()==mentions[2] then killerkey = key break end
					end
				end
				mentions[2]=killerkey and po[killerkey] or mentions[2]
				if killerkey then
					killerkey=killerkey:lower()
				end
				if table.contains(_G.GetActiveCharacterList(), killerkey) then killerkey=nil end
			end
		end
		message=string.format(message, _G.unpack(mentions or {"","","",""}))
		return message
	end
	
	local messages=split(message,"\n") or {message}
	message=""
	local i=1
	while i<=#messages do
		local trans
		trans=TranslateMessage(messages[i])
		if trans~=messages[i] then
			message=message..(i>1 and "\n" or "")..trans
			if i<#messages then
				message=message..TranslateMessage("\n"..messages[i+1])
				for k=i+2,#messages do message=message.."\n"..messages[k] end
			end
			break
		elseif i<#message then
			trans=TranslateMessage(messages[i].."\n"..messages[i+1])
			if trans~=messages[i].."\n"..messages[i+1] then
				message=message..(i>1 and "\n" or "")..trans
				for k=i+2,#messages do message=message.."\n"..messages[k] end
				break
			else
				message=message..(i>1 and "\n" or "")..messages[i]
				i=i+1
			end
		else
			message=message..(i>1 and "\n" or "")..messages[i]
			break
		end
	end
	return message
end

if rawget(_G,"Networking_Talk") then
	local OldNetworking_Talk=_G.Networking_Talk

	function Networking_Talk(guid, message, ...)
		-- print("Networking_Talk", guid, message, ...)
		local entity = _G.Ents[guid]
		message=KOTranslater(message,entity) or message --Переводим на русский
		if OldNetworking_Talk then OldNetworking_Talk(guid, message, ...) end
	end
	_G.Networking_Talk=Networking_Talk
end

if TheNet.Talker then
	_G.getmetatable(TheNet).__index.Talker = (function()
		local oldTalker = _G.getmetatable(TheNet).__index.Talker
		return function(self, message, entity, ... )
			oldTalker(self, message, entity, ...)
 
			local inst=entity and entity:GetGUID() or nil
			inst=inst and _G.Ents[inst] or nil --определяем инстанс персонажа по entity
			if inst and inst.components.talker.widget then --если он может говорить
				if message and type(message)=="string" then
					--Делаем одноразовую подмену для последующего задания текста, в котором осуществляем перевод.
					local OldSetString = inscomponents.talker.widgetexSetString
					function inst.components.talker.widgetext:SetString(str, ...)
						str = KOTranslater(str, inst) or str --переводим
						OldSetString(self, str, ...)
						self.SetString = OldSetString
					end
				end
			end
		end
	end)()
end

function BuildCharacterHash(charname, kosource)
	local source = kosource or po
	local function CreateHashTable(hashtbl,tbl,str)
		for i,v in pairs(tbl) do
			if type(v)=="table" then
				CreateHashTable(hashtbl,tbl[i],str.."."..i)
			else
				local val=source[str.."."..i] or val
				
				if v and string.find(v,"%s",1,true) then
					hashtbl["mentioned_class"]=hashtbl["mentioned_class"] or {}
					hashtbl["mentioned_class"][v]=val
				end
				if not hashtbl[v] then
					hashtbl[v]=val
				elseif type(hashtbl[v])=="string" and val~=hashtbl[v] then
					local temp=hashtbl[v]
					hashtbl[v]={}
					table.insert(hashtbl[v],temp)
					table.insert(hashtbl[v],val)
				elseif type(hashtbl[v])=="table" then
					local found=false
					for _,vv in ipairs(hashtbl[v]) do
						if vv==val then
							found=true
							break
						end
					end
					if not found then table.insert(hashtbl[v],val) end
				end
			end
		end
	end
	charname=charname:upper()
	if character=="WILSON" then character="GENERIC" end
	if character=="MAXWELL" then character="WAXWELL" end
	if character=="WIGFRID" then character="WATHGRITHR" end
	SpeechHashTbl[charname]={}
	CreateHashTable(SpeechHashTbl[charname],STRINGS.CHARACTERS[charname],"STRINGS.CHARACTERS."..charname)
end

for charname,v in pairs(STRINGS.CHARACTERS) do
	BuildCharacterHash(charname)
end

SpeechHashTbl.NAMES = {Tr={},Key={}}
for i,v in pairs(STRINGS.NAMES) do
	local fullkey = "STRINGS.NAMES."..i
	SpeechHashTbl.NAMES.Key[v] = fullkey
	SpeechHashTbl.NAMES.Tr[po[fullkey] or v] = v
end
 
--SpeechHashTbl.CHESSPIECE = {Tr={}, Key={}}
--for 

SpeechHashTbl.PIGNAMES={Tr={}}
for i,v in pairs(STRINGS.PIGNAMES) do
	SpeechHashTbl.PIGNAMES.Tr[v]=po["STRINGS.PIGNAMES."..i] or v
	po["STRINGS.PIGNAMES."..i]=nil
end
SpeechHashTbl.BUNNYMANNAMES={Tr={}}
for i,v in pairs(STRINGS.BUNNYMANNAMES) do
	SpeechHashTbl.BUNNYMANNAMES.Tr[v]=po["STRINGS.BUNNYMANNAMES."..i] or v
	po["STRINGS.BUNNYMANNAMES."..i]=nil
end
SpeechHashTbl.SWAMPIGNAMES={Tr={}}
for i,v in pairs(STRINGS.SWAMPIGNAMES) do
	SpeechHashTbl.SWAMPIGNAMES.Tr[v]=po["STRINGS.SWAMPIGNAMES."..i] or v
	po["STRINGS.SWAMPIGNAMES."..i]=nil
end

--The Gorge Mumsy Speeches
SpeechHashTbl.GOATMUM_CRAVING_HINTS={Tr={}}
for i,v in pairs(STRINGS.GOATMUM_CRAVING_HINTS) do
	SpeechHashTbl.GOATMUM_CRAVING_HINTS.Tr[v]=po["STRINGS.GOATMUM_CRAVING_HINTS."..i] or v
	po["STRINGS.GOATMUM_CRAVING_HINTS."..i]=nil
end
for i,v in pairs(STRINGS.GOATMUM_CRAVING_MATCH) do
	if string.find(po["STRINGS.GOATMUM_CRAVING_MATCH."..i],'%%s') then 
		SpeechHashTbl.GOATMUM_CRAVING_HINTS.Tr[v]=po["STRINGS.GOATMUM_CRAVING_MATCH."..i] or v
		po["STRINGS.GOATMUM_CRAVING_MATCH."..i]=nil
	end
end
for i,v in pairs(STRINGS.GOATMUM_CRAVING_MISMATCH) do
	if string.find(po["STRINGS.GOATMUM_CRAVING_MISMATCH."..i],'%%s') then 
		SpeechHashTbl.GOATMUM_CRAVING_HINTS.Tr[v]=po["STRINGS.GOATMUM_CRAVING_MISMATCH."..i] or v
		po["STRINGS.GOATMUM_CRAVING_MISMATCH."..i]=nil
	end
end

SpeechHashTbl.GOATMUM_CRAVING_HINTS_PART2={Tr={}}
for i,v in pairs(STRINGS.GOATMUM_CRAVING_HINTS_PART2) do
	SpeechHashTbl.GOATMUM_CRAVING_HINTS_PART2.Tr[v]=po["STRINGS.GOATMUM_CRAVING_HINTS_PART2."..i] or v
	po["STRINGS.GOATMUM_CRAVING_HINTS_PART2."..i]=nil
end
for i,v in pairs(STRINGS.GOATMUM_CRAVING_HINTS_PART2_IMPATIENT) do
	SpeechHashTbl.GOATMUM_CRAVING_HINTS_PART2.Tr[v]=po["STRINGS.GOATMUM_CRAVING_HINTS_PART2_IMPATIEN"..i] or v
	po["STRINGS.GOATMUM_CRAVING_HINTS_PART2_IMPATIEN"..i]=nil
end

SpeechHashTbl.GOATMUM_CRAVING_MAP={Tr={}}
for i,v in pairs(STRINGS.GOATMUM_CRAVING_MAP) do
	SpeechHashTbl.GOATMUM_CRAVING_MAP.Tr[v]=po["STRINGS.GOATMUM_CRAVING_MAP."..i] or v
	po["STRINGS.GOATMUM_CRAVING_MAP."..i]=nil
end


SpeechHashTbl.GOATMUM_WELCOME_INTRO={Tr={}}
for i,v in pairs(STRINGS.GOATMUM_WELCOME_INTRO) do
	SpeechHashTbl.GOATMUM_WELCOME_INTRO.Tr[v]=po["STRINGS.GOATMUM_WELCOME_INTRO."..i] or v
	po["STRINGS.GOATMUM_WELCOME_INTRO."..i]=nil
end
for i,v in pairs(STRINGS.GOATMUM_LOST) do
	SpeechHashTbl.GOATMUM_WELCOME_INTRO.Tr[v]=po["STRINGS.GOATMUM_LOS"..i] or v
	po["STRINGS.GOATMUM_LOS"..i]=nil
end
for i,v in pairs(STRINGS.GOATMUM_VICTORY) do
	SpeechHashTbl.GOATMUM_WELCOME_INTRO.Tr[v]=po["STRINGS.GOATMUM_VICTORY."..i] or v
	po["STRINGS.GOATMUM_VICTORY."..i]=nil
end
for i,v in pairs(STRINGS.GOATMUM_CRAVING_MATCH) do
	if po["STRINGS.GOATMUM_CRAVING_MATCH."..i] then 
		SpeechHashTbl.GOATMUM_WELCOME_INTRO.Tr[v]=po["STRINGS.GOATMUM_CRAVING_MATCH."..i] or v
		po["STRINGS.GOATMUM_CRAVING_MATCH."..i]=nil
	end
end
for i,v in pairs(STRINGS.GOATMUM_CRAVING_MISMATCH) do
	if po["STRINGS.GOATMUM_CRAVING_MISMATCH."..i] then 
		SpeechHashTbl.GOATMUM_WELCOME_INTRO.Tr[v]=po["STRINGS.GOATMUM_CRAVING_MISMATCH."..i] or v
		po["STRINGS.GOATMUM_CRAVING_MISMATCH."..i]=nil
	end
end

--Hash for epitaphs
SpeechHashTbl.EPITAPHS={}
for i,v in pairs(STRINGS.EPITAPHS) do
	if po["STRINGS.EPITAPHS."..i] then
		SpeechHashTbl.EPITAPHS[v]=po["STRINGS.EPITAPHS."..i] or v
	end
end

local GetDisplayNameOld=_G.EntityScript["GetDisplayName"]
function GetDisplayNameNew(self, act)
	
	local name = GetDisplayNameOld(self)
	local player = _G.ThePlayer
	
	
	if name and self.prefab then
		if self. prefab=="pigman" then
			name=SpeechHashTbl.PIGNAMES.Tr[name] or name
		elseif self.prefab=="pigguard" then
			name=SpeechHashTbl.PIGNAMES.Tr[name] or name
		elseif self.prefab=="bunnyman" then
			name=SpeechHashTbl.BUNNYMANNAMES.Tr[name] or name
		elseif self.prefab=="quagmire_swampig" then
			name=SpeechHashTbl.SWAMPIGNAMES.Tr[name] or name
		end
	end	
	return name
end
_G.EntityScript["GetDisplayName"]=GetDisplayNameNew


--saving announcement strings
local announcekor = announcekor or {}
announcekor.LEFTGAME=po["STRINGS.UI.NOTIFICATION.LEFTGAME"] or ""
announcekor.JOINEDGAME=po["STRINGS.UI.NOTIFICATION.JOINEDGAME"] or ""
announcekor.KICKEDFROMGAME=po["STRINGS.UI.NOTIFICATION.KICKEDFROMGAME"] or ""
announcekor.BANNEDFROMGAME=po["STRINGS.UI.NOTIFICATION.BANNEDFROMGAME"] or ""

announcekor.DEATH_ANNOUNCEMENT_1=po["STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1"] or ""
announcekor.DEATH_ANNOUNCEMENT_2_MALE=po["STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_MALE"] or ""
announcekor.DEATH_ANNOUNCEMENT_2_FEMALE=po["STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_FEMALE"] or ""
announcekor.DEATH_ANNOUNCEMENT_2_ROBOT=po["STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_ROBOT"] or ""
announcekor.DEATH_ANNOUNCEMENT_2_DEFAULT=po["STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_DEFAULT"] or ""
announcekor.GHOST_DEATH_ANNOUNCEMENT_MALE=po["STRINGS.UI.HUD.GHOST_DEATH_ANNOUNCEMENT_MALE"] or ""
announcekor.GHOST_DEATH_ANNOUNCEMENT_FEMALE=po["STRINGS.UI.HUD.GHOST_DEATH_ANNOUNCEMENT_FEMALE"] or ""
announcekor.GHOST_DEATH_ANNOUNCEMENT_ROBOT=po["STRINGS.UI.HUD.GHOST_DEATH_ANNOUNCEMENT_ROBOT"] or ""
announcekor.GHOST_DEATH_ANNOUNCEMENT_DEFAULT=po["STRINGS.UI.HUD.GHOST_DEATH_ANNOUNCEMENT_DEFAULT"] or ""
announcekor.REZ_ANNOUNCEMENT=po["STRINGS.UI.HUD.REZ_ANNOUNCEMENT"] or ""
announcekor.START_AFK=po["STRINGS.UI.HUD.START_AFK"] or ""
announcekor.STOP_AFK=po["STRINGS.UI.HUD.STOP_AFK"] or ""

po["STRINGS.UI.NOTIFICATION.LEFTGAME"]=nil
po["STRINGS.UI.NOTIFICATION.JOINEDGAME"]=nil
po["STRINGS.UI.NOTIFICATION.KICKEDFROMGAME"]=nil
po["STRINGS.UI.NOTIFICATION.BANNEDFROMGAME"]=nil
po["STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1"]=nil
po["STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_MALE"]=nil
po["STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_FEMALE"]=nil
po["STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_ROBOT"]=nil
po["STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_DEFAULT"]=nil
po["STRINGS.UI.HUD.GHOST_DEATH_ANNOUNCEMENT_MALE"]=nil
po["STRINGS.UI.HUD.GHOST_DEATH_ANNOUNCEMENT_FEMALE"]=nil
po["STRINGS.UI.HUD.GHOST_DEATH_ANNOUNCEMENT_ROBOT"]=nil
po["STRINGS.UI.HUD.GHOST_DEATH_ANNOUNCEMENT_DEFAULT"]=nil
po["STRINGS.UI.HUD.REZ_ANNOUNCEMENT"]=nil
po["STRINGS.UI.HUD.START_AFK"]=nil
po["STRINGS.UI.HUD.STOP_AFK"]=nil

--Hooking for Death Announcement
AddClassPostConstruct("widgets/eventannouncer", function(self)
	local oldGetNewDeathAnnouncementString=_G.GetNewDeathAnnouncementString
	function newGetNewDeathAnnouncementString(theDead, source, pkname, sourceispet)
		local str=oldGetNewDeathAnnouncementString(theDead, source, pkname, sourceispet)
		if _G.TheWorld and not _G.TheWorld.ismastersim then return str end
		if string.find(str,STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1,1,true) then
			local capturestring=nil
			if string.find(str,STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_MALE,1,true) then
				capturestring="( "..STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1.." )(.*)("..STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_MALE..")"
			elseif string.find(str,STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_FEMALE,1,true) then
				capturestring="( "..STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1.." )(.*)("..STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_FEMALE..")"
			elseif string.find(str,STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_ROBOT,1,true) then
				capturestring="( "..STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1.." )(.*)("..STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_ROBOT..")"
			elseif string.find(str,STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_DEFAULT,1,true) then
				capturestring="( "..STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1.." )(.*)("..STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_DEFAULT..")"
			else 
				capturestring="( "..STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1.." )(.*)(%.)$"
			end
			if capturestring then
				local a, killername, b=str:match(capturestring)
				if killername then
					killername=SpeechHashTbl.NAMES.Tr[killername] or killername
					str=str:gsub(capturestring,"%1"..killername.."%3")
				end
			end
		end
		return str
	end
	_G.GetNewDeathAnnouncementString=newGetNewDeathAnnouncementString
	
	local oldGetNewRezAnnouncementString=_G.GetNewRezAnnouncementString
	function NewGetRezAnnouncementString(theRezzed, source, ...)
		source=source and (SpeechHashTbl.NAMES.Tr[source] or source)
		return oldGetNewRezAnnouncementString(TheRezzed, source, ...)
	end
	_G.GetNewRezAnnouncementString=NewGetRezAnnouncementString
	
	local OldShowNewAnnouncement = self.ShowNewAnnouncement
	if OldShowNewAnnouncement then function self:ShowNewAnnouncement(announcement, ...)
		local gender, player, message_tr, name, name2, killerkey
		
		local function test(adder1,msg1,msgtr1,adder2,msg2,msgtr2)
			if name or name2 then return end
			msg1=msg1 and msg1:gsub("%%s","(.*)") or ""
			msg2=msg2 and msg2:gsub("%%s","(.*)") or ""
			name, name2=announcement:match((adder1 or "")..msg1..(adder2 or "")..msg2)
			if name then message_tr=msgtr1 end
			if adder2 and name and name2 and msgtr2 then message_tr=message_tr..msgtr2 end
		end
		
		test(nil,STRINGS.UI.NOTIFICATION.JOINEDGAME, announcekor.JOINEDGAME)
		test(nil,STRINGS.UI.NOTIFICATION.LEFTGAME, announcekor.LEFTGAME)
		
		test(nil,STRINGS.UI.NOTIFICATION.KICKEDFROMGAME, announcekor.KICKEDFROMGAME)
		test(nil,STRINGS.UI.NOTIFICATION.BANNEDFROMGAME, announcekor.BANNEDFROMGAME)
		
		if not name2 then
			test("(.*) ",STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1, announcekor.DEATH_ANNOUNCEMENT_1,
				 " (.*)",STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_MALE, announcekor.DEATH_ANNOUNCEMENT_2_MALE)
			test("(.*) ",STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1, announcekor.DEATH_ANNOUNCEMENT_1,
				 " (.*)",STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_FEMALE, announcekor.DEATH_ANNOUNCEMENT_2_FEMALE)
			test("(.*) ",STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1, announcekor.DEATH_ANNOUNCEMENT_1,
				 " (.*)",STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_ROBOT, announcekor.DEATH_ANNOUNCEMENT_2_ROBOT)
			test("(.*) ",STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1, announcekor.DEATH_ANNOUNCEMENT_1,
				 " (.*)",STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_2_DEFAULT, announcekor.DEATH_ANNOUNCEMENT_2_DEFAULT)
			test("(.*) ",STRINGS.UI.HUD.DEATH_ANNOUNCEMENT_1, announcekor.DEATH_ANNOUNCEMENT_1, " (.*)%.$", nil, nil, ".")
			test("(.*) ",STRINGS.UI.HUD.GHOST_DEATH_ANNOUNCEMENT_MALE, announcekor.GHOST_DEATH_ANNOUNCEMENT_MALE)
			test("(.*) ",STRINGS.UI.HUD.GHOST_DEATH_ANNOUNCEMENT_FEMALE, announcekor.GHOST_DEATH_ANNOUNCEMENT_FEMALE)
			test("(.*) ",STRINGS.UI.HUD.GHOST_DEATH_ANNOUNCEMENT_ROBOT, announcekor.GHOST_DEATH_ANNOUNCEMENT_ROBOT)
			test("(.*) ",STRINGS.UI.HUD.GHOST_DEATH_ANNOUNCEMENT_DEFAULT, announcekor.GHOST_DEATH_ANNOUNCEMENT_DEFAULT)
			test("(.*) ",STRINGS.UI.HUD.REZ_ANNOUNCEMENT, announcekor.REZ_ANNOUNCEMENT, " (.*)%.$", nil, nil, ".")

			if name2 then
				ispet = name2:match(" 's")
				if ispet then
					local pkname, petname
					pkname, petname = name2:match("(.*)".."'s ".."(.*)")
					killerkey=SpeechHashTbl.NAMES.Key[petname]
					petname = po[killerkey] or petname
					name2=string.format(po["STRINGS.UI.HUD.DEATH_PET_NAME"], pkname, petname)
				else
					killerkey=SpeechHashTbl.NAMES.Key[name2]
				end
				if killerkey then
					name2=po[killerkey]
				end
			end
		end
		if name and message_tr then
			if TheNet.GetClientTable then TheNet:GetClientTable()	end
			announcement = string.format(message_tr, name or "", name2 or "") or announcement
		end
		OldShowNewAnnouncement(self, announcement,...)
		end
	end
end)

--Reassigns sketch, adverts, and blueprints. By Yukari
AddClassPostConstruct("components/named_replica", function(self)
	local function OnNameDirtyMoose(inst)
		inst.name = inst.possiblenames[math.random(#inst.possiblenames)]
	end
	
	local function OnNameDirty(inst)
		local item, itemgroup
		local function test(origin, itemtype)
			if item or itemgroup then return end
			item = origin:match("(.*)".." "..itemtype)
			if item then itemgroup = itemtype end
		end
		local str = inst.replica.named._name:value()
		test(str, "Blueprint")
		test(str, "Sketch")
		test(str, "Advert")
		--print("debug OnNameDirty:"..item..", "..itemgroup..", "..str)
		--for k, v in pairs(self) do
		--	print(k, v)
		--end
			
		if item ~= nil then
			if itemgroup == "Sketch" then
				--print("this is sketch:"..item)
				inst.name = string.gsub(STRINGS.NAMES.SKETCH, "{item}", po[SpeechHashTbl.NAMES.Key[item]])--str:gsub(subfmt(STRINGS.NAMES.SKETCH, {item = name}), subfmt(po["STRINGS.NAMES.SKETCH"], {item = po[SpeechHashTbl.Key[name]]}))
			elseif itemgroup == "Blueprint" then
				--print("this is blueprint: "..item)
				inst.name = string.gsub(STRINGS.NAMES.BLUEPRINT_RARE, "{item}", po[SpeechHashTbl.NAMES.Key[item]])--str:gsub(subfmt(STRINGS.NAMES.BLUEPRINT_RARE, {item = name}), subfmt(po["STRINGS.NAMES.BLUEPRINT_RARE"], {item = po[SpeechHashTbl.Key[name]]}))
			elseif itemgroup == "Advert" then
				--print("this is advert:"..item)
				inst.name = string.gsub(STRINGS.NAMES.TACKLESKETCH, "{item}", po[SpeechHashTbl.NAMES.Key[item]])--str:gsub(subfmt(STRINGS.NAMES.TACKLESKETCH, {item = name}), subfmt(po["STRINGS.NAMES.TACKLESKETCH"], {item = po[SpeechHashTbl.Key[name]]}))
			end
		else
			inst.name = str ~= "" and str or STRINGS.NAMES[string.upper(inst.prefab)]
		end
	end
	
	self.inst.event_listening.namedirty[self.inst] = nil -- Yukari: We need to remove the event related namedirty but since replica's listner is only this one and I have no idea how to track this local function value with UpvalueHacker, remove all instead.
	
	if not _G.TheWorld.ismastersim then
		if self.inst.prefab=="moose" then
			self.inst.possiblenames={STRINGS.NAMES["MOOSE1"], STRINGS.NAMES["MOOSE2"]}
			self.inst:ListenForEvent("namedirty", OnNameDirtyMoose)
		elseif self.inst.prefab=="mooseegg" then
			self.inst.possiblenames={STRINGS.NAMES["MOOSEEGG1"], STRINGS.NAMES["MOOSEEGG2"]}
			self.inst:ListenForEvent("namedirty", OnNameDirtyMoose)
		elseif self.inst.prefab=="moosenest" then
			self.inst.possiblenames={STRINGS.NAMES["MOOSENEST1"], STRINGS.NAMES["MOOSENEST2"]}
			self.inst:ListenForEvent("namedirty", OnNameDirtyMoose)
		else
			self.inst:ListenForEvent("namedirty", OnNameDirty) -- redefine event callback.
		end
	end
end)



---------------------------------------------------------
-- Added Overriding Function --
-- Change word order.(nouns + Verb or adjective + nouns)
---------------------------------------------------------

-- In WorldgenScreen
local worldgenscreen = _G.require "screens/worldgenscreen"
local ChangeFlavourText_Old = worldgenscreen.ChangeFlavourText or function() end
	
function worldgenscreen:ChangeFlavourText()
	self.flavourtext:SetString(self.nouns[self.nounidx].." "..self.verbs[self.verbidx])
	ChangeFlavourText_Old(self)
	self.flavourtext:SetString(self.nouns[self.nounidx].." "..self.verbs[self.verbidx])
end

-- In-Game Hovering Text
local hoverer = _G.require "widgets/hoverer"
local HoveringText = hoverer.OnUpdate or function() end
function hoverer:OnUpdate()
	HoveringText(self)
	if self.isFE == false then
		str = self.owner.HUD.controls:GetTooltip()
	else
		str = self.owner:GetTooltip()
	end
	
	local lmb = nil
	if str == nil and self.isFE == false and self.owner:IsActionsVisible() then
		local lmb = self.owner.components.playercontroller:GetLeftMouseAction()
		if lmb ~= nil then
			local overriden
			str, overriden = lmb:GetActionString()
			
			if not overriden and lmb.target ~= nil and lmb.invobject == nil and lmb.target ~= lmb.doer then
				local name = lmb.target:GetDisplayName()
				if name ~= nil then
					local adjective = lmb.target:GetAdjective()
					if lmb.target.replica.stackable ~= nil and lmb.target.replica.stackable:IsStack() then
						str = (adjective ~= nil and (adjective.." "..name) or name).." "..tostring(lmb.target.replica.stackable:StackSize()).." 개 "..str
					else
						str = (adjective ~= nil and (adjective.." "..name) or name).." "..str
					end
				end
			end
		end
		if str then
			self.text:SetString(str)
			self.str = str
		end
	end
end

-- pp. handling of player name for player
local function GetStatus(inst, viewer)
    return (inst:HasTag("playerghost") and "GHOST")
        or (inst.hasRevivedPlayer and "REVIVER")
        or (inst.hasKilledPlayer and "MURDERER")
        or (inst.hasAttackedPlayer and "ATTACKER")
        or (inst.hasStartedFire and "FIRESTARTER")
        or nil
end

local function TryDescribe(descstrings, modifier)
    return descstrings ~= nil and (
            type(descstrings) == "string" and
            descstrings or
            descstrings[modifier] or
            descstrings.GENERIC
        ) or nil
end

local function TryCharStrings(inst, charstrings, modifier)
    return charstrings ~= nil and (
            TryDescribe(charstrings.DESCRIBE[string.upper(inst.prefab)], modifier) or
            TryDescribe(charstrings.DESCRIBE.PLAYER, modifier)
        ) or nil
end

local function GetDescription(inst, viewer)
	local modifier = inst.components.inspectable:GetStatus(viewer) or "GENERIC"
	local desc = TryCharStrings(inst, STRINGS.CHARACTERS[string.upper(viewer.prefab)], modifier) or
            TryCharStrings(inst, STRINGS.CHARACTERS.GENERIC, modifier)
	local name = inst:GetDisplayName()
	desc = pp.replacePP(desc, "%%s", name)
    
    return string.format(desc, name)
end

AddPrefabPostInit("player_common", function(inst)
	inst.components.inspectable.getspecialdescription = GetDescription
end)

--pp. handling of player name for player_skeleton



--pp. handling for Carrat Race
local function getdesc(inst, viewer)
	if inst:HasTag("burnt") then
		return GetDescription(viewer, inst, "BURNT")
	elseif inst._active and inst._winner ~= nil then
		if inst._winner.userid ~= nil and inst._winner.userid == viewer.userid then
			return GetDescription(viewer, inst, "I_WON")
		elseif inst._winner.name ~= nil then
			return subfmt(pp.replacePP(GetDescription(viewer, inst, "SOMEONE_ELSE_WON"), "{winner}", inst._winner.name), { winner = inst._winner.name })
		end
	end
	
	return GetDescription(viewer, inst) or nil
end
AddPrefabPostInit("yotc_carrat_race_finish", function(inst)
	inst.components.inspectable.getspecialdescription = getdesc
end)

-- In-Game UI Clock
AddClassPostConstruct("widgets/uiclock", function(self)
	local UpdateDayStr = self.UpdateDayString or function() end
	local basescale = 1
	
	function self:UpdateDayString()
		UpdateDayStr(self)
		
		if self._cycles ~= nil then
			self._text:SetString(tostring(GLOBAL.ThePlayer.Network:GetPlayerAge() ).." "..STRINGS.UI.HUD.CLOCKDAY)
		else
			self._text:SetString("")
		end
		self._showingcycles = false
	end
	
	local UpdateWorldStr = self.UpdateWorldString or function() end
	function self:UpdateWorldString()
		UpdateWorldStr(self)

		self._text:SetString("세계 날짜\n"..tostring(GLOBAL.TheWorld.state.cycles + 1).." "..STRINGS.UI.HUD.WORLD_CLOCKDAY)
		self._text:SetPosition(3, 0 / basescale, 0)
		self._text:SetSize(28)
		self._showingcycles = true
	end
end)

------------------------------------------