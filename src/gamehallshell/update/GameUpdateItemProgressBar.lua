local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
local GameConfig = require(require("GameHallShellConfig").GAME_CONFIG_PATH)

local GameUpdateItemProgressBar = class("GameUpdateItemProgressBar", function ()
    return display.newNode()
end)

local gamehallshell_res_path = GameConfig.res_path.."gamehallshell/"
local res_prefix = gamehallshell_res_path

local PROGRESS_BAR_BG = res_prefix .. "update/gameitem_progre_bar_bg.png"
local PROGRESS_CONTENT_ITEM = res_prefix .. "update/gameitem_progress_bar_content.png"

function GameUpdateItemProgressBar:ctor(params)
	params = params or {}
	self:enableNodeEvents()

	self.mPercent = 0

	local progressBarBg = params.progressBarBg or PROGRESS_BAR_BG
	local progressContentItem = params.progressContentItem or PROGRESS_CONTENT_ITEM
	self.mBg = display.newSprite(progressBarBg):addTo(self)

	local sz = self.mBg:getContentSize()

	self.mProgressContent = display.newSprite(progressContentItem)

	local stencil = display.newSprite(progressContentItem)

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

function GameUpdateItemProgressBar:getProgressMaxSize()
	return {width = self.mProgressMaxWidth, height = self.mProgressHeight}
end

function GameUpdateItemProgressBar:getProgressMaxWidth()
	return self.mProgressMaxWidth
end

function GameUpdateItemProgressBar:getProgressMaxHeight()
	return self.mProgressHeight
end

function GameUpdateItemProgressBar:setPercent(value)
	if value then
		if value == self.mPercent then
			return
		end
		if value < 0 then value = 0 end
		if value > 100 then value = 100 end
		local diff = value - self.mPercent
        local lastPercent = self.mPercent
        self.mPercent = value

        self:unregistSchedule()

        if value <= 5 or value >= 95 or diff <= 2 then
			self.mProgressContent:pos(self.mProgressMaxWidth * (self.mPercent - 100) / 100, 0)
        else
			self.fromProgressPos = (lastPercent - 100) / 100 * self.mProgressMaxWidth
			self.toProgressPos = (self.mPercent - 100) / 100 * self.mProgressMaxWidth
			self.deltaProgressOffset = self.toProgressPos - self.fromProgressPos
            -- 模拟一个ActionFloat, 每帧回调一次，如果有100帧算我输
            self.lastClock = core.getTime()
            self.schedulerHandle_ = scheduler.scheduleGlobal(handler(self, self.setProgressFluently), 0.01)
        end
	end
end

function GameUpdateItemProgressBar:getPercent()
	return self.mPercent
end

function GameUpdateItemProgressBar:setProgressFluently(d)
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
	
	self.mProgressContent:pos(self.fromProgressPos + delta * self.deltaProgressOffset, 0)

    if delta == 1 then
        self:unregistSchedule()
    end
end

function GameUpdateItemProgressBar:unregistSchedule()
	if self.schedulerHandle_ then
        scheduler.unscheduleGlobal(self.schedulerHandle_)
        self.schedulerHandle_ = nil
    end
end

function GameUpdateItemProgressBar:onCleanup()
	print("GameUpdateItemProgressBar:onCleanup")
	self:unregistSchedule()
end

return GameUpdateItemProgressBar