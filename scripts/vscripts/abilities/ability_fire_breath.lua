function OnCast(keys)
	local caster = keys.caster;

	BasicParticle(TreeTag.PARTICLES['ability_fire_breath'], keys.caster, keys.caster:GetAbsOrigin(), 2, false);
end