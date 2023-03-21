---
--- Created by Max
--- Significant help from: Konijima#9279
--- Created on: 10/07/2022 21:23
---

-- Mod info class
---@class SkillLimiter
SkillLimiter = {}

-- Mod info
SkillLimiter.modName = "SkillLimiter"
SkillLimiter.modVersion = "1.0.0"
SkillLimiter.modAuthor = "Max"
SkillLimiter.modDescription = "Limits the maximum skill level of a character based on their traits and profession."


---@return number
local function getAgilityBonus()
    local bonus = SandboxVars.SkillLimiter.AgilityBonus
    if bonus == nil then
        bonus = 0
    end
    return bonus
end

---@return number
local function getCombatBonus()
    local bonus = SandboxVars.SkillLimiter.CombatBonus
    if bonus == nil then
        bonus = 0
    end
    return bonus
end

---@return number
local function getCraftingBonus()
    local bonus = SandboxVars.SkillLimiter.CraftingBonus
    if bonus == nil then
        bonus = 0
    end
    return bonus
end

---@return number
local function getFirearmBonus()
    local bonus = SandboxVars.SkillLimiter.FirearmBonus
    if bonus == nil then
        bonus = 0
    end
    return bonus
end

---@return number
local function getSurvivalistBonus()
    local bonus = SandboxVars.SkillLimiter.SurvivalistBonus
    if bonus == nil then
        bonus = 0
    end
    return bonus
end

---@return number
local function getPassivesBonus()
    local bonus = SandboxVars.SkillLimiter.PassivesBonus
    if bonus == nil then
        bonus = 0
    end
    return bonus
end

---@return number
---@param perk PerkFactory.Perk
local function getPerkBonus(perk)
    local perkBonuses = SandboxVars.SkillLimiter.PerkBonuses
    if perkBonuses == nil then
        perkBonuses = {}
    end
    -- parse perk bonuses. Comma separated list of perk id:bonus pairs
    for perkBonus in perkBonuses:gmatch("[^;]+") do
        local perkBonusSplit = perkBonus:split(":")
        if perkBonusSplit[1] == perk:getId() then
            return tonumber(perkBonusSplit[2])
        end
    end

    return 0
end

---@return number
---@param character IsoGameCharacter
---@param perk PerkFactory.Perk
---@param bonus number @The bonus to apply to final score before deciding max skill level. Can be left nil.
local function getMaxSkill(character, perk, bonus)
    local character_traits = character:getTraits()
    local character_profession_str = character:getDescriptor():getProfession()
    local trait_perk_level = 0

    -- Go through all traits and add their relevant perk level to the total
    for i=0, character_traits:size()-1 do
        local trait_str = character_traits:get(i);
        local trait = TraitFactory.getTrait(trait_str)
        local map = trait:getXPBoostMap();
        if map then
            local mapTable = transformIntoKahluaTable(map)
            for trait_perk, level in pairs(mapTable) do
                if trait_perk:getId() == perk:getId() then
                    trait_perk_level = trait_perk_level + level:intValue()
                end
            end
        end
    end

    local character_profession = ProfessionFactory.getProfession(character_profession_str)

    -- Go through the XPBoostMap of the profession and add the relevant perk level to the total
    local profession_xp_boost_map = character_profession:getXPBoostMap()
    if profession_xp_boost_map then
        local mapTable = transformIntoKahluaTable(profession_xp_boost_map)
        for prof_perk, level in pairs(mapTable) do
            if prof_perk:getId() == perk:getId() then
                trait_perk_level = trait_perk_level + level:intValue()
            end
        end
    end

    if bonus then
        trait_perk_level = trait_perk_level + bonus
    end

    if trait_perk_level <= 0 then
        return SandboxVars.SkillLimiter.PerkLvl0Cap
    end
    if trait_perk_level == 1 then
        return SandboxVars.SkillLimiter.PerkLvl1Cap
    end
    if trait_perk_level == 2 then
        return SandboxVars.SkillLimiter.PerkLvl2Cap
    end
    if trait_perk_level >= 3 then
        return SandboxVars.SkillLimiter.PerkLvl3Cap
    end
end

---@param character IsoGameCharacter
---@param perk PerkFactory.Perk
---@param level Integer
local function limitSkill(character, perk, level)
    local perk_name = perk:getId():lower()
    local perk_found = false
    local bonus = 0

    -- If perk is Sprinting, Lightfooted, Nimble, or Sneaking, add the relevant Agility bonus.
    if perk_name == "sprinting" or perk_name == "lightfoot" or perk_name == "nimble" or perk_name == "sneak" then
        bonus = getAgilityBonus()
        perk_found = true
    end

    -- If perk is Axe, Long Blunt, Short Blunt, Long Blade, Short Blade, Spear, or Maintenance, then we add the relevant Combat bonus.
    if perk_name == "axe" or perk_name == "blunt" or perk_name == "smallblunt" or perk_name == "longblade" or perk_name == "smallblade" or perk_name == "spear" or perk_name == "maintenance" then
        bonus = getCombatBonus()
        perk_found = true
    end

    -- If perk is Carpentry, Cooking, Farming, First Aid, Electrical, Metalworking, Mechanics, or Tailoring, then we add the relevant Crafting bonus.
    if perk_name == "woodwork" or perk_name == "cooking" or perk_name == "farming" or perk_name == "doctor" or perk_name == "electricity" or perk_name == "metalwelding" or perk_name == "mechanics" or perk_name == "tailoring" then
        bonus = getCraftingBonus()
        perk_found = true
    end

    -- If perk is Aiming or Reloading, then we add the relevant Firearm bonus.
    if perk_name == "aiming" or perk_name == "reloading" then
        bonus = getFirearmBonus()
        perk_found = true
    end

    -- If perk is Fishing, Trapping, or Foraging, add the relevant Survivalist bonus.
    if perk_name == "fishing" or perk_name == "trapping" or perk_name == "plantscavenging" then
        bonus = getSurvivalistBonus()
        perk_found = true
    end

    -- If perk is Strength or Fitness, add the relevant Passives bonus.
    if perk_name == "strength" or perk_name == "fitness" then
        bonus = getPassivesBonus()
        perk_found = true
    end

    -- If perk is not found, then we do not need to limit the skill. This is to provide compatibility with other mods that add skills.
    if not perk_found then
        print("SkillLimiter: Not limiting since perk was not found: " .. perk_name)
        return
    end

    -- If the perk is in the perk bonus list, add the bonus to the total.
    bonus = bonus + getPerkBonus(perk)

    -- If bonus is 3 or more, we do not need to check whether or not we should cap the skill. Return.
    if bonus >= 3 then
        print("SkillLimiter: Not limiting since bonus >= 3: (" .. bonus .. ")")
        return
    end

    -- Get the maximum skill level for this perk, based on the character's traits & profession.
    local max_skill = getMaxSkill(character, perk, bonus)
    if max_skill == nil then
        print("SkillLimiter: Error. Max Skill is nil.")
        return
    end

    if level > max_skill then
        -- Cap the skill level.
        character:getXp():setXPToLevel(perk, max_skill)
        character:setPerkLevelDebug(perk, max_skill)
        SyncXp(character)

        print("SkillLimiter: " .. character:getFullName() .. " leveled up " .. perk:getId() .. " and was capped to " .. max_skill .. "." .. "Bonus: " .. bonus)
        HaloTextHelper.addText(character, "The " .. perk:getId() .. " skill was capped to " .. max_skill .. ".", HaloTextHelper.getColorWhite())
    end
end


local ticks_since_check = 0
local perks_leveled_up = {}

---@param character IsoGameCharacter
---@param perk PerkFactory.Perk
---@param level Integer
---@param levelUp Boolean
local function add_to_table(character, perk, level, levelUp)
    -- If not levelUp, then we do not need to check whether or not we should cap the skill.
    -- This also prevents some infinite loops, since this function can cause a LevelPerk event to be fired.
    if not levelUp then
        return
    end

    table.insert(perks_leveled_up, {
        character = character,
        perk = perk,
        level = level
    })
end

local function check_table()
    if (ticks_since_check < 30) then
        ticks_since_check = ticks_since_check + 1
        return
    end

    ticks_since_check = 0

    for i, v in ipairs(perks_leveled_up) do
        limitSkill(v.character, v.perk, v.level)
    end
    perks_leveled_up = {}
end

local function init_check()
    local character = getPlayer()

    if character then
        for j=0, Perks.getMaxIndex() - 1 do
            local perk = PerkFactory.getPerk(Perks.fromIndex(j))
            local level = character:getPerkLevel(perk)
            limitSkill(character, perk, level)
        end
    end
end

local function init()
    Events.OnTick.Remove(init)

    print(SkillLimiter.modName .. " " .. SkillLimiter.modVersion .. " initialized.")

    init_check()
end

Events.LevelPerk.Add(add_to_table)
Events.OnTick.Add(check_table)
Events.OnTick.Add(init);