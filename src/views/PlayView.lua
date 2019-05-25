local PlayView = class("PlayView")
local GameConfig = import("..GameConfig")
local resPath = GameConfig.res_path
local CURRENT_MODULE_NAME = ...
CURRENT_MODULE_NAME = game.getPkgName(CURRENT_MODULE_NAME)

local PlayView = class(PlayView,cc.load("mvc").ViewBase)

PlayView.LRESOURCE_FILENAME = CURRENT_MODULE_NAME ..  ".PlayView_UI"

local  theHighest=6
local  theMostWide=4

local  startColorID=0
local  endColorID=6

local shapeSize = 120

local PauseDlg = import("..module.PauseDlg")
local GameOverDlg = import("..module.GameOverDlg")
function PlayView:ctor(ctx)
	PlayView.super.ctor(self)
	self:enableNodeEvents()
	self:doLayout()

	self.ctx = ctx
	self.InGame_UI  = self.resourceNode_:getChildByName("InGame_UI") 
    self.Grid5x8 = self.resourceNode_:getChildByName("Grid5x8")
    self.socreText = self.InGame_UI:getChildByName("Score"):getChildByName("ScoreBG"):getChildByName("score")
    self.highScoreText = self.InGame_UI:getChildByName("HighSocre"):getChildByName("ScoreBG"):getChildByName("highScore")
     
	local listener = cc.EventListenerKeyboard:create()
	listener:registerScriptHandler(handler(self,self.__onKeypadEvent), cc.Handler.EVENT_KEYBOARD_PRESSED )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

	self.schedulerPool = core.SchedulerPool.new()

	local PauseBtn = self.InGame_UI:getChildByName("Pause")
 	PauseBtn:setTouchEnabled(true)
 	PauseBtn:addTouchEventListener(handler(self,self.onPauseClick))

	self:initGame()
end
function PlayView:initGame( isRestart )
	 
 	self.transitionInterval = 0.7
	self.fastTransitionInterval = 0
	self.lastFall = 0
	 
	self.isInstantFall = false

	self.socre = 0
	self.hightSocre = cc.UserDefault:getInstance():getIntegerForKey("2048HightScore",0)
	self.highScoreText:setString(self.hightSocre)
	self.placeShapes = {}
	self.lianxiaoCount=0
	self.socreText:setString("0")

 	if isRestart then
		for i=0,theMostWide do
			for j=0,theHighest do
				local shape = self:getInRangeShape(i*shapeSize,j*shapeSize)
				if  shape then
					local fadeAnim = transition.sequence(
			        {	
			        	cc.FadeTo:create(0.2,0),
			        	cc.CallFunc:create(function ( ... )
			        		shape:removeFromParent()
			        	end),
			        })
			        shape:runAction(fadeAnim)

					self.gameGridcol[i*shapeSize][j*shapeSize]=nil
				end
			end
		end
 	else
 		self.gameGridcol = {}
		for i=0,theMostWide do
			self.gameGridcol[i*shapeSize] = {}
			for j=0,theHighest do
				self.gameGridcol[i*shapeSize][j*shapeSize]=nil
			end
		end
 	end
	 
	self:startUpdate()
	self:initShape()
end

function PlayView:startUpdate( ... )
	self:onUpdate(handler(self,self.onUpdatexx))
	self.isUpdate = true
end

function PlayView:stopUpdate( ... )
	self.isUpdate = false
	self:unscheduleUpdate()
	self.schedulerPool:clearAll()
end

function PlayView:InsideBorder( x,y )
	return x>=0 and x <=theMostWide*shapeSize and y>=0 and y<= theHighest*shapeSize
end
function PlayView:IsValidGridPosition(currentShape)
	local posX,posY = currentShape:getPosition()
	if self:InsideBorder(posX,posY)==false then
		return false
	end
	 
	if self.gameGridcol[posX]~=nil and self.gameGridcol[posX][posY]~=nil and self.gameGridcol[posX][posY] ~= currentShape then
		return false
	end
	return true
end

function PlayView:MoveHorizontal(x,y)
	if self.currentShape==nil then return end

	local deltaMovement = x*shapeSize
	local posX,posY = self.currentShape:getPosition()
	self.currentShape:setPosition(posX+deltaMovement,posY)

	if self:IsValidGridPosition(self.currentShape) then
		self:UpdateGrid(self.currentShape)
	else
		local m_posX,m_posY = self.currentShape:getPosition()
		self.currentShape:setPosition(m_posX-deltaMovement,m_posY)
	end
end

function PlayView:InstantiateBlock()
	math.randomseed(os.time())
	local idColor = math.random(startColorID,endColorID)
	 
	local node=cc.Node:create()
	node:addTo(self.Grid5x8)
	node:setAnchorPoint(0,0)
	node:setPosition(2*shapeSize, 6*shapeSize)
	node:setOpacity(0)
	node:setCascadeOpacityEnabled(true)
	node.idColor = idColor
 	node.isPlaceShape = false

	local temp = ccui.ImageView:create()
    temp:ignoreContentAdaptWithSize(false)
	temp:loadTexture(resPath.."nums/2.png",0)
	temp:setPosition(shapeSize/2,shapeSize/2)
	temp:setAnchorPoint(0.5,0.5)
	temp:setSize({width = shapeSize, height = shapeSize})
	temp:addTo(node)
 	temp:setName("block")
 	temp:setCascadeOpacityEnabled(true)

	local tempSize = temp:getContentSize()

	local numTxt = ccui.Text:create()
	numTxt:ignoreContentAdaptWithSize(true)
	numTxt:setTextAreaSize({width = 0, height = 0})
	numTxt:setFontName("tetris2048/res/Font/fangzheng.ttf")
	numTxt:setFontSize(40)
	numTxt:setString(2)
	numTxt:setAnchorPoint(0.5,0.5)
	numTxt:addTo(temp)
	numTxt:setName("numText")
	numTxt:setCascadeOpacityEnabled(true)

	numTxt:setPosition(tempSize.width/2,tempSize.height/2)

	self:UpdateCurrentShape(node)

	local fadeAnim = transition.sequence(
    {	
    	cc.FadeTo:create(0.3,255)
    })
    node:runAction(fadeAnim)


	return node
end

function PlayView:getShowText( num )
	local showText=2 
	for i=1,num do
		showText=showText*2
	end
	return showText
end
function PlayView:UpdateCurrentShape( temp)
	local showText = self:getShowText(temp.idColor)
	
	self.socre = self.socre+showText

	if self.socre>self.hightSocre then
		cc.UserDefault:getInstance():setIntegerForKey("2048HightScore",self.socre)
	end

	temp.idColor = math.floor(temp.idColor % 13)

	showText = self:getShowText(temp.idColor)
	temp:getChildByName("block"):loadTexture(resPath.."nums/"..showText..".png",0)
 	local numTxt=temp:getChildByName("block"):getChildByName("numText")
	numTxt:setString(showText)

	if showText== 16 then
		numTxt:setColor(cc.c3b(209,179,143))
	else
		numTxt:setColor(cc.c3b(255,243,252))
	end

end

function PlayView:UpdateSocre( temp )
	self.socreText:setString(tostring(self.socre))

	if self.socre>self.hightSocre then
		self.highScoreText:setString(self.socre)
	end
end

function PlayView:initShape()

	for i=0,theMostWide do
		for j=0,theHighest do
			local shape = self:getInRangeShape(i*shapeSize,j*shapeSize)
			if shape~=nil then 
				shape.isPlaceShape = false
			end
		end
	end

	self.lianxiaoCount=0 
	self.currentShape = self:InstantiateBlock()
	if self:IsValidGridPosition(self.currentShape) then
		 self:UpdateGrid(self.currentShape)
	else
		print("游戏结束")
		self:stopUpdate()
		self.currentShape:removeFromParent()
		self.currentShape = nil
		GameOverDlg.new(self):showPanel_(true,true,false)
	end
end

function PlayView:UpdateGrid( shape )
	local m_posX,m_posY = shape:getPosition()
	for i=0,theMostWide do
		for j=0,theHighest do
			if self.gameGridcol[i*shapeSize]~=nil and self.gameGridcol[i*shapeSize][j*shapeSize]~=nil 
				and self.gameGridcol[i*shapeSize][j*shapeSize]==shape then
				self.gameGridcol[i*shapeSize][j*shapeSize] = nil
			end
		end
	end

	self.gameGridcol[m_posX][m_posY] = shape
end

local scale = 100
local time = 0
function PlayView:sign( value )
	-- body
	if value>=0 then
		return 1
	else
		return -1
	end
end
function PlayView:onUpdatexx(deltaTime)
	self.deltaTime = deltaTime
	if self.currentShape==nil then return end

	time = time+1*deltaTime
	local scaleX = math.abs(math.sin(time)*0.1)+0.9
	local scaleY = math.abs(math.cos(time)*0.1)+0.9
	
	self.currentShape:getChildByName("block"):setScaleX(scaleX)
	self.currentShape:getChildByName("block"):setScaleY(scaleY)

	self.lastFall = self.lastFall+deltaTime
	if self.lastFall>=self.transitionInterval then
		local posX,posY = self.currentShape:getPosition()
		self.currentShape:setPosition(posX, posY-shapeSize)

		local m_posX,m_posY = self.currentShape:getPosition()
		if self:IsValidGridPosition(self.currentShape) then
			if self.isInstantFall==false then
				-- 播放下落声音
				game.SoundManager:playSound("Drop")
			end
			self:UpdateGrid(self.currentShape)
		else
			self.currentShape:setPosition(m_posX,m_posY+shapeSize)
			self:PlaceShape(self.currentShape)

			self.transitionInterval = 1
			self.isInstantFall = false
		end

		self.lastFall = 0
	end
end


function PlayView:PlaceShape( currentShape )
	if self.currentShape then
		local block = self.currentShape:getChildByName("block")
		local scaleAnim = transition.sequence(
        {	
        	cc.ScaleTo:create(0.5,1)
        })
        block:runAction(scaleAnim)
        self.currentShape = nil 
	end
	 

	for k,v in pairs(self.placeShapes) do
		if currentShape == v then
			table.remove( self.placeShapes, k )
		end
	end
	local  shapes = self:FindNearShapesBySameIdColor(currentShape)
	if #shapes>0 then
		table.insert( self.placeShapes, currentShape )
	 	local shapesCount = #shapes
		for _,shape in pairs(shapes) do

		 	local m_posX,m_posY = shape:getPosition()
		 	local targetPos = cc.p(currentShape:getPositionX(),currentShape:getPositionY())


	 	    local moveAnim = transition.sequence(
	        {	
	        	cc.MoveTo:create(0.1,targetPos),
	        	cc.CallFunc:create(function ( ... )

	        		for i=#self.placeShapes,1,-1 do
					 	 if self.placeShapes[i]==shape then
					 	 	table.remove( self.placeShapes, i )
					 	 end
					end

	        		shape:removeFromParent()
	        		self.gameGridcol[m_posX][m_posY] = nil
					currentShape.idColor=currentShape.idColor+1
					self.lianxiaoCount = self.lianxiaoCount+1
					self:UpdateCurrentShape(currentShape)

					-- for k,v in pairs(currentShape.idColor) do
					for i=1,currentShape.idColor do
						local fly_coin = ccui.ImageView:create()
					    fly_coin:ignoreContentAdaptWithSize(true)
						fly_coin:loadTexture(resPath.."other/fly_coin.png",0)
						fly_coin:setAnchorPoint(0,0)
						fly_coin:addTo(self)
						fly_coin:setScale(1)

						local fly_coinPos = self.Grid5x8:convertToWorldSpace(cc.p(currentShape:getPositionX(),currentShape:getPositionY()))
						fly_coin:setPosition(fly_coinPos)

						local socrePos = self.InGame_UI:convertToWorldSpace(cc.p(self.socreText:getPositionX(),self.socreText:getPositionY()))


						local bezierOffsetX,bezierOffsetY = math.random(-500,500),math.random(-500,500)
						local bezier = {
					        fly_coinPos,
					        cc.p((socrePos.x+fly_coinPos.x)/2+bezierOffsetX, (socrePos.y+fly_coinPos.y)/2+bezierOffsetY),
					        socrePos
					    }

						local moveAnim = transition.sequence(
				        {	
				        	cc.BezierTo:create(0.7, bezier),
				        	-- cc.MoveTo:create(0.5,socrePos),
				        	cc.CallFunc:create(function ( ... )
				        		if i == currentShape.idColor then
				        			self:UpdateSocre(currentShape)
				        		end
				        	end),
				        	cc.FadeTo:create(0.2,0),
				        	cc.CallFunc:create(function ( ... )
				        		fly_coin:removeFromParent()
				        		if i == currentShape.idColor then
				        			game.SoundManager:playSound("moneyfly")
				        		end
				        	end),
				        })
				        fly_coin:runAction(moveAnim)
					end

			        game.SoundManager:playSound("Lineclear")
	        		shapesCount = shapesCount-1
	        		if shapesCount<=0 then
	        			self:DownBlock(currentShape)
	        		end
	        	end)
	        })
	        shape:runAction(moveAnim)
		 end


		-- self.schedulerPool:delayCall(function () 
		-- end,0.3)
		 
	else
		-- if #self.placeShapes>0 then
			-- for i=#self.placeShapes,1,-1 do
			--  	 if self.placeShapes[i]~=nil then
			--  	 	self:PlaceShape(self.placeShapes[i])
			--  	 else
			--  	 	table.remove( self.placeShapes, i )
			--  	 end
			--  end

			for i=0,theMostWide do
				for j=0,theHighest do
					local shape = self:getInRangeShape(i*shapeSize,j*shapeSize)
					if shape~=nil and shape.isPlaceShape==false and shape~=currentShape then 
						shape.isPlaceShape = true
						self:PlaceShape(shape)
						return
					end
				end
			end
		-- else
			if self.lianxiaoCount>=2 then
				local lianxiaoNum = "good"
				if self.lianxiaoCount==2 then
					lianxiaoNum = "good"
					game.SoundManager:playSound("good")
				elseif self.lianxiaoCount>=3 and self.lianxiaoCount<=4 then
					lianxiaoNum = "great"
					game.SoundManager:playSound("great")
				else
					lianxiaoNum = "excellent"
					game.SoundManager:playSound("excellent")
				end
				local lianxiao = ccui.ImageView:create()
			    lianxiao:ignoreContentAdaptWithSize(true)
				lianxiao:loadTexture(resPath.."other/"..lianxiaoNum..".png",0)
				lianxiao:setPosition(display.width/2, display.height/2)
				lianxiao:setAnchorPoint(0.5,0.5)
				lianxiao:addTo(self)
				lianxiao:setScale(0)

				local scaleAnim = transition.sequence(
		        {	
		        	cc.ScaleTo:create(0.2,1.2),
	    			cc.ScaleTo:create(0.2, 1),
	    			cc.DelayTime:create(0.1),
	    			cc.FadeTo:create(0.2, 0),
		        	cc.CallFunc:create(function ( ... )
		        		lianxiao:removeFromParent()
		        		self:initShape()
		        	end)
		        })
		        lianxiao:runAction(scaleAnim)
			else
				self:initShape()
			end
		-- end
	end
end

function PlayView:DownBlock( shape )
	for i=0,theMostWide do
		for j=0,theHighest do
			local shape = self:getInRangeShape(i*shapeSize,j*shapeSize)
			if shape==nil then 
				for k=j+1,theHighest do
					local topShape = self:getInRangeShape(i*shapeSize,k*shapeSize)
					local topNextShape = self:getInRangeShape(i*shapeSize,(k-1)*shapeSize)
					if topShape~=nil and topNextShape==nil  then
						self.gameGridcol[i*shapeSize][(k-1)*shapeSize] = topShape
						self.gameGridcol[i*shapeSize][k*shapeSize] = nil

						-- topShape:setPosition(i*shapeSize,(k-1)*shapeSize)
						table.insert( self.placeShapes, topShape )
						
						local moveAnim = transition.sequence(
				        {	
				        	cc.MoveTo:create(0.1,cc.p(i*shapeSize,(k-1)*shapeSize)),
				        	cc.CallFunc:create(function ( ... )
				        	end)
				        })
				        topShape:runAction(moveAnim)
					end
				end
			end
		end
	end

	self.schedulerPool:delayCall(function () 
		self:PlaceShape(shape)
	end,0.11)
end
function PlayView:getInRangeShape ( x,y )
    if (x<0 or x>theMostWide*shapeSize) or ( y<0 or y>theHighest*shapeSize ) then
    	return nil
    end
	return self.gameGridcol[x][y]
end
function PlayView:FindNearShapesBySameIdColor ( currentShape )
	local m_posX,m_posY = currentShape:getPosition()
		 
	local shapes = {}
	 
	local leftShape = self:getInRangeShape(m_posX-shapeSize,m_posY)  
	local rightShape = self:getInRangeShape(m_posX+shapeSize,m_posY)  
	local topShape = self:getInRangeShape(m_posX,m_posY+shapeSize)  
	local bottomShape = self:getInRangeShape(m_posX,m_posY-shapeSize)  

	if leftShape~=nil and  currentShape.idColor ==  leftShape.idColor then
		table.insert( shapes, leftShape )
	end
	if rightShape~=nil and currentShape.idColor ==  rightShape.idColor then
		table.insert( shapes, rightShape )
	end
	if topShape~=nil and currentShape.idColor ==  topShape.idColor then
		table.insert( shapes, topShape )
	end
	if bottomShape~=nil and currentShape.idColor ==  bottomShape.idColor then
		table.insert( shapes, bottomShape )
	end

	return shapes
end

function PlayView:InstantFall( ... )
	self.transitionInterval = self.fastTransitionInterval
	self.isInstantFall = true
end

function PlayView:onPauseClick( sender, eventType )
	self.ctx.gameController:onBtnTouch(sender,eventType,function ( ... )
		self:stopUpdate()
		PauseDlg.new(self):showPanel_(true,true,false)
	end)
end


function PlayView:playShowAnim( ... )
	-- body
end


function PlayView:playHideAnim( ... )
	self:removeFromParent()
end


function PlayView:__onKeypadEvent(keyCode, event)
	if keyCode == cc.KeyCode.KEY_LEFT_ARROW or keyCode == cc.KeyCode.KEY_A then
		self:MoveHorizontal(-1,0)
    elseif keyCode == cc.KeyCode.KEY_RIGHT_ARROW or keyCode == cc.KeyCode.KEY_D then
    	self:MoveHorizontal(1,0)
    elseif keyCode == cc.KeyCode.KEY_UP_ARROW or keyCode == cc.KeyCode.KEY_W then
   	elseif keyCode == cc.KeyCode.KEY_DOWN_ARROW or keyCode == cc.KeyCode.KEY_S then
   		self:InstantFall()
    end
end


-- cc.EventCode =
-- {
--     BEGAN = 0,
--     MOVED = 1,
--     ENDED = 2,
--     CANCELLED = 3,
-- }

local _startPressPosition 
local _endPressPosition 
local _currentSwipe 
local _buttonDownPhaseStart
local isLongMove 
local OneScreenMove = 6
function PlayView:onTouch(touch,event)
	if not self.isUpdate then return end

	local location =  touch:getLocation()
	local eventCode = event:getEventCode()
	if eventCode == cc.EventCode.BEGAN then
		-- print("移动X="..location.x.." Y="..location.y)
		_startPressPosition = location
		_endPressPosition = location
		_buttonDownPhaseStart = 0
		_buttonDownPhaseStart = _buttonDownPhaseStart+self.deltaTime
		isLongMove = false
	elseif  eventCode == cc.EventCode.MOVED then
		_buttonDownPhaseStart = _buttonDownPhaseStart+self.deltaTime
		_endPressPosition = location
		_currentSwipe = cc.p(_endPressPosition.x -_startPressPosition.x, _endPressPosition.y -_startPressPosition.y)

		if(math.abs(_currentSwipe.x)>display.width/OneScreenMove) then
			isLongMove = true
			_startPressPosition = location
			_currentSwipe = cc.pNormalize(_currentSwipe)
			-- _currentSwipe.normalize()
			if(_currentSwipe.x<0 and _currentSwipe.y> -0.5 and _currentSwipe.y<0.5) then
				print("左")
				self:MoveHorizontal(-1,0)
			end
			if(_currentSwipe.x>0 and _currentSwipe.y> -0.5 and _currentSwipe.y<0.5) then
				print("右")
				self:MoveHorizontal(1,0)
			end
		end
	else
		if eventCode == cc.EventCode.ENDED or eventCode == cc.EventCode.CANCELLED then
			local endTime = _buttonDownPhaseStart+self.deltaTime
			if endTime - _buttonDownPhaseStart >0 then
				_endPressPosition = location
				_currentSwipe = cc.p(_endPressPosition.x -_startPressPosition.x, _endPressPosition.y -_startPressPosition.y)
				-- _currentSwipe.normalize()
				_currentSwipe = cc.pNormalize(_currentSwipe)
				if isLongMove == false then 
					if(_currentSwipe.x<0 and _currentSwipe.y> -0.5 and _currentSwipe.y<0.5) then
						print("左")
						self:MoveHorizontal(-1,0)
					end
					if(_currentSwipe.x>0 and _currentSwipe.y> -0.5 and _currentSwipe.y<0.5) then
						print("右")
						self:MoveHorizontal(1,0)
					end
				end

				if(_currentSwipe.y<0 and _currentSwipe.x> -0.5 and _currentSwipe.x<0.5) then
						print("下")
						self:InstantFall()
				end
			end
		end
	end
end

function PlayView:onCleanup()
	self:stopUpdate()
end

return PlayView