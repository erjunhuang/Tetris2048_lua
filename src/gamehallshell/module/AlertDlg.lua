local GameConfig = require(require("GameHallShellConfig").GAME_CONFIG_PATH)
local gamehallshell_res_path = GameConfig.res_path.."gamehallshell/"


local AlertDlg = class("AlertDlg", function()
        return display.newNode()
    end)




function AlertDlg:ctor(time)
        self:ShowUI(self.msg,time)
       -- self:scale(0.2)
       -- transition.fadeIn(self, {time =0.1, easing = "BACKOUT", scale = 1})
end
--提示框
function AlertDlg:ShowUI(msg,time)
  
  local isSuccess, gameConfig = pcall(function ()
  
  local node = display.newNode()
  :addTo(self)
  
  local TipMsg = display.newTTFLabel({text=msg, font=gamehallshell_res_path.."fonts/FZHei-B01S.TTF",color = cc.c3b(255,255,255), size = 25, align = cc.TEXT_ALIGNMENT_CENTER,cc.size(500, 100)})
  :addTo(node,1)
  :pos(0,0)

  local sprite  = display.newScale9Sprite(gamehallshell_res_path.."common/common_alert_bg.png",0, 0, cc.size(350+TipMsg:getContentSize().width, 52))
  :addTo(node,0)
  :pos(0,0)

  local action = transition.sequence({
    cc.MoveBy:create(time or 1, cc.p(0, display.cy/2)),
    cc.DelayTime:create(1),
    cc.MoveBy:create(0.5, cc.p(0, display.cy/2 + 100)),
    cc.CallFunc:create(function ( ... )
      if self.callback_ then
        self.callback_()
      end
    end),
    cc.RemoveSelf:create(),
  })

  self:runAction(action)


  if posx~=nil and posy~=nil then
    TipMsg:pos(posx, posy)
    sprite:pos(posx, posy)
  end

  end)
  if not isSuccess then
     print("异常")
     return nil
  end
end

function AlertDlg:ShowTip(params,callback)
  self.callback_ = callback
  local msg = params.msg or ""
  local time = params.time or 1

   self.time=params.time or 2
    self.msg=msg
   self.new(time)
   :pos(display.cx, display.cy)
   :addTo(game.runningScene,1000)

end


function AlertDlg:onClose()
  if self.callback_ then
    self.callback_()
  end
  self:removeFromParent()
  return self
end



function AlertDlg:Aniamtion(target)

 -- transition.fadeIn(target, {time = 0.4 , onComplete= function()
      transition.fadeOut(target, {time =self.time, onComplete = 
      function()
        self:onClose()
      end})
   -- end
 -- })
end

return AlertDlg