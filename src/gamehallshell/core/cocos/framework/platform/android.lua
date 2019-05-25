

luaj = require("cocos.cocos2d.luaj")

function io.exists(path)
    return cc.FileUtils:getInstance():isFileExist(path)
end

function io.readfile(path)
    return cc.FileUtils:getInstance():getDataFromFile(path)
end

