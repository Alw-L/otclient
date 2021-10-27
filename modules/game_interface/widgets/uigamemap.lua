UIGameMap = extends(UIMap, "UIGameMap")

function UIGameMap.create()
    local gameMap = UIGameMap.internalCreate()
    gameMap:setKeepAspectRatio(true)
    gameMap:setVisibleDimension({width = 15, height = 11})
    gameMap:setDrawLights(true)
    return gameMap
end

function UIGameMap:onDragEnter(mousePos)
    local tile = self:getTile(mousePos)
    if not tile then return false end

    local thing = tile:getTopMoveThing()
    if not thing then return false end

    self.currentDragThing = thing

    g_mouse.pushCursor('target')
    self.allowNextRelease = false
    return true
end

function UIGameMap:onDragLeave(droppedWidget, mousePos)
    local getLeftTopSlot = rootWidget:recursiveGetChildByPos({x = mousePos.x-2, y = mousePos.y+2})
    local getLeftDownSlot = rootWidget:recursiveGetChildByPos({x = mousePos.x-2, y = mousePos.y-2})
    local getRightDownSlot = rootWidget:recursiveGetChildByPos({x = mousePos.x+2, y = mousePos.y-2})
    local getRightTopSlot = rootWidget:recursiveGetChildByPos({x = mousePos.x+2, y = mousePos.y+2})
    local WindowContents = rootWidget:recursiveGetChildByPos(mousePos)

    if WindowContents:getStyleName() == "ContainerWindow" then
        if getLeftTopSlot:getStyleName() == "Item" then
        local item = self.currentDragThing
            if item:isItem() then
                local toPos = getLeftTopSlot.position
                local itemPos = item:getPosition()
                if itemPos.x ~= toPos.x and itemPos.y ~= toPos.y and itemPos.z ~= toPos.z then
                    if item:getCount() > 1 then
                        modules.game_interface.moveStackableItem(item, toPos)
                    else
                        g_game.move(item, toPos, 1)
                    end
                end
            end
        elseif getLeftDownSlot:getStyleName() == "Item" then
            local item = self.currentDragThing
            if item:isItem() then
                local toPos = getLeftDownSlot.position
                local itemPos = item:getPosition()
                if itemPos.x ~= toPos.x and itemPos.y ~= toPos.y and itemPos.z ~= toPos.z then
                    if item:getCount() > 1 then
                        modules.game_interface.moveStackableItem(item, toPos)
                    else
                        g_game.move(item, toPos, 1)
                    end
                end
            end
        elseif getRightDownSlot:getStyleName() == "Item" then
            local item = self.currentDragThing
            if item:isItem() then
                local toPos = getRightDownSlot.position
                local itemPos = item:getPosition()
                if itemPos.x ~= toPos.x and itemPos.y ~= toPos.y and itemPos.z ~= toPos.z then
                    if item:getCount() > 1 then
                        modules.game_interface.moveStackableItem(item, toPos)
                    else
                        g_game.move(item, toPos, 1)
                    end
                end
            end
        elseif getRightTopSlot:getStyleName() == "Item" then
            local item = self.currentDragThing
            if item:isItem() then
                local toPos = getRightTopSlot.position
                local itemPos = item:getPosition()
                if itemPos.x ~= toPos.x and itemPos.y ~= toPos.y and itemPos.z ~= toPos.z then
                    if item:getCount() > 1 then
                        modules.game_interface.moveStackableItem(item, toPos)
                    else
                        g_game.move(item, toPos, 1)
                    end
                end
            end
        end
    end
    self.currentDragThing = nil
    self.hoveredWho = nil
    g_mouse.popCursor('target')
    return true
end

function UIGameMap:onDrop(widget, mousePos)
    if not self:canAcceptDrop(widget, mousePos) then return false end

    local tile = self:getTile(mousePos)
    if not tile then return false end

    local thing = widget.currentDragThing
    local thingPos = thing:getPosition()
    if not thingPos then return false end

    local thingTile = thing:getTile()
    if thingPos.x ~= 65535 and not thingTile then return false end

    local toPos = tile:getPosition()
    if thingPos.x == toPos.x and thingPos.y == toPos.y and thingPos.z == toPos.z then
        return false
    end

    if thing:isItem() and thing:getCount() > 1 then
        modules.game_interface.moveStackableItem(thing, toPos)
    else
        g_game.move(thing, toPos, 1)
    end

    return true
end

function UIGameMap:onMousePress()
    if not self:isDragging() then self.allowNextRelease = true end
end

function UIGameMap:onMouseRelease(mousePosition, mouseButton)
    if not self.allowNextRelease then return true end

    local autoWalkPos = self:getPosition(mousePosition)

    -- happens when clicking outside of map boundaries
    if not autoWalkPos then return false end

    local localPlayerPos = g_game.getLocalPlayer():getPosition()
    if autoWalkPos.z ~= localPlayerPos.z then
        local dz = autoWalkPos.z - localPlayerPos.z
        autoWalkPos.x = autoWalkPos.x + dz
        autoWalkPos.y = autoWalkPos.y + dz
        autoWalkPos.z = localPlayerPos.z
    end

    local lookThing
    local useThing
    local creatureThing
    local multiUseThing
    local attackCreature

    local tile = self:getTile(mousePosition)
    if tile then
        lookThing = tile:getTopLookThing()
        useThing = tile:getTopUseThing()
        creatureThing = tile:getTopCreature()
    end

    local autoWalkTile = g_map.getTile(autoWalkPos)
    if autoWalkTile then attackCreature = autoWalkTile:getTopCreature() end

    local ret = modules.game_interface.processMouseAction(mousePosition,
                                                          mouseButton,
                                                          autoWalkPos,
                                                          lookThing, useThing,
                                                          creatureThing,
                                                          attackCreature)
    if ret then self.allowNextRelease = false end

    return ret
end

function UIGameMap:canAcceptDrop(widget, mousePos)
    if not widget or not widget.currentDragThing then return false end

    local children = rootWidget:recursiveGetChildrenByPos(mousePos)
    for i = 1, #children do
        local child = children[i]
        if child == self then
            return true
        elseif not child:isPhantom() then
            return false
        end
    end

    error('Widget ' .. self:getId() .. ' not in drop list.')
    return false
end
