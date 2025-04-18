if GetLocale() ~= "zhCN" then
    return
end

local _, addon = ...
local log = addon.log
local lockit = addon.lockit
--====================== NO ADDON DATA BELOW, ONLY LOCKIT ===================================================
-- Common
lockit["ui-addon-name"] = "Delve Companion" -- Do not translate
lockit["ui-common-bountiful-delve"] = "丰裕地下堡"

-- Delves List
lockit["ui-delve-instance-button-tooltip-click-instruction"] = "<Shift + 左键：设置地下堡的路径点>"
lockit["ui-delve-instance-button-tooltip-current-text"] = "路径点设置"
lockit["ui-delve-instance-button-tooltip-current-instruction"] = "<Shift + 左键：清空路径点>"

-- Delves UI
lockit["ui-gilded-stash-cannot-retrieve-data"] = "探访卡兹阿加地区以获取地下堡赛季进度"
lockit["ui-gilded-stash-bountiful-note"] = "仅出现在 |cnNORMAL_FONT_COLOR:难度 11|r 丰裕地下堡|A:delves-bountiful:16:16|a。"
lockit["ui-no-active-bountiful"] = "没有激活的地下堡"

-- Loot Info
lockit["ui-loot-info-description"] = "完成地下堡获取战利品："

-- Keys Info
lockit["ui-bountiful-keys-count-caches-prefix"] = "宝箱里获取的钥匙数量"

-- Settings
lockit["ui-settings-section-title-account"] = "账号设置"
lockit["ui-settings-ach-widgets"] = "冒险指南-地下堡：显示地下堡成就进度（故事和探索）。"

lockit["ui-settings-section-title-character"] = "角色设置"
lockit["ui-settings-gv-details"] = "地下堡：显示详细的宏伟宝库奖励。"
lockit["ui-settings-dashboard-overview"] = "地下堡：显示地下堡的其他概要（鎏金藏匿物，丰裕地下堡）。"
lockit["ui-settings-keys-cap"] = "提示里显示每周宝箱获取的钥匙数量。"
lockit["ui-settings-translation-title"] = "特别鸣谢翻译贡献者："

-- Debug
lockit["debug-unexpected-enum-element"] = "Enum `%s` 未包含元素：%s。"
