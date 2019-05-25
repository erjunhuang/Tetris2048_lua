
local TestUtil = class("TestUtil")

function TestUtil:ctor() 
    -- simu login reward switch
    self.simuLogrinRewardJust = false

    -- 语言包比较
    --self.compareLangResource()

    self.simuDevice = "android"
end

-- simu login reward data
function TestUtil.simuLoginReward() 
    -- nk.userData.loginReward = {ret=1, chips=5000, data={{tag=0, chips=3000, type="base", id=0, days=2}, {tag=0, chips=2000, type="fb", id=2}}, 
    --     baseReward={1500, 3000, 5000, 8000, 10000, 12000}}
    nk.userData.loginReward = {
        ["addMoney"] = 12000,
        ["day"]      = 2,
        ["days"] = 
        {
            [1] = 10000,
            [2] = 12000,
            [3] = 24000,
            [4] = 36000,
            [5] = 48000,
            [6] = 60000
        },
        ["money"]    = 12000,
        ["ret"]      = 1
     }
end

function TestUtil.compareLangResource()
    local cn = require("lang")
    local th = require("lang_th")
    local vn = require("lang_vn")
    local en = require("lang_en")

    print("======= th not exists ========")
    core.LangUtil.compareResource(cn, th, "L")
    print("======= cn not exists ========")
    core.LangUtil.compareResource(th, cn, "L")
    print("=========== end  =============")

    print("======= vn not exists ========")
    core.LangUtil.compareResource(cn, vn, "L")
    print("======= cn not exists ========")
    core.LangUtil.compareResource(vn, cn, "L")
    print("=========== end  =============")

    print("======= en not exists ========")
    core.LangUtil.compareResource(cn, en, "L")
    print("======= cn not exists ========")
    core.LangUtil.compareResource(en, cn, "L")
    print("=========== end  =============")
end

return TestUtil