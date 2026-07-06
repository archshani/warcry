-- Options.lua
local addonName, addonTable = ...

function addonTable.InitializeUI()
    -- Standalone Frame
    local mainFrame = CreateFrame("Frame", "WarCryMainFrame", UIParent)
    mainFrame:SetSize(400, 450)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetFrameStrata("DIALOG")
    mainFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:Hide()

    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -15)
    title:SetText("WarCry - " .. addonTable.GetProfileKey())

    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)

    -- Enable Checkbox
    local enableCheck = CreateFrame("CheckButton", "WarCryEnableCheck", mainFrame, "InterfaceOptionsCheckButtonTemplate")
    enableCheck:SetPoint("TOPLEFT", 20, -50)
    _G[enableCheck:GetName() .. "Text"]:SetText("Enable WarCry")
    enableCheck:SetScript("OnShow", function(self) self:SetChecked(addonTable.GetCurrentSettings().enabled) end)
    enableCheck:SetScript("OnClick", function(self) addonTable.GetCurrentSettings().enabled = self:GetChecked() end)

    -- Chance Slider
    local chanceSlider = CreateFrame("Slider", "WarCryChanceSlider", mainFrame, "OptionsSliderTemplate")
    chanceSlider:SetPoint("TOPLEFT", 20, -110)
    chanceSlider:SetMinMaxValues(1, 100)
    chanceSlider:SetValueStep(1)
    chanceSlider:SetWidth(180)
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
    local cdSlider = CreateFrame("Slider", "WarCryCDSlider", mainFrame, "OptionsSliderTemplate")
    cdSlider:SetPoint("TOPLEFT", 20, -170)
    cdSlider:SetMinMaxValues(0, 60)
    cdSlider:SetValueStep(1)
    cdSlider:SetWidth(180)
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

    -- Phrases Title
    local phrasesTitle = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    phrasesTitle:SetPoint("TOPLEFT", 20, -220)
    phrasesTitle:SetText("Phrases (One per line):")

    -- Phrases EditBox ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", "WarCryPhrasesScroll", mainFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(330, 120)
    scrollFrame:SetPoint("TOPLEFT", 20, -240)

    local editBox = CreateFrame("EditBox", "WarCryPhrasesEditBox", scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(2000)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(330)
    editBox:SetAutoFocus(false)
    scrollFrame:SetScrollChild(editBox)

    -- EditBox Background
    local bg = CreateFrame("Frame", nil, mainFrame)
    bg:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    bg:SetPoint("TOPLEFT", scrollFrame, -8, 8)
    bg:SetPoint("BOTTOMRIGHT", scrollFrame, 25, -8)

    editBox:SetScript("OnShow", function(self)
        local s = ""
        local settings = addonTable.GetCurrentSettings()
        if settings.phrases then
            for _, p in ipairs(settings.phrases) do
                s = s .. p .. "\n"
            end
        end
        self:SetText(s)
    end)

    editBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        local settings = addonTable.GetCurrentSettings()
        settings.phrases = {}
        for line in text:gmatch("[^\r\n]+") do
            local trimmed = strtrim(line)
            if trimmed ~= "" then
                table.insert(settings.phrases, trimmed)
            end
        end
        -- Auto-update scroll frame child height
        self:SetHeight(0) -- Trigger recalculation
        local height = self:GetTextHeight() + 20
        self:SetHeight(height)
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    -- Test Button
    local testBtn = CreateFrame("Button", "WarCryTestButton", mainFrame, "UIPanelButtonTemplate")
    testBtn:SetPoint("BOTTOMLEFT", 20, 20)
    testBtn:SetText("Test Shout")
    testBtn:SetSize(120, 25)
    testBtn:SetScript("OnClick", function()
        local settings = addonTable.GetCurrentSettings()
        if settings.phrases and #settings.phrases > 0 then
            local phrase = settings.phrases[math.random(1, #settings.phrases)]
            SendChatMessage(phrase, "YELL")
        else
            print("|cFFFF0000WarCry:|r No phrases configured!")
        end
    end)

    -- Interface Options Panel (Separate frame for integration)
    local configPanel = CreateFrame("Frame", "WarCryConfigPanel", UIParent)
    configPanel.name = "WarCry"
    local panelTitle = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    panelTitle:SetPoint("TOPLEFT", 16, -16)
    panelTitle:SetText("WarCry - Ability Shouter")

    local openBtn = CreateFrame("Button", nil, configPanel, "UIPanelButtonTemplate")
    openBtn:SetPoint("TOPLEFT", 16, -50)
    openBtn:SetText("Open Configuration Window")
    openBtn:SetSize(200, 30)
    openBtn:SetScript("OnClick", function()
        InterfaceOptionsFrame:Hide()
        mainFrame:Show()
    end)

    InterfaceOptions_AddCategory(configPanel)

    addonTable.mainFrame = mainFrame
end

function addonTable.ToggleUI()
    if addonTable.mainFrame then
        if addonTable.mainFrame:IsShown() then
            addonTable.mainFrame:Hide()
        else
            addonTable.mainFrame:Show()
        end
    end
end
