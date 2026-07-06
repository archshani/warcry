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
    phrases = {"For Glory!", "Victory or Death!"},
    enabled = true
}

-- Shared functions
function addonTable.GetProfileKey()
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
        for _, v in ipairs(defaults.phrases) do
            table.insert(WarCryDB.profiles[key].phrases, v)
        end
    end
    return WarCryDB.profiles[key]
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == "WarCry" then
            WarCryDB = WarCryDB or { profiles = {} }
            playerGUID = UnitGUID("player")

            if addonTable.InitializeUI then
                addonTable.InitializeUI()
            end
            print("|cFF00FF00WarCry|r loaded. Type /warcry for options.")
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if not playerGUID then playerGUID = UnitGUID("player") end

        local timestamp, subevent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...

        if sourceGUID == playerGUID and (subevent == "SPELL_CAST_SUCCESS" or subevent == "SPELL_CAST_START") then
            local settings = addonTable.GetCurrentSettings()
            if not settings.enabled then return end

            local currentTime = GetTime()
            if currentTime - lastShoutTime >= settings.cooldown then
                if math.random(1, 100) <= settings.chance then
                    if settings.phrases and #settings.phrases > 0 then
                        local phrase = settings.phrases[math.random(1, #settings.phrases)]
                        SendChatMessage(phrase, "YELL")
                        lastShoutTime = currentTime
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
    end
end
