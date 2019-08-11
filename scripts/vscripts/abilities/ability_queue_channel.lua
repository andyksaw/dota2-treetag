function OnChannelBegin(keys)
	local caster = keys.caster;
	local target = keys.target;

	if caster._isChanneling then
		return;
	end
	caster._isChanneling = true;

	local startDelay = 0.03;

	Timers:CreateTimer({
		endTime = caster._uqBuildTime - startDelay,
		callback = function() 
			OnChannelFinish(caster);
		end
	});

	local particle = ParticleManager:CreateParticle("particles/items2_fx/teleport_end_tube.vpcf", PATTACH_ABSORIGIN, caster);
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin());
	caster._uqParticle = particle;
end

function OnChannelFinish(caster)
	local caster = caster;
	caster._isChanneling = nil;

	caster:RemoveAbility("ability_unit_channel_timer");
	caster:SetMana(caster:GetMana() + 1);

	-- clean up the build queue particle
	if caster._uqParticle ~= nil then
		ParticleManager:DestroyParticle(caster._uqParticle, false);
		caster._uqParticle = nil;
	end

	-- create build complete particle
	local particle = ParticleManager:CreateParticle("particles/neutral_fx/roshan_spawn.vpcf", PATTACH_ABSORIGIN, caster);
	ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin());
	Timers:CreateTimer({
		endTime = 3,
		callback = function() ParticleManager:DestroyParticle(particle, false); end
	});

	-- spawn unit
	local owner = caster:GetPlayerOwner():GetAssignedHero();
	local unit = CreateUnitByName(caster._uqUnitName, caster:GetAbsOrigin() + RandomVector(100), true, owner, owner, caster:GetPlayerOwner():GetTeam());
	unit:SetControllableByPlayer(caster:GetPlayerOwnerID(), true);
	unit:SetTeam(caster:GetPlayerOwner():GetTeam());
	unit:SetOwner(owner);

	unit:AddNewModifier(unit, nil, "modifier_phased", {Duration = 3.0});
	unit._isUnit = true;

	local rallyPoint = caster._uqRallyPoint;
	if rallyPoint ~= nil then
		if unit:HasAttackCapability() then
			ExecuteOrderFromTable({ UnitIndex = unit:GetEntityIndex(),
                           	 	OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
                            	Position = rallyPoint, Queue = true })
		else
			ExecuteOrderFromTable({ UnitIndex = unit:GetEntityIndex(),
                            	OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                            	Position = rallyPoint, Queue = true })
		end
	end

	local particle = ParticleManager:CreateParticle("particles/econ/items/meepo/meepo_diggers_divining_rod/meepo_divining_rod_poof_end.vpcf", PATTACH_ABSORIGIN, unit);
	ParticleManager:SetParticleControl(particle, 0, unit:GetAbsOrigin() + Vector(0, 55, 0));
	Timers:CreateTimer({
		endTime = 3,
		callback = function() ParticleManager:DestroyParticle(particle, false); end
	});

	-- process queue again for any other queued build orders
	caster:ProcessQueue();
end