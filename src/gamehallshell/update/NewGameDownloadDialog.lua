local NewUpdateMgr = import(".NewUpdateMgr")
local GameConfig = require(require("GameHallShellConfig").GAME_CONFIG_PATH)
local gamehallshell_res_path = GameConfig.res_path.."gamehallshell/"

-- 游戏下载弹窗
local NewGameDownloadDialog = class("NewGameDownloadDialog",game.ui.Panel)

local res_prefix = gamehallshell_res_path
local fontPath = gamehallshell_res_path.."fonts/FZHei-B01S.TTF"

NewGameDownloadDialog.WIDTH = 600
NewGameDownloadDialog.HEIGHT = 400

NewGameDownloadDialog.TITLE_BG_HEIGHT = 100
NewGameDownloadDialog.TITLE_BG_BORDER = 6

NewGameDownloadDialog.DESC_TEXT_MAX_WIDTH = NewGameDownloadDialog.WIDTH - 48
NewGameDownloadDialog.DESC_TEXT_MAX_HEIGHT = NewGameDownloadDialog.HEIGHT - 214

local function getShowSizeString(size)
  if size < 1024 then
    return string.format("%dB", size)
  elseif size >= 1024 and size < 1048576 then
    return string.format("%0.2fKB", size/1024)
  elseif size >= 1048576 then
    return string.format("%0.2fMB", size/1048576)
  end
end

-- isUpdate true，更新
-- isUpdate false，下载
function NewGameDownloadDialog:ctor(isUpdate, gameid, confirmFunc, cancelFunc)
    NewGameDownloadDialog.super.ctor(self,{NewGameDownloadDialog.WIDTH,NewGameDownloadDialog.HEIGHT})
    self:enableNodeEvents()
    self.mIsUpdateDialog = isUpdate
    self.mConfirmHandler = confirmFunc
    self.mCancelHandler = cancelFunc

    -- test
    self.mUpdateData = {}
    if self.mIsUpdateDialog then
      self.mUpdateData.desc = "游戏需要更新，是否现在下载？"
    else
      self.mUpdateData.desc = "游戏尚未安装，是否现在下载？"
    end

    --背景
    self.mBg = display.newScale9Sprite(res_prefix .. "common/common_panel_bg2.png", 0, 0, cc.size(NewGameDownloadDialog.WIDTH,NewGameDownloadDialog.HEIGHT)):addTo(self)
    cc.bind(self.mBg,"touch"):setTouchEnabled(true)

    self.mTitleBg = display.newScale9Sprite(res_prefix .. "common/common_panel_bg2_title.png", 0, NewGameDownloadDialog.HEIGHT/2 - NewGameDownloadDialog.TITLE_BG_HEIGHT/2 - NewGameDownloadDialog.TITLE_BG_BORDER, 
      cc.size(self.__width - NewGameDownloadDialog.TITLE_BG_BORDER * 2,NewGameDownloadDialog.TITLE_BG_HEIGHT)):addTo(self)

    local textHeightPos = 16

    local titleText = self.mIsUpdateDialog and "发现新版本" or "游戏下载"

    local titleBgSize = self.mTitleBg:getContentSize()
    self.mTitle = display.newTTFLabel({text=titleText, font=fontPath,color = cc.c3b(253,237,202), size = 35, align = cc.TEXT_ALIGNMENT_CENTER,})
      :addTo(self.mTitleBg)
      :enableOutline(cc.c4b(36,27,77,150), 2)
      :pos(titleBgSize.width/2,titleBgSize.height/2 + 9)
    
    local diffY = 0

    local descStr = self.mUpdateData.desc or ""

    -- 描述
    self.mDescText = display.newTTFLabel({text=descStr,
      color = cc.c3b(255,255,255), size = 26, font=fontPath, align = cc.TEXT_ALIGNMENT_LEFT, valign = cc.VERTICAL_TEXT_ALIGNMENT_CENTER,})
    local descTextSize = self.mDescText:getContentSize()
    if descTextSize.height > NewGameDownloadDialog.DESC_TEXT_MAX_HEIGHT then
      self.mDescScrollView = ccui.ScrollView:create()
      self.mDescScrollView:setContentSize(cc.size(NewGameDownloadDialog.DESC_TEXT_MAX_WIDTH, NewGameDownloadDialog.DESC_TEXT_MAX_HEIGHT))
      self.mDescScrollView:setInnerContainerSize(descTextSize)
      self.mDescScrollView:setBounceEnabled(false)
      if descTextSize.width > NewGameDownloadDialog.DESC_TEXT_MAX_WIDTH then
        self.mDescScrollView:setDirection(ccui.ScrollViewDir.both)
        self.mDescText:addTo(self.mDescScrollView):pos(descTextSize.width/2,descTextSize.height/2)
      else
        self.mDescScrollView:setDirection(ccui.ScrollViewDir.vertical)
        self.mDescText:addTo(self.mDescScrollView):pos(NewGameDownloadDialog.DESC_TEXT_MAX_WIDTH/2,descTextSize.height/2)
      end
      self.mDescScrollView:setTouchEnabled(true)
      self.mDescScrollView:setScrollBarEnabled(false)
      -- 调试用
      -- self.mDescScrollView:setBackGroundColorType(1)
      -- self.mDescScrollView:setBackGroundColor({r = 255, g = 150, b = 100})
      self.mDescScrollView:addTo(self):pos(-NewGameDownloadDialog.DESC_TEXT_MAX_WIDTH/2,textHeightPos-NewGameDownloadDialog.DESC_TEXT_MAX_HEIGHT/2)
    else
      self.mDescText:addTo(self):pos(0,textHeightPos)
      diffY = NewGameDownloadDialog.DESC_TEXT_MAX_HEIGHT - descTextSize.height - 80
      -- self.mDescBg:size(self.DESC_TEXT_MAX_WIDTH+4, descTextSize.height + 80)
      -- self.mDescBg:hide()
      self.mBg:size(NewGameDownloadDialog.WIDTH, NewGameDownloadDialog.HEIGHT - diffY)
    end

    self.mConfirmBtn = ccui.Button:create(res_prefix.."common/new_common_tip_btn_selBg.png",res_prefix.."common/new_common_tip_btn_selBg.png")
    self.mConfirmBtn:setScale9Enabled(true)
    self.mConfirmBtn:addClickEventListener(buttonHandler(self, self.onConfirmBtnClick))
    self.mConfirmBtn:addTo(self):pos(160,-142)
    self.mConfirmBtn:setTitleColor(cc.c3b(0x2c,0x23,0x1f))
    self.mConfirmBtn:setTitleFontName(fontPath)
    self.mConfirmBtn:getTitleRenderer():enableOutline(cc.c4b(0xff,0xff,0xd8,100), 2)
    self.mConfirmBtn:setTitleText("确认下载")
    self.mConfirmBtn:setTitleFontSize(28)


    self.mCancelBtn = ccui.Button:create(res_prefix.."common/new_common_tip_btn_norBg.png",res_prefix.."common/new_common_tip_btn_norBg.png")
    self.mCancelBtn:setScale9Enabled(true)
    self.mCancelBtn:addClickEventListener(cancelButtonHandler(self, self.onCancelBtnClick))
    self.mCancelBtn:addTo(self):pos(-160,-142)
    self.mCancelBtn:setTitleColor(cc.c3b(0x2c,0x23,0x1f))
    self.mCancelBtn:setTitleFontName(fontPath)
    self.mCancelBtn:getTitleRenderer():enableOutline(cc.c4b(0xff,0xff,0xd8,100), 2)
    self.mCancelBtn:setTitleText("暂不下载")
    self.mCancelBtn:setTitleFontSize(28)

    self.mTipString = "提示"
    self.mStringDotCounts = 0
    self.mText = display.newTTFLabel({text=self.mTipString,color = cc.c3b(236,226,160), size = 24, font=fontPath, align = cc.TEXT_ALIGNMENT_CENTER})
      :pos(0,-82)
      :addTo(self)
      :hide()

    -- 重新定位
    if diffY ~= 0 then
      local children = self:getChildren()
      for _, node in ipairs(children) do
          if node ~= self.mBg and node ~= self.mDescText then
            local x,y = node:getPosition()
            node:pos(x,y>0 and (y-diffY/2) or (y + diffY/2))
          end
      end
    end
end

-- override
function NewGameDownloadDialog:showPanel_()
  NewGameDownloadDialog.super.showPanel_(self,true,true,false,false)
end

-- override
function NewGameDownloadDialog:onClose()
  NewGameDownloadDialog.super.onClose(self, false)
end

function NewGameDownloadDialog:onCancelBtnClick()
  if self.mCancelHandler then
    self.mCancelHandler()
    self.mCancelHandler = nil
  end
  self:onClose()
end

function NewGameDownloadDialog:onConfirmBtnClick()
  if self.mConfirmHandler then
    self.mConfirmHandler()
    self.mConfirmHandler = nil
  end
  self:onClose()
end

return NewGameDownloadDialog