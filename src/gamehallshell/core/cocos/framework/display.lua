--[[

Copyright (c) 2011-2014 chukong-inc.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

local display = {}

local director = cc.Director:getInstance()
local view = director:getOpenGLView()

if not view then
    local width = 960
    local height = 640
    if CC_DESIGN_RESOLUTION then
        if CC_DESIGN_RESOLUTION.width then
            width = CC_DESIGN_RESOLUTION.width
        end
        if CC_DESIGN_RESOLUTION.height then
            height = CC_DESIGN_RESOLUTION.height
        end
    end
    view = cc.GLViewImpl:createWithRect("Cocos2d-Lua", cc.rect(0, 0, width, height))
    director:setOpenGLView(view)
end

local framesize = view:getFrameSize()
local textureCache = director:getTextureCache()
local spriteFrameCache = cc.SpriteFrameCache:getInstance()
local animationCache = cc.AnimationCache:getInstance()

-- auto scale
local function checkResolution(r)
    r.width = checknumber(r.width)
    r.height = checknumber(r.height)
    r.autoscale = string.upper(r.autoscale)
    assert(r.width > 0 and r.height > 0,
        string.format("display - invalid design resolution size %d, %d", r.width, r.height))
end

local function setDesignResolution(r, framesize)
    if r.autoscale == "FILL_ALL" then
        view:setDesignResolutionSize(framesize.width, framesize.height, cc.ResolutionPolicy.FILL_ALL)
    else
        local scaleX, scaleY = framesize.width / r.width, framesize.height / r.height
        local width, height = framesize.width, framesize.height
        if r.autoscale == "FIXED_WIDTH" then
            width = framesize.width / scaleX
            height = framesize.height / scaleX
            view:setDesignResolutionSize(width, height, cc.ResolutionPolicy.NO_BORDER)
        elseif r.autoscale == "FIXED_HEIGHT" then
            width = framesize.width / scaleY
            height = framesize.height / scaleY
            view:setDesignResolutionSize(width, height, cc.ResolutionPolicy.NO_BORDER)
        elseif r.autoscale == "EXACT_FIT" then
            view:setDesignResolutionSize(r.width, r.height, cc.ResolutionPolicy.EXACT_FIT)
        elseif r.autoscale == "NO_BORDER" then
            view:setDesignResolutionSize(r.width, r.height, cc.ResolutionPolicy.NO_BORDER)
        elseif r.autoscale == "SHOW_ALL" then
            view:setDesignResolutionSize(r.width, r.height, cc.ResolutionPolicy.SHOW_ALL)
        else
            printError(string.format("display - invalid r.autoscale \"%s\"", r.autoscale))
        end
    end
end

local function setConstants()
    local sizeInPixels = view:getFrameSize()
    display.sizeInPixels = {width = sizeInPixels.width, height = sizeInPixels.height}

    local viewsize = director:getWinSize()
    display.contentScaleFactor = director:getContentScaleFactor()
    display.size               = {width = viewsize.width, height = viewsize.height}
    display.width              = display.size.width
    display.height             = display.size.height
    display.cx                 = display.width / 2
    display.cy                 = display.height / 2
    display.c_left             = -display.width / 2
    display.c_right            = display.width / 2
    display.c_top              = display.height / 2
    display.c_bottom           = -display.height / 2
    display.left               = 0
    display.right              = display.width
    display.top                = display.height
    display.bottom             = 0
    display.center             = cc.p(display.cx, display.cy)
    display.left_top           = cc.p(display.left, display.top)
    display.left_bottom        = cc.p(display.left, display.bottom)
    display.left_center        = cc.p(display.left, display.cy)
    display.right_top          = cc.p(display.right, display.top)
    display.right_bottom       = cc.p(display.right, display.bottom)
    display.right_center       = cc.p(display.right, display.cy)
    display.top_center         = cc.p(display.cx, display.top)
    display.top_bottom         = cc.p(display.cx, display.bottom)


    --安全区域,正常手机同上，iphonex则为官方推荐安全区域
    print("getSafeAreaRect",type(director.getSafeAreaRect))
    local safeRect = type(director.getSafeAreaRect) == "function" and director:getSafeAreaRect() or cc.rect(0,0,display.width,display.height)
    
    -- local xscale = display.sizeInPixels.width/display.sizeInPixels.height

    -- if xscale and (xscale+0.1) >= 2 then
    --     safeRect = cc.rect(100,68,display.width-200,display.height-136)
    -- end

    --如果是android,为兼容所有游戏,临时强制safeRect为全屏
    display.safeRectReal = safeRect
    if device.platform == "android" then
        safeRect = cc.rect(0,0,display.width,display.height)
    end

    display.safeRect = safeRect
    display.ssize = {width = safeRect.width, height = safeRect.height}
    display.swidth = display.ssize.width
    display.sheight = display.ssize.height
    display.scx = display.cx
    display.scy = display.cy
    display.sc_left             = -display.swidth / 2
    display.sc_right            = display.swidth / 2
    display.sc_top              = display.sheight / 2
    display.sc_bottom           = -display.sheight / 2
    display.sleft               = safeRect.x
    display.sright              = safeRect.x + display.swidth
    display.stop                = safeRect.y + display.sheight
    display.sbottom             = safeRect.y
    display.scenter             = cc.p(display.scx, display.scy)
    display.sleft_top           = cc.p(display.sleft, display.stop)
    display.sleft_bottom        = cc.p(display.sleft, display.sbottom)
    display.sleft_center        = cc.p(display.sleft, display.scy)
    display.sright_top          = cc.p(display.sright, display.stop)
    display.sright_bottom       = cc.p(display.sright, display.sbottom)
    display.sright_center       = cc.p(display.sright, display.scy)
    display.stop_center         = cc.p(display.scx, display.stop)
    display.stop_bottom         = cc.p(display.scx, display.sbottom)


    printInfo(string.format("# display.sizeInPixels         = {width = %0.2f, height = %0.2f}", display.sizeInPixels.width, display.sizeInPixels.height))
    printInfo(string.format("# display.size                 = {width = %0.2f, height = %0.2f}", display.size.width, display.size.height))
    printInfo(string.format("# display.contentScaleFactor   = %0.2f", display.contentScaleFactor))
    printInfo(string.format("# display.width                = %0.2f", display.width))
    printInfo(string.format("# display.height               = %0.2f", display.height))
    printInfo(string.format("# display.cx                   = %0.2f", display.cx))
    printInfo(string.format("# display.cy                   = %0.2f", display.cy))
    printInfo(string.format("# display.left                 = %0.2f", display.left))
    printInfo(string.format("# display.right                = %0.2f", display.right))
    printInfo(string.format("# display.top                  = %0.2f", display.top))
    printInfo(string.format("# display.bottom               = %0.2f", display.bottom))
    printInfo(string.format("# display.c_left               = %0.2f", display.c_left))
    printInfo(string.format("# display.c_right              = %0.2f", display.c_right))
    printInfo(string.format("# display.c_top                = %0.2f", display.c_top))
    printInfo(string.format("# display.c_bottom             = %0.2f", display.c_bottom))
    printInfo(string.format("# display.center               = {x = %0.2f, y = %0.2f}", display.center.x, display.center.y))
    printInfo(string.format("# display.left_top             = {x = %0.2f, y = %0.2f}", display.left_top.x, display.left_top.y))
    printInfo(string.format("# display.left_bottom          = {x = %0.2f, y = %0.2f}", display.left_bottom.x, display.left_bottom.y))
    printInfo(string.format("# display.left_center          = {x = %0.2f, y = %0.2f}", display.left_center.x, display.left_center.y))
    printInfo(string.format("# display.right_top            = {x = %0.2f, y = %0.2f}", display.right_top.x, display.right_top.y))
    printInfo(string.format("# display.right_bottom         = {x = %0.2f, y = %0.2f}", display.right_bottom.x, display.right_bottom.y))
    printInfo(string.format("# display.right_center         = {x = %0.2f, y = %0.2f}", display.right_center.x, display.right_center.y))
    printInfo(string.format("# display.top_center           = {x = %0.2f, y = %0.2f}", display.top_center.x, display.top_center.y))
    printInfo(string.format("# display.top_bottom           = {x = %0.2f, y = %0.2f}", display.top_bottom.x, display.top_bottom.y))

    printInfo("# safeArea ==")
    printInfo(string.format("# display.swidth                = %0.2f", display.swidth))
    printInfo(string.format("# display.sheight               = %0.2f", display.sheight))
    printInfo(string.format("# display.scx                   = %0.2f", display.scx))
    printInfo(string.format("# display.scy                   = %0.2f", display.scy))
    printInfo(string.format("# display.sleft                 = %0.2f", display.sleft))
    printInfo(string.format("# display.sright                = %0.2f", display.sright))
    printInfo(string.format("# display.stop                  = %0.2f", display.stop))
    printInfo(string.format("# display.sbottom               = %0.2f", display.sbottom))
    printInfo(string.format("# display.sc_left               = %0.2f", display.sc_left))
    printInfo(string.format("# display.sc_right              = %0.2f", display.sc_right))
    printInfo(string.format("# display.sc_top                = %0.2f", display.sc_top))
    printInfo(string.format("# display.c_bottom             = %0.2f", display.sc_bottom))
    printInfo(string.format("# display.scenter               = {x = %0.2f, y = %0.2f}", display.scenter.x, display.scenter.y))
    printInfo(string.format("# display.sleft_top             = {x = %0.2f, y = %0.2f}", display.sleft_top.x, display.sleft_top.y))
    printInfo(string.format("# display.sleft_bottom          = {x = %0.2f, y = %0.2f}", display.sleft_bottom.x, display.sleft_bottom.y))
    printInfo(string.format("# display.sleft_center          = {x = %0.2f, y = %0.2f}", display.sleft_center.x, display.sleft_center.y))
    printInfo(string.format("# display.sright_top            = {x = %0.2f, y = %0.2f}", display.sright_top.x, display.sright_top.y))
    printInfo(string.format("# display.sright_bottom         = {x = %0.2f, y = %0.2f}", display.sright_bottom.x, display.sright_bottom.y))
    printInfo(string.format("# display.sright_center         = {x = %0.2f, y = %0.2f}", display.sright_center.x, display.sright_center.y))
    printInfo(string.format("# display.stop_center           = {x = %0.2f, y = %0.2f}", display.stop_center.x, display.stop_center.y))
    printInfo(string.format("# display.stop_bottom           = {x = %0.2f, y = %0.2f}", display.stop_bottom.x, display.stop_bottom.y))
    printInfo("#")
end

function display.setAutoScale(configs)
    if type(configs) ~= "table" then return end

    checkResolution(configs)
    if type(configs.callback) == "function" then
        local c = configs.callback(framesize)
        for k, v in pairs(c or {}) do
            configs[k] = v
        end
        checkResolution(configs)
    end

    setDesignResolution(configs, framesize)

    printInfo(string.format("# design resolution size       = {width = %0.2f, height = %0.2f}", configs.width, configs.height))
    printInfo(string.format("# design resolution autoscale  = %s", configs.autoscale))
    setConstants()
end

--[[
    因为上面的display固定使用的是require时获取的framesize，
    不满足游戏中切换屏幕方向/尺寸的需求
    所以重写一个
]]
function display.setAudoScaleWithCurrentFrameSize(configs)
    if type(configs) ~= "table" then return end

    local framesize = view:getFrameSize()
    checkResolution(configs)
    if type(configs.callback) == "function" then
        local c = configs.callback(framesize)
        for k, v in pairs(c or {}) do
            configs[k] = v
        end
        checkResolution(configs)
    end

    setDesignResolution(configs, framesize)

    printInfo(string.format("# design resolution size       = {width = %0.2f, height = %0.2f}", configs.width, configs.height))
    printInfo(string.format("# design resolution autoscale  = %s", configs.autoscale))
    setConstants()
end

if type(CC_DESIGN_RESOLUTION) == "table" then
    display.setAutoScale(CC_DESIGN_RESOLUTION)
end

display.COLOR_WHITE = cc.c3b(255, 255, 255)
display.COLOR_BLACK = cc.c3b(0, 0, 0)
display.COLOR_RED   = cc.c3b(255, 0, 0)
display.COLOR_GREEN = cc.c3b(0, 255, 0)
display.COLOR_BLUE  = cc.c3b(0, 0, 255)

display.AUTO_SIZE      = 0
display.FIXED_SIZE     = 1
display.LEFT_TO_RIGHT  = 0
display.RIGHT_TO_LEFT  = 1
display.TOP_TO_BOTTOM  = 2
display.BOTTOM_TO_TOP  = 3

display.CENTER        = cc.p(0.5, 0.5)
display.LEFT_TOP      = cc.p(0, 1)
display.LEFT_BOTTOM   = cc.p(0, 0)
display.LEFT_CENTER   = cc.p(0, 0.5)
display.RIGHT_TOP     = cc.p(1, 1)
display.RIGHT_BOTTOM  = cc.p(1, 0)
display.RIGHT_CENTER  = cc.p(1, 0.5)
display.CENTER_TOP    = cc.p(0.5, 1)
display.CENTER_BOTTOM = cc.p(0.5, 0)

display.SCENE_TRANSITIONS = {
    CROSSFADE       = {cc.TransitionCrossFade},
    FADE            = {cc.TransitionFade, cc.c3b(0, 0, 0)},
    FADEBL          = {cc.TransitionFadeBL},
    FADEDOWN        = {cc.TransitionFadeDown},
    FADETR          = {cc.TransitionFadeTR},
    FADEUP          = {cc.TransitionFadeUp},
    FLIPANGULAR     = {cc.TransitionFlipAngular, cc.TRANSITION_ORIENTATION_LEFT_OVER},
    FLIPX           = {cc.TransitionFlipX, cc.TRANSITION_ORIENTATION_LEFT_OVER},
    FLIPY           = {cc.TransitionFlipY, cc.TRANSITION_ORIENTATION_UP_OVER},
    JUMPZOOM        = {cc.TransitionJumpZoom},
    MOVEINB         = {cc.TransitionMoveInB},
    MOVEINL         = {cc.TransitionMoveInL},
    MOVEINR         = {cc.TransitionMoveInR},
    MOVEINT         = {cc.TransitionMoveInT},
    PAGETURN        = {cc.TransitionPageTurn, false},
    ROTOZOOM        = {cc.TransitionRotoZoom},
    SHRINKGROW      = {cc.TransitionShrinkGrow},
    SLIDEINB        = {cc.TransitionSlideInB},
    SLIDEINL        = {cc.TransitionSlideInL},
    SLIDEINR        = {cc.TransitionSlideInR},
    SLIDEINT        = {cc.TransitionSlideInT},
    SPLITCOLS       = {cc.TransitionSplitCols},
    SPLITROWS       = {cc.TransitionSplitRows},
    TURNOFFTILES    = {cc.TransitionTurnOffTiles},
    ZOOMFLIPANGULAR = {cc.TransitionZoomFlipAngular},
    ZOOMFLIPX       = {cc.TransitionZoomFlipX, cc.TRANSITION_ORIENTATION_LEFT_OVER},
    ZOOMFLIPY       = {cc.TransitionZoomFlipY, cc.TRANSITION_ORIENTATION_UP_OVER},
}

display.TEXTURES_PIXEL_FORMAT = {}

display.DEFAULT_TTF_FONT        = "Arial"
display.DEFAULT_TTF_FONT_SIZE   = 32


local PARAMS_EMPTY = {}
local RECT_ZERO = cc.rect(0, 0, 0, 0)

local sceneIndex = 0
function display.newScene(name, params)
    params = params or PARAMS_EMPTY
    sceneIndex = sceneIndex + 1
    local scene
    if not params.physics then
        scene = cc.Scene:create()
    else
        scene = cc.Scene:createWithPhysics()
    end
    scene.name_ = string.format("%s:%d", name or "<unknown-scene>", sceneIndex)

    if params.transition then
        scene = display.wrapSceneWithTransition(scene, params.transition, params.time, params.more)
    end

    return scene
end

function display.wrapScene(scene, transition, time, more)
    local key = string.upper(tostring(transition))

    if key == "RANDOM" then
        local keys = table.keys(display.SCENE_TRANSITIONS)
        key = keys[math.random(1, #keys)]
    end

    if display.SCENE_TRANSITIONS[key] then
        local t = display.SCENE_TRANSITIONS[key]
        local cls = t[1]
        time = time or 0.2
        more = more or t[2]
        if more ~= nil then
            scene = cls:create(time, scene, more)
        else
            scene = cls:create(time, scene)
        end
    else
        error(string.format("display.wrapScene() - invalid transition %s", tostring(transition)))
    end
    return scene
end

function display.runScene(newScene,transition, time, more)
    if director:getRunningScene() then
        if transition then
            newScene = display.wrapScene(newScene, transition, time, more)
        end
        director:replaceScene(newScene)
    else
        director:runWithScene(newScene)
    end
end

function display.pushScene(newScene,transition, time, more)
    if transition then
        newScene = display.wrapScene(newScene, transition, time, more)
    end
    director:pushScene(newScene)
end

function display.popScene(level)
    print("display.popScene",level)
    if type(level) == "number" then

        director:popToSceneStackLevel(level)
    else
        director:popScene()
    end
     
end

function display.getRunningScene()
    return director:getRunningScene()
end

function display.newNode()
    return cc.Node:create()
end

function display.newLayer(...)
    local params = {...}
    local c = #params
    local layer
    if c == 0 then
        -- /** creates a fullscreen black layer */
        -- static Layer *create();
        layer = cc.Layer:create()
    elseif c == 1 then
        -- /** creates a Layer with color. Width and height are the window size. */
        -- static LayerColor * create(const Color4B& color);
        layer = cc.LayerColor:create(cc.convertColor(params[1], "4b"))
    elseif c == 2 then
        -- /** creates a Layer with color, width and height in Points */
        -- static LayerColor * create(const Color4B& color, const Size& size);
        --
        -- /** Creates a full-screen Layer with a gradient between start and end. */
        -- static LayerGradient* create(const Color4B& start, const Color4B& end);
        local color1 = cc.convertColor(params[1], "4b")
        local p2 = params[2]
        assert(type(p2) == "table" and (p2.width or p2.r), "display.newLayer() - invalid paramerter 2")
        if p2.r then
            layer = cc.LayerGradient:create(color1, cc.convertColor(p2, "4b"))
        else
            layer = cc.LayerColor:create(color1, p2.width, p2.height)
        end
    elseif c == 3 then
        -- /** creates a Layer with color, width and height in Points */
        -- static LayerColor * create(const Color4B& color, GLfloat width, GLfloat height);
        --
        -- /** Creates a full-screen Layer with a gradient between start and end in the direction of v. */
        -- static LayerGradient* create(const Color4B& start, const Color4B& end, const Vec2& v);
        local color1 = cc.convertColor(params[1], "4b")
        local p2 = params[2]
        local p2type = type(p2)
        if p2type == "table" then
            layer = cc.LayerGradient:create(color1, cc.convertColor(p2, "4b"), params[3])
        else
            layer = cc.LayerColor:create(color1, p2, params[3])
        end
    end
    return layer
end

function display.newSprite(source, x, y, params)
    local spriteClass = cc.Sprite
    local scale9 = false

    if type(x) == "table" and not x.x then
        -- x is params
        params = x
        x = nil
        y = nil
    end

    local params = params or PARAMS_EMPTY
    if params.scale9 or params.capInsets then
        spriteClass = ccui.Scale9Sprite
        scale9 = true
        params.capInsets = params.capInsets or RECT_ZERO
        params.rect = params.rect or RECT_ZERO
    end

    local sprite
    while true do
        -- create sprite
        if not source then
            sprite = spriteClass:create()
            break
        end

        local sourceType = type(source)
        if sourceType == "string" then
            if string.byte(source) == 35 then -- first char is #
                -- create sprite from spriteFrame
                if not scale9 then
                    sprite = spriteClass:createWithSpriteFrameName(string.sub(source, 2))
                else
                    sprite = spriteClass:createWithSpriteFrameName(string.sub(source, 2), params.capInsets)
                end
                break
            end

            -- create sprite from image file
            if display.TEXTURES_PIXEL_FORMAT[source] then
                cc.Texture2D:setDefaultAlphaPixelFormat(display.TEXTURES_PIXEL_FORMAT[source])
            end
            if not scale9 then
                sprite = spriteClass:create(source)
            else
                sprite = spriteClass:create(source, params.rect, params.capInsets)
            end
            if display.TEXTURES_PIXEL_FORMAT[source] then
                cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_BGR_A8888)
            end
            break
        elseif sourceType ~= "userdata" then
            error(string.format("display.newSprite() - invalid source type \"%s\"", sourceType), 0)
        else
            sourceType = tolua.type(source)
            if sourceType == "cc.SpriteFrame" then
                if not scale9 then
                    sprite = spriteClass:createWithSpriteFrame(source)
                else
                    sprite = spriteClass:createWithSpriteFrame(source, params.capInsets)
                end
            elseif sourceType == "cc.Texture2D" then
                sprite = spriteClass:createWithTexture(source)
            else
                error(string.format("display.newSprite() - invalid source type \"%s\"", sourceType), 0)
            end
        end
        break
    end

    if sprite then
        if x and y then sprite:setPosition(x, y) end
        if params.size then sprite:setContentSize(params.size) end
    else
        error(string.format("display.newSprite() - create sprite failure, source \"%s\"", tostring(source)), 0)
    end

    return sprite
end


function display.newScale9Sprite(filename, x, y, size, capInsets)
    return display.newSprite(filename, x, y, {scale9 = true,size = size, capInsets = capInsets})
end


function display.newBatchNode(image, capacity)
    return cc.SpriteBatchNode:create(image, capacity or 100)
end



function display.newSpriteFrame(source, ...)
    local frame
    if type(source) == "string" then
        if string.byte(source) == 35 then -- first char is #
            source = string.sub(source, 2)
        end
        frame = spriteFrameCache:getSpriteFrame(source)
        if not frame then
            error(string.format("display.newSpriteFrame() - invalid frame name \"%s\"", tostring(source)), 0)
        end
    elseif tolua.type(source) == "cc.Texture2D" then
        frame = cc.SpriteFrame:createWithTexture(source, ...)
    else
        error("display.newSpriteFrame() - invalid parameters", 0)
    end
    return frame
end

function display.newFrames(pattern, begin, length, isReversed)
    local frames = {}
    local step = 1
    local last = begin + length - 1
    if isReversed then
        last, begin = begin, last
        step = -1
    end

    for index = begin, last, step do
        local frameName = string.format(pattern, index)
        local frame = spriteFrameCache:getSpriteFrame(frameName)
        if not frame then
            error(string.format("display.newFrames() - invalid frame name %s", tostring(frameName)), 0)
        end
        frames[#frames + 1] = frame
    end
    return frames
end

local function newAnimation(frames, time)
    local count = #frames
    assert(count > 0, "display.newAnimation() - invalid frames")
    time = time or 1.0 / count
    return cc.Animation:createWithSpriteFrames(frames, time),
           cc.Sprite:createWithSpriteFrame(frames[1])
end

function display.newAnimation(...)
    local params = {...}
    local c = #params
    if c == 2 then
        -- frames, time
        return newAnimation(params[1], params[2])
    elseif c == 4 then
        -- pattern, begin, length, time
        local frames = display.newFrames(params[1], params[2], params[3])
        return newAnimation(frames, params[4])
    elseif c == 5 then
        -- pattern, begin, length, isReversed, time
        local frames = display.newFrames(params[1], params[2], params[3], params[4])
        return newAnimation(frames, params[5])
    else
        error("display.newAnimation() - invalid parameters")
    end
end

function display.loadImage(imageFilename, callback)
    if not callback then
        return textureCache:addImage(imageFilename)
    else
        textureCache:addImageAsync(imageFilename, callback)
    end
end

local fileUtils = cc.FileUtils:getInstance()
function display.getImage(imageFilename)
    local fullpath = fileUtils:fullPathForFilename(imageFilename)
    return textureCache:getTextureForKey(fullpath)
end

function display.removeImage(imageFilename)
    textureCache:removeTextureForKey(imageFilename)
end

--缓存纹理集防止内存警告被释放
local _cacheSpriteFrames = {}

local function cacheSpriteFrames(plistFilename, image)
    if _cacheSpriteFrames[plistFilename] then
        return
    end
    local cache = {}
    local fullpath = fileUtils:fullPathForFilename(plistFilename)
    local frames = fileUtils:getValueMapFromFile(fullpath)["frames"]
    for name, _ in pairs(frames) do
        local spriteFrame = spriteFrameCache:getSpriteFrame(name)
        table.insert(cache, spriteFrame)
    end
    _cacheSpriteFrames[plistFilename] = cache
end

local function uncacheSpriteFrames(plistFilename, image)
    if _cacheSpriteFrames[plistFilename] then
        printInfo("uncacheSpriteFrames plist:%s", plistFilename)
        _cacheSpriteFrames[plistFilename] = nil
    end
end

function display.loadSpriteFrames(plistFilename, image, handler)
    -- if display.TEXTURES_PIXEL_FORMAT[imageFilename] then
    --     cc.Texture2D:setDefaultAlphaPixelFormat(display.TEXTURES_PIXEL_FORMAT[imageFilename])
    -- end
    -- if not callback then
    --     spriteFrameCache:addSpriteFrames(dataFilename, imageFilename)
    -- else
    --     spriteFrameCache:addSpriteFramesAsync(dataFilename, imageFilename, callback)
    -- end
    -- if display.TEXTURES_PIXEL_FORMAT[imageFilename] then
    --     cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_BGR_A8888)
    -- end

    local async = type(handler) == "function"
    local asyncHandler = nil
    if async then
        asyncHandler = function()
            local texture = textureCache:getTextureForKey(image)
            assert(texture, string.format("The texture %s, %s is unavailable.", plistFilename, image))
            spriteFrameCache:addSpriteFrames(plistFilename, texture)
            handler(plistFilename, image)
        end
    end

    if display.TEXTURES_PIXEL_FORMAT[image] then
        cc.Texture2D:setDefaultAlphaPixelFormat(display.TEXTURES_PIXEL_FORMAT[image])
        if async then
            textureCache:addImageAsync(image, asyncHandler)
        else
            spriteFrameCache:addSpriteFrames(plistFilename, image)
        end
        cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_BGR_A8888)
    else
        if async then
            textureCache:addImageAsync(image, asyncHandler)
        else
            spriteFrameCache:addSpriteFrames(plistFilename, image)
        end
    end


end




function display.removeSpriteFrames(dataFilename, imageFilename)
    spriteFrameCache:removeSpriteFramesFromFile(dataFilename)
    if imageFilename then
        display.removeImage(imageFilename)
    end
end

function display.removeSpriteFrame(imageFilename)
    spriteFrameCache:removeSpriteFrameByName(imageFilename)
end

function display.setTexturePixelFormat(imageFilename, format)
    display.TEXTURES_PIXEL_FORMAT[imageFilename] = format
end

function display.setAnimationCache(name, animation)
    animationCache:addAnimation(animation, name)
end

function display.getAnimationCache(name)
    return animationCache:getAnimation(name)
end

function display.removeAnimationCache(name)
    animationCache:removeAnimation(name)
end

function display.removeUnusedSpriteFrames()
    spriteFrameCache:removeUnusedSpriteFrames()
    textureCache:removeUnusedTextures()
end


function display.newTTFLabel(params)
    assert(type(params) == "table",
           "[framework.display] newTTFLabel() invalid params")

    local text       = tostring(params.text)
    local font       = params.font or display.DEFAULT_TTF_FONT
    local size       = params.size or display.DEFAULT_TTF_FONT_SIZE
    local color      = params.color or display.COLOR_WHITE
    local textAlign  = params.align or cc.TEXT_ALIGNMENT_LEFT
    local textValign = params.valign or cc.VERTICAL_TEXT_ALIGNMENT_TOP
    local x, y       = params.x, params.y
    local dimensions = params.dimensions or cc.size(0, 0)

    assert(type(size) == "number",
           "[framework.display] newTTFLabel() invalid params.size")

    local label
    if cc.FileUtils:getInstance():isFileExist(font) then
        label = cc.Label:createWithTTF(text, font, size, dimensions, textAlign, textValign)
        if label then
            label:setColor(color)
        end
    else
        label = cc.Label:createWithSystemFont(text, font, size, dimensions, textAlign, textValign)
        if label then
            label:setTextColor(color)
        end
    end

    if label then
        if x and y then label:setPosition(x, y) end
    end

    return label
end

function display.newRect(rect, params)
    local x, y, width, height = 0, 0
    x = rect.x or 0
    y = rect.y or 0
    height = rect.height
    width = rect.width

    local points = {
        {x,y},
        {x + width, y},
        {x + width, y + height},
        {x, y + height}
    }
    return display.newPolygon(points, params)
end

function display.newEditBox(params)
    local imageNormal = params.image
    local imagePressed = params.imagePressed
    local imageDisabled = params.imageDisabled

    if type(imageNormal) == "string" then
        imageNormal = display.newScale9Sprite(imageNormal)
    end
    if type(imagePressed) == "string" then
        imagePressed = display.newScale9Sprite(imagePressed)
    end
    if type(imageDisabled) == "string" then
        imageDisabled = display.newScale9Sprite(imageDisabled)
    end

    print(cc.bPlugin_,"ddd")

    local editboxCls
    if cc.bPlugin_ then
        editboxCls = ccui.EditBox
    else
        editboxCls = cc.EditBox
    end
    local editbox = editboxCls:create(params.size, imageNormal, imagePressed, imageDisabled)

    if editbox then
        if params.listener then
            editbox:registerScriptEditBoxHandler(params.listener)
        end
        if params.x and params.y then
            editbox:setPosition(params.x, params.y)
        end
    end

    return editbox
end




function display.newTextField(params)
    local textfieldCls
    if cc.bPlugin_ then
        textfieldCls = ccui.TextField
    else
        textfieldCls = cc.TextField
    end
    local editbox = textfieldCls:create()
    editbox:setPlaceHolder(params.placeHolder)
    if params.x and params.y then
        editbox:setPosition(params.x, params.y)
    end
    if params.listener then
        editbox:addEventListener(params.listener)
    end
    if params.size then
        editbox:setTextAreaSize(params.size)
        editbox:setTouchSize(params.size)
        editbox:setTouchAreaEnabled(true)
    end
    if params.text then
        if editbox.setString then
            editbox:setString(params.text)
        else
            editbox:setText(params.text)
        end
    end
    if params.font then
        editbox:setFontName(params.font)
    end
    if params.fontSize then
        editbox:setFontSize(params.fontSize)
    end
    if params.fontColor then
        editbox:setTextColor(cc.c4b(params.fontColor.R or 255, params.fontColor.G or 255, params.fontColor.B or 255, 255))
    end
    if params.maxLength and 0 ~= params.maxLength then
        editbox:setMaxLengthEnabled(true)
        editbox:setMaxLength(params.maxLength)
    end
    if params.passwordEnable then
        editbox:setPasswordEnabled(true)
    end
    if params.passwordChar then
        editbox:setPasswordStyleText(params.passwordChar)
    end

    return editbox
end

display.PROGRESS_TIMER_BAR = 1
display.PROGRESS_TIMER_RADIAL = 0
function display.newProgressTimer(image, progresssType)
    if type(image) == "string" then
        image = display.newSprite(image)
    end

    local progress = cc.ProgressTimer:create(image)
    progress:setType(progresssType)
    return progress
end


function display.newDrawNode()
    return cc.DrawNode:create()
end


function display.clearAll()
    animationCache:purgeSharedAnimationCache();
    spriteFrameCache:removeUnusedSpriteFrame();
    textureCache:removeUnusedTextures();
    textureCachegetCachedTextureInfo();
end


--先放这里，根据机型返回最佳适配策略(iphone以及android刘海屏使用SHOW_ALL，其他使用FIXED_WIDTH_HEIGHT)
function display.getFitAutoScale(autoScale)
     if type(ODE_SO_VERSION) ~= "nil" and ODE_SO_VERSION >= 20181123 then
        local normalRect = cc.rect(0,0,display.width,display.height)
        local safeRect = display.safeRectReal
        if normalRect.x ~= safeRect.x or normalRect.y ~= safeRect.y or normalRect.width ~= safeRect.width or normalRect.height ~= safeRect.height then
            --刘海屏
            return "SHOW_ALL"
        else
            return "FIXED_WIDTH_HEIGHT"
        end
    else
         return autoScale or "SHOW_ALL"
    end
end

function display.isScreenNotch( ... )
    local normalRect = cc.rect(0,0,display.width,display.height)
    local safeRect = display.safeRectReal
    if normalRect.x ~= safeRect.x or normalRect.y ~= safeRect.y or normalRect.width ~= safeRect.width or normalRect.height ~= safeRect.height then
        --刘海屏
        return true
    else
        return false
    end
end



return display
