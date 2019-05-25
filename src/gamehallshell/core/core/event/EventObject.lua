

local EventObject = class("EventObject")

function EventObject:ctor()
    -- cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()

    cc.bind(self,"event")
end

return EventObject