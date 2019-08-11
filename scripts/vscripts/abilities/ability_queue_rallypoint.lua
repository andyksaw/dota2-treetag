function OnCreated(keys)
	local caster = keys.caster;
	caster._uqOrigin = caster:GetAbsOrigin();
	caster._canSetRallypoint = true;
end

function OnSetRally(keys)
	local point = keys.target_points[1];
	local caster = keys.caster;

	caster._uqRallyPoint = point;

	-- TODO: allow only 1 particle at a time
	local particle = ParticleManager:CreateParticleForPlayer("particles/units/heroes/hero_kunkka/kunkka_spell_x_spot.vpcf", PATTACH_ABSORIGIN, caster, caster:GetPlayerOwner());
	ParticleManager:SetParticleControl(particle, 0, point);
	Timers:CreateTimer({
		endTime = 3,
		callback = function() 
			ParticleManager:DestroyParticle(particle, false);
		end
	});
end