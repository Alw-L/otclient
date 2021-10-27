-- @docclass
UIMiniWindowModified = extends(UIMiniWindow, "UIMiniWindowModified")

function UIMiniWindowModified:minimize(dontSave)
    if (self.notMinimize) then return end
    
    self:setOn(true)
    self:getChildById('contentsPanel'):hide()
    self:getChildById('miniwindowScrollBar'):hide()
    self:getChildById('bottomResizeBorder'):hide()
    self:getChildById('miniBorder'):hide()
    self:getChildById('minimizeButton'):setOn(true)
    self.maximizedHeight = self:getHeight()
    self:setHeight(self.minimizedHeight)

    if not dontSave then self:setSettings({minimized = true}) end

    signalcall(self.onMinimize, self)
end

function UIMiniWindowModified:maximize(dontSave)
    self:setOn(false)
    self:getChildById('contentsPanel'):show()
    self:getChildById('miniwindowScrollBar'):show()
    self:getChildById('bottomResizeBorder'):show()
    self:getChildById('miniBorder'):show()
    self:getChildById('minimizeButton'):setOn(false)
    self:setHeight(self:getSettings('height') or self.maximizedHeight)

    if not dontSave then self:setSettings({minimized = false}) end

    local parent = self:getParent()
    if parent and parent:getClassName() == 'UIMiniWindowContainer' then
        parent:fitAll(self)
    end

    signalcall(self.onMaximize, self)
end

function UIMiniWindowModified:disableResize()
    self:getChildById('bottomResizeBorder'):disable()
    self:getChildById('miniBorder'):disable()
end

function UIMiniWindowModified:enableResize()
    self:getChildById('bottomResizeBorder'):enable()
    self:getChildById('miniBorder'):enable()
end

function UIMiniWindowModified:setContentHeight(height)
    local contentsPanel = self:getChildById('contentsPanel')
    local minHeight = contentsPanel:getMarginTop() +
                          contentsPanel:getMarginBottom() +
                          contentsPanel:getPaddingTop() +
                          contentsPanel:getPaddingBottom()

    local resizeBorder = self:getChildById('bottomResizeBorder')
    resizeBorder:setParentSize(minHeight + height)
    local miniBorder = self:getChildById('miniBorder')
    miniBorder:setParentSize(minHeight + height)
end

function UIMiniWindowModified:setContentMinimumHeight(height)
    local contentsPanel = self:getChildById('contentsPanel')
    local minHeight = contentsPanel:getMarginTop() +
                          contentsPanel:getMarginBottom() +
                          contentsPanel:getPaddingTop() +
                          contentsPanel:getPaddingBottom()

    local resizeBorder = self:getChildById('bottomResizeBorder')
    resizeBorder:setMinimum(minHeight + height)
    local miniBorder = self:getChildById('miniBorder')
    miniBorder:setMinimum(minHeight + height)
end

function UIMiniWindowModified:setContentMaximumHeight(height)
    local contentsPanel = self:getChildById('contentsPanel')
    local minHeight = contentsPanel:getMarginTop() +
                          contentsPanel:getMarginBottom() +
                          contentsPanel:getPaddingTop() +
                          contentsPanel:getPaddingBottom()

    local resizeBorder = self:getChildById('bottomResizeBorder')
    resizeBorder:setMaximum(minHeight + height)
    local miniBorder = self:getChildById('miniBorder')
    miniBorder:setMaximum(minHeight + height)
end

function UIMiniWindowModified:getMinimumHeight()
    local resizeBorder = self:getChildById('bottomResizeBorder')
    return resizeBorder:getMinimum()
end

function UIMiniWindowModified:getMaximumHeight()
    local resizeBorder = self:getChildById('bottomResizeBorder')
    return resizeBorder:getMaximum()
end

function UIMiniWindowModified:modifyMaximumHeight(height)
    local resizeBorder = self:getChildById('bottomResizeBorder')
    local miniBorder = self:getChildById('miniBorder')
    local newHeight = resizeBorder:getMaximum()+height
    local curHeight = self:getHeight()
    resizeBorder:setMaximum(newHeight)
    miniBorder:setMaximum(newHeight)
    if newHeight < curHeight or newHeight-height == curHeight then
        self:setHeight(newHeight)
    end
end

function UIMiniWindowModified:isResizeable()
    local resizeBorder = self:getChildById('bottomResizeBorder')
    return resizeBorder:isExplicitlyVisible() and resizeBorder:isEnabled()
end
