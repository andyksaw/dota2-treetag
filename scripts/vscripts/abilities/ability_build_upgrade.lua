function OnUpgrade(keys)
	local ability = keys.ability;
	local caster = keys.caster;
	local increment = 1.0;

	if caster.isUpgrading then
		return;
	end
	caster._isUpgrading = true;

	local upgradeTimes = StringToTable(keys.UpgradeTime, function(i) return tonumber(i); end);
	local upgradeTime = upgradeTimes[ability:GetLevel()];

	-- add upgrade channel
	caster:AddAbility("ability_channel_upgrade");
	local ability = caster:FindAbilityByName("ability_channel_upgrade");
	ability:SetLevel(upgradeTime);
	Timers:CreateTimer(function()
	    caster:CastAbilityOnTarget(caster, ability, caster:GetPlayerOwnerID());
	end);

	-- create particle
	local particle = BasicParticle("particles/econ/items/tinker/boots_of_travel/teleport_end_bots.vpcf", caster, caster:GetAbsOrigin());
	caster._upgradeParticle = particle;

	caster._upgradeElapsed = 0;
	Timers:CreateTimer(function()
	    if caster:IsAlive() then

	    	if caster._upgradeElapsed >= upgradeTime then
	    		OnUpgradeFinished(keys);
	    	else
	    		caster._upgradeElapsed = caster._upgradeElapsed + increment;
	    		return increment;
	    	end

		end
	end);
end

function OnUpgradeFinished(keys)
	local caster = keys.caster;
	local ability = keys.ability;

	caster._isUpgrading = nil;

	local value = ability:GetSpecialValueFor("cost");
	caster._buildValue = caster._buildValue + value;

	local newLevel = ability:GetLevel();

	ability:SetLevel(newLevel + 1);
	caster:RemoveAbility("ability_channel_upgrade");
	--caster:SetLevel(caster:GetLevel() + 1);

	if caster._upgradeParticle ~= nil then
		ParticleManager:DestroyParticle(caster._upgradeParticle, false);
		caster._upgradeParticle = nil;
	end

	if keys.Name ~= nil then
		local names = StringToTable(keys.Name);
		local name = names[newLevel];
		caster:SetUnitName(name);
	end

	if keys.HealthBoost ~= nil then
		local healthBoosts = StringToTable(keys.HealthBoost, function(i) return tonumber(i); end);
		local healthBoost = healthBoosts[newLevel];
		caster:SetMaxHealth(caster:GetMaxHealth() + healthBoost);
		caster:SetHealth(caster:GetMaxHealth());
	end

	if keys.Armor ~= nil then
		local armors = StringToTable(keys.Armor, function(i) return tonumber(i); end);
		local armor = armors[newLevel];
		caster:SetPhysicalArmorBaseValue(armor);
	end

	if keys.Describer ~= nil then
		local describer = caster:FindAbilityByName(keys.Describer);
		if describer ~= nil then
			describer:SetLevel(describer:GetLevel() + 1);
		end
	end

	if newLevel >= ability:GetMaxLevel() then
		caster:RemoveAbility(ability:GetAbilityName());
	end

	if keys.Callback ~= nil then
		keys.Callback();
	end


end

function OnUpgradeFarm(keys)
	local newAbilityLevel = keys.ability:GetLevel();

	keys.Callback = function()
		local caster = keys.caster;
		local incomeList = StringToTable(keys.Income, function(i) return tonumber(i); end);

		local currentFarmIncome = caster._farmIncome;
		local newFarmIncome = incomeList[newAbilityLevel];
		local playerID = caster:GetPlayerOwnerID();

		local playerIncome = TreeTag.Treants[playerID]['INCOME'];
		TreeTag.Treants[playerID]['INCOME'] = playerIncome - currentFarmIncome + newFarmIncome;
		caster._farmIncome = newFarmIncome;
	end

	OnUpgrade(keys);
end

function OnUpgradeSentry(keys)
	local newAbilityLevel = keys.ability:GetLevel();

	keys.Callback = function()
		local caster = keys.caster;
		local dayVision = StringToTable(keys.DayVision, function(i) return tonumber(i); end);
		local nightVision = StringToTable(keys.NightVision, function(i) return tonumber(i); end);
		local trueSight = StringToTable(keys.TrueSight);

		local dummy = caster._dummyUnit;
		dummy:SetDayTimeVisionRange(dayVision[newAbilityLevel]);
		dummy:SetNightTimeVisionRange(nightVision[newAbilityLevel]);

		if trueSight == "true" then
			caster:AddAbility("ability_sentry_truesight");
			caster:AddNewModifier(caster, nil, "modifier_truesight", nil);
		end
	end

	OnUpgrade(keys);
end