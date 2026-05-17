if isServer() then return end
if not ISPanel then
    print("[ProjectFadedCar] Service panel skipped: ISPanel unavailable")
    return
end

PFC_ServicePanel = ISPanel:derive("PFC_ServicePanel")
PFC_ServicePanel.instance = nil

print("[ProjectFadedCar] Client service panel module loaded")

local PFC = ProjectFadedCar
local ENGINE_BAY_BACKGROUND = getTexture and getTexture("media/textures/PFC_EngineBayBackground.png") or nil

local function conditionColor(value)
    value = PFC.clamp(value, 0, 100)
    if value < 35 then return 0.94, 0.24, 0.18 end
    if value < 65 then return 0.95, 0.68, 0.22 end
    return 0.15, 0.76, 0.46
end

local function trimText(text, maxChars)
    text = tostring(text or "")
    if #text <= maxChars then return text end
    return string.sub(text, 1, math.max(1, maxChars - 3)) .. "..."
end

local function drawValueBar(panel, x, y, w, h, value)
    local r, g, b = conditionColor(value)
    panel:drawRect(x, y, w, h, 0.62, 0.035, 0.04, 0.045)
    panel:drawRectBorder(x, y, w, h, 0.75, 0.20, 0.22, 0.24)
    panel:drawRect(x + 1, y + 1, math.floor((w - 2) * PFC.clamp(value, 0, 100) / 100), h - 2, 0.92, r, g, b)
end

local function drawSectionLine(panel, y, title)
    panel:drawRect(18, y, panel.width - 36, 1, 0.85, 0.00, 0.78, 0.92)
    panel:drawText(title, 20, y + 8, 0.96, 0.96, 0.90, 1, UIFont.Small)
end

local function drawNeonFrame(panel)
    panel:drawRectBorder(0, 0, panel.width, panel.height, 1.0, 0.00, 0.92, 1.00)
    panel:drawRectBorder(1, 1, panel.width - 2, panel.height - 2, 0.85, 0.02, 0.62, 0.82)
    panel:drawRectBorder(3, 3, panel.width - 6, panel.height - 6, 0.45, 0.00, 0.38, 0.52)
    panel:drawRect(0, 0, panel.width, 2, 0.22, 0.00, 0.92, 1.00)
    panel:drawRect(0, panel.height - 2, panel.width, 2, 0.18, 0.00, 0.92, 1.00)
    panel:drawRect(0, 0, 2, panel.height, 0.18, 0.00, 0.92, 1.00)
    panel:drawRect(panel.width - 2, 0, 2, panel.height, 0.18, 0.00, 0.92, 1.00)
end

local function drawPanelBackground(panel)
    if ENGINE_BAY_BACKGROUND then
        panel:drawTextureScaled(ENGINE_BAY_BACKGROUND, 0, 0, panel.width, panel.height, 0.34, 1, 1, 1)
        panel:drawTextureScaled(ENGINE_BAY_BACKGROUND, panel.width - 380, 92, 330, 330, 0.30, 0.86, 1, 1)
    end
    panel:drawRect(8, 8, panel.width - 16, panel.height - 16, 0.40, 0.018, 0.024, 0.030)
    panel:drawRect(12, 102, panel.width - 24, panel.height - 188, 0.24, 0.018, 0.022, 0.026)
end

function PFC_ServicePanel:new(x, y, w, h, playerIndex, vehicle)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.playerIndex = playerIndex or 0
    o.vehicle = vehicle
    o.backgroundColor = { r = 0.012, g = 0.016, b = 0.020, a = 0.94 }
    o.borderColor = { r = 0.00, g = 0.92, b = 1.00, a = 1.0 }
    o.moveWithMouse = true
    o.partButtons = {}
    o.fluidButtons = {}
    o.lastRequestMs = 0
    return o
end

function PFC_ServicePanel:getLayout()
    local partRows = math.ceil(#PFC.PARTS / 2)
    local partTop = 122
    local partRowH = 26
    local fluidTop = partTop + (partRows * partRowH) + 36
    return {
        labelX = 22,
        barX = 172,
        barW = 300,
        valueX = 486,
        statusX = 536,
        buttonX = self.width - 124,
        buttonW = 100,
        buttonH = 22,
        partTop = partTop,
        partRowH = partRowH,
        partRows = partRows,
        partColW = math.floor((self.width - 56) / 2),
        partColGap = 16,
        fluidTop = fluidTop,
        fluidRowH = 27,
        tuneTop = self.height - 124,
        physicsTop = self.height - 68,
        physicsButtonX = math.max(420, self.width - 410),
    }
end

function PFC_ServicePanel:getPartRow(index)
    local layout = self:getLayout()
    local column = math.floor((index - 1) / layout.partRows)
    local row = (index - 1) % layout.partRows
    local x = 20 + (column * (layout.partColW + layout.partColGap))
    local y = layout.partTop + (row * layout.partRowH)
    return {
        labelX = x,
        barX = x + 112,
        barW = 132,
        valueX = x + 250,
        statusX = x + 286,
        buttonX = x + layout.partColW - 70,
        buttonW = 68,
        y = y,
    }
end

function PFC_ServicePanel:getFluidRow(index)
    local layout = self:getLayout()
    local y = layout.fluidTop + ((index - 1) * layout.fluidRowH)
    return {
        labelX = layout.labelX,
        barX = layout.barX,
        barW = layout.barW,
        valueX = layout.valueX,
        statusX = layout.statusX,
        buttonX = layout.buttonX,
        buttonW = layout.buttonW,
        y = y,
    }
end

function PFC_ServicePanel:getPlayer()
    return getSpecificPlayer and getSpecificPlayer(self.playerIndex) or getPlayer()
end

function PFC_ServicePanel:createChildren()
    ISPanel.createChildren(self)

    self.closeButton = ISButton:new(self.width - 76, 10, 60, 24, PFC.text("IGUI_PFC_Close", "Close"), self, PFC_ServicePanel.onClose)
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self:addChild(self.closeButton)

    self.guideButton = ISButton:new(self.width - 152, 10, 66, 24, PFC.text("IGUI_PFC_GuideButton", "Guide"), self, PFC_ServicePanel.onGuide)
    self.guideButton:initialise()
    self.guideButton:instantiate()
    self:addChild(self.guideButton)

    self.restoreWreckButton = ISButton:new(self.width - 246, 10, 84, 24, PFC.text("IGUI_PFC_RestoreWreck", "Restore"), self, PFC_ServicePanel.onRestoreWreck)
    self.restoreWreckButton:initialise()
    self.restoreWreckButton:instantiate()
    self:addChild(self.restoreWreckButton)

    self.installEngineButton = ISButton:new(self.width - 338, 10, 82, 24, PFC.text("IGUI_PFC_InstallEngine", "Install"), self, PFC_ServicePanel.onInstallEngine)
    self.installEngineButton:initialise()
    self.installEngineButton:instantiate()
    self:addChild(self.installEngineButton)

    self.pullEngineButton = ISButton:new(self.width - 424, 10, 76, 24, PFC.text("IGUI_PFC_PullEngine", "Pull"), self, PFC_ServicePanel.onPullEngine)
    self.pullEngineButton:initialise()
    self.pullEngineButton:instantiate()
    self:addChild(self.pullEngineButton)

    self.tuneButton = ISButton:new(self.width - 504, 10, 70, 24, PFC.text("IGUI_PFC_Tune", "Tune"), self, PFC_ServicePanel.onTune)
    self.tuneButton:initialise()
    self.tuneButton:instantiate()
    self:addChild(self.tuneButton)

    local layout = self:getLayout()
    for index, spec in ipairs(PFC.PARTS) do
        local row = self:getPartRow(index)
        local btn = ISButton:new(row.buttonX, row.y - 2, row.buttonW, layout.buttonH, PFC.text("IGUI_PFC_Replace", "Replace"), self, PFC_ServicePanel.onReplacePart)
        btn.internal = spec.id
        btn:initialise()
        btn:instantiate()
        self:addChild(btn)
        self.partButtons[spec.id] = btn
    end

    for index, spec in ipairs(PFC.FLUIDS) do
        local row = self:getFluidRow(index)
        local btn = ISButton:new(row.buttonX, row.y - 2, row.buttonW, layout.buttonH, PFC.text("IGUI_PFC_Add", "Add"), self, PFC_ServicePanel.onAddFluid)
        btn.internal = spec.id
        btn:initialise()
        btn:instantiate()
        self:addChild(btn)
        self.fluidButtons[spec.id] = btn
    end

    self.towDownButton = ISButton:new(layout.buttonX, layout.tuneTop + 28, 46, layout.buttonH, "-5", self, PFC_ServicePanel.onTowDown)
    self.towDownButton:initialise()
    self.towDownButton:instantiate()
    self:addChild(self.towDownButton)

    self.towUpButton = ISButton:new(layout.buttonX + 54, layout.tuneTop + 28, 46, layout.buttonH, "+5", self, PFC_ServicePanel.onTowUp)
    self.towUpButton:initialise()
    self.towUpButton:instantiate()
    self:addChild(self.towUpButton)

    self.physicsStatusButton = ISButton:new(layout.physicsButtonX, layout.physicsTop, 74, layout.buttonH, PFC.text("IGUI_PFC_PhysicsStatusButton", "Status"), self, PFC_ServicePanel.onPhysicsStatus)
    self.physicsStatusButton:initialise()
    self.physicsStatusButton:instantiate()
    self:addChild(self.physicsStatusButton)

    self.physicsSyncButton = ISButton:new(layout.physicsButtonX + 80, layout.physicsTop, 54, layout.buttonH, PFC.text("IGUI_PFC_PhysicsSyncButton", "Sync"), self, PFC_ServicePanel.onPhysicsSync)
    self.physicsSyncButton:initialise()
    self.physicsSyncButton:instantiate()
    self:addChild(self.physicsSyncButton)

    self.physicsRetuneButton = ISButton:new(layout.physicsButtonX + 140, layout.physicsTop, 68, layout.buttonH, PFC.text("IGUI_PFC_PhysicsRetuneButton", "Retune"), self, PFC_ServicePanel.onPhysicsRetune)
    self.physicsRetuneButton:initialise()
    self.physicsRetuneButton:instantiate()
    self:addChild(self.physicsRetuneButton)

    self.physicsSafeButton = ISButton:new(layout.physicsButtonX + 214, layout.physicsTop, 96, layout.buttonH, PFC.text("IGUI_PFC_PhysicsSafeButton", "Safe Reset"), self, PFC_ServicePanel.onPhysicsSafe)
    self.physicsSafeButton:initialise()
    self.physicsSafeButton:instantiate()
    self:addChild(self.physicsSafeButton)
end

function PFC_ServicePanel:onClose()
    self:removeFromUIManager()
    PFC_ServicePanel.instance = nil
end

function PFC_ServicePanel:onGuide()
    if PFC_GuidePanel and PFC_GuidePanel.open then
        PFC_GuidePanel.open()
    end
end

function PFC_ServicePanel:onTune()
    local blocked = PFC.serviceBlocked and PFC.serviceBlocked(self.vehicle)
    if blocked then return end
    local player = self:getPlayer()
    if ProjectFadedCarClient then
        ProjectFadedCarClient.queueService(player, self.vehicle, "tuneEngine", "engine", 210)
    end
end

function PFC_ServicePanel:onPullEngine()
    local blocked = PFC.serviceBlocked and PFC.serviceBlocked(self.vehicle)
    if blocked then return end
    local player = self:getPlayer()
    if ProjectFadedCarClient then
        ProjectFadedCarClient.queueService(player, self.vehicle, "pullEngine", "engine", 420)
    end
end

function PFC_ServicePanel:onInstallEngine()
    local blocked = PFC.serviceBlocked and PFC.serviceBlocked(self.vehicle)
    if blocked then return end
    local player = self:getPlayer()
    if ProjectFadedCarClient then
        ProjectFadedCarClient.queueService(player, self.vehicle, "installEngine", "engine", 360)
    end
end

function PFC_ServicePanel:onRestoreWreck()
    local blocked = PFC.serviceBlocked and PFC.serviceBlocked(self.vehicle)
    if blocked then return end
    local player = self:getPlayer()
    if ProjectFadedCarClient then
        ProjectFadedCarClient.queueService(player, self.vehicle, "restoreWreck", "vehicle", 820)
    end
end

function PFC_ServicePanel:onReplacePart(button)
    local blocked = PFC.serviceBlocked and PFC.serviceBlocked(self.vehicle)
    if blocked then return end
    local player = self:getPlayer()
    if ProjectFadedCarClient then
        ProjectFadedCarClient.queueService(player, self.vehicle, "replacePart", button.internal, 240)
    end
end

function PFC_ServicePanel:onAddFluid(button)
    local blocked = PFC.serviceBlocked and PFC.serviceBlocked(self.vehicle)
    if blocked then return end
    local player = self:getPlayer()
    if ProjectFadedCarClient then
        ProjectFadedCarClient.queueService(player, self.vehicle, "addFluid", button.internal, 120)
    end
end

function PFC_ServicePanel:getTowAssist()
    local snapshot = PFC.getSnapshot(self.vehicle)
    local store = snapshot and snapshot.store or nil
    PFC.ensureStoreDefaults(store)
    return store and store.tuning and store.tuning.towAssist or 100
end

function PFC_ServicePanel:requestTowAssist(value)
    local blocked = PFC.serviceBlocked and PFC.serviceBlocked(self.vehicle)
    if blocked then return end
    local player = self:getPlayer()
    if ProjectFadedCarClient then
        ProjectFadedCarClient.requestTune(player, self.vehicle, "towAssist", PFC.clamp(value, 75, 125))
    end
end

function PFC_ServicePanel:onTowDown()
    self:requestTowAssist(self:getTowAssist() - 5)
end

function PFC_ServicePanel:onTowUp()
    self:requestTowAssist(self:getTowAssist() + 5)
end

function PFC_ServicePanel:requestPhysics(action)
    local player = self:getPlayer()
    if ProjectFadedCarClient and ProjectFadedCarClient.requestPhysicsBridge then
        ProjectFadedCarClient.requestPhysicsBridge(action, player, self.vehicle)
    end
end

function PFC_ServicePanel:onPhysicsStatus()
    self:requestPhysics("status")
end

function PFC_ServicePanel:onPhysicsSync()
    self:requestPhysics("syncVehicle")
end

function PFC_ServicePanel:onPhysicsRetune()
    self:requestPhysics("retune")
end

function PFC_ServicePanel:onPhysicsSafe()
    self:requestPhysics("safeHandling")
end

function PFC_ServicePanel:update()
    ISPanel.update(self)
    if not self.vehicle or not PFC.engineBayEnabled() then
        self:onClose()
        return
    end
    local snapshot = PFC.getSnapshot(self.vehicle)
    if not snapshot then
        local now = getTimestampMs and getTimestampMs() or 0
        if now - (self.lastRequestMs or 0) > 1500 then
            self.lastRequestMs = now
            if ProjectFadedCarClient then ProjectFadedCarClient.requestVehicleInit(self.vehicle) end
        end
    end

    local player = self:getPlayer()
    local blocked = PFC.serviceBlocked and PFC.serviceBlocked(self.vehicle)
    local store = snapshot and snapshot.store or nil
    for _, spec in ipairs(PFC.PARTS) do
        local btn = self.partButtons[spec.id]
        if btn then
            local hasItem = ProjectFadedCarClient and ProjectFadedCarClient.hasServiceItem(player, spec)
            local value = store and store.parts and PFC.clamp(store.parts[spec.id] or 0, 0, 100) or 100
            btn.enable = hasItem == true and not blocked and value < 100
        end
    end
    for _, spec in ipairs(PFC.FLUIDS) do
        local btn = self.fluidButtons[spec.id]
        if btn then
            local hasItem = ProjectFadedCarClient and ProjectFadedCarClient.hasItem(player, spec.item)
            local value = store and PFC.clamp(store[spec.id] or 0, 0, 100) or 100
            btn.enable = hasItem == true and not blocked and value < 100
        end
    end
    if self.tuneButton then
        local hasEngineParts = false
        if ProjectFadedCarClient then
            hasEngineParts = ProjectFadedCarClient.hasItem(player, "Base.EngineParts") or ProjectFadedCarClient.hasItem(player, "EngineParts")
        end
        self.tuneButton.enable = hasEngineParts == true and PFC.getEnginePart(self.vehicle) ~= nil and not blocked and (not snapshot or snapshot.average < 100 or snapshot.engineCondition < 100)
    end
    if self.pullEngineButton then
        self.pullEngineButton.enable = PFC.canPullEngine and PFC.canPullEngine(player, self.vehicle) == true
    end
    if self.installEngineButton then
        self.installEngineButton.enable = PFC.canInstallEngine and PFC.canInstallEngine(player, self.vehicle) == true
    end
    if self.restoreWreckButton then
        self.restoreWreckButton.enable = PFC.canRestoreWreck and PFC.canRestoreWreck(player, self.vehicle) == true
    end
    if self.towDownButton and self.towUpButton then
        local tow = self:getTowAssist()
        self.towDownButton.enable = not blocked and tow > 75
        self.towUpButton.enable = not blocked and tow < 125
    end
    if self.physicsStatusButton and self.physicsSyncButton and self.physicsRetuneButton and self.physicsSafeButton then
        local physics = PFC.IKFRVPBridge and PFC.IKFRVPBridge.status(self.vehicle) or nil
        local active = physics and physics.active == true
        local loaded = physics and physics.loaded == true
        local admin = PFC.IKFRVPBridge and PFC.IKFRVPBridge.hasAdminAccess(player) or false
        self.physicsStatusButton.enable = active
        self.physicsSyncButton.enable = loaded and self.vehicle ~= nil
        self.physicsRetuneButton.enable = loaded and admin
        self.physicsSafeButton.enable = loaded and admin
    end
end

function PFC_ServicePanel:drawHeader(snapshot)
    self:drawText(PFC.text("IGUI_PFC_EngineBay", "The Shop"), 18, 12, 0.96, 0.96, 0.90, 1, UIFont.Medium)
    if not snapshot then return end

    local label = trimText(snapshot.vehicleLabel or PFC.getVehicleLabel(self.vehicle), 42)
    self:drawText(label, 20, 40, 0.70, 0.76, 0.75, 1, UIFont.Small)

    local diag = PFC.text(PFC.diagnosticLabel(snapshot.diagnosticCode), PFC.text("IGUI_PFC_Diagnostic_OK", "Nominal"))
    local weakest = snapshot.worstPart and PFC.text(snapshot.worstPart.labelKey, snapshot.worstPart.id) or PFC.text("IGUI_PFC_None", "None")
    local speed = PFC.round(PFC.vehicleSpeed(self.vehicle))
    local heat = PFC.round(snapshot.store and snapshot.store.engineHeat or 70)
    local oilQuality = PFC.round(snapshot.store and snapshot.store.oilQuality or 0)

    self:drawText(PFC.text("IGUI_PFC_EngineHealth", "Engine") .. ": " .. tostring(PFC.round(snapshot.engineCondition)) .. "%", 20, 64, 0.76, 0.82, 0.80, 1, UIFont.Small)
    self:drawText(PFC.text("IGUI_PFC_AvgInternals", "Internals") .. ": " .. tostring(PFC.round(snapshot.average)) .. "%", 178, 64, 0.76, 0.82, 0.80, 1, UIFont.Small)
    self:drawText(PFC.text("IGUI_PFC_Diagnostic", "Diagnostic") .. ": " .. diag, 352, 64, 0.76, 0.82, 0.80, 1, UIFont.Small)
    self:drawText(PFC.text("IGUI_PFC_Weakest", "Weakest") .. ": " .. weakest .. " " .. tostring(PFC.round(snapshot.worstValue)) .. "%", 20, 84, 0.62, 0.68, 0.66, 1, UIFont.Small)
    self:drawText(PFC.text("IGUI_PFC_OilQuality", "Oil quality") .. ": " .. tostring(oilQuality) .. "%", 280, 84, 0.62, 0.68, 0.66, 1, UIFont.Small)
    self:drawText(PFC.text("IGUI_PFC_Heat", "Heat") .. ": " .. tostring(heat) .. "C", 430, 84, 0.62, 0.68, 0.66, 1, UIFont.Small)
    self:drawText(PFC.text("IGUI_PFC_Speed", "Speed") .. ": " .. tostring(speed) .. " km/h", 532, 84, 0.62, 0.68, 0.66, 1, UIFont.Small)

    if PFC.requireEngineOff() and self.vehicle.isEngineRunning and self.vehicle:isEngineRunning() then
        self:drawText(PFC.text("IGUI_PFC_EngineMustBeOff", "Engine must be off for service"), 650, 84, 0.94, 0.38, 0.28, 1, UIFont.Small)
    end
end

function PFC_ServicePanel:drawServiceRows(snapshot)
    local layout = self:getLayout()
    local store = snapshot.store
    local player = self:getPlayer()

    drawSectionLine(self, layout.partTop - 24, PFC.text("IGUI_PFC_Systems", "Systems"))
    for index, spec in ipairs(PFC.PARTS) do
        local row = self:getPartRow(index)
        local y = row.y
        local value = PFC.clamp(store.parts and store.parts[spec.id] or 0, 0, 100)
        local hasItem = ProjectFadedCarClient and ProjectFadedCarClient.hasServiceItem(player, spec)
        self:drawText(trimText(PFC.text(spec.labelKey, spec.id), 16), row.labelX, y, 0.90, 0.92, 0.88, 1, UIFont.Small)
        drawValueBar(self, row.barX, y, row.barW, 18, value)
        self:drawText(tostring(PFC.round(value)) .. "%", row.valueX, y + 1, 0.90, 0.92, 0.88, 1, UIFont.Small)
        if hasItem then
            self:drawText(PFC.text("IGUI_PFC_Ready", "Ready"), row.statusX, y + 1, 0.44, 0.78, 0.54, 1, UIFont.Small)
        else
            self:drawText(PFC.text("IGUI_PFC_NeedItem", "Need"), row.statusX, y + 1, 0.78, 0.46, 0.36, 1, UIFont.Small)
        end
    end

    drawSectionLine(self, layout.fluidTop - 28, PFC.text("IGUI_PFC_Fluids", "Fluids"))
    for index, spec in ipairs(PFC.FLUIDS) do
        local row = self:getFluidRow(index)
        local y = row.y
        local value = PFC.clamp(store[spec.id] or 0, 0, 100)
        local hasItem = ProjectFadedCarClient and ProjectFadedCarClient.hasItem(player, spec.item)
        self:drawText(PFC.text(spec.labelKey, spec.id), row.labelX, y, 0.90, 0.92, 0.88, 1, UIFont.Small)
        drawValueBar(self, row.barX, y, row.barW, 18, value)
        self:drawText(tostring(PFC.round(value)) .. "%", row.valueX, y + 1, 0.90, 0.92, 0.88, 1, UIFont.Small)
        if hasItem then
            self:drawText(PFC.text("IGUI_PFC_Ready", "Ready"), row.statusX, y + 1, 0.44, 0.78, 0.54, 1, UIFont.Small)
        else
            self:drawText(PFC.text("IGUI_PFC_MissingItem", "Missing item"), row.statusX, y + 1, 0.78, 0.46, 0.36, 1, UIFont.Small)
        end
    end
end

function PFC_ServicePanel:drawTuning(snapshot)
    local layout = self:getLayout()
    local store = snapshot.store
    PFC.ensureStoreDefaults(store)
    local tow = store.tuning and store.tuning.towAssist or 100
    local effectiveTow = store.csrBridge and store.csrBridge.effectiveTowAssist or tow
    local csrStatus = snapshot.csr and PFC.text("IGUI_PFC_CSRDetected", "CSR detected") or PFC.text("IGUI_PFC_CSRStandby", "CSR standby")
    local bridge = PFC.text("IGUI_PFC_CSRBridge", "CSR bridge") .. ": " .. csrStatus

    drawSectionLine(self, layout.tuneTop - 16, PFC.text("IGUI_PFC_Tuning", "Tuning"))
    self:drawText(PFC.text("IGUI_PFC_TowAssist", "Tow assist") .. ": " .. tostring(tow) .. "% / " .. tostring(effectiveTow) .. "%", 22, layout.tuneTop + 28, 0.90, 0.92, 0.88, 1, UIFont.Small)
    self:drawText(bridge, 250, layout.tuneTop + 28, 0.62, 0.68, 0.66, 1, UIFont.Small)

    local physics = PFC.IKFRVPBridge and PFC.IKFRVPBridge.status(self.vehicle) or nil
    local physicsLabel = PFC.text("IGUI_PFC_PhysicsBridge", "Physics bridge")
    local physicsText = PFC.text("IGUI_PFC_PhysicsMissing", "IKFRVP not detected")
    local physicsDetail = ""
    if physics and physics.active and not physics.loaded then
        physicsText = PFC.text("IGUI_PFC_PhysicsWaiting", "IKFRVP detected, bridge waiting")
    elseif physics and physics.loaded then
        local mode = physics.profileTuning and PFC.text("IGUI_PFC_PhysicsRoster", "roster") or PFC.text("IGUI_PFC_PhysicsGeneric", "generic")
        if not physics.profileTuning and not physics.genericTuning then
            mode = PFC.text("IGUI_PFC_PhysicsReadOnly", "read-only")
        end
        local profile = physics.profileId ~= "" and physics.profileId or PFC.text("IGUI_PFC_PhysicsUnknownProfile", "unknown")
        physicsText = PFC.text("IGUI_PFC_PhysicsActive", "IKFRVP active") .. " / " .. mode .. " / " .. profile
        physicsDetail = PFC.text("IGUI_PFC_PhysicsPower", "Power") .. " " .. PFC.formatPhysicsNumber(physics.powerScale)
            .. "  " .. PFC.text("IGUI_PFC_PhysicsTorque", "Torque") .. " " .. PFC.formatPhysicsNumber(physics.engineTorqueMult)
            .. "  " .. PFC.text("IGUI_PFC_PhysicsMass", "Mass") .. " " .. PFC.formatPhysicsNumber(physics.massScale)
            .. "  " .. PFC.text("IGUI_PFC_PhysicsBrake", "Brake") .. " " .. PFC.formatPhysicsNumber(physics.brakeBaseRetain)
            .. "  " .. PFC.text("IGUI_PFC_PhysicsTrunk", "Trunk") .. " " .. PFC.formatPhysicsNumber(physics.trunkCapacityMult)
        if physics.glitchTripped then
            physicsDetail = PFC.text("IGUI_PFC_PhysicsGlitchGuardTripped", "Glitch guard tripped") .. ": " .. tostring(physics.tripReason or "")
        elseif physics.handlingPhysics then
            physicsDetail = physicsDetail .. "  " .. PFC.text("IGUI_PFC_PhysicsAdvancedHandling", "Advanced handling")
        end
    end
    self:drawText(physicsLabel .. ": " .. trimText(physicsText, 58), 22, layout.physicsTop + 2, 0.78, 0.84, 0.82, 1, UIFont.Small)
    if physicsDetail ~= "" then
        self:drawText(trimText(physicsDetail, 74), 22, layout.physicsTop + 26, 0.56, 0.64, 0.62, 1, UIFont.Small)
    end

    local last = store.history and store.history[1] or nil
    if last then
        local text = PFC.text("IGUI_PFC_LastService", "Last service") .. ": " .. tostring(last.action) .. " " .. tostring(last.target) .. " @" .. tostring(last.hour) .. "h"
        self:drawText(trimText(text, 86), 18, self.height - 18, 0.62, 0.68, 0.66, 1, UIFont.Small)
    end
end

function PFC_ServicePanel:prerender()
    ISPanel.prerender(self)
    drawPanelBackground(self)
    drawNeonFrame(self)
    local snapshot = PFC.getSnapshot(self.vehicle)
    if not snapshot then
        self:drawText(PFC.text("IGUI_PFC_EngineBay", "The Shop"), 18, 12, 0.96, 0.96, 0.90, 1, UIFont.Medium)
        self:drawText(PFC.text("IGUI_PFC_Syncing", "Syncing vehicle data"), 18, 48, 0.76, 0.82, 0.80, 1, UIFont.Small)
        return
    end

    self:drawHeader(snapshot)
    self:drawServiceRows(snapshot)
    self:drawTuning(snapshot)
end

function PFC_ServicePanel.open(playerIndex, vehicle)
    if PFC_ServicePanel.instance then
        PFC_ServicePanel.instance:removeFromUIManager()
        PFC_ServicePanel.instance = nil
    end
    if not vehicle then return end
    local w, h = 900, 660
    if getCore():getScreenWidth() < w + 16 then w = getCore():getScreenWidth() - 16 end
    if getCore():getScreenHeight() < h + 16 then h = getCore():getScreenHeight() - 16 end
    local x = math.max(8, math.floor((getCore():getScreenWidth() - w) / 2))
    local y = math.max(8, math.floor((getCore():getScreenHeight() - h) / 2))
    local ui = PFC_ServicePanel:new(x, y, w, h, playerIndex, vehicle)
    ui:initialise()
    ui:instantiate()
    ui:addToUIManager()
    PFC_ServicePanel.instance = ui
end
