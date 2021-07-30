-- @docclass
UIWindow = extends(UIWidget, "UIWindow")

function UIWindow.create()
  local window = UIWindow.internalCreate()
  window:setTextAlign(AlignTopCenter)
  window:setDraggable(true)
  window:setAutoFocusPolicy(AutoFocusFirst)
  return window
end

function UIWindow:onKeyDown(keyCode, keyboardModifiers)
  if keyboardModifiers == KeyboardNoModifier then
    if keyCode == KeyEnter then
      signalcall(self.onEnter, self)
    elseif keyCode == KeyEscape then
      signalcall(self.onEscape, self)
    end
  end
end

function UIWindow:onFocusChange(focused)
  if focused then self:raise() end
end

function UIWindow:onDragEnter(mousePos)
  self:breakAnchors()
  self.movingReference = { x = mousePos.x - self:getX(), y = mousePos.y - self:getY() }
  return true
end

function UIWindow:onDragLeave(droppedWidget, mousePos)
  -- TODO: auto detect and reconnect anchors
end

function UIWindow:onDragMove(mousePos, mouseMoved)
  if self:getId() == 'inventoryWindow' or self:getId() == 'minimapWindow' or self:getId() == 'healthInfoWindow' then
    local parent = self:getParent()
    local isFirst = parent:getChildIndex(self) == 1
    local isLast = parent:getChildIndex(self) == parent:getChildCount()
    if isFirst and isLast then -- its the only child, cannot move.
      return
    end
    if isFirst and not isLast then -- first child
      local nextChild = parent:getChildAfter(self)
      local toIndex = parent:getChildIndex(nextChild)
      if mousePos.y >= nextChild:getPosition().y then
        parent:moveChildToIndex(self, toIndex)  
      end
    elseif not isFirst and not isLast then -- child somewhere between
      local prevChild = parent:getChildBefore(self)
      local nextChild = parent:getChildAfter(self)
      local prevIndex = parent:getChildIndex(prevChild)
      local nextIndex = parent:getChildIndex(nextChild)
      if mousePos.y >= nextChild:getPosition().y then
        parent:moveChildToIndex(self, nextIndex)  
      elseif mousePos.y <= prevChild:getPosition().y then
        parent:moveChildToIndex(self, prevIndex)  
      end
    elseif not isFirst and isLast then -- last child
      local prevChild = parent:getChildBefore(self)
      local toIndex = parent:getChildIndex(prevChild)
      if mousePos.y <= prevChild:getPosition().y then
        parent:moveChildToIndex(self, toIndex)  
      end
    end
    return
  end

  local pos = { x = mousePos.x - self.movingReference.x, y = mousePos.y - self.movingReference.y }
  self:setPosition(pos)
  self:bindRectToParent()
end
