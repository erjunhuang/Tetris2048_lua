local GameDownloadProgressBar = import(".GameDownloadProgressBar")
local Juhua = import(".Juhua")
local ConstantConfig = import(".ConstantConfig")
local GameConfig = require(require("GameHallShellConfig").GAME_CONFIG_PATH)

-- 壳游戏更新Scene
local ShellUpdateScene = class("ShellUpdateScene", function()
        return display.newScene("ShellUpdateScene")
    end)

local gamehallshell_res_path = GameConfig.res_path.."gamehallshell/"
-- 临时的
local res_prefix = gamehallshell_res_path

ShellUpdateScene.STATE = {}
ShellUpdateScene.STATE.NONE = 0
ShellUpdateScene.STATE.DOWNLOADING = 1
ShellUpdateScene.STATE.LOADING = 2
ShellUpdateScene.STATE.ENTERING = 3
ShellUpdateScene.STATE.FINISHED = 4
ShellUpdateScene.STATE.DOWNLOADFAILED = 5
ShellUpdateScene.STATE.WAITING_BSPATCH = 6 -- 等待合并补丁包
ShellUpdateScene.STATE.WAITING_INSTALL = 7 -- 等待安装apk

ShellUpdateScene.s_download_waiting_threhold1 = 50
ShellUpdateScene.s_download_waiting_threhold2 = 80
ShellUpdateScene.s_download_waiting_threhold3 = 90

function ShellUpdateScene:ctor(controller, designWidth, designHeight)
    self:enableNodeEvents()
    self.mDesignWidth = designWidth or 1280
    self.mDesignHeight = designHeight or 720
    self.mController = controller
    self.mJuhua = nil

    -- 初始状态
    self.mState = ShellUpdateScene.STATE.NONE

    self:initViews()
end

-- enableNodeEvents
function ShellUpdateScene:onCleanup()
    self.mController:dispose()
end

function ShellUpdateScene:initViews()
    print("ShellUpdateScene:initViews => displaySize:", display.width, display.height, "designSize:", self.mDesignWidth, self.mDesignHeight)
    local scaleX = display.width / self.mDesignWidth
    local scaleY = display.height / self.mDesignHeight
    self.mBgNode = display.newNode()
    self.mBgNode:setContentSize(display.size)
    self:addChild(self.mBgNode)
    self.mBg = display.newSprite(res_prefix .. "logingameview/login_bg.jpg")
        :addTo(self.mBgNode):center()
    local bgImageSize = self.mBg:getContentSize()
    local bgScaleX = display.width / bgImageSize.width
    local bgScaleY = display.height / bgImageSize.height
    print("ShellUpdateScene:initViews => bgScale:", bgScaleX, bgScaleY)
    self.mBg:setScaleX(bgScaleX)
    self.mBg:setScaleY(bgScaleY)

    self.mTipString = "提示"
    self.mStringDotCounts = 0
    self.mText = display.newTTFLabel(
        {
            text = self.mTipString,
            color = cc.c3b(236, 226, 160),
            size = 30,
            font = res_prefix .. "fonts/FZHei-B01S.TTF",
            align = cc.TEXT_ALIGNMENT_CENTER
        }):pos(display.cx, 1/3 * display.height):addTo(self):hide()

    -- 进度条
    self.mProgressBar = GameDownloadProgressBar.new(23/32 * display.width, 27)
    self.mProgressBar:addTo(self):pos(display.cx, 1/4 * display.height):hide()

    self.mJuhuaNode = display.newNode():addTo(self):center()
    self.mDialogNode = display.newNode():addTo(self):center()

    ccui.Helper:doLayout(self.mBgNode)
end

function ShellUpdateScene:showJuhua()
    if not self.mJuhua then
        self.mJuhua = Juhua.new():addTo(self.mJuhuaNode)
    else
        self.mJuhua:show()
    end
end

function ShellUpdateScene:hideJuhua()
    if self.mJuhua then
        self.mJuhua:hide()
    end
end

function ShellUpdateScene:setDownloadProgress(progress)
    if self.mState ~= ShellUpdateScene.STATE.DOWNLOADING or self.mIsDownloadFinished then
        return
    end
    print("ShellUpdateScene:setDownloadProgress: " .. tostring(progress))
    self.mProgressBar:setPercent(progress)
end

function ShellUpdateScene:setViewState(state, tipString)
    if state == self.mState then
        return
    end

    if state == ShellUpdateScene.STATE.DOWNLOADING then
        -- self:startDownloadProgressAction()
        self.mState = ShellUpdateScene.STATE.DOWNLOADING
        self.mProgressBar:show()
        self.mProgressBar:startProgressAnim()
        self.mText:show()
        self.mTipString = tipString or "正在加载游戏配置"
        self.mText:setString(self.mTipString)
        self.mProgressBar:setPercent(0)
        self.mProgressBar:show()
        self:startTipsAction()
    elseif state == ShellUpdateScene.STATE.LOADING then
        self.mState = ShellUpdateScene.STATE.LOADING
        self.mTipString = tipString or "正在初始化游戏场景"
        self.mText:setString(self.mTipString)
        self.mProgressBar:setPercent(0)
        self.mProgressBar:startProgressAnim()
        self.mProgressBar:show()
        self:startLoadingProgressAction()
    elseif state == ShellUpdateScene.STATE.ENTERING then
        self.mState = ShellUpdateScene.STATE.ENTERING
        self.mTipString = tipString or "祝您游戏愉快"
        self.mText:setString(self.mTipString)
        self.mProgressBar:setPercent(100)
        self.mProgressBar:stopAllActions()
        self:onDownloadActionFlowFinished()
    elseif state == ShellUpdateScene.STATE.WAITING_BSPATCH then
        self.mState = ShellUpdateScene.STATE.WAITING_BSPATCH
        self.mTipString = tipString or "正在生成安装包"
        self.mText:setString(self.mTipString)
        self.mProgressBar:setPercent(100)
        self.mProgressBar:stopAllActions()
        self:onDownloadActionFlowFinished()
    elseif state == ShellUpdateScene.STATE.WAITING_INSTALL then
        self.mState = ShellUpdateScene.STATE.WAITING_INSTALL
        self.mTipString = ""
        self.mText:setString(self.mTipString)
        self.mText:stopAllActions()
        self.mProgressBar:setPercent(100)
        self.mProgressBar:stopAllActions()
        self:onDownloadActionFlowFinished()
    elseif state == ShellUpdateScene.STATE.FINISHED then
        self.mState = ShellUpdateScene.STATE.FINISHED
        self:onDownloadActionFlowFinished()
    elseif state == ShellUpdateScene.STATE.DOWNLOADFAILED then
        self.mState = ShellUpdateScene.STATE.DOWNLOADFAILED
        self.mText:stopAllActions()
        self.mText:hide()
        self.mProgressBar:stopAllActions()
        self.mProgressBar:setPercent(0)
        self.mProgressBar:stopProgressAnim()
        self.mProgressBar:hide()
    elseif state == ShellUpdateScene.STATE.NONE then
        self.mState = ShellUpdateScene.STATE.NONE
        self.mText:stopAllActions()
        self.mText:hide()
        self.mProgressBar:stopAllActions()
        self.mProgressBar:setPercent(0)
        self.mProgressBar:stopProgressAnim()
        self.mProgressBar:hide()
    end
end

function ShellUpdateScene:onDownloadActionFlowFinished()
    self.mController:onDownloadActionFlowFinished(self.mDownloadFinishedInfo)
end

function ShellUpdateScene:startLoadingProgressAction()
    local progressSequence =
        transition.sequence(
        {
            cc.DelayTime:create(0.01),
            cc.CallFunc:create(handler(self, self.onUpdateProgress))
        }
    )

    self.mProgressBar:stopAllActions()
    local progressAction = cc.RepeatForever:create(progressSequence)
    self.mProgressBar:runAction(progressAction)
end

function ShellUpdateScene:startDownloadProgressAction()
    local progressSequence =
        transition.sequence(
        {
            cc.DelayTime:create(0.05),
            cc.CallFunc:create(handler(self, self.onUpdateProgress))
        }
    )

    self.mProgressBar:stopAllActions()
    local progressAction = cc.RepeatForever:create(progressSequence)
    self.mProgressBar:runAction(progressAction)
end

function ShellUpdateScene:startSlowerDownloadProgressAction()
    local progressSequence =
        transition.sequence(
        {
            cc.DelayTime:create(0.2),
            cc.CallFunc:create(handler(self, self.onUpdateProgress))
        }
    )

    self.mProgressBar:stopAllActions()
    local progressAction = cc.RepeatForever:create(progressSequence)
    self.mProgressBar:runAction(progressAction)
end

function ShellUpdateScene:startMuchSlowerDownloadProgressAction()
    local progressSequence =
        transition.sequence(
        {
            cc.DelayTime:create(0.5),
            cc.CallFunc:create(handler(self, self.onUpdateProgress))
        }
    )

    self.mProgressBar:stopAllActions()
    local progressAction = cc.RepeatForever:create(progressSequence)
    self.mProgressBar:runAction(progressAction)
end

function ShellUpdateScene:startDownloadProgressQuickFinishAction(downloadInfo)
    self.mDownloadFinishedInfo = downloadInfo
    if self.mState == ShellUpdateScene.STATE.DOWNLOADING then
        -- 正在跑进度条
        self.mIsDownloadFinished = true
        local progressSequence =
            transition.sequence(
            {
                cc.DelayTime:create(0.01),
                cc.CallFunc:create(handler(self, self.onUpdateProgress))
            }
        )

        local progressAction = cc.RepeatForever:create(progressSequence)
        self.mProgressBar:runAction(progressAction)
    else
        -- 没有在跑进度条
        if self.mState ~= ShellUpdateScene.STATE.FINISHED then
            -- 下载完毕状态，虽然不可能
            self:setViewState(ShellUpdateScene.STATE.FINISHED)
        else
            -- 通知Controller成功
            self:onDownloadActionFlowFinished()
        end
    end
end

function ShellUpdateScene:stopProgressAction()
    self.mProgressBar:stopAllActions()
end

function ShellUpdateScene:startTipsAction()
    local textSequence =
        transition.sequence(
        {
            cc.DelayTime:create(0.6),
            cc.CallFunc:create(handler(self, self.onUpdateTips))
        }
    )
    local textAction = cc.RepeatForever:create(textSequence)
    self.mText:stopAllActions()
    self.mText:runAction(textAction)
end

function ShellUpdateScene:onUpdateProgress()
    local percent = self.mProgressBar:getPercent()
    percent = percent + 1
    self.mProgressBar:setPercent(percent)

    if self.mState == ShellUpdateScene.STATE.DOWNLOADING then
        if self.mIsDownloadFinished then
            -- 小于0是容错
            if percent >= 100 or percent < 0 then
                if self.mDownloadFinishedInfo then
                    local updateType = self.mDownloadFinishedInfo.type
                    if
                        updateType == ConstantConfig.UPDATETYPE.OPTIONAL_BS_DIFF_APK or
                            updateType == ConstantConfig.UPDATETYPE.FORCE_BS_DIFF_APK
                     then
                        -- 差异包
                        self:setViewState(ShellUpdateScene.STATE.WAITING_BSPATCH)
                        return
                    elseif
                        updateType == ConstantConfig.UPDATETYPE.OPTIONAL_FULL_APK or
                            updateType == ConstantConfig.UPDATETYPE.FORCE_FULL_APK
                     then
                        -- 完整包
                        self:setViewState(ShellUpdateScene.STATE.WAITING_INSTALL)
                        return
                    end
                end
                self:setViewState(ShellUpdateScene.STATE.LOADING)
            end
        elseif percent == ShellUpdateScene.s_download_waiting_threhold1 then
            self:startSlowerDownloadProgressAction()
        elseif percent == ShellUpdateScene.s_download_waiting_threhold2 then
            self:startMuchSlowerDownloadProgressAction()
        elseif percent == ShellUpdateScene.s_download_waiting_threhold3 then
            self:stopProgressAction()
        end
    elseif self.mState == ShellUpdateScene.STATE.LOADING then
        if percent >= 100 or percent < 0 then
            self:setViewState(ShellUpdateScene.STATE.ENTERING)
            self:performWithDelay(
                function()
                    self:setViewState(ShellUpdateScene.STATE.FINISHED)
                end,
                1
            )
        end
    end
end

function ShellUpdateScene:onUpdateTips()
    self.mStringDotCounts = self.mStringDotCounts + 1
    if self.mStringDotCounts > 3 then
        self.mStringDotCounts = 0
    end

    local appendingStr = ""
    if self.mStringDotCounts == 1 then
        appendingStr = "."
    elseif self.mStringDotCounts == 2 then
        appendingStr = ".."
    elseif self.mStringDotCounts == 3 then
        appendingStr = "..."
    end

    self.mText:setString(self.mTipString .. appendingStr)
end

return ShellUpdateScene
