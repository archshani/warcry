-- WarCry.lua
local addonName, addonTable = ...
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local lastShoutTime = 0
local playerGUID

-- Default settings
local defaults = {
    chance = 20,
    cooldown = 10,
    phrases = {}, -- Should be empty by default as requested
    enabled = false -- Disabled by default as requested
}
addonTable.defaults = defaults

-- Shared functions
function addonTable.GetCharKey()
    return UnitName("player") .. " - " .. GetRealmName()
end

function addonTable.GetProfileKey()
    local charKey = addonTable.GetCharKey()
    if WarCryDB and WarCryDB.charToProfile and WarCryDB.charToProfile[charKey] then
        return WarCryDB.charToProfile[charKey]
    end
    -- Fallback to a default name based on race/class for the very first time
    local _, raceEn = UnitRace("player")
    local _, classEn = UnitClass("player")
    return (raceEn or "Unknown") .. "_" .. (classEn or "Unknown")
end

function addonTable.GetCurrentSettings()
    if not WarCryDB or not WarCryDB.profiles then 
        return defaults 
    end
    local key = addonTable.GetProfileKey()
    if not WarCryDB.profiles[key] then
        WarCryDB.profiles[key] = {
            chance = defaults.chance,
            cooldown = defaults.cooldown,
            phrases = {},
            enabled = defaults.enabled
        }
    end

    local settings = WarCryDB.profiles[key]
    -- Migration logic for old string-based phrases
    if settings.phrases then
        for i, p in ipairs(settings.phrases) do
            if type(p) == "string" then
                settings.phrases[i] = { text = p, enabled = true }
            end
        end
    end

    return settings
end

frame:SetScript("OnEvent", function(self, event, ...)
    local arg1 = ...
    if event == "ADDON_LOADED" and arg1 == addonName then
        WarCryDB = WarCryDB or { profiles = {}, charToProfile = {} }
        playerGUID = UnitGUID("player")
        
        local charKey = addonTable.GetCharKey()
        if not WarCryDB.charToProfile[charKey] then
            local defaultProfileName = addonTable.GetProfileKey()
            WarCryDB.charToProfile[charKey] = defaultProfileName
        end

        -- Initialize settings for current profile if it doesn't exist
        addonTable.GetCurrentSettings()

        -- Small delay to ensure both files are loaded
        if addonTable.InitializeUI then
            addonTable.InitializeUI()
        end
        print("|cFF00FF00WarCry|r loaded. Type /warcry to toggle UI.")
        
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if not playerGUID then playerGUID = UnitGUID("player") end
        
        local timestamp, subevent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...
        
        if sourceGUID == playerGUID and (subevent == "SPELL_CAST_SUCCESS" or subevent == "SPELL_CAST_START") then
            local settings = addonTable.GetCurrentSettings()
            if not settings or not settings.enabled then return end
            
            local currentTime = GetTime()
            if currentTime - lastShoutTime >= settings.cooldown then
                if math.random(1, 100) <= settings.chance then
                    if settings.phrases and #settings.phrases > 0 then
                        -- Get only enabled phrases
                        local activePhrases = {}
                        for _, p in ipairs(settings.phrases) do
                            if p.enabled then
                                table.insert(activePhrases, p.text)
                            end
                        end

                        if #activePhrases > 0 then
                            local phrase = activePhrases[math.random(1, #activePhrases)]
                            SendChatMessage(phrase, "YELL")
                            lastShoutTime = currentTime
                        end
                    end
                end
            end
        end
    end
end)

-- Slash commands
SLASH_WARCRY1 = "/warcry"
SlashCmdList["WARCRY"] = function(msg)
    if addonTable.ToggleUI then
        addonTable.ToggleUI()
    else
        print("|cFFFF0000WarCry Error:|r UI not initialized.")
    end
end
