local function getdesc(inst, viewer)
	if inst:HasTag("burnt") then
		return GetDescription(viewer, inst, "BURNT")
	elseif inst._active and inst._winner ~= nil then
		if inst._winner.userid ~= nil and inst._winner.userid == viewer.userid then
			return GetDescription(viewer, inst, "I_WON")
		elseif inst._winner.name ~= nil then
			return subfmt(pp.replacePP(GetDescription(viewer, inst, "SOMEONE_ELSE_WON"), "{winner}", inst._winner.name), { winner = inst._winner.name })
		end
	end
	
	return GetDescription(viewer, inst) or nil
end