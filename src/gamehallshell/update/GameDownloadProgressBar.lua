local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
local GameConfig = require(require("GameHallShellConfig").GAME_CONFIG_PATH)

local GameDownloadProgressBar = class("GameDownloadProgressBar", function ()
    return display.newNode()
end)

local gamehallshell_res_path = GameConfig.res_path.."gamehallshell/"
local res_prefix = gamehallshell_res_path

local PROGRESS_BAR_BG = res_prefix .. "update/progress_bar_bg.png"
local PROGRESS_CONTENT_ITEM = res_prefix .. "update/progress_bar_content.png"
local PROGRESS_CONTENT_VISUAL_EFFECTS = res_prefix .. "update/progress_bar_content_vfx.png"

local BORDER_HORIZONTAL = 8
local BORDER_VERTICAL = 4

local VFX_OFFSET = -8

function GameDownloadProgressBar:ctor(width, height)
    self:enableNodeEvents()
    self.mPercent = 0

    self.mBg = display.newSprite(PROGRESS_BAR_BG):addTo(self)

    local sz = self.mBg:getContentSize()

    local scaleX = width / sz.width
    local scaleY = height / sz.height
    self.mScaleX = math.min(scaleX, scaleY)
    self.mScaleY = self.mScaleX

    self.mBg:setScaleX(self.mScaleX)
    self.mBg:setScaleY(self.mScaleY)

    self.mBgHeight = sz.height

    self.mProgressTxt = display.newTTFLabel({text="0%",color = cc.c3b(236,226,160), size = 24, align = cc.TEXT_ALIGNMENT_RIGHT, valign = cc.VERTICAL_TEXT_ALIGNMENT_CENTER, dimensions = cc.size(80,40)})
        :addTo(self.mBg)
    self.mProgressTxt:pos(sz.width - self.mProgressTxt:getContentSize().width / 2 - BORDER_HORIZONTAL, sz.height + self.mProgressTxt:getContentSize().height / 2 + BORDER_VERTICAL)

    self.mProgressContent = display.newSprite(PROGRESS_CONTENT_ITEM)

    local stencil = display.newSprite(PROGRESS_CONTENT_ITEM)

	local clippingNode = cc.ClippingNode:create()
	clippingNode:setStencil(stencil)
	stencil:setBlendFunc({src = 1, dst = 1}) --颜色混合方案
	clippingNode:setAlphaThreshold(0.2)
	clippingNode:setInverted(false)

	clippingNode:addChild(self.mProgressContent)
	clippingNode:pos(sz.width/2, sz.height/2)

	sz = self.mProgressContent:getContentSize()
	self.mProgressMaxWidth = sz.width
	self.mProgressHeight = sz.height

	self.mProgressContent:pos(sz.width * (self.mPercent - 100) / 100, 0)

    self.mBg:addChild(clippingNode)
end

function GameDownloadProgressBar:startProgressAnim()
    if not self.mSparkSprite then
        self.mSparkSprite = display.newSprite(PROGRESS_CONTENT_VISUAL_EFFECTS)
        self.mSparkSprite:pos(VFX_OFFSET, self.mBgHeight/2)
        self.mBg:addChild(self.mSparkSprite)

        self.mSparkSprite:runAction(cc.RepeatForever:create(cc.RotateBy:create(2, 360)))
    end
end

function GameDownloadProgressBar:stopProgressAnim()
    if self.mSparkSprite then
        self.mSparkSprite:removeFromParent()
        self.mSparkSprite = nil
    end
end

-- percent 0-100
function GameDownloadProgressBar:setPercent(value)
    if value then
        if value == self.mPercent then
            return
        end
        local diff = value - self.mPercent
        local lastPercent = self.mPercent
        self.mPercent = value
        self.mProgressTxt:setString(string.format("%d%%",self.mPercent))
        self:unregistSchedule()

        if value <= 5 or value >= 95 or diff <= 2 then
            if self.mSparkSprite then
                self.mSparkSprite:pos(VFX_OFFSET + self.mPercent / 100 * self.mProgressMaxWidth, self.mBgHeight/2)
            end
            self.mProgressContent:pos(self.mProgressMaxWidth * (self.mPercent - 100) / 100, 0)
        else
            self.fromProgressPos = (lastPercent - 100) / 100 * self.mProgressMaxWidth
			self.toProgressPos = (self.mPercent - 100) / 100 * self.mProgressMaxWidth
            self.deltaProgressOffset = self.toProgressPos - self.fromProgressPos
            
            self.fromSparkPos = lastPercent / 100 * self.mProgressMaxWidth
            self.toSparkPos = self.mPercent / 100 * self.mProgressMaxWidth
            self.deltaSparkOffset = self.toSparkPos - self.fromSparkPos
            -- 模拟一个ActionFloat, 每帧回调一次，如果有100帧算我输
            self.lastClock = core.getTime()
            self.schedulerHandle_ = scheduler.scheduleGlobal(handler(self, self.setProgressFluently), 0.01)
        end
    end
end

function GameDownloadProgressBar:getPercent()
    return self.mPercent
end

function GameDownloadProgressBar:setProgressFluently(d)
    if not self.lastClock then
        -- 容错处理
        return
    end
    local currClock = core.getTime()
    local deltaClock = currClock - self.lastClock

    local delta = deltaClock / 0.2

    if delta > 1 then
        delta = 1
	end
    
    if self.mSparkSprite then
        self.mSparkSprite:pos(VFX_OFFSET + self.fromSparkPos + delta * self.deltaSparkOffset, self.mBgHeight/2)
    end
	self.mProgressContent:pos(self.fromProgressPos + delta * self.deltaProgressOffset, 0)

    if delta == 1 then
        self:unregistSchedule()
    end
end

function GameDownloadProgressBar:unregistSchedule()
    if self.schedulerHandle_ then
        scheduler.unscheduleGlobal(self.schedulerHandle_)
        self.schedulerHandle_ = nil
    end
end

function GameDownloadProgressBar:onCleanup()
    print("GameDownloadProgressBar:onCleanup")
    self:unregistSchedule()
end

return GameDownloadProgressBar