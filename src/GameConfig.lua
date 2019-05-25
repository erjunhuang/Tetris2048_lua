local GameConfig = {}

GameConfig.gameVersion = "1.0.4.23"
GameConfig.gameName = "tetris2048"
GameConfig.gameId = 41000
GameConfig.gameHallTitle = ""
GameConfig.buildTime = ""
GameConfig.gameResolution = {720,1280}

GameConfig.gameVerticalScreen = 2
GameConfig.gameAutoscale = "FIXED_WIDTH_HEIGHT"


---[[每个游戏必须配置GamePath,res_Path,src_Path,CommonSrcPath,CommonResPath
GameConfig.GamePath = "tetris2048"
GameConfig.res_path = "tetris2048/res/"
GameConfig.src_path = "tetris2048.src"
GameConfig.CommonSrcPath = GameConfig.GamePath .. ".common.src"
GameConfig.CommonResPath = GameConfig.GamePath .. "/common/res/"
--]]


GameConfig.scenes = 
{
	GameScene = 41000, --场景入口
	
}


GameConfig.BGM = 
{
	GameConfig.res_path .. "audio/%s/bgm.%s",
}

GameConfig.scenesMap = 
{
	[GameConfig.scenes.GameScene] = {"GameScene",GameConfig.src_path..".GameScene"},
	
}


GameConfig.LoadGameFiles = function()
end




GameConfig.LoadCommonFiles = function()
	
end



return GameConfig