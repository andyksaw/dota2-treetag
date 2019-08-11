function OnUse(keys)
	local caster = keys.caster;
	local point = keys.target_points[1];
	local player = caster:GetOwner();

	AddFOWViewer(player:GetTeam(), point, 1350, 7, false);

	-- display red marker for treants
	MinimapEvent( DOTA_TEAM_GOODGUYS, caster, point.x, point.y, DOTA_MINIMAP_EVENT_ENEMY_TELEPORTING, 5 );
	-- display normal marker for infernals
	MinimapEvent( DOTA_TEAM_BADGUYS, caster, point.x, point.y, DOTA_MINIMAP_EVENT_TEAMMATE_TELEPORTING, 2 );

	-- create overhead particle
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_static_storm.vpcf", PATTACH_ABSORIGIN, caster);
	ParticleManager:SetParticleControl(particle, 0, point);
	ParticleManager:SetParticleControl(particle, 1, Vector(15, 15, 15));
	ParticleManager:SetParticleControl(particle, 2, Vector(7, 0, 0));
	
	Timers:CreateTimer({
		endTime = 7,
		callback = function()
			ParticleManager:DestroyParticle(particle, false);
		end
	});
end