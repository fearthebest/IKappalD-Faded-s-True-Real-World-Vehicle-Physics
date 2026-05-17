if isServer() then return end
if not ISPanel then
    print("[ProjectFadedCar] Guide panel skipped: ISPanel unavailable")
    return
end

PFC_GuidePanel = ISPanel:derive("PFC_GuidePanel")
PFC_GuidePanel.instance = nil

print("[ProjectFadedCar] Client guide panel module loaded")

local PFC = ProjectFadedCar

local TAB_ACTIVE_BG = { r = 0.00, g = 0.45, b = 0.52, a = 0.42 }
local TAB_ACTIVE_BORDER = { r = 0.00, g = 0.90, b = 1.00, a = 0.80 }
local TAB_INACTIVE_BG = { r = 0.05, g = 0.06, b = 0.07, a = 0.55 }
local TAB_INACTIVE_BORDER = { r = 0.24, g = 0.26, b = 0.28, a = 0.70 }

local GUIDE_TABS = {
    {
        id = "overview",
        labelKey = "IGUI_PFC_GuideTab_Overview",
        fallback = "Overview",
        titleKey = "IGUI_PFC_GuideTitle_Overview",
        titleFallback = "What Project Faded Car Does",
        lines = {
            "Project Faded Car adds a deeper vehicle maintenance layer without replacing vehicle scripts.",
            "The Shop tracks virtual engine systems on the normal vehicle Engine part: cooling, oiling, ignition, belts, transmission, brake assist, steering pump, fluids, oil quality, and heat.",
            "Those values wear down while vehicles run, can affect vanilla engine condition, and are saved in vehicle part ModData.",
            "The Shop can also pull a usable engine into a Salvaged Engine item, install a stored engine into another vehicle, and rebuild supported vanilla wreck scripts back into rough drivable cars.",
            "Bad condition can cause heat, oil/coolant/ATF loss, battery drain, engine damage, stalling, service sparks, smoke, burns, or rare fire depending on sandbox settings.",
        },
    },
    {
        id = "use",
        labelKey = "IGUI_PFC_GuideTab_Use",
        fallback = "How To",
        titleKey = "IGUI_PFC_GuideTitle_Use",
        titleFallback = "How To Use The Shop",
        lines = {
            "Enter a vehicle, open vanilla mechanics near one, or right-click a supported wreck, then open The Shop from the dashboard button, floating button, or context option.",
            "Read the top diagnostics first: vanilla engine health, internal condition, weakest system, heat, oil quality, and current warning.",
            "To replace a system, carry the matching Project Faded Car service kit and press Replace on that row.",
            "To top up fluids, carry fresh motor oil, coolant mix, or transmission fluid and press Add.",
            "Use Tune to improve the overall engine with engine parts. Use Tow Assist to tune PFC's compatibility metadata for other vehicle systems.",
            "Use Pull with a wrench and enough Mechanics skill to store the current engine as a Salvaged Engine. Use Install with that item and two engine parts to swap it into the target vehicle.",
            "Use Restore on supported burnt or smashed vanilla wrecks when you have a welding torch, welder mask, rebuild materials, Mechanics skill, and Welding skill.",
            "If service is blocked, shut the engine off or move closer to the engine area.",
        },
    },
    {
        id = "supplies",
        labelKey = "IGUI_PFC_GuideTab_Supplies",
        fallback = "Supplies",
        titleKey = "IGUI_PFC_GuideTitle_Supplies",
        titleFallback = "Getting Parts And Fluids",
        lines = {
            "Select Base.EngineParts in inventory and use the Project Faded Car submenu to assemble service kits.",
            "Select a petrol can to prepare fresh motor oil or transmission fluid.",
            "Select a water bottle to mix coolant.",
            "Engine installs consume two vanilla engine parts. Wreck restoration uses vanilla engine parts, sheet metal, small sheet metal, and electronics scrap unless that sandbox requirement is disabled.",
            "Supplies can also spawn in mechanic shops, gas stations, warehouses, car supply shelves, tool storage, farm and barn storage.",
            "Low Mechanics skill raises service failure risk, so early repairs may restore less and trigger more hazards.",
        },
    },
    {
        id = "compat",
        labelKey = "IGUI_PFC_GuideTab_Compat",
        fallback = "Mods",
        titleKey = "IGUI_PFC_GuideTitle_Compat",
        titleFallback = "When Other Mods Are Present",
        lines = {
            "Common Sense Reborn: PFC does not edit CSR. It detects CSR, keeps its dashboard compact, and writes PFC tow-assist metadata for future compatibility.",
            "IKappaID & Faded's True Real World Vehicle Physics: IKFRVP remains the physics authority. PFC shows bridge status, sends safe server-side requests, and asks IKFRVP to re-sync after engine swaps or wreck rebuilds.",
            "Vehicle packs: PFC usually works when the vehicle exposes a normal Engine part and vanilla mechanics can reach it. Engine-less trailers and custom nonstandard engine systems may be ignored.",
            "Project Summer Car: PFC declares it incompatible because this rebuild is meant to replace that style of gameplay, not run beside it.",
            "Multiplayer: real service, tuning, and physics bridge actions are validated server-side. Client UI is only a request surface.",
        },
    },
}

local function trimText(text, maxChars)
    text = tostring(text or "")
    if #text <= maxChars then return text end
    return string.sub(text, 1, math.max(1, maxChars - 3)) .. "..."
end

local function wrapLine(text, maxChars)
    local lines = {}
    text = tostring(text or "")
    while #text > maxChars do
        local cut = maxChars
        for i = maxChars, 1, -1 do
            if string.sub(text, i, i) == " " then
                cut = i
                break
            end
        end
        lines[#lines + 1] = string.sub(text, 1, cut - 1)
        text = string.sub(text, cut + 1)
    end
    if text ~= "" then
        lines[#lines + 1] = text
    end
    return lines
end

local function drawGuideFrame(panel)
    panel:drawRect(0, 0, panel.width, panel.height, 0.94, 0.012, 0.016, 0.020)
    panel:drawRectBorder(0, 0, panel.width, panel.height, 1.0, 0.00, 0.82, 0.92)
    panel:drawRectBorder(2, 2, panel.width - 4, panel.height - 4, 0.55, 0.02, 0.48, 0.62)
    panel:drawRect(12, 52, panel.width - 24, 1, 0.75, 0.00, 0.70, 0.82)
    panel:drawRect(12, panel.height - 42, panel.width - 24, 1, 0.45, 0.00, 0.70, 0.82)
end

function PFC_GuidePanel:new(x, y, w, h)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.012, g = 0.016, b = 0.020, a = 0.94 }
    o.borderColor = { r = 0.00, g = 0.82, b = 0.92, a = 1.0 }
    o.moveWithMouse = true
    o.activeTab = 1
    o.tabButtons = {}
    return o
end

function PFC_GuidePanel:createChildren()
    ISPanel.createChildren(self)

    self.closeButton = ISButton:new(self.width - 76, 10, 60, 24, PFC.text("IGUI_PFC_Close", "Close"), self, PFC_GuidePanel.onClose)
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self:addChild(self.closeButton)

    local x = 18
    for index, tab in ipairs(GUIDE_TABS) do
        local label = PFC.text(tab.labelKey, tab.fallback)
        local btn = ISButton:new(x, 58, 94, 24, label, self, PFC_GuidePanel.onTab)
        btn.internal = index
        btn:initialise()
        btn:instantiate()
        self:addChild(btn)
        self.tabButtons[index] = btn
        x = x + 100
    end
end

function PFC_GuidePanel:onClose()
    self:removeFromUIManager()
    PFC_GuidePanel.instance = nil
end

function PFC_GuidePanel:onTab(button)
    self.activeTab = button and button.internal or 1
end

function PFC_GuidePanel:update()
    ISPanel.update(self)
    for index, button in ipairs(self.tabButtons) do
        if button then
            if index == self.activeTab then
                button.backgroundColor = TAB_ACTIVE_BG
                button.borderColor = TAB_ACTIVE_BORDER
            else
                button.backgroundColor = TAB_INACTIVE_BG
                button.borderColor = TAB_INACTIVE_BORDER
            end
        end
    end
end

function PFC_GuidePanel:prerender()
    ISPanel.prerender(self)
    drawGuideFrame(self)

    self:drawText(PFC.text("IGUI_PFC_GuideTitle", "The Shop Guide"), 18, 14, 0.96, 0.96, 0.90, 1, UIFont.Medium)

    local tab = GUIDE_TABS[self.activeTab] or GUIDE_TABS[1]
    local title = PFC.text(tab.titleKey, tab.titleFallback)
    self:drawText(trimText(title, 60), 22, 96, 0.90, 0.96, 0.94, 1, UIFont.Medium)

    local y = 128
    local maxChars = math.max(42, math.floor((self.width - 56) / 7))
    for _, paragraph in ipairs(tab.lines) do
        local wrapped = wrapLine(paragraph, maxChars)
        for _, line in ipairs(wrapped) do
            self:drawText(line, 28, y, 0.74, 0.82, 0.80, 1, UIFont.Small)
            y = y + 18
        end
        y = y + 8
    end

    local footer = PFC.text("IGUI_PFC_GuideFooter", "The Shop changes PFC maintenance data. Other mods keep authority over their own systems.")
    self:drawText(trimText(footer, maxChars), 18, self.height - 28, 0.54, 0.62, 0.60, 1, UIFont.Small)
end

function PFC_GuidePanel.open()
    if PFC_GuidePanel.instance then
        PFC_GuidePanel.instance:setVisible(true)
        PFC_GuidePanel.instance:bringToTop()
        return
    end

    local w, h = 720, 480
    if getCore():getScreenWidth() < w + 16 then w = getCore():getScreenWidth() - 16 end
    if getCore():getScreenHeight() < h + 16 then h = getCore():getScreenHeight() - 16 end
    local x = math.max(8, math.floor((getCore():getScreenWidth() - w) / 2))
    local y = math.max(8, math.floor((getCore():getScreenHeight() - h) / 2))
    local ui = PFC_GuidePanel:new(x, y, w, h)
    ui:initialise()
    ui:instantiate()
    ui:addToUIManager()
    PFC_GuidePanel.instance = ui
end
