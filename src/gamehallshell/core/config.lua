IS_RELEASE = true

if IS_RELEASE then
    DEBUG = 0
    CF_DEBUG = 0
    CC_SHOW_FPS = false
else
    DEBUG =2
    CF_DEBUG = 5
    CC_SHOW_FPS = false
end


--是否开启定位功能
-- IS_OPEN_LOCATION = true

local tprint = _G["print"]
if CF_DEBUG == 0 then
    _G["print"] = function( ... )end
else
    _G["print"] = tprint
end

IS_SANDBOX = false

-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
-- DEBUG = 2

-- use framework, will disable all deprecated API, false - use legacy API
CC_USE_FRAMEWORK = true

-- -- show FPS on screen
CC_SHOW_FPS = not IS_RELEASE

-- disable create unexpected global variable
CC_DISABLE_GLOBAL = true


-- design resolution
CONFIG_SCREEN_WIDTH  = 1280
CONFIG_SCREEN_HEIGHT = 720
CONFIG_SCREEN_AUTOSCALE = "SHOW_ALL"

-- for module display
CC_DESIGN_RESOLUTION = {
    width = CONFIG_SCREEN_WIDTH,
    height = CONFIG_SCREEN_HEIGHT,
    autoscale = CONFIG_SCREEN_AUTOSCALE,
    callback = function(framesize)
        if framesize.width/framesize.height >= CONFIG_SCREEN_WIDTH / CONFIG_SCREEN_HEIGHT then
            CONFIG_SCREEN_AUTOSCALE = "SHOW_ALL"
            return {autoscale = CONFIG_SCREEN_AUTOSCALE}
        else
            CONFIG_SCREEN_AUTOSCALE = "SHOW_ALL"
            return {autoscale = CONFIG_SCREEN_AUTOSCALE}
        end

    end
}

