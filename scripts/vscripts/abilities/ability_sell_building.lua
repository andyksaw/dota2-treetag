function OnSell(keys)
	local caster = keys.caster;
	local playerID = caster:GetPlayerOwnerID();

	local value = Round(caster._buildValue / 2);
	PopupGoldGain(caster, value);
	
	local gold = PlayerResource:GetGold(playerID);
	PlayerResource:SetGold(playerID, gold + value, false);

	BasicParticle(TreeTag.PARTICLES['build_sell'], caster, caster:GetAbsOrigin(), 3, false);

	caster:OnDeath();
	caster:ForceKill(false);
end