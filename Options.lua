-- Options.lua
local addonName, addonTable = ...

-- Static Popups
StaticPopupDialogs["WARCRY_NEW_PROFILE"] = {
    text = "Enter name for new profile:",
    button1 = "Create",
    button2 = "Cancel",
    hasEditBox = true,
    OnAccept = function(self)
        local name = self.editBox:GetText()
        if name and name ~= "" then
            if not WarCryDB.profiles[name] then
                WarCryDB.profiles[name] = {
                    chance = addonTable.defaults.chance,
                    cooldown = addonTable.defaults.cooldown,
                    phrases = {},
                    enabled = addonTable.defaults.enabled
                }
            end
            local charKey = addonTable.GetCharKey()
            WarCryDB.charToProfile[charKey] = name
            addonTable.RefreshUI()
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        StaticPopupDialogs["WARCRY_NEW_PROFILE"].OnAccept(parent)
        parent:Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

StaticPopupDialogs["WARCRY_ADD_PHRASE"] = {
    text = "Enter phrase to add:",
    button1 = "Add",
    button2 = "Cancel",
    hasEditBox = true,
    OnAccept = function(self)
        local text = self.editBox:GetText()
        if text and text ~= "" then
            local settings = addonTable.GetCurrentSettings()
            table.insert(settings.phrases, { text = text, enabled = true })
            addonTable.UpdatePhrasesList()
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        StaticPopupDialogs["WARCRY_ADD_PHRASE"].OnAccept(parent)
        parent:Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local function CreateTab(id, text, parent)
    local tab = CreateFrame("Button", parent:GetName().."Tab"..id, parent, "CharacterFrameTabButtonTemplate")
    tab:SetID(id)
    tab:SetText(text)
    tab:SetScript("OnClick", function(self)
        PanelTemplates_SetTab(parent, self:GetID())
        addonTable.ShowTab(self:GetID())
    end)
    return tab
end

function addonTable.InitializeUI()
    if _G["WarCryMainFrame"] then
        addonTable.mainFrame = _G["WarCryMainFrame"]
        return
    end

    -- Main Frame
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
    title:SetText("WarCry")

    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function() mainFrame:Hide() end)

    -- Tabs
    mainFrame.numTabs = 2
    local tab1 = CreateTab(1, "Settings", mainFrame)
    tab1:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 11, -24)
    local tab2 = CreateTab(2, "Phrases", mainFrame)
    tab2:SetPoint("LEFT", tab1, "RIGHT", -16, 0)

    PanelTemplates_SetNumTabs(mainFrame, 2)
    PanelTemplates_SetTab(mainFrame, 1)
    PanelTemplates_UpdateTabs(mainFrame)

    -- Content Frames
    local settingsTab = CreateFrame("Frame", "WarCrySettingsTab", mainFrame)
    settingsTab:SetAllPoints()
    mainFrame.settingsTab = settingsTab

    local phrasesTab = CreateFrame("Frame", "WarCryPhrasesTab", mainFrame)
    phrasesTab:SetAllPoints()
    phrasesTab:Hide()
    mainFrame.phrasesTab = phrasesTab

    function addonTable.ShowTab(id)
        if id == 1 then
            settingsTab:Show()
            phrasesTab:Hide()
            addonTable.RefreshUI()
        else
            settingsTab:Hide()
            phrasesTab:Show()
            addonTable.UpdatePhrasesList()
        end
        PanelTemplates_UpdateTabs(mainFrame)
    end

    -----------------------------------------
    -- Settings Tab Content
    -----------------------------------------

    -- Profile Dropdown
    local profileLabel = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profileLabel:SetPoint("TOPLEFT", 20, -50)
    profileLabel:SetText("Profile:")

    local profileDropdown = CreateFrame("Frame", "WarCryProfileDropDown", settingsTab, "UIDropDownMenuTemplate")
    profileDropdown:SetPoint("TOPLEFT", 100, -45)
    UIDropDownMenu_SetWidth(profileDropdown, 150)

    local function OnProfileSelect(self)
        local charKey = addonTable.GetCharKey()
        WarCryDB.charToProfile[charKey] = self.value
        UIDropDownMenu_SetSelectedValue(profileDropdown, self.value)
        UIDropDownMenu_SetText(profileDropdown, self.value)
        addonTable.RefreshUI()
    end

    UIDropDownMenu_Initialize(profileDropdown, function(self, level)
        local selected = addonTable.GetProfileKey()
        for name, _ in pairs(WarCryDB.profiles) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = name
            info.value = name
            info.func = OnProfileSelect
            info.checked = (name == selected)
            UIDropDownMenu_AddButton(info)
        end
    end)

    -- New Profile Button
    local newProfileBtn = CreateFrame("Button", nil, settingsTab, "UIPanelButtonTemplate")
    newProfileBtn:SetPoint("TOPLEFT", 300, -45)
    newProfileBtn:SetSize(80, 25)
    newProfileBtn:SetText("New")
    newProfileBtn:SetScript("OnClick", function()
        StaticPopup_Show("WARCRY_NEW_PROFILE")
    end)

    -- Enable Checkbox
    local enableCheck = CreateFrame("CheckButton", "WarCryEnableCheck", settingsTab, "InterfaceOptionsCheckButtonTemplate")
    enableCheck:SetPoint("TOPLEFT", 20, -90)
    _G[enableCheck:GetName() .. "Text"]:SetText("Enable WarCry")
    enableCheck:SetScript("OnClick", function(self) addonTable.GetCurrentSettings().enabled = self:GetChecked() end)

    -- Chance Slider
    local chanceSlider = CreateFrame("Slider", "WarCryChanceSlider", settingsTab, "OptionsSliderTemplate")
    chanceSlider:SetPoint("TOPLEFT", 20, -150)
    chanceSlider:SetMinMaxValues(1, 100)
    chanceSlider:SetValueStep(1)
    chanceSlider:SetWidth(180)
    _G[chanceSlider:GetName() .. "Low"]:SetText("1%")
    _G[chanceSlider:GetName() .. "High"]:SetText("100%")
    chanceSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        addonTable.GetCurrentSettings().chance = value
        _G[self:GetName() .. "Text"]:SetText("Shout Chance: " .. value .. "%")
    end)

    -- Cooldown Slider
    local cdSlider = CreateFrame("Slider", "WarCryCDSlider", settingsTab, "OptionsSliderTemplate")
    cdSlider:SetPoint("TOPLEFT", 20, -210)
    cdSlider:SetMinMaxValues(0, 60)
    cdSlider:SetValueStep(1)
    cdSlider:SetWidth(180)
    _G[cdSlider:GetName() .. "Low"]:SetText("0s")
    _G[cdSlider:GetName() .. "High"]:SetText("60s")
    cdSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        addonTable.GetCurrentSettings().cooldown = value
        _G[self:GetName() .. "Text"]:SetText("Cooldown: " .. value .. "s")
    end)

    function addonTable.RefreshUI()
        local settings = addonTable.GetCurrentSettings()
        local profileName = addonTable.GetProfileKey()

        UIDropDownMenu_SetSelectedValue(profileDropdown, profileName)
        UIDropDownMenu_SetText(profileDropdown, profileName)

        enableCheck:SetChecked(settings.enabled)

        chanceSlider:SetValue(settings.chance)
        _G[chanceSlider:GetName() .. "Text"]:SetText("Shout Chance: " .. settings.chance .. "%")

        cdSlider:SetValue(settings.cooldown)
        _G[cdSlider:GetName() .. "Text"]:SetText("Cooldown: " .. settings.cooldown .. "s")

        if phrasesTab:IsShown() then
            addonTable.UpdatePhrasesList()
        end
    end

    -----------------------------------------
    -- Phrases Tab Content
    -----------------------------------------

    local addPhraseBtn = CreateFrame("Button", nil, phrasesTab, "UIPanelButtonTemplate")
    addPhraseBtn:SetPoint("TOP", 0, -45)
    addPhraseBtn:SetSize(120, 25)
    addPhraseBtn:SetText("Add Phrase")
    addPhraseBtn:SetScript("OnClick", function()
        StaticPopup_Show("WARCRY_ADD_PHRASE")
    end)

    local currentProfileText = phrasesTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    currentProfileText:SetPoint("LEFT", addPhraseBtn, "RIGHT", 10, 0)

    -- Phrases ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", "WarCryPhrasesListScroll", phrasesTab, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(330, 300)
    scrollFrame:SetPoint("TOPLEFT", 20, -80)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(330, 1)
    scrollFrame:SetScrollChild(scrollChild)

    -- Background for ScrollFrame
    local scrollBG = CreateFrame("Frame", nil, phrasesTab)
    scrollBG:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    scrollBG:SetPoint("TOPLEFT", scrollFrame, -8, 8)
    scrollBG:SetPoint("BOTTOMRIGHT", scrollFrame, 25, -8)

    local phraseRows = {}
    local function CreatePhraseRow(i)
        local row = CreateFrame("Frame", nil, scrollChild)
        row:SetSize(330, 30)
        row:SetPoint("TOPLEFT", 0, -(i-1)*30)

        local check = CreateFrame("CheckButton", "WarCryPhraseCheck"..i, row, "InterfaceOptionsCheckButtonTemplate")
        check:SetPoint("LEFT", 0, 0)
        check:SetScale(0.8)
        row.check = check

        local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("LEFT", 30, 0)
        text:SetPoint("RIGHT", -30, 0) -- Leave space for delete button
        text:SetJustifyH("LEFT")
        text:SetWordWrap(false)
        row.text = text

        local delBtn = CreateFrame("Button", nil, row, "UIPanelCloseButton")
        delBtn:SetPoint("RIGHT", 0, 0)
        delBtn:SetSize(24, 24)
        delBtn:SetScript("OnClick", function()
            local settings = addonTable.GetCurrentSettings()
            table.remove(settings.phrases, i)
            addonTable.UpdatePhrasesList()
        end)
        row.delBtn = delBtn

        row:Hide()
        return row
    end

    function addonTable.UpdatePhrasesList()
        local settings = addonTable.GetCurrentSettings()
        currentProfileText:SetText("Profile: " .. addonTable.GetProfileKey())

        local phrases = settings.phrases or {}
        for i = 1, math.max(#phrases, #phraseRows) do
            if not phraseRows[i] then
                phraseRows[i] = CreatePhraseRow(i)
            end

            local row = phraseRows[i]
            if phrases[i] then
                row.text:SetText(phrases[i].text)
                row.check:SetChecked(phrases[i].enabled)
                row.check:SetScript("OnClick", function(self)
                    phrases[i].enabled = self:GetChecked()
                end)
                row.delBtn:SetScript("OnClick", function()
                    table.remove(settings.phrases, i)
                    addonTable.UpdatePhrasesList()
                end)
                row:Show()
            else
                row:Hide()
            end
        end
        scrollChild:SetHeight(math.max(1, #phrases * 30))
    end

    mainFrame:SetScript("OnShow", function()
        addonTable.RefreshUI()
    end)

    -- Interface Options Panel
    local configPanel = CreateFrame("Frame", "WarCryConfigPanel", UIParent)
    configPanel.name = "WarCry"
    local panelTitle = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    panelTitle:SetPoint("TOPLEFT", 16, -16)
    panelTitle:SetText("WarCry")
    
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
    addonTable.RefreshUI()
end

function addonTable.ToggleUI()
    if addonTable.mainFrame then
        if addonTable.mainFrame:IsShown() then
            addonTable.mainFrame:Hide()
        else
            addonTable.mainFrame:Show()
        end
    else
        print("|cFFFF0000WarCry Error:|r UI not ready. Try /reload.")
    end
end
