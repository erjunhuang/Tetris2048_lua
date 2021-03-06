
--[[
    用法：
    1. 纯文本：game.MarqueeTipManager:showTip("我就是我，不一样的烟火")
    2. 文本加图标：game.MarqueeTipManager:showTip({text = "我就是我，不一样的花朵", image = display.newSprite("top_tip_icon.png")})
]]
local GameConfig = require(require("GameHallShellConfig").GAME_CONFIG_PATH)
local gamehallshell_res_path = GameConfig.res_path.."gamehallshell/"

local MarqueeTipManager = class("MarqueeTipManager")

local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
local DEFAULT_STAY_TIME = 3
local X_GAP = 100
local Y_GAP = 0
local TIP_HEIGHT = 36
local LABEL_X_GAP = 16
local ICON_SIZE = 56
local LABEL_ROLL_VELOCITY = 80
local BG_CONTENT_SIZE = cc.size(display.width - X_GAP * 5, TIP_HEIGHT)
local Z_ORDER = 1001

function MarqueeTipManager:ctor()
    -- 视图容器
    self.container_ = display.newNode()
    self.container_:retain()
    self.container_:enableNodeEvents()

    -- 等待队列
    self.waitQueue_ = {}
    self.isPlaying_ = false

    --test
    local testArgs = {
        pos = cc.p(display.cx, display.top - Y_GAP - TIP_HEIGHT * 0.5 - 100)
    }
    self:setDefaultTheme(testArgs)
end


function MarqueeTipManager:setDefaultTheme(args)
    local bgFile = args and args.bgFile or gamehallshell_res_path.."hall/hall_laba_bg.png"
    self._bgFile = bgFile
    self._cPos = args and args.pos or cc.p(display.cx, display.top - Y_GAP - TIP_HEIGHT * 0.5)
end

function MarqueeTipManager:showTip(topTipData)
    assert(type(topTipData) == "table" or type(topTipData) == "string", "topTipData should be a table")
    if not self.tipBg_ then
        -- 背景
        self.tipBg_ = display.newScale9Sprite(self._bgFile, 0, 0, BG_CONTENT_SIZE)
            :addTo(self.container_)

        -- 小的裁剪模板（文本 + 图标）
        self.smallStencil_ = display.newDrawNode()
        self.smallStencil_:drawPolygon({
            cc.p(-BG_CONTENT_SIZE.width * 0.5 + LABEL_X_GAP * 2 + ICON_SIZE, -BG_CONTENT_SIZE.height * 0.5), 
            cc.p(-BG_CONTENT_SIZE.width * 0.5 + LABEL_X_GAP * 2 + ICON_SIZE,  BG_CONTENT_SIZE.height * 0.5), 
            cc.p(BG_CONTENT_SIZE.width * 0.5 - LABEL_X_GAP,  BG_CONTENT_SIZE.height * 0.5), 
            cc.p(BG_CONTENT_SIZE.width * 0.5 - LABEL_X_GAP, -BG_CONTENT_SIZE.height * 0.5)
        },4,cc.c4f(1,1,1,1),1,cc.c4f(1,1,1,1))
        self.smallStencil_:retain()

        -- 大的裁剪模板（文本）
        self.bigStencil_ = display.newDrawNode()
        self.bigStencil_:drawPolygon({
            cc.p(-BG_CONTENT_SIZE.width * 0.5 + LABEL_X_GAP, -BG_CONTENT_SIZE.height * 0.5), 
            cc.p(-BG_CONTENT_SIZE.width * 0.5 + LABEL_X_GAP,  BG_CONTENT_SIZE.height * 0.5), 
            cc.p(BG_CONTENT_SIZE.width * 0.5 - LABEL_X_GAP,  BG_CONTENT_SIZE.height * 0.5), 
            cc.p(BG_CONTENT_SIZE.width * 0.5 - LABEL_X_GAP, -BG_CONTENT_SIZE.height * 0.5)
        },4,cc.c4f(1,1,1,1),1,cc.c4f(1,1,1,1))
        self.bigStencil_:retain()

        -- 裁剪容器
        self.clipNode_ = cc.ClippingNode:create():addTo(self.container_)
        self.clipNode_:setStencil(self.bigStencil_)

        -- 文本
        self.label_ = display.newTTFLabel({text = "", size = 28, align = cc.TEXT_ALIGNMENT_CENTER,color = cc.c3b(0xbd,0xc9,0xf1)})
            :addTo(self.clipNode_)
    end

    if type(topTipData) == "string" then
        -- 过滤重复的消息
        for _, v in pairs(self.waitQueue_) do
            if v.text == topTipData then
                return
            end
        end
        table.insert(self.waitQueue_, {text = topTipData})
    else
        -- 过滤重复的消息
        for _, v in pairs(self.waitQueue_) do
            if v.text == topTipData.text then
                return
            end
        end
        if topTipData.image and type(topTipData.image) == "userdata" then
            topTipData.image:retain()
        end
        table.insert(self.waitQueue_, topTipData)
    end
    
    if not self.isPlaying_ then
        self:playNext_()
    end
end

function MarqueeTipManager:playNext_()
    if self.waitQueue_[1] then
        self.currentData_ = table.remove(self.waitQueue_, 1)
    else
        -- 播放完毕
        self.isPlaying_ = false
        return
    end

    -- 设置文本和图标
    local topTipData = self.currentData_
    local scrollTime = 0
    if topTipData.text then
        print("topTipData.text",topTipData.text)
        self.label_:setString(topTipData.text)
        local labelWidth = self.label_:getContentSize().width
        local startXPos = 0
        if topTipData.image and type(topTipData.image) == "userdata" then
            topTipData.image:pos(LABEL_X_GAP + ICON_SIZE * 0.5 - BG_CONTENT_SIZE.width * 0.5 , 0):addTo(self.container_)
            -- 设置对应的裁剪模板
            self.clipNode_:setStencil(self.smallStencil_)
            -- 计算文本滚屏时间
            scrollTime = (labelWidth - (BG_CONTENT_SIZE.width - LABEL_X_GAP * 2 - LABEL_X_GAP - ICON_SIZE)) / LABEL_ROLL_VELOCITY
            if scrollTime > 0 then
                startXPos = labelWidth * 0.5 - BG_CONTENT_SIZE.width * 0.5 + LABEL_X_GAP + LABEL_X_GAP + ICON_SIZE
                self.label_:pos(startXPos, 0)
                transition.execute(self.label_, cc.MoveTo:create(scrollTime, cc.p(-startXPos + LABEL_X_GAP + ICON_SIZE, 0)), {delay = 1.5})
            else
                scrollTime = 0
                self.label_:pos((LABEL_X_GAP * 2 + ICON_SIZE) * 0.5, 0)
            end
        else
            -- 设置对应的裁剪模板
            self.clipNode_:setStencil(self.bigStencil_)
            -- 计算文本滚屏时间
            scrollTime = (labelWidth - (BG_CONTENT_SIZE.width - LABEL_X_GAP * 2)) / LABEL_ROLL_VELOCITY
            if scrollTime > 0 then
                startXPos = labelWidth * 0.5 - BG_CONTENT_SIZE.width * 0.5 + LABEL_X_GAP
                self.label_:pos(startXPos, 0)
                transition.execute(self.label_, cc.MoveTo:create(scrollTime, cc.p(-startXPos, 0)), {delay = DEFAULT_STAY_TIME * 0.5})
            else
                scrollTime = 0
                self.label_:pos(0, 0)
            end
        end
    end    

    -- 下滑动画
    self.isPlaying_ = true
    -- self.container_:pos(display.cx, display.top + TIP_HEIGHT * 0.5)
    self.container_:pos(self._cPos.x,self._cPos.y)
        :addTo(game.runningScene, Z_ORDER)
        -- :moveTo({time = 0.3,x = display.cx,y =  display.top - Y_GAP - TIP_HEIGHT * 0.5})
        :fadeIn({time = 0.3})

    -- 移除tip定时器
    self.delayScheduleHandle_ = scheduler.performWithDelayGlobal(handler(self, self.delayCallback_), 0.3 + DEFAULT_STAY_TIME + scrollTime)

    local getFrame = display.newSpriteFrame
    if topTipData.messageType == 1000 then
        self.label_:setTextColor(cc.c3b(0xff, 0xae, 0x70))
        -- self.tipBg_:setSpriteFrame(getFrame("common_top_tip_bg.png"))
        self.tipBg_:setContentSize(display.width - X_GAP * 5, TIP_HEIGHT)
    else
        self.label_:setTextColor(cc.c3b(0xff, 0xff, 0xff))
        -- self.tipBg_:setSpriteFrame(getFrame("common_top_tip_bg.png"))
        self.tipBg_:setContentSize(display.width - X_GAP * 5, TIP_HEIGHT)
    end

end

function MarqueeTipManager:delayCallback_()
    self.delayScheduleHandle_ = nil
    if self.container_:getParent() then
        -- transition.moveTo(self.container_, {
        --     x = display.cx, 
        --     y = display.top + TIP_HEIGHT * 0.5, 
        --     time = 0.3, 
        --     onComplete = handler(self, self.onHideComplete_), 
        -- })

        self.container_:fadeOut({time = 0.3,onComplete = handler(self, self.onHideComplete_)})
    else
        -- self.container_:pos(display.cx, display.top + TIP_HEIGHT * 0.5)
        self.container_:fadeOut({time = 0.1})
        self:onHideComplete_()
    end
end

function MarqueeTipManager:cleanup()
    -- body
    if self.currentData_ and self.currentData_.image and type(self.currentData_.image) == "userdata" then
        self.currentData_.image:release()
        self.currentData_.image:removeFromParent()
    end
    -- 移除定时器
    if self.delayScheduleHandle_ then
        scheduler.unscheduleGlobal(self.delayScheduleHandle_)
        self.delayScheduleHandle_ = nil
    end
    -- 延迟一秒播放下一条
    scheduler.performWithDelayGlobal(function ()
        self:playNext_()
    end, 1)
    -- print("container removed")
end

function MarqueeTipManager:onHideComplete_()
    self.container_:removeFromParent()
    self:cleanup()
end


function MarqueeTipManager:dispose()
    if self.container_:getParent() then
        self.container_:removeSelf()
    end
    self.container_:release()
    self.container_ = nil
end

return MarqueeTipManager