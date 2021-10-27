-- @docclass
UIWindow = extends(UIWidget, "UIWindow")

function UIWindow.create()
    local window = UIWindow.internalCreate()
    window:setTextAlign(AlignTopCenter)
    window:setDraggable(true)
    window:setAutoFocusPolicy(AutoFocusFirst)
    return window
end

function UIWindow:onKeyPress(keyCode, keyboardModifiers)
    if keyboardModifiers == KeyboardNoModifier then
        if keyCode == KeyEnter then
            signalcall(self.onEnter, self)
        elseif keyCode == KeyEscape then
            signalcall(self.onEscape, self)
        end
    end
end

function UIWindow:onFocusChange(focused) if focused then self:raise() end end

function UIWindow:onDragEnter(mousePos)
    self:breakAnchors()
    self.movingReference = {
        x = mousePos.x - self:getX(),
        y = mousePos.y - self:getY()
    }
    return true
end

function UIWindow:onDragLeave(droppedWidget, mousePos)
    -- NOTE: change widget to droppedWidget for snap to panel feature
    if widget then
        if widget:getClassName() == 'UIMiniWindow' then
            if widget:getParent():getStyleName() ~= "GameSidePanel" then
                local oldParent = widget:getParent()
                if oldParent == self then
                    return true
                end
                if oldParent then
                    oldParent:removeChild(widget)
                end
                modules.game_interface.getRightPanel():addChild(widget)
            end
        end
    end
end

function UIWindow:onDragMove(mousePos, mouseMoved)
    local pos = {
        x = mousePos.x - self.movingReference.x,
        y = mousePos.y - self.movingReference.y
    }
    self:setPosition(pos)
    self:bindRectToParent()
end


function UIWindow:show(dontDisableHotkeys)
    if modules.game_hotkeys and not dontDisableHotkeys then
        modules.game_hotkeys.enableHotkeys(false)
    end
    self:setVisible(true)
end

function UIWindow:hide(dontDisableHotkeys)
    if modules.game_hotkeys and not dontDisableHotkeys then
        modules.game_hotkeys.enableHotkeys(true)
    end
    self:setVisible(false)
end