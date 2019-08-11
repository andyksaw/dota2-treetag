function OnSummon(keys)
	local caster = keys.caster;
	local ability = keys.ability;

	if caster._spirits ~= nil then
		for k,spirit in pairs(caster._spirits) do
			ParticleManager:DestroyParticle(spirit._particle, false);
			spirit:ForceKill(false);
		end
	end

	local special_level = ability:GetLevel() - 1;
	local count = ability:GetLevelSpecialValueFor("unit_count", special_level);
	local health = ability:GetLevelSpecialValueFor("health", special_level);
	local scale = ability:GetLevelSpecialValueFor("scale", special_level);
	local speed = ability:GetLevelSpecialValueFor("movespeed", special_level);
	local damage = ability:GetLevelSpecialValueFor("min_damage", special_level);


	caster._spirits = {};
	for i=1,count do
		local unit = CreateUnitByName("npc_dota_creature_infernal_spirit", caster:GetAbsOrigin(), true, caster, caster, DOTA_TEAM_BADGUYS);
		unit:SetControllableByPlayer(caster:GetOwner():GetPlayerID(), true);

		unit:SetMaxHealth(health);
		unit:SetHealth(health);
		unit:SetModelScale(scale);
		unit:SetBaseMoveSpeed(speed);
		unit:SetBaseDamageMin(damage - 10);
		unit:SetBaseDamageMax(damage + 10);

		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_forge_spirit_ambient.vpcf", PATTACH_EYES_FOLLOW, unit);
		ParticleManager:SetParticleControl(particle, 1, unit:GetAbsOrigin());
		unit._particle = particle;

		unit.OnDeath = function()
			ParticleManager:DestroyParticle(particle, true);
		end

		table.insert(caster._spirits, unit);
	end

	EmitSoundOn("Hero_Invoker.ForgeSpirit", caster);
end