function OnUse(keys)
	local caster = keys.caster;
    caster:AddNewModifier(caster, nil, 'modifier_item_forcestaff_active', {push_length = keys.PushLength});
    EmitSoundOn('DOTA_Item.ForceStaff.Activate', caster);
end