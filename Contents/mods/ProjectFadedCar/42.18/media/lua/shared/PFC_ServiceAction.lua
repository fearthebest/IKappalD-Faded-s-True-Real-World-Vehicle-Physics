if not ISBaseTimedAction then
    print("[ProjectFadedCar] Service action skipped: ISBaseTimedAction unavailable")
    return
end

PFC_ServiceAction = ISBaseTimedAction:derive("PFC_ServiceAction")

print("[ProjectFadedCar] Shared service action module loaded")

function PFC_ServiceAction:isValid()
    if self.character == nil or self.vehicle == nil or not ProjectFadedCar.enabled() then return false end
    local blocked = ProjectFadedCar.serviceBlocked and ProjectFadedCar.serviceBlocked(self.vehicle)
    if blocked then return false end
    if ProjectFadedCar.canReachEngine then
        return ProjectFadedCar.canReachEngine(self.character, self.vehicle)
    end
    return true
end

function PFC_ServiceAction:waitToStart()
    if self.vehicle and self.character and self.character.faceThisObject then
        self.character:faceThisObject(self.vehicle)
        return self.character:shouldBeTurning()
    end
    return false
end

function PFC_ServiceAction:update()
    if self.vehicle and self.character and self.character.faceThisObject then
        self.character:faceThisObject(self.vehicle)
    end
    if self.toolItem and self.toolItem.setJobDelta then
        self.toolItem:setJobDelta(self:getJobDelta())
    end
    if self.character and self.character.setMetabolicTarget and Metabolics then
        self.character:setMetabolicTarget(Metabolics.MediumWork)
    end
end

function PFC_ServiceAction:start()
    self:setActionAnim("VehicleWorkOnMid")
    if self.toolItem and self.toolItem.setJobType then
        self.toolItem:setJobType(ProjectFadedCar.text("IGUI_PFC_ServiceAction", "Service vehicle"))
    end
end

function PFC_ServiceAction:stop()
    if self.toolItem and self.toolItem.setJobDelta then
        self.toolItem:setJobDelta(0)
    end
    ISBaseTimedAction.stop(self)
end

function PFC_ServiceAction:perform()
    if self.toolItem and self.toolItem.setJobDelta then
        self.toolItem:setJobDelta(0)
    end
    ISBaseTimedAction.perform(self)
end

function PFC_ServiceAction:complete()
    local args = {
        vehicle = self.vehicle and self.vehicle:getId() or -1,
        action = self.pfcAction,
        target = self.pfcTarget,
    }
    if isClient() then
        sendClientCommand(ProjectFadedCar.MODULE_ID, "ServiceVehicle", args)
    else
        local ok, message, hazard = ProjectFadedCar.applyService(self.vehicle, self.character, self.pfcAction, self.pfcTarget)
        if ProjectFadedCarClient and ProjectFadedCarClient.showServiceOutcome then
            ProjectFadedCarClient.showServiceOutcome(ok, message, hazard)
        end
    end
    return true
end

function PFC_ServiceAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    return self.maxTime
end

function PFC_ServiceAction:new(character, vehicle, action, target, maxTime)
    local o = ISBaseTimedAction.new(self, character)
    o.vehicle = vehicle
    o.pfcAction = action
    o.pfcTarget = target
    o.maxTime = maxTime or 180
    o.toolItem = character and character:getInventory() and character:getInventory():getFirstTypeRecurse("Base.Wrench") or nil
    o.stopOnWalk = true
    o.stopOnRun = true
    o.jobType = ProjectFadedCar.text("IGUI_PFC_ServiceAction", "Service vehicle")
    return o
end
