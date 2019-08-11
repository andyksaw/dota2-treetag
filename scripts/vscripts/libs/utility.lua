function BroadcastMessage( sMessage, fDuration )
    local centerMessage = {
        message = sMessage,
        duration = fDuration
    }
    FireGameEvent( "show_center_message", centerMessage )
end

function Count(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

--[[
	Searches Key column in given table (haystack) for a value (needle)
]]
function ContainsKey(haystack, needle)
	local exists = false;
	for k,v in pairs(haystack) do
		if k == needle then
			exists = true;
			break;
		end
	end

	return exists;
end

function ContainsValue(haystack, needle)
	local exists = false;
	for k,v in pairs(haystack) do
		if v == needle then
			exists = true;
			break;
		end
	end

	return exists;
end

function TableContains(haystack, needle)
	if haystack == nil then	return nil;	end

	if type(needle) == "table" then
		for k,v in pairs(haystack) do
			for _k,_v in pairs(needle) do
				if v == _v then return true; end
			end
		end
	else
		for k,v in pairs(haystack) do
			if v == needle then	return true; end
		end
	end
	return false;
end

function CreateFlyingDummy(location, player, day_vision, night_vision, duration)
	local unit = CreateUnitByName("npc_flying_dummy", location, false, player:GetAssignedHero(), player:GetAssignedHero(), player:GetTeam());
	local ability = unit:FindAbilityByName("passive_flying_dummy");
	ability:SetLevel(1);

	unit:SetDayTimeVisionRange(day_vision);
	unit:SetNightTimeVisionRange(night_vision);

	if duration ~= nil then
		Timers:CreateTimer({
		    endTime = duration,
		    callback = function()
		    	unit:ForceKill(false);
		    end
		 });
	end
	return unit;
end

function BasicParticle(particleName, caster, location, duration, destroyImmediately, controls)
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, caster);

	local controls = controls or {0, 1, 2};
	for _,index in pairs(controls) do
		ParticleManager:SetParticleControl(particle, index, location);
	end
	
	if duration ~= nil then
		Timers:CreateTimer({
			endTime = duration,
			callback = function()
				ParticleManager:DestroyParticle(particle, destroyImmediately);
			end
		});
	end
	return particle;
end

function StringToTable(string, callbackEach)
	local temp = {};
	for i in string.gmatch(string, "%S+") do
		if callbackEach ~= nil then
			i = callbackEach(i);
		end
		table.insert(temp, i);
	end
	return temp;
end

function Round(num, idp)
	local mult = 10^(idp or 0)
  	return math.floor(num * mult + 0.5) / mult
end

function CreateQuest(name, endTime, onTick, onFinish)
	local Quest = SpawnEntityFromTableSynchronous( "quest", { name = name, title = "#"..name } );
    Quest.EndTime = endTime;

    local subQuest = SpawnEntityFromTableSynchronous( "subquest_base", { 
           show_progress_bar = true, 
           progress_bar_hue_shift = -119 
         } )
    Quest:AddSubquest( subQuest );

    -- text on the quest timer at start
	Quest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, endTime );
	Quest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, endTime );
	-- value on the bar
	subQuest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, endTime );
	subQuest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, endTime );

	-- timer
    Timers:CreateTimer(1, function()
	    Quest.EndTime = Quest.EndTime - 1
	    Quest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, Quest.EndTime );
	    subQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, Quest.EndTime );

	    if onTick ~= nil then
		    onTick();
		end

	    if Quest.EndTime <= 0 then 
	    	if onFinish ~= nil then
		    	onFinish();
		    end
	        Quest:CompleteQuest();
	        return
	    else
	        return 1
	    end
	end);
end

function DestroyTreesInArea(location, radius, team)
	local trees = GridNav:GetAllTreesAroundPoint(location, radius, true);
	for _,tree in pairs(trees) do
		TreeTag.CutTrees[tree:GetAbsOrigin()] = tree;
		tree:CutDown(team);
	end
end