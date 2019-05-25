
require("config")
require("cocos.init")
require("core.init")

print("appentry========")
cc.exports.appconfig = require("appconfig")
require("app.App").new():run()