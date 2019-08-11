function OnNuke(keys)
	local caster = keys.caster;
	local ability = keys.ability;

	local specialLevel = ability:GetLevel() - 1;
	local radius = ability:GetLevelSpecialValueFor("radius", specialLevel);
	local damage = ability:GetLevelSpecialValueFor("damage", specialLevel);

	EmitSoundOn("Hero_Phoenix.SuperNova.Explode", caster);

	BasicParticle(TreeTag.PARTICLES['ability_nuke_slam'], keys.caster, keys.caster:GetAbsOrigin(), 2, false);
	BasicParticle(TreeTag.PARTICLES['ability_nuke_end'], keys.caster, keys.caster:GetAbsOrigin(), 2, false);
	DestroyTreesInArea(caster:GetAbsOrigin(), radius, caster:GetTeam());

	local units = FindUnitsInRadius(
		DOTA_TEAM_BADGUYS,
		caster:GetAbsOrigin(), 
		nil, 
		radius, 
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false 
	);


	local damage = {
		victim = nil,
		attacker = caster,
		damage = damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
	}

	for _,unit in pairs(units) do
		damage['victim'] = unit;
		ApplyDamage(damage);
	end
end