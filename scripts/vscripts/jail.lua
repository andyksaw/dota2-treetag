function OnTriggerExit(keys)
	local caller = keys.caller;
	local unit = keys.activator;

	if unit ~= nil and unit:GetUnitName() == "npc_dota_hero_wisp" then
		BasicParticle("particles/units/heroes/hero_wisp/wisp_relocate_teleport.vpcf", unit, unit:GetAbsOrigin(), 3, false);
		unit:SetAbsOrigin( TreeTag.Jail:GetAbsOrigin() );
		unit:Stop();
		BasicParticle("particles/units/heroes/hero_wisp/wisp_relocate_teleport.vpcf", unit, unit:GetAbsOrigin(), 3, false);
	end
end