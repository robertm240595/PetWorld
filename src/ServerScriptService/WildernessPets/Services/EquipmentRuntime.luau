local Runtime = {}

local auras = {}

local function petId(pet)
    return type(pet) == "table" and tostring(pet.Id or "") or ""
end

function Runtime:SetAuraBonuses(pet, bonuses)
    local id = petId(pet)
    if id == "" then return end

    auras[id] = type(bonuses) == "table" and bonuses or {}
end

function Runtime:GetAuraBonuses(pet)
    local id = petId(pet)
    if id == "" then return {} end
    return auras[id] or {}
end

function Runtime:ClearPet(pet)
    local id = petId(pet)
    if id ~= "" then
        auras[id] = nil
    end
end

function Runtime:ClearId(id)
    id = tostring(id or "")
    if id ~= "" then
        auras[id] = nil
    end
end

return Runtime
