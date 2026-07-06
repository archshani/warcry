-- Options.lua
local addonName, addonTable = ...

function addonTable.InitializeUI()
    -- Create the panel
    local panel = CreateFrame("Frame", "WarCryOptionsPanel", UIParent)
    panel.name = "WarCry"

    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    panel:SetSize(400, 500)
    panel:SetPoint("CENTER")
    panel:Hide()

    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)

    local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -8, -8)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("WarCry Settings (Profile: " .. addonTable.GetProfileKey() .. ")")

    -- Enable Checkbox
    local enableCheck = CreateFrame("CheckButton", "WarCryEnableCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    enableCheck:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
    _G[enableCheck:GetName() .. "Text"]:SetText("Enable Addon")
    enableCheck:SetScript("OnShow", function(self) self:SetChecked(addonTable.GetCurrentSettings().enabled) end)
    enableCheck:SetScript("OnClick", function(self) addonTable.GetCurrentSettings().enabled = self:GetChecked() end)

    -- Chance Slider
    local chanceSlider = CreateFrame("Slider", "WarCryChanceSlider", panel, "OptionsSliderTemplate")
    chanceSlider:SetPoint("TOPLEFT", enableCheck, "BOTTOMLEFT", 0, -32)
    chanceSlider:SetMinMaxValues(1, 100)
    chanceSlider:SetValueStep(1)
    chanceSlider:SetWidth(200)
    _G[chanceSlider:GetName() .. "Low"]:SetText("1%")
    _G[chanceSlider:GetName() .. "High"]:SetText("100%")
    chanceSlider:SetScript("OnShow", function(self)
        local val = addonTable.GetCurrentSettings().chance
        self:SetValue(val)
        _G[self:GetName() .. "Text"]:SetText("Shout Chance: " .. val .. "%")
    end)
    chanceSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        addonTable.GetCurrentSettings().chance = value
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
        local val = addonTable.GetCurrentSettings().cooldown
        self:SetValue(val)
        _G[self:GetName() .. "Text"]:SetText("Cooldown: " .. val .. "s")
    end)
    cdSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        addonTable.GetCurrentSettings().cooldown = value
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
    editBox:SetAutoFocus(false)
    scrollFrame:SetScrollChild(editBox)

    editBox:SetScript("OnShow", function(self)
        local s = ""
        for _, p in ipairs(addonTable.GetCurrentSettings().phrases) do
            s = s .. p .. "\n"
        end
        self:SetText(s)
    end)

    editBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        local settings = addonTable.GetCurrentSettings()
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

    -- Test Button
    local testBtn = CreateFrame("Button", "WarCryTestButton", panel, "UIPanelButtonTemplate")
    testBtn:SetPoint("TOPLEFT", bg, "BOTTOMLEFT", 0, -16)
    testBtn:SetText("Test Shout")
    testBtn:SetSize(120, 22)
    testBtn:SetScript("OnClick", function()
        local settings = addonTable.GetCurrentSettings()
        if settings.phrases and #settings.phrases > 0 then
            local phrase = settings.phrases[math.random(1, #settings.phrases)]
            SendChatMessage(phrase, "YELL")
        else
            UIErrorsFrame:AddMessage("WarCry: No phrases configured!", 1, 0, 0)
        end
    end)

    InterfaceOptions_AddCategory(panel)
    addonTable.panel = panel
end

function addonTable.ToggleUI()
    if addonTable.panel then
        if addonTable.panel:IsShown() then
            addonTable.panel:Hide()
        else
            addonTable.panel:Show()
        end
    end
end
