local LuaJavaBridge = class("LuaJavaBridge")

LuaJavaBridge.ORIENTATION = {}
LuaJavaBridge.ORIENTATION.ORIENTATION_UNKNOWN = 0
LuaJavaBridge.ORIENTATION.ORIENTATION_LANDSCAPE = 1
LuaJavaBridge.ORIENTATION.ORIENTATION_PORTRAIT = 2
LuaJavaBridge.ORIENTATION.ORIENTATION_SENSOR_LANDSCAPE = 3
LuaJavaBridge.ORIENTATION.ORIENTATION_SENSOR_PORTRAIT = 4

function LuaJavaBridge:ctor()
end

function LuaJavaBridge:call_(javaClassName, javaMethodName, javaParams, javaMethodSig)
    if device.platform == "android" then
        local ok, ret = luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
        if not ok then
            if ret == -1 then
                print("call %s failed, -1 不支持的参数类型或返回值类型", javaMethodName)
            elseif ret == -2 then
                print("call %s failed, -2 无效的签名", javaMethodName)
            elseif ret == -3 then
                print("call %s failed, -3 没有找到指定的方法", javaMethodName)
            elseif ret == -4 then
                print("call %s failed, -4 Java 方法执行时抛出了异常", javaMethodName)
            elseif ret == -5 then
                print("call %s failed, -5 Java 虚拟机出错", javaMethodName)
            elseif ret == -6 then
                print("call %s failed, -6 Java 虚拟机出错", javaMethodName)
            end
        end
        return ok, ret
    else
        print("call %s failed, not in android platform", javaMethodName)
        return false, nil
    end
end

--[[
    获取当前的屏幕方向，注意设置屏幕方向是异步的，获取屏幕方向是同步的
    使用的时候需要注意可能由于多线程导致的问题（虽然概率很低）
    另外，安卓原生只能返回：
    LuaJavaBridge.ORIENTATION.ORIENTATION_UNKNOWN = 0 -- 对应安卓端的UnDefine
    LuaJavaBridge.ORIENTATION.ORIENTATION_LANDSCAPE = 1
    LuaJavaBridge.ORIENTATION.ORIENTATION_PORTRAIT = 2
]]
function LuaJavaBridge:getCurrentScreenOrientation()
    local ok, ret = self:call_("org/ode/cocoslib/core/functions/OrientationFunction",
        "getCurrentScreenOrientation", {}, "()I")
    if ok then
        return ret
    end
    return LuaJavaBridge.ORIENTATION.ORIENTATION_UNKNOWN
end

function LuaJavaBridge:changeScreenOrientation(toOrientation, callback)
    local ok, ret = self:call_("org/ode/cocoslib/core/functions/OrientationFunction",
        "changeScreenOrientation", {toOrientation, callback}, "(II)V")
end






local LuaOCBridge = class("LuaOCBridge")

function LuaOCBridge:ctor()
end

-- 1为横屏
-- 2为竖屏
function LuaOCBridge:getCurrentScreenOrientation()
    print("LuaOCBridge:getCurrentScreenOrientation()")
    local ok, orientation = luaoc.callStaticMethod("LuaOCBridge", "getCurrentScreenOrientation", nil)
    if ok then
        print("LuaOCBridge:getCurrentScreenOrientation => ", orientation)
        return orientation
    end
end

-- 1为横屏
-- 2为竖屏
function LuaOCBridge:changeScreenOrientation(toOrientation)
    print("LuaOCBridge:changeScreenOrientation(", toOrientation, ")")
    local ok, result = luaoc.callStaticMethod("LuaOCBridge", "changeScreenOrientation", {orientation = toOrientation})
    if ok then
        local jsonTab = json.decode(result)
        --[[
        jsonTab.result 是否成功
        jsonTab.orientation 要改变的屏幕方向
        jsonTab.last_orientation 改变前的屏幕方向
        ]]
        dump(jsonTab, "LuaOCBridge:changeScreenOrientation => ")
        return jsonTab
    end
end













-- 从game.screenOrientationManager中拷来修改的，因为原代码中用到了game.Native
local ShellScreenOrientationManager = class("ShellScreenOrientationManager")

--屏幕方向
ShellScreenOrientationManager.SCREEN_ORIENTATION = {
    LANDSCAPE = 1; --横屏
    PORTRAIT = 2;  --竖屏
}

ShellScreenOrientationManager.s_instance = nil

ShellScreenOrientationManager.getInstance = function()
    if not ShellScreenOrientationManager.s_instance then
        ShellScreenOrientationManager.s_instance = ShellScreenOrientationManager.new()
    end
    return ShellScreenOrientationManager.s_instance
end

-- 安卓是异步的，iOS是同步的，win32是模拟的
-- 安卓使用的时候要注意避免出现连续多次触发，或者是在触发转屏时马上触发获取屏幕方向
function ShellScreenOrientationManager:ctor()
	self.mCurScreenOrientation = ShellScreenOrientationManager.SCREEN_ORIENTATION.LANDSCAPE
	self.mLuaJavaBridge = LuaJavaBridge.new()
	self.mLuaOCBridge = LuaOCBridge.new()
end

function ShellScreenOrientationManager:getCurScreenOrientation()
	if device.platform == "windows" or device.platform == "mac" then
		-- win32的话就用默认构造时配置的方向
	elseif device.platform == "android" then
        self.mCurScreenOrientation = self.mLuaJavaBridge:getCurrentScreenOrientation()
	elseif device.platform == "ios" then
        self.mCurScreenOrientation = self.mLuaOCBridge:getCurrentScreenOrientation()
	end
	print("ShellScreenOrientationManager:getCurScreenOrientation() => ", self.mCurScreenOrientation)
	return self.mCurScreenOrientation
end


--设置分辨率
--autoscele:
--FIXED_WIDTH_HEIGHT:默认CONFIG_SCREEN_AUTOSCALE = FIXED_WIDTH
-- if framesize.width/framesize.height >= CONFIG_SCREEN_WIDTH / CONFIG_SCREEN_HEIGHT then
--     CONFIG_SCREEN_AUTOSCALE = "FIXED_HEIGHT"
--     return {autoscale = CONFIG_SCREEN_AUTOSCALE}
-- else
--     CONFIG_SCREEN_AUTOSCALE = "FIXED_WIDTH"
--     return {autoscale = CONFIG_SCREEN_AUTOSCALE}
-- end

--FIXED_HEIGHT_WIDTH 默认CONFIG_SCREEN_AUTOSCALE = FIXED_HEIGHT
-- if framesize.width/framesize.height >= CONFIG_SCREEN_WIDTH / CONFIG_SCREEN_HEIGHT then
--     CONFIG_SCREEN_AUTOSCALE = "FIXED_WIDTH"
--     return {autoscale = CONFIG_SCREEN_AUTOSCALE}
-- else
--     CONFIG_SCREEN_AUTOSCALE = "FIXED_HEIGHT"
--     return {autoscale = CONFIG_SCREEN_AUTOSCALE}
-- end

function ShellScreenOrientationManager:__setAutoscaleOrResolution(width, height,autoscale)

    -- print("__setAutoscaleOrResolution",width,height) --暂时屏蔽
    local autoscaleTb = string.split(autoscale,"_")
    local autoscale_1 = autoscale
    local autoscale_2 = autoscale
    if #autoscaleTb >= 3 then
        autoscale_1 = string.format("%s_%s",autoscaleTb[1],autoscaleTb[2])
        autoscale_2 = string.format("%s_%s",autoscaleTb[1],autoscaleTb[3])
    end
    CONFIG_SCREEN_AUTOSCALE = autoscale_1
    local newDesign = {
            width = width,
            height = height,
            autoscale = CONFIG_SCREEN_AUTOSCALE,
            callback = function(framesize)
                if framesize.width/framesize.height >= CONFIG_SCREEN_WIDTH / CONFIG_SCREEN_HEIGHT then
                    CONFIG_SCREEN_AUTOSCALE = autoscale_2
                    return {autoscale = CONFIG_SCREEN_AUTOSCALE}
                else
                    CONFIG_SCREEN_AUTOSCALE = autoscale_1
                    return {autoscale = CONFIG_SCREEN_AUTOSCALE}
                end
            end,
        }

    display.setAudoScaleWithCurrentFrameSize(newDesign)
end


-- designSize = {width = xxx, height = xxx}
function ShellScreenOrientationManager:changeScreenOrientation(orientation, designSize,autoscale, callback)

    if orientation ~= ShellScreenOrientationManager.SCREEN_ORIENTATION.LANDSCAPE then
		orientation = ShellScreenOrientationManager.SCREEN_ORIENTATION.PORTRAIT
	elseif orientation ~= ShellScreenOrientationManager.SCREEN_ORIENTATION.PORTRAIT then
		orientation = ShellScreenOrientationManager.SCREEN_ORIENTATION.LANDSCAPE
	end
	
	local innerCallback = function(resultTab)
		if designSize and autoscale then
			self:__setAutoscaleOrResolution(designSize.width,designSize.height,autoscale)
		end
		
		if type(callback) == "function" then
			callback(resultTab)
		end
	end

	local director = cc.Director:getInstance()
    local glView = director:getOpenGLView()
    
    local currentOrientation = self:getCurScreenOrientation()

    if currentOrientation == orientation then
		-- 如果要转的方向与当前方向相同，则不转，直接回调
		local resultTab = {}
		resultTab.result = true
		resultTab.orientation = orientation
		resultTab.last_orientation = self.mCurScreenOrientation
		innerCallback(resultTab)

	elseif device.platform == "windows" or device.platform == "mac" then
		-- win32下模拟一个类似的接口
		local resultTab = {}
		resultTab.result = true
		resultTab.orientation = orientation
		resultTab.last_orientation = self.mCurScreenOrientation
		local frameSize = glView:getFrameSize()
		glView:setFrameSize(frameSize.height, frameSize.width)

		self.mCurScreenOrientation = orientation
		innerCallback(resultTab)
    elseif device.platform == "android" then

    	self.mLuaJavaBridge:changeScreenOrientation(orientation, function(jsonStr)
			print("changeScreenOrientation callback jsonStr = ", jsonStr)
			local frameSize = glView:getFrameSize()
			glView:setFrameSize(frameSize.height, frameSize.width)

			local resultTab = json.decode(jsonStr)
			-- android 就当全是成功了
			resultTab.result = true

			self.mCurScreenOrientation = resultTab.orientation
			innerCallback(resultTab)
		end)
    elseif device.platform == "ios" then

    	local resultTab = self.mLuaOCBridge:changeScreenOrientation(orientation)
    	if resultTab then
    		local frameSize = glView:getFrameSize()
			glView:setFrameSize(frameSize.height, frameSize.width)
    		self.mCurScreenOrientation = resultTab.orientation
    		innerCallback(resultTab)
    	end
    end
end

return ShellScreenOrientationManager