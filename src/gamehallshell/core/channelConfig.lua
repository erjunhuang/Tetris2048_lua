
local channel = require("channel")

local ChannelConfig = 
{
	------------------------------------------------------牌友---------------------------------------------------------------------
	[10] = 
	{
		["device"] = "android",
		["appid"] = 10,
		["name"] = "牌友棋牌",
		["lang"] = "zh_CN",
		["wxAppid"] = "wxdb92011c4d13b2f7",
		["localServerUrl"] = "http://192.168.1.158/game/game/first.php",
		["localPublishServerUrl"] = "http://192.168.1.158/gamerelease/game/first.php",
		["onlineServerUrl"] = 
		{
			"http://qg.ode.cn/game/first.php",
			"http://qgbk.ode.cn/game/first.php",
			"http://qgios.ode.cn/game/first.php",
		},
		["onlineTestServerUrl"] = "http://qgtest.ode.cn/game/first.php",
		["buglyAppid"] = "875afd10ab",
		["gvoiceInfo"] = {appID = "1721988055",appKey="49283384a6722e513e2b54d7f869bc79"},
		["amapAppKey"] = "bd6e9c085d8dddce59da71187dbabeb8",
		["xlAppid"] = "R10Z4KeesxekETT0",
		["cnChat"] = {appId = "cn74479dbb0a434d",appSecret = "72fe6962d65f496a824353971c7183c"},
		["wxShareAppids"] = 
		{
			{name="竹报平安",appid="wx2de3e82d62570ab4",appSec="d8f44b60d2a71eeb28548df5687d008c"},
			{name="凤凰来仪",appid="wx8e0bb7d7b3382d6b",appSec="2df1de1da8f29732b73a60be432aad63"},
			{name="景星庆云",appid="wx5765e95cfddd897f",appSec="b8386b3722611d5b0822fa64ca835aba"},
			{name="三阳开泰",appid="wx5e65cc8ab53acbc1",appSec="e3b728bb7f0e82b34f9c5cd27e1d38b0"},
			{name="福地洞天",appid="wx421435a98ca1e31c",appSec="6ead49cf51bbe2f947ca30c7181b55ab"},
			{name="迎吉",appid="wxa297b1fc6af9b0d2",appSec="831dbbaa593910947bd22a9f90f871a5"},
			{name="赵公元帅",appid="wx9b9ce4a5d0c72ec1",appSec="9668982aacdc09f466061973687c49f5"},
			{name="接天禄",appid="wx8f9f2ab62248db38",appSec="5727d1a165c8082e7c7d6a2b7405098e"},
			
		},
		["hbpayMini"] = {name = "海贝小程序",wxappid = "wx54f060d241817a38",miniappid = "gh_5464122359e4"}

	},
	[1010] = 
	{
		["device"] = "ios",
		["appid"] = 1010,
		["name"] = "牌友棋牌",
		["lang"] = "zh_CN",
		["wxAppid"] = "wxdb92011c4d13b2f7",
		["localServerUrl"] = "http://192.168.1.158/game/game/first.php",
		["localPublishServerUrl"] = "http://192.168.1.158/gamerelease/game/first.php",
		["onlineServerUrl"] = 
		{
			"http://qg.ode.cn/game/first.php",
			"http://qgbk.ode.cn/game/first.php",
			"http://qgios.ode.cn/game/first.php",
		},
		-- ["onlineServerUrl"] = {"http://qgios.ode.cn/game/first.php"},
		["onlineTestServerUrl"] = "http://qgtest.ode.cn/game/first.php",
		["gvoiceInfo"] = {appID = "1721988055",appKey="49283384a6722e513e2b54d7f869bc79"},
		["buglyAppid"] = "2e8553130d",
		["amapAppKey"] = "ddf8510b6af671548491f41bec01d12a",
		["xlAppid"] = "R10Z4KeesxekETT0",
		["cnChat"] = {appId = "cn74479dbb0a434d",appSecret = "72fe6962d65f496a824353971c7183c"},
		["newPkgCfg"]=
		{
			bundleId = "org.ode.pyqp",
			wxAppid = "wxa6c82066d8908116",
			amapAppKey = "85704fc7f23ce5b5aa7cdc819853fcc2",
			isnew = 1,
		},
		["wxShareAppids"] = 
		{
			{name="竹报平安",appid="wx2de3e82d62570ab4",appSec="d8f44b60d2a71eeb28548df5687d008c"},
			{name="凤凰来仪",appid="wx8e0bb7d7b3382d6b",appSec="2df1de1da8f29732b73a60be432aad63"},
			{name="景星庆云",appid="wx5765e95cfddd897f",appSec="b8386b3722611d5b0822fa64ca835aba"},
			{name="三阳开泰",appid="wx5e65cc8ab53acbc1",appSec="e3b728bb7f0e82b34f9c5cd27e1d38b0"},
			{name="福地洞天",appid="wx421435a98ca1e31c",appSec="6ead49cf51bbe2f947ca30c7181b55ab"},
			{name="迎吉",appid="wxa297b1fc6af9b0d2",appSec="831dbbaa593910947bd22a9f90f871a5"},
			{name="赵公元帅",appid="wx9b9ce4a5d0c72ec1",appSec="9668982aacdc09f466061973687c49f5"},
			{name="接天禄",appid="wx8f9f2ab62248db38",appSec="5727d1a165c8082e7c7d6a2b7405098e"},

		}	
	},
	[2010] = 
	{
		["device"] = "ios",
		["appid"] = 2010,
		["name"] = "牌友棋牌",
		["lang"] = "zh_CN",
		["wxAppid"] = "wxdb92011c4d13b2f7",
		["localServerUrl"] = "http://192.168.1.158/game/game/first.php",
		["localPublishServerUrl"] = "http://192.168.1.158/gamerelease/game/first.php",
		["onlineServerUrl"] = {"http://qg.ode.cn/game/first.php","http://qgios.ode.cn/game/first.php"},
		["onlineTestServerUrl"] = "http://qgtest.ode.cn/game/first.php",
		["gvoiceInfo"] = {appID = "1721988055",appKey="49283384a6722e513e2b54d7f869bc79"},
		["buglyAppid"] = "2e8553130d",
		["amapAppKey"] = "ddf8510b6af671548491f41bec01d12a",
		["xlAppid"] = "R10Z4KeesxekETT0",
		["cnChat"] = {appId = "cn74479dbb0a434d",appSecret = "72fe6962d65f496a824353971c7183c"}
	},
}

local targetPlatform = cc.Application:getInstance():getTargetPlatform()
local platform = "windows"

if targetPlatform == 3 then
	platform = "android"
elseif targetPlatform == 4 or targetPlatform == 5 then
	platform = "ios"
end

---------------- android start --------------------
local function checkJavaArguments(args, sig)
    if type(args) ~= "table" then args = {} end
    if sig then return args, sig end

    sig = {"("}
    for i, v in ipairs(args) do
        local t = type(v)
        if t == "number" then
            sig[#sig + 1] = "F"
        elseif t == "boolean" then
            sig[#sig + 1] = "Z"
        elseif t == "function" then
            sig[#sig + 1] = "I"
        else
            sig[#sig + 1] = "Ljava/lang/String;"
        end
    end
    sig[#sig + 1] = ")V"

    return args, table.concat(sig)
end

local function callJavaStaticMethod(className, methodName, args, sig)
    local args, sig = checkJavaArguments(args, sig)
    return LuaJavaBridge.callStaticMethod(className, methodName, args, sig)
end

-- 读安卓
local function readAndroidAppInfos()
	local infos = {}
	if platform == "android" then
		local ok, ret = callJavaStaticMethod("org/ode/cocoslib/core/functions/ManifestFunction", 
	        "getManifestInformations", {}, "()Ljava/lang/String;")
		if ok then
			local tmp = json.decode(ret)
	        if tmp and type(tmp) == "table" then
	        	-- String packageName
			    -- int versionCode
			    -- String versionName
			    -- long lastUpdateTime
			    -- String appName
	            infos = tmp
	        end
		end
	end
	return infos
end
---------------- android end --------------------

---------------- ios start --------------------
function callIOSStaticMethod(className, methodName, args)
    local ok, ret = LuaObjcBridge.callStaticMethod(className, methodName, args)
    if not ok then
        local msg = string.format("luaoc.callStaticMethod(\"%s\", \"%s\", \"%s\") - error: [%s] ",
                className, methodName, tostring(args), tostring(ret))
        if ret == -1 then
            print(msg .. "INVALID PARAMETERS")
        elseif ret == -2 then
            print(msg .. "CLASS NOT FOUND")
        elseif ret == -3 then
            print(msg .. "METHOD NOT FOUND")
        elseif ret == -4 then
            print(msg .. "EXCEPTION OCCURRED")
        elseif ret == -5 then
            print(msg .. "INVALID METHOD SIGNATURE")
        else
            print(msg .. "UNKNOWN")
        end
    end
    return ok, ret
end

-- 读iOS
function readIOSAppInfos()
	local infos = {}
	if platform == "ios" then
		local ok, ret = callIOSStaticMethod (
	        "LuaOCBridge",
	        "getManifestInformations", nil)
		if ok then
			local tmp = json.decode(ret)
			if tmp and type(tmp) == "table" then
				-- bundleId
				-- shortVersion   --1.0.0
				-- appName
				-- buildVersion   --1.0.0.xxxx
				infos = tmp
			end
		end
	end
	return infos
end
---------------- ios end --------------------

local function updateChannelConfig(originalTab, updateTable,excludeKeys)

	if not originalTab or not updateTable then return end
	excludeKeys = excludeKeys or {}
	for k, v in pairs(updateTable) do
		if excludeKeys[k] ~= true then
			originalTab[k] = v
		end
    end
end

if platform == "ios" then
	local channelInfo = ChannelConfig[channel];
	if channelInfo and type(channelInfo.newPkgCfg) == "table" then
		local iosAppInfos = readIOSAppInfos()
		if iosAppInfos.bundleId == channelInfo.newPkgCfg.bundleId then
			local excludeKeys = {["bundleId"] = true}
			local newPkgCfg = channelInfo.newPkgCfg
			channelInfo.newPkgCfg = nil  --置空不需要了
			updateChannelConfig(channelInfo, newPkgCfg,excludeKeys)
		end
	end

elseif platform == "android" then
	
else

end

return ChannelConfig[channel]