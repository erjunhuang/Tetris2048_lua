local Touch = class("Touch")

local EXPORTED_METHODS = {
    "addTouchListener",
    "removeTouchListener",
    "setTouchEnabled",
    "setSwallowTouches",
    "setTouchInNode"
}

function Touch:init_()
    self.target_ = nil
    self.listener_ = nil
    self.inNode_ = true
    self.swallow_ = true 
    self.touchEnabled_ = false
end


function Touch:bind(target)
    self:init_()
    cc.setmethods(target, self, EXPORTED_METHODS)
    self.target_ = target
end

function Touch:unbind(target)
    cc.unsetmethods(target, EXPORTED_METHODS)
    self:init_()
end


function Touch:addTouchListener(callback)
	self.callback_ = callback
    return self.target_
end


function Touch:removeTouchListener(doClean)
	self.callback_ = nil
	if doClean then
		self:setTouchEnabled(false)
	end
    return self.target_
end


function Touch:setClipRect(rect)
    self.clipRect_ = rect
end

function Touch:setTouchInNode(inNode)
    self.inNode_ = inNode
    return self.target_
end

function Touch:setSwallowTouches(swallow)
    self.swallow_ = swallow
    if self.listener_ then
        self.listener_:setSwallowTouches(swallow)
    end
    return self.target_
end

function Touch:setTouchEnabled(enable)
    if self.touchEnabled_ == enable then
        return self.target_
    end

    self.touchEnabled_ = enable
    if self.touchEnabled_ then
        self.listener_ = cc.EventListenerTouchOneByOne:create()
        self.listener_:setSwallowTouches(self.swallow_)
        self.listener_:registerScriptHandler(handler(self,self.onTouch),cc.Handler.EVENT_TOUCH_BEGAN )
        self.listener_:registerScriptHandler(handler(self,self.onTouch),cc.Handler.EVENT_TOUCH_MOVED )
        self.listener_:registerScriptHandler(handler(self,self.onTouch),cc.Handler.EVENT_TOUCH_ENDED )
        self.listener_:registerScriptHandler(handler(self,self.onTouch),cc.Handler.EVENT_TOUCH_CANCELLED )
        local eventDispatcher = self.target_:getEventDispatcher()
        eventDispatcher:addEventListenerWithSceneGraphPriority(self.listener_, self.target_)

    else
        local eventDispatcher = self.target_:getEventDispatcher()
        eventDispatcher:removeEventListener(self.listener_)
        self.listener_ = nil
    end

    return self.target_

end


function Touch:onTouch(touch,event)
    local location = touch:getLocation()
    local eventCode = event:getEventCode()
    local isTouchInNode = self:isTouchInNode(location,self.target_)
    if eventCode == cc.EventCode.BEGAN then
        local isVisible = self.target_:isVisible()
        local isAncestorsVisible = self:isAncestorsVisible(self.target_)
        local isClippingParentContainsPoint = self:isClippingParentContainsPoint(self.target_)
        if not isVisible or not isAncestorsVisible or not isClippingParentContainsPoint then
            return false
        end
        if self.inNode_ and not isTouchInNode then
            return false
        end
        self.isTouching_ = true
        self:notifyTarget(touch,event,isTouchInNode)
        return true
    elseif not self.isTouching_ then
        return false
    elseif eventCode == cc.EventCode.MOVED then

        self:notifyTarget(touch,event,isTouchInNode)
    elseif eventCode == cc.EventCode.ENDED  or eventCode == cc.EventCode.CANCELLED then
        self.isTouching_ = false
        self:notifyTarget(touch,event,isTouchInNode)
    end
end



function Touch:isTouchInNode(pt, node)
    local s = node:getContentSize()
    local rect
    if s.width == 0 or s.height == 0 then
        rect = cc.utils_:getCascadeBoundingBox(node)
    else
        pt = node:convertToNodeSpace(pt)
        rect = cc.rect(0, 0, s.width, s.height)
    end

    if cc.rectContainsPoint(rect, pt) then
        return true
    end
    return false
end


function Touch:isAncestorsVisible(node)
    if not node then
        return true
    end

    local parent = node:getParent()
    if parent and not parent:isVisible() then
        return false
    end

    return self:isAncestorsVisible(parent)
end


function Touch:isClippingParentContainsPoint(pt,node)
    if not node then
        return true
    end

    if not self.clipRect_ then
        return true
    end

    if cc.rectContainsPoint(self.clipRect_, pt) then
        return true
    end

    return false

end


function Touch:notifyTarget(touch,event, ...)
    if self.callback_ then
        self.callback_(touch,event, ...)
    end
end

return Touch



