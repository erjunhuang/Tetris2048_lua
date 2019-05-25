-- 由于game.ui.Dialog依赖了过多game和app的lua代码，不能直接使用，所以按照样式实现一个
local GameConfig = require(require("GameHallShellConfig").GAME_CONFIG_PATH)


local Dialog = class("Dialog", cc.load("mvc").ViewBase)

local DEFAULT_WIDTH = 540
local DEFAULT_HEIGHT = 400
local TOP_HEIGHT = 68
local PADDING = 32
local BTN_HEIGHT = 86
local Z_ORDER = 1000

local gamehallshell_res_path = GameConfig.res_path.."gamehallshell/"

Dialog.FIRST_BTN_CLICK  = 1
Dialog.SECOND_BTN_CLICK = 2
Dialog.CLOSE_BTN_CLICK  = 3

function Dialog:ctor(args)
	if type(args) == "table" then
        self:addTo(args.parent, Z_ORDER)
        self.callbackPassArgs = args.callbackPassArgs
        self.dontAutoHideByFirstOrSecond = args.dontAutoHideByFirstOrSecond
        self.messageText_ = args.messageText
        self.specialWidth_ = args.specialWidth
        self.callback_ = args.callback
        self.firstBtnText_ = args.firstBtnText or "取消"
        self.secondBtnText_ = args.secondBtnText or "确认"
        self.titleText_ = args.titleText or "温馨提示"
        self.noCloseBtn_ = (args.hasCloseButton == false)
        self.noFristBtn_ = (args.hasFirstButton == false)
        self.notCloseWhenTouchModel_ = (args.closeWhenTouchModel == false)
    end

    -- 设置dialog的尺寸
    local dialogWidth = self.specialWidth_ or DEFAULT_WIDTH
    -- 初始化文本
    local messageLabel = display.newTTFLabel({
            text = self.messageText_,
            cc.c3b(0xff,0xff,0xff),
            size = 26,
            align = cc.TEXT_ALIGNMENT_CENTER,
            font= gamehallshell_res_path .. "fonts/FZHei-B01S.TTF" ,
            dimensions = cc.size(dialogWidth - 50, 0)
        })
        :pos(0, (PADDING + BTN_HEIGHT - TOP_HEIGHT) * 0.5)

    local dialogHeight =  messageLabel:getContentSize().height + PADDING * 3 + BTN_HEIGHT + TOP_HEIGHT
    if dialogHeight < DEFAULT_HEIGHT then dialogHeight = DEFAULT_HEIGHT end
    Dialog.super.ctor(self, {dialogWidth, dialogHeight})
    self.__width = dialogWidth
    self.__height = dialogHeight

    if not self.noCloseBtn_ then
        self:addCloseBtn()
    end

    self.background_ = display.newScale9Sprite(gamehallshell_res_path.."common/common_panel_bg2.png", 0, 0, cc.size(self.__width, self.__height)):addTo(self)
    cc.bind(self.background_,"touch"):setTouchEnabled(true)
    self.backgroundTitle = display.newScale9Sprite(gamehallshell_res_path.."common/common_panel_bg2_title.png"
        ,0,0,cc.size(self.__width -12,74)):addTo(self)
    :pos(0,self.__height/2 - 74/2 - 8)

    -- 添加标签
    display.newTTFLabel({text = self.titleText_, color = cc.c3b(253,237,202),font=gamehallshell_res_path.."fonts/FZHei-B01S.TTF" , size = 35, align = cc.TEXT_ALIGNMENT_CENTER})
        :pos(0, self.__height * 0.5 - TOP_HEIGHT * 0.5-5)
        :addTo(self)
        :enableOutline(cc.c4b(36,27,77,150), 2)
    messageLabel:addTo(self)

    -- 初始化按钮
    local showFirstBtn = false
    local buttonWidth = 0
    if not self.noFristBtn_ then
        if self.firstBtnText_ then
            showFirstBtn = true
        end
    end
    self.secondBtn_ = ccui.Button:create(gamehallshell_res_path.."common/new_common_tip_btn_selBg.png",gamehallshell_res_path.."common/new_common_tip_btn_selBg.png")
        :addTo(self)
        :setTitleText(self.secondBtnText_)
        self.secondBtn_:setScale9Enabled(false)
        self.secondBtn_:setTitleFontSize(32)
        :setTitleColor(cc.c3b(0x2c,0x23,0x1f))
        :setTitleFontName(gamehallshell_res_path.."fonts/FZHei-B01S.TTF")
        self.secondBtn_:addClickEventListener(handler(self, self.onSecButtonClick_))

        local label = self.secondBtn_:getTitleRenderer()
        label:enableOutline(cc.c4b(0xff,0xff,0xd8,100), 2)
    if showFirstBtn then
        self.firstBtn_ = ccui.Button:create(gamehallshell_res_path.."common/new_common_tip_btn_norBg.png",gamehallshell_res_path.."common/new_common_tip_btn_norBg.png")
            :addTo(self)
        self.firstBtn_:setScale9Enabled(false)
        self.firstBtn_:setTitleText(self.firstBtnText_)
        self.firstBtn_:setTitleFontSize(32)
        self.firstBtn_:setTitleColor(cc.c3b(0x2c,0x23,0x1f))
        :setTitleFontName(gamehallshell_res_path.."fonts/FZHei-B01S.TTF")
        self.firstBtn_:addClickEventListener(handler(self, self.onFirButtonClick_))

        local label = self.firstBtn_:getTitleRenderer()
        label:enableOutline(cc.c4b(0xff,0xff,0xd8,100), 2)
        buttonWidth = (dialogWidth - 3 * PADDING) * 0.5 - 10
        self.firstBtn_:size(buttonWidth, BTN_HEIGHT):pos(-(PADDING + buttonWidth) * 0.5, -dialogHeight * 0.5 + PADDING*0.2 + BTN_HEIGHT * 0.5)
        self.secondBtn_:size(buttonWidth, BTN_HEIGHT):pos((PADDING + buttonWidth) * 0.5, -dialogHeight * 0.5 + PADDING*0.2 + BTN_HEIGHT * 0.5)
    else
        buttonWidth = 280
	    self.secondBtn_:pos(0, -dialogHeight * 0.5 + PADDING*0.2 + BTN_HEIGHT * 0.5)
    end
end


function Dialog:addCloseBtn()
    if not self.closeBtn_ then
        game.ui.ColorButton.new(gamehallshell_res_path.."common/common_panel_close_btn2.png")
        :onClick(handler(self,self.onClose))
        :addTo(self,9)
        :pos(self.__width * 0.5-10, self.__height * 0.5-74)
    end

end


function Dialog:onSecButtonClick_( ... )
    dump("Dialog:onSecButtonClick_")
    if self.callback_ then
        self.callback_(Dialog.SECOND_BTN_CLICK, self, self.callbackPassArgs)
    end
    -- self.callback_ = nil

    if self.hidePanel_ and not self.dontAutoHideByFirstOrSecond then
        --todo
        self:hidePanel_()
    end
end


function Dialog:onFirButtonClick_( ... )
    dump("Dialog:onFirButtonClick_")
    if self.callback_ then
        self.callback_(Dialog.FIRST_BTN_CLICK, self, self.callbackPassArgs)
    end
    -- self.callback_ = nil

    if self.hidePanel_ and not self.dontAutoHideByFirstOrSecond then
        --todo
        self:hidePanel_()
    end
end

function Dialog:show()
    self:showPanel_()
    return self
end

function Dialog:onClose()
    if self.callback_ then
        self.callback_(Dialog.CLOSE_BTN_CLICK, self, self.callbackPassArgs)
    end
    -- self.callback_ = nil
    self:hidePanel_()
end

function Dialog:showPanel_()
    self:scale(0.2)
    transition.scaleTo(self, {time = 0.2, easing = "BACKOUT", scale = 1,})
end

function Dialog:hidePanel_()
    self:removeFromParent()
end

return Dialog