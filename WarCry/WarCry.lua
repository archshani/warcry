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

local function GetProfileKey()
    local _, raceEn = UnitRace("player")
    local _, classEn = UnitClass("player")
    return (raceEn or "Unknown") .. "_" .. (classEn or "Unknown")
end

local function GetCurrentSettings()
    if not WarCryDB or not WarCryDB.profiles then
        return defaults
    end
    local key = GetProfileKey()
    if not WarCryDB.profiles[key] then
        WarCryDB.profiles[key] = {
            chance = defaults.chance,
            cooldown = defaults.cooldown,
            phrases = {},
            enabled = defaults.enabled
        }
        -- Copy default phrases
        for _, v in ipairs(defaults.phrases) do
            table.insert(WarCryDB.profiles[key].phrases, v)
        end
    end
    return WarCryDB.profiles[key]
end

-- UI Initialization Function
function addonTable.InitializeUI()
    local panel = CreateFrame("Frame", "WarCryOptionsPanel", InterfaceOptionsFramePanelContainer)
    panel.name = "WarCry"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("WarCry Settings (Profile: " .. GetProfileKey() .. ")")

    -- Enable Checkbox
    local enableCheck = CreateFrame("CheckButton", "WarCryEnableCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    enableCheck:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
    _G[enableCheck:GetName() .. "Text"]:SetText("Enable Addon")
    enableCheck:SetScript("OnShow", function(self) self:SetChecked(GetCurrentSettings().enabled) end)
    enableCheck:SetScript("OnClick", function(self) GetCurrentSettings().enabled = self:GetChecked() end)

    -- Chance Slider
    local chanceSlider = CreateFrame("Slider", "WarCryChanceSlider", panel, "OptionsSliderTemplate")
    chanceSlider:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 0, -32)
    chanceSlider:SetMinMaxValues(1, 100)
    chanceSlider:SetValueStep(1)
    chanceSlider:SetWidth(200)
    _G[chanceSlider:GetName() .. "Low"]:SetText("1%")
    _G[chanceSlider:GetName() .. "High"]:SetText("100%")
    chanceSlider:SetScript("OnShow", function(self)
        local val = GetCurrentSettings().chance
        self:SetValue(val)
        _G[self:GetName() .. "Text"]:SetText("Shout Chance: " .. val .. "%")
    end)
    chanceSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        GetCurrentSettings().chance = value
        _G[self:GetName() .. "Text"]:SetText("Shout Chance: " .. value .. "%")
    end)

    -- Cooldown Slider
    local cdSlider = CreateFrame("Slider", "WarCryCDSlider", panel, "OptionsSliderTemplate")
    cdSlider:SetPoint("TOPLEFT", chanceSlider, "BOTTOMLEFT", 0, -32)
    cdSlider:SetMinMaxValues(0, 60)
    cdSlider:SetValueStep(1)
    cdSlider:SetWidth(200)
    _G[cdSlider:GetName() .. "Low"]:SetText("0s")
    _G[cdSlider:GetName() .. "High"]:SetText("60s")
    cdSlider:SetScript("OnShow", function(self)
        local val = GetCurrentSettings().cooldown
        self:SetValue(val)
        _G[self:GetName() .. "Text"]:SetText("Cooldown: " .. val .. "s")
    end)
    cdSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        GetCurrentSettings().cooldown = value
        _G[self:GetName() .. "Text"]:SetText("Cooldown: " .. value .. "s")
    end)

    -- Phrases EditBox
    local phrasesTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    phrasesTitle:SetPoint("TOPLEFT", cdSlider, "BOTTOMLEFT", 0, -32)
    phrasesTitle:SetText("Phrases (one per line):")

    local scrollFrame = CreateFrame("ScrollFrame", "WarCryPhrasesScroll", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(300, 150)
    scrollFrame:SetPoint("TOPLEFT", phrasesTitle, "BOTTOMLEFT", 0, -8)

    local editBox = CreateFrame("EditBox", "WarCryPhrasesEditBox", scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(1000)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(300)
    scrollFrame:SetScrollChild(editBox)

    editBox:SetScript("OnShow", function(self)
        local s = ""
        for _, p in ipairs(GetCurrentSettings().phrases) do
            s = s .. p .. "\n"
        end
        self:SetText(s)
    end)

    editBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        local settings = GetCurrentSettings()
        settings.phrases = {}
        for line in text:gmatch("[^\r\n]+") do
            table.insert(settings.phrases, line)
        end
    end)

    -- Background for EditBox
    local bg = CreateFrame("Frame", nil, panel)
    bg:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    bg:SetPoint("TOPLEFT", scrollFrame, -8, 8)
    bg:SetPoint("BOTTOMRIGHT", scrollFrame, 24, -8)

    InterfaceOptions_AddCategory(panel)
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
            local settings = GetCurrentSettings()
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
    InterfaceOptionsFrame_OpenToCategory("WarCry")
    InterfaceOptionsFrame_OpenToCategory("WarCry")
end
