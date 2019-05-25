--- 用于获取此gamehallshell的游戏的GameConfig（因为core是被添加到索引路径的，所以通过相对路径是不一定能找到该GameConfig的）
local GameHallShellConfig = {}

GameHallShellConfig.GAME_PACKAGE_PATH = "tetris2048"
GameHallShellConfig.GAME_CONFIG_PATH = GameHallShellConfig.GAME_PACKAGE_PATH .. ".src.GameConfig"

return GameHallShellConfig