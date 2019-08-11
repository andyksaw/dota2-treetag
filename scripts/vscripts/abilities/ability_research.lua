--[[
	Level up the specified skill.
	Adds skill to unit if it doesn't have it.
]]
function OnResearchSkillLevel(keys)
	local caster = keys.caster;
	local ability = keys.ability;

	if caster._isChanneling then
		return;
	end
	caster._isChanneling = true;

	local researchTimes = StringToTable(keys.ResearchTime, function(i) return tonumber(i); end);
	local researchTime = researchTimes[ability:GetLevel()];
	local increment = 1.0;

	-- add and use channeling ability as an indicator of research time
	caster:AddAbility("ability_channel_upgrade");
	local ability = caster:FindAbilityByName("ability_channel_upgrade");
	ability:SetLevel(researchTime);

	Timers:CreateTimer({
		endTime = 0.03,
		callback = function() 
			caster:CastAbilityNoTarget(ability, caster:GetPlayerOwnerID());
		end
	});	

	-- create particle
	local particle = BasicParticle("particles/econ/items/tinker/boots_of_travel/teleport_end_bots.vpcf", caster, caster:GetAbsOrigin());
	caster._researchParticle = particle;

	caster._researchElapsed = 0;
	Timers:CreateTimer(function()
	    if caster:IsAlive() then
	    	if caster._researchElapsed >= researchTime then
	    		OnResearchSkillFinished(keys);
	    	else
	    		caster._researchElapsed = caster._researchElapsed + increment;
	    		return increment;
	    	end
		end
	end);
end

function OnResearchSkillFinished(keys)
	local caster = keys.caster;
	local ability = keys.ability;

	caster._isChanneling = nil;

	local newLevel = ability:GetLevel();

	ability:SetLevel(newLevel + 1);
	caster:RemoveAbility("ability_channel_upgrade");

	if newLevel >= ability:GetMaxLevel() then
		caster:RemoveAbility(ability:GetAbilityName());
	end

	local researchedSkill = keys.Skill;
	if researchedSkill ~= nil then
		ability = caster:FindAbilityByName(researchedSkill);

		if ability == nil then
			caster:AddAbility(researchedSkill);
			ability = caster:FindAbilityByName(researchedSkill);
		else
			ability:SetLevel( ability:GetLevel() + 1 );
		end
	end

	if caster._researchParticle ~= nil then
		ParticleManager:DestroyParticle(caster._researchParticle, false);
		caster._researchParticle = nil;
	end

	if keys.ResearchCallback ~= nil then
		keys.ResearchCallback(caster);
	end
end

function ResearchBlinkUpgrade(keys)
	keys.ResearchCallback = function(caster)
		local player = caster:GetPlayerOwner();
		local hero = player:GetAssignedHero();

		local ability = hero:FindAbilityByName("antimage_blink");
		if ability ~= nil then
			ability:SetLevel(ability:GetLevel() + 1);
		end
	end

	OnResearchSkillLevel(keys);
end

function ResearchRegrowUpgrade(keys)
	keys.ResearchCallback = function(caster)
		local player = caster:GetPlayerOwner();
		local hero = player:GetAssignedHero();

		local ability = hero:FindAbilityByName("ability_regrow_trees_area");
		if ability ~= nil then
			ability:SetLevel(ability:GetLevel() + 1);
		else
			hero:AddAbility("ability_regrow_trees_area");
			ability = hero:FindAbilityByName("ability_regrow_trees_area"):SetLevel(1);
		end
	end

	OnResearchSkillLevel(keys);
end