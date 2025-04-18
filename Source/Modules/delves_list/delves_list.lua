local addonName, addon = ...
local log = addon.log
local lockit = addon.lockit
local enums = addon.enums

--#region Constants

local EJ_DELVES_TAB_BUTTON_ID = 6
local EJ_TABS_NUMBER = 6

local DELVES_LIST_VIEW_COLS = 4
local DELVES_LIST_VIEW_BUTTONS_OFFSET = 12
local DELVES_LIST_VIEW_BUTTONS_PADDING = 5
--#endregion

--============ DelveProgressWidget ======================
DelveCompanionDelveProgressWidgetMixin = {}

--============ DelveInstanceButton ======================
DelveCompanionDelveInstanceButtonMixin = {}

function DelveCompanionDelveInstanceButtonMixin:Update()
    if self.data.isBountiful then
        self.BountifulIcon:Show()
    else
        self.BountifulIcon:Hide()
    end

    if DelveCompanionAccountData.useTomTomWaypoints then
        self:CheckTomTomWaypoint()
    else
        self:OnSuperTrackChanged()
    end
end

function DelveCompanionDelveInstanceButtonMixin:OnEvent(event, ...)
    self:OnSuperTrackChanged()
end

function DelveCompanionDelveInstanceButtonMixin:OnShow()
    self:RegisterEvent("SUPER_TRACKING_CHANGED")
end

function DelveCompanionDelveInstanceButtonMixin:OnHide()
    self:UnregisterEvent("SUPER_TRACKING_CHANGED")
end

function DelveCompanionDelveInstanceButtonMixin:OnEnter()
    if addon.maxLevelReached == false then
        return
    end

    self:UpdateTooltip()
end

function DelveCompanionDelveInstanceButtonMixin:OnLeave()
    GameTooltip:Hide()
end

function DelveCompanionDelveInstanceButtonMixin:OnClick()
    if not addon.maxLevelReached then
        return
    end

    if IsShiftKeyDown() then
        self:ToggleTracking()
    end
end

--============ DelvesListFrame ======================

DelveCompanionDelvesListMixin = {}

function DelveCompanionDelvesListMixin:CreateMapHeader(parent, mapName)
    local header = CreateFrame("Frame", nil, parent, "DelveCompanionMapHeaderTemplate")
    header.MapName:SetText(mapName)

    return header
end

function DelveCompanionDelvesListMixin:CreateDelveAchievementsWidget(parent, config)
    local widget = CreateFrame("Frame", nil, parent, "DelveCompanionDelveAchievementsWidgetTemplate")

    do
        -- Story progress
        local achID = config.achievements.story
        widget.Story:SetFrameInfo(enums.CodeType.Achievement, achID)

        local totalCount = GetAchievementNumCriteria(achID)
        local completedCount = 0
        for index = 1, totalCount, 1 do
            local completed = select(3, GetAchievementCriteriaInfo(achID, index))
            if completed then
                completedCount = completedCount + 1
            end
        end
        local text = format(_G["GENERIC_FRACTION_STRING"], completedCount, totalCount)
        if completedCount == totalCount then
            text = _G["GREEN_FONT_COLOR"]:WrapTextInColorCode(text)
        end
        widget.Story:SetLabelText(text)
        widget.Story:SetOnClick(function() OpenAchievementFrameToAchievement(achID) end)
    end

    do
        -- Chest progress
        local achID = config.achievements.chest
        widget.Chest:SetFrameInfo(enums.CodeType.Achievement, achID)

        local quantity, reqQuantity = select(4, GetAchievementCriteriaInfo(achID, 1))
        local text = format(_G["GENERIC_FRACTION_STRING"], quantity, reqQuantity)
        if quantity == reqQuantity then
            text = _G["GREEN_FONT_COLOR"]:WrapTextInColorCode(text)
        end
        widget.Chest:SetLabelText(text)
        widget.Chest:SetOnClick(function() OpenAchievementFrameToAchievement(achID) end)
    end

    return widget
end

function DelveCompanionDelvesListMixin:CreateDelveInstanceButton(parent, delveData)
    local item = CreateFrame("Button", nil, parent, "DelveCompanionDelveInstanceButtonTemplate")
    item.data = delveData

    item.DelveName:SetText(delveData.delveName)
    if C_Texture.GetAtlasInfo(delveData.config.atlasBgID) ~= nil then
        item.DelveArtBg:SetAtlas(delveData.config.atlasBgID)
    end

    return item
end

function DelveCompanionDelvesListMixin:InitDelvesList()
    local offsetX, offsetY = DELVES_LIST_VIEW_BUTTONS_OFFSET, 0
    local instanceButtons = {}
    for _, mapID in ipairs(addon.config.DELVES_MAPS_DATA) do
        local areaName = C_Map.GetMapInfo(mapID).name
        local header = self:CreateMapHeader(self.DelvesListScroll.Content, areaName)
        header:SetPoint("TOPLEFT", self.DelvesListScroll.Content, "TOPLEFT", 0, -offsetY)

        offsetY = offsetY + header:GetHeight() + DELVES_LIST_VIEW_BUTTONS_PADDING

        local count = 0
        local cellHeight = 0
        local prevRow = 0
        for _, delveData in ipairs(addon.delvesData) do
            local delveConfig = delveData.config
            local parentMapID = C_Map.GetMapInfo(delveConfig.uiMapID).parentMapID

            if parentMapID == mapID then
                local instanceButton = self:CreateDelveInstanceButton(
                    self.DelvesListScroll.Content,
                    delveData)
                count = count + 1
                table.insert(instanceButtons, instanceButton)

                local cellWidth = instanceButton:GetWidth()
                cellHeight = instanceButton:GetHeight()

                local row = math.floor((count - 1) / DELVES_LIST_VIEW_COLS)
                local col = (count - 1) % DELVES_LIST_VIEW_COLS

                if row > prevRow then
                    offsetY = offsetY + cellHeight + DELVES_LIST_VIEW_BUTTONS_PADDING
                    prevRow = row
                end

                local anchorX = offsetX +
                    col * (cellWidth + DELVES_LIST_VIEW_BUTTONS_OFFSET)
                local anchorY = -(row * (cellHeight + DELVES_LIST_VIEW_BUTTONS_OFFSET) + DELVES_LIST_VIEW_BUTTONS_PADDING)

                instanceButton:SetPoint("TOPLEFT", header, "BOTTOMLEFT", anchorX,
                    anchorY)

                if DelveCompanionAccountData.achievementWidgetsEnabled and delveConfig.achievements then
                    local progressWidget = self:CreateDelveAchievementsWidget(self.DelvesListScroll.Content,
                        delveConfig)
                    progressWidget:SetPoint("TOPLEFT", instanceButton, "BOTTOMLEFT", 0, 0)
                end
            end
        end
        offsetY = offsetY + cellHeight + DELVES_LIST_VIEW_BUTTONS_OFFSET * 2 +
            DELVES_LIST_VIEW_BUTTONS_PADDING * (prevRow + 1)
    end

    self.instanceButtons = instanceButtons
end

function DelveCompanionDelvesListMixin:UpdateKeysWidget()
    local keyCurrInfo = C_CurrencyInfo.GetCurrencyInfo(addon.config.BOUNTIFUL_KEY_CURRENCY_CODE)
    if not keyCurrInfo then
        self.KeysWidget:Hide()
        return
    end

    self.KeysWidget:SetLabelText(keyCurrInfo.quantity)

    self.KeysWidget:Show()
end

function DelveCompanionDelvesListMixin:OnLoad()
    --log("DelvesList OnLoad start")
    self.Title:SetText(_G["DELVES_LABEL"])
    self.KeysWidget:SetFrameInfo(enums.CodeType.Currency, addon.config.BOUNTIFUL_KEY_CURRENCY_CODE)

    self.AffixWidget:SetFrameInfo(enums.CodeType.Spell, addon.config.NEMESIS_AFFIX_SPELL_CODE)
    self.AffixWidget:SetLabelText(_G["MODIFIERS_COLON"])

    self:InitDelvesList()
end

function DelveCompanionDelvesListMixin:OnEvent(event, ...)
    self:UpdateKeysWidget()
end

function DelveCompanionDelvesListMixin:OnShow()
    -- log("DelvesList OnShow start")
    addon.CacheActiveBountiful()

    for _, instanceButton in ipairs(self.instanceButtons) do
        instanceButton:Update()
    end

    if addon.maxLevelReached then
        self:UpdateKeysWidget()
        self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    else
        self.KeysWidget:Hide()
    end
end

function DelveCompanionDelvesListMixin:OnHide()
    --log("DelvesList OnHide start")
    self:UnregisterEvent("CURRENCY_DISPLAY_UPDATE")
end

--============ Init ======================
function DelveCompanion_DelvesListFrame_Init()
    local button = CreateFrame("Button", "$parent.DelvesTab", EncounterJournal,
        "BottomEncounterTierTabTemplate")
    button:SetPoint("LEFT", EncounterJournal.LootJournalTab, "RIGHT", -15, 0)
    button:SetText(_G["DELVES_LABEL"])
    button:SetID(EJ_DELVES_TAB_BUTTON_ID)
    button:SetParentKey("delvesTab")
    PanelTemplates_SetNumTabs(EncounterJournal, EJ_TABS_NUMBER)

    addon.delvesListFrame = CreateFrame("Frame", "$parent.DelvesListFrame", EncounterJournal,
        "DelveCompanionDelvesListFrameTemplate")

    EventRegistry:RegisterCallback("EncounterJournal.TabSet",
        function(_, EncounterJournal, tabID)
            if tabID == EJ_DELVES_TAB_BUTTON_ID then
                -- EncounterJournal.instanceSelect.Title:SetText(_G["DELVES_LABEL"])
                EJ_HideNonInstancePanels()
                addon.delvesListFrame:Show()
            else
                addon.delvesListFrame:Hide()
            end
        end,
        addon)
end
