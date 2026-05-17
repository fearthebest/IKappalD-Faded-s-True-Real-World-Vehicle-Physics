if isServer() then return end
if not ISPanel then
    print("[ProjectFadedCar] Dashboard skipped: ISPanel unavailable")
    return
end

PFC_Dashboard = ISPanel:derive("PFC_Dashboard")
PFC_Dashboard.instance = nil

print("[ProjectFadedCar] Client dashboard module loaded")

local PFC = ProjectFadedCar
local ENGINE_BUTTON_TEXTURE = getTexture and getTexture("media/textures/PFC_EngineBayButton.png") or nil

local function trimText(text, maxChars)
    text = tostring(text or "")
    if #text <= maxChars then return text end
    return string.sub(text, 1, math.max(1, maxChars - 3)) .. "..."
end

local function drawBar(panel, x, y, w, h, value, label)
    value = PFC.clamp(value, 0, 100)
    panel:drawText(label .. " " .. tostring(PFC.round(value)) .. "%", x, y - 16, 0.76, 0.82, 0.80, 1, UIFont.Small)
    panel:drawRect(x, y, w, h, 0.58, 0.04, 0.045, 0.050)
    panel:drawRectBorder(x, y, w, h, 0.55, 0.14, 0.15, 0.16)
    local fill = math.floor((w - 2) * (value / 100))
    local r, g, b = 0.15, 0.76, 0.46
    if value < 35 then
        r, g, b = 0.94, 0.24, 0.18
    elseif value < 65 then
        r, g, b = 0.95, 0.68, 0.22
    end
    panel:drawRect(x + 1, y + 1, fill, h - 2, 0.9, r, g, b)
end

local function drawDashBackground(panel)
    panel:drawRect(0, 0, panel.width, panel.height, 0.60, 0.012, 0.013, 0.014)
    panel:drawRect(0, 0, panel.width, 1, 0.42, 0.10, 0.11, 0.12)
    panel:drawRect(0, panel.height - 1, panel.width, 1, 0.42, 0.08, 0.09, 0.10)
    panel:drawRectBorder(0, 0, panel.width, panel.height, 0.34, 0.08, 0.09, 0.10)
end

local function clampToScreen(panel)
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    if panel.x < 8 then panel:setX(8) end
    if panel.y < 8 then panel:setY(8) end
    if panel.x > screenW - panel.width - 8 then panel:setX(screenW - panel.width - 8) end
    if panel.y > screenH - panel.height - 8 then panel:setY(screenH - panel.height - 8) end
end

function PFC_Dashboard:new(playerIndex)
    local width = PFC.csrCompatMode() and 330 or 382
    local height = 68
    local x = PFC_Dashboard.savedX or math.floor((getCore():getScreenWidth() - width) / 2)
    local y = PFC_Dashboard.savedY or getCore():getScreenHeight() - height - 116
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.playerIndex = playerIndex or 0
    o.backgroundColor = { r = 0.012, g = 0.013, b = 0.014, a = 0.60 }
    o.borderColor = { r = 0.08, g = 0.09, b = 0.10, a = 0.35 }
    o.moveWithMouse = false
    o.dragging = false
    o.dragMoved = false
    o.lastInitVehicle = -1
    o.lastRequestMs = 0
    return o
end

function PFC_Dashboard:createChildren()
    ISPanel.createChildren(self)
    self.engineButton = ISButton:new(self.width - 46, 12, 34, 34, "", self, PFC_Dashboard.onEngine)
    self.engineButton:initialise()
    self.engineButton:instantiate()
    self.engineButton.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.engineButton.backgroundColorMouseOver = { r = 0.00, g = 0.70, b = 0.82, a = 0.18 }
    self.engineButton.borderColor = { r = 0.00, g = 0.82, b = 0.92, a = 0.18 }
    if ENGINE_BUTTON_TEXTURE and self.engineButton.setImage then
        self.engineButton:setImage(ENGINE_BUTTON_TEXTURE)
    end
    self:addChild(self.engineButton)
end

function PFC_Dashboard:getPlayer()
    return getSpecificPlayer and getSpecificPlayer(self.playerIndex) or getPlayer()
end

function PFC_Dashboard:getVehicle()
    local player = self:getPlayer()
    if not player then return nil end
    return player:getVehicle()
end

function PFC_Dashboard:onEngine()
    local player = self:getPlayer()
    local vehicle = self:getVehicle()
    if ProjectFadedCarClient then
        ProjectFadedCarClient.openServicePanel(player, vehicle)
    end
end

function PFC_Dashboard:onMouseDown(x, y)
    self.dragging = true
    self.dragMoved = false
    return true
end

function PFC_Dashboard:onMouseMove(dx, dy)
    if not self.dragging then return end
    if math.abs(dx) + math.abs(dy) > 1 then
        self.dragMoved = true
    end
    self:setX(self.x + dx)
    self:setY(self.y + dy)
    clampToScreen(self)
end

function PFC_Dashboard:onMouseMoveOutside(dx, dy)
    self:onMouseMove(dx, dy)
end

function PFC_Dashboard:onMouseUp(x, y)
    if not self.dragging then return end
    self.dragging = false
    PFC_Dashboard.savedX = self.x
    PFC_Dashboard.savedY = self.y
    return true
end

function PFC_Dashboard:onMouseUpOutside(x, y)
    self:onMouseUp(x, y)
end

function PFC_Dashboard:update()
    ISPanel.update(self)
    local vehicle = self:getVehicle()
    if not vehicle or not PFC.dashboardEnabled() then
        self:removeFromUIManager()
        PFC_Dashboard.instance = nil
        return
    end
    clampToScreen(self)
    if vehicle:getId() ~= self.lastInitVehicle then
        self.lastInitVehicle = vehicle:getId()
        self.lastRequestMs = getTimestampMs and getTimestampMs() or 0
        if ProjectFadedCarClient then ProjectFadedCarClient.requestVehicleInit(vehicle) end
    end
end

function PFC_Dashboard:prerender()
    ISPanel.prerender(self)
    drawDashBackground(self)
    local vehicle = self:getVehicle()
    if not vehicle then return end

    local snapshot = PFC.getSnapshot(vehicle)
    if not snapshot then
        local now = getTimestampMs and getTimestampMs() or 0
        if now - (self.lastRequestMs or 0) > 1500 then
            self.lastRequestMs = now
            if ProjectFadedCarClient then ProjectFadedCarClient.requestVehicleInit(vehicle) end
        end
        self:drawText(PFC.text("IGUI_PFC_Syncing", "Syncing vehicle data"), 12, 8, 0.76, 0.82, 0.80, 1, UIFont.Small)
        return
    end
    local store = snapshot.store

    self:drawText(PFC.text("IGUI_PFC_EngineHealth", "Engine") .. " " .. tostring(PFC.round(snapshot.engineCondition)) .. "%", 12, 8, 0.82, 0.88, 0.86, 1, UIFont.Small)
    self:drawText(PFC.text("IGUI_PFC_AvgInternals", "Internals") .. " " .. tostring(PFC.round(snapshot.average)) .. "%", 100, 8, 0.82, 0.88, 0.86, 1, UIFont.Small)

    local warning = tostring(store.warning or "")
    local diag = trimText(PFC.text(PFC.diagnosticLabel(snapshot.diagnosticCode), PFC.text("IGUI_PFC_Diagnostic_OK", "Nominal")), PFC.csrCompatMode() and 10 or 14)
    if warning ~= "" then
        local warningText = PFC.text("IGUI_PFC_Hazard_" .. warning, diag)
        self:drawText(trimText(warningText, PFC.csrCompatMode() and 10 or 14), 210, 8, 0.96, 0.30, 0.22, 1, UIFont.Small)
    elseif snapshot.csr then
        self:drawText(PFC.text("IGUI_PFC_CSRMode", "CSR mode"), 210, 8, 0.42, 0.78, 0.92, 1, UIFont.Small)
    else
        self:drawText(diag, 210, 8, 0.78, 0.82, 0.80, 1, UIFont.Small)
    end

    local availableW = self.width - 68
    local barW = math.floor((availableW - 24) / 3)
    drawBar(self, 12, 44, barW, 6, store.oilLevel or 0, PFC.text("IGUI_PFC_Fluid_OilShort", "Oil"))
    drawBar(self, 20 + barW, 44, barW, 6, store.coolantLevel or 0, PFC.text("IGUI_PFC_Fluid_CoolantShort", "Cool"))
    drawBar(self, 28 + (barW * 2), 44, barW, 6, store.transmissionFluid or 0, PFC.text("IGUI_PFC_Fluid_TransmissionShort", "ATF"))

    local worst = snapshot.worstPart and PFC.text(snapshot.worstPart.labelKey, snapshot.worstPart.id) or PFC.text("IGUI_PFC_None", "None")
    self:drawText(trimText(PFC.text("IGUI_PFC_WorstPart", "Weakest") .. " " .. worst .. " " .. tostring(PFC.round(snapshot.worstValue)) .. "%", 46), 12, 54, 0.62, 0.68, 0.66, 1, UIFont.Small)
end

function PFC_Dashboard.open(playerIndex)
    if PFC_Dashboard.instance then return end
    if not PFC.dashboardEnabled() then return end
    local ui = PFC_Dashboard:new(playerIndex or 0)
    ui:initialise()
    ui:instantiate()
    ui:addToUIManager()
    PFC_Dashboard.instance = ui
end

local function onEnterVehicle(character)
    if not character or not character.getPlayerNum then return end
    if not PFC.dashboardEnabled() then return end
    PFC_Dashboard.open(character:getPlayerNum())
end

local function onExitVehicle(character)
    if PFC_Dashboard.instance then
        PFC_Dashboard.instance:removeFromUIManager()
        PFC_Dashboard.instance = nil
    end
end

local function onGameStart()
    local player = getPlayer and getPlayer() or nil
    if player and player:getVehicle() then
        PFC_Dashboard.open(player:getPlayerNum())
    end
end

if Events and Events.OnEnterVehicle then Events.OnEnterVehicle.Add(onEnterVehicle) end
if Events and Events.OnExitVehicle then Events.OnExitVehicle.Add(onExitVehicle) end
if Events and Events.OnGameStart then Events.OnGameStart.Add(onGameStart) end
