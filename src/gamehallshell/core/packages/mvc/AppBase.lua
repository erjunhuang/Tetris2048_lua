
local AppBase = class("AppBase")

AppBase.APP_ENTER_BACKGROUND_EVENT = "APP_ENTER_BACKGROUND_EVENT"
AppBase.APP_ENTER_FOREGROUND_EVENT = "APP_ENTER_FOREGROUND_EVENT"

AppBase.APP_RESIGN_ACTIVE_EVENT = "APP_RESIGN_ACTIVE_EVENT"
AppBase.APP_BECOME_ACTIVE_EVENT = "APP_BECOME_ACTIVE_EVENT"


function AppBase:ctor(configs)
    cc.bind(self, "event")
    self.__eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    self.__customListenerBg = cc.EventListenerCustom:create(AppBase.APP_ENTER_BACKGROUND_EVENT,
                                handler(self, self.onEnterBackground))
    self.__eventDispatcher:addEventListenerWithFixedPriority(self.__customListenerBg, 1)
    self.__customListenerFg = cc.EventListenerCustom:create(AppBase.APP_ENTER_FOREGROUND_EVENT,
                                handler(self, self.onEnterForeground))
    self.__eventDispatcher:addEventListenerWithFixedPriority(self.__customListenerFg, 1)
    cc.exports.app = self


    self.__customListenerResignActive = cc.EventListenerCustom:create(AppBase.APP_RESIGN_ACTIVE_EVENT,
                                handler(self, self.onResignActive))
    self.__eventDispatcher:addEventListenerWithFixedPriority(self.__customListenerResignActive, 1)
    self.__customListenerBecomeActive = cc.EventListenerCustom:create(AppBase.APP_BECOME_ACTIVE_EVENT,
                                handler(self, self.onBecomeActive))
    self.__eventDispatcher:addEventListenerWithFixedPriority(self.__customListenerBecomeActive, 1)

    

    self.configs_ = {
        viewsRoot  = "app.views",
        modelsRoot = "app.models",
        defaultSceneName = "MainScene",
    }

    for k, v in pairs(configs or {}) do
        self.configs_[k] = v
    end

    if type(self.configs_.viewsRoot) ~= "table" then
        self.configs_.viewsRoot = {self.configs_.viewsRoot}
    end
    if type(self.configs_.modelsRoot) ~= "table" then
        self.configs_.modelsRoot = {self.configs_.modelsRoot}
    end

    if DEBUG > 1 then
        -- dump(self.configs_, "AppBase configs")
    end

    if CC_SHOW_FPS then
        cc.Director:getInstance():setDisplayStats(true)
    end

    -- event
    self:onCreate()
end


function AppBase:onEnterBackground()
    self:dispatchEvent({name = AppBase.APP_ENTER_BACKGROUND_EVENT})
end

function AppBase:onEnterForeground()
    self:dispatchEvent({name = AppBase.APP_ENTER_FOREGROUND_EVENT})
end


function AppBase:onResignActive()
    self:dispatchEvent({name = AppBase.APP_RESIGN_ACTIVE_EVENT})
end

function AppBase:onBecomeActive()
    self:dispatchEvent({name = AppBase.APP_BECOME_ACTIVE_EVENT})
end



function AppBase:run(initSceneName)
    initSceneName = initSceneName or self.configs_.defaultSceneName
    self:enterScene(initSceneName)
end

function AppBase:enterScene(sceneName, transition, time, more)
    local view = self:createView(sceneName)
    view:showWithScene(transition, time, more)
    return view
end

function AppBase:createView(name)
    for _, root in ipairs(self.configs_.viewsRoot) do
        local packageName = string.format("%s.%s", root, name)
        local status, view = xpcall(function()
                return require(packageName)
            end, function(msg)
            if not string.find(msg, string.format("'%s' not found:", packageName)) then
                print("load view error: ", msg)
            end
        end)
        local t = type(view)
        if status and (t == "table" or t == "userdata") then
            return view:create(self, name)
        end
    end
    error(string.format("AppBase:createView() - not found view \"%s\" in search paths \"%s\"",
        name, table.concat(self.configs_.viewsRoot, ",")), 0)
end

function AppBase:onCreate()
end


function AppBase:exit()
    cc.Director:getInstance():endToLua()
    if device.platform == "windows" or device.platform == "mac" then
        os.exit()
    end
end


function AppBase:dispose( ... )
    self.__eventDispatcher:removeEventListener(self.__customListenerBg)
    self.__eventDispatcher:removeEventListener(self.__customListenerFg)
    self.__eventDispatcher:removeEventListener(self.__customListenerResignActive)
    self.__eventDispatcher:removeEventListener(self.__customListenerBecomeActive)
end

return AppBase
