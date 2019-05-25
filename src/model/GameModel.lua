local logger = core.Logger.new("GameModel")


local GameModel = {}


function GameModel.new(...)
    local inst = {}
    local dataTb = {}
    local function get(table, key)
        return GameModel[key] or dataTb[key]
    end
    local function set(table, key, value)
        dataTb[key] = value
    end
    local function clear(self)
        local newdataTb = {}
        for k, v in pairs(dataTb) do
            if type(v) == "function" then
                newdataTb[k] = v
            end
        end
        dataTb = newdataTb
        return self
    end
    inst.clear = clear
    local mt = {__index = get, __newindex = set}
    setmetatable(inst, mt)
    if inst.ctor then
        inst:ctor(...)
    end
    return inst
end

function GameModel:ctor()
    print("GameModel:ctor")
end



return GameModel