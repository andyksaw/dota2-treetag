function OnSelectTarget(keys)
	local caster = keys.caster;
	local target = keys.target;

	if target._isMine and target:GetPlayerOwner():GetTeam() == caster:GetTeam() then
		caster._connectedMine = target;

		caster._connectedMine._connectedMine = caster;
		print("Mine connected");
	end
end

function OnUseMine(keys)
	local caster = keys.caster;
	local target = keys.target;

	if target._connectedMine ~= nil then
		local isInRange = caster:IsPositionInRange(target:GetAbsOrigin(), 180);
		if isInRange then
			Timers:CreateTimer(function() 
				caster:Stop();
			end);
			FindClearSpaceForUnit(caster, target._connectedMine:GetAbsOrigin(), true);
		end
	else
		print("NO CONNECTED MINE")
	end
end