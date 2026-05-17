if isServer() then return end
if not ISPanel then
    print("[ProjectFadedCar] Floating engine button skipped: ISPanel unavailable")
    return
end

PFC_EngineButton = ISPanel:derive("PFC_EngineButton")
PFC_EngineButton.instance = nil

print("[ProjectFadedCar] Client floating engine button module loaded")

local PFC = ProjectFadedCar
local BUTTON_TEXTURE = getTexture and getTexture("media/textures/PFC_EngineBayButton.png") or nil

function PFC_EngineButton:new(playerIndex)
    local size = 58
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local x = math.max(8, screenW - size - 118)
    local y = math.max(8, screenH - size - 214)
    local o = ISPanel:new(x, y, size, size)
    setmetatable(o, self)
    self.__index = self
    o.playerIndex = playerIndex or 0
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.moveWithMouse = false
    o.dragging = false
    o.dragMoved = false
    return o
end

function PFC_EngineButton:getPlayer()
    return getSpecificPlayer and getSpecificPlayer(self.playerIndex) or getPlayer()
end

function PFC_EngineButton:getVehicle()
    local player = self:getPlayer()
    if ProjectFadedCarClient and ProjectFadedCarClient.getActiveVehicle then
        return ProjectFadedCarClient.getActiveVehicle(player)
    end
    return player and player.getVehicle and player:getVehicle() or nil
end

function PFC_EngineButton:update()
    ISPanel.update(self)
    if not PFC.floatingButtonEnabled() or not PFC.engineBayEnabled() then
        self:removeFromUIManager()
        PFC_EngineButton.instance = nil
        return
    end

    local vehicle = self:getVehicle()
    self:setVisible(vehicle ~= nil)

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    if self.x > screenW - self.width - 8 then self:setX(screenW - self.width - 8) end
    if self.y > screenH - self.height - 8 then self:setY(screenH - self.height - 8) end
    if self.x < 8 then self:setX(8) end
    if self.y < 8 then self:setY(8) end
end

function PFC_EngineButton:prerender()
    if self.getIsVisible and not self:getIsVisible() then return end
    local hovered = self:isMouseOver()
    local alpha = hovered and 0.95 or 0.72

    self:drawRect(7, 7, self.width - 14, self.height - 14, hovered and 0.14 or 0.04, 0.02, 0.025, 0.028)
    self:drawRectBorder(5, 5, self.width - 10, self.height - 10, hovered and 0.70 or 0.34, 0.00, 0.80, 0.92)

    if BUTTON_TEXTURE then
        self:drawTextureScaled(BUTTON_TEXTURE, 7, 7, self.width - 14, self.height - 14, alpha, 1, 1, 1)
    else
        self:drawTextCentre(PFC.text("IGUI_PFC_EngineButton", "The Shop"), self.width / 2, 34, 0.94, 0.98, 1.00, 1, UIFont.Small)
    end
end

function PFC_EngineButton:onMouseDown(x, y)
    self.dragging = true
    self.dragMoved = false
    return true
end

function PFC_EngineButton:onMouseMove(dx, dy)
    if not self.dragging then return end
    if math.abs(dx) + math.abs(dy) > 1 then
        self.dragMoved = true
    end
    self:setX(self.x + dx)
    self:setY(self.y + dy)
end

function PFC_EngineButton:onMouseMoveOutside(dx, dy)
    self:onMouseMove(dx, dy)
end

function PFC_EngineButton:onMouseUp(x, y)
    if not self.dragging then return end
    local wasClick = not self.dragMoved
    self.dragging = false
    self.dragMoved = false

    if wasClick then
        local player = self:getPlayer()
        local vehicle = self:getVehicle()
        if ProjectFadedCarClient then
            ProjectFadedCarClient.openServicePanel(player, vehicle)
        end
    end
    return true
end

function PFC_EngineButton:onMouseUpOutside(x, y)
    self:onMouseUp(x, y)
end

function PFC_EngineButton.open(playerIndex)
    if PFC_EngineButton.instance then return end
    if not PFC.floatingButtonEnabled() then return end
    local ui = PFC_EngineButton:new(playerIndex or 0)
    ui:initialise()
    ui:instantiate()
    ui:addToUIManager()
    PFC_EngineButton.instance = ui
end

local function ensureButton(character)
    if not PFC.floatingButtonEnabled() then return end
    local playerIndex = 0
    if character and character.getPlayerNum then
        playerIndex = character:getPlayerNum()
    else
        local player = getPlayer and getPlayer() or nil
        if player and player.getPlayerNum then playerIndex = player:getPlayerNum() end
    end
    PFC_EngineButton.open(playerIndex)
end

if Events and Events.OnGameStart then Events.OnGameStart.Add(ensureButton) end
if Events and Events.OnEnterVehicle then Events.OnEnterVehicle.Add(ensureButton) end
