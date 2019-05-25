--
-- Author: HLF(IdaHuang@boyaa.com)
-- Date: 2016-02-16 14:53:03
--
--不进行灰化的对象特有的方法
local  DisplayUtil = {}

DisplayUtil.LIST_DONT_SHADER = {
    "getSprite",     --ProgressTimer
    "setString",     --Label
}

-- 冰冻
function DisplayUtil.setIce(node, v)
	DisplayUtil.setShader(DisplayUtil.drawIceNode, node, v)
end
-- 灰色
function DisplayUtil.setGray(node, v)
	DisplayUtil.setShader(DisplayUtil.drawGrayNode, node, v)
end
-- 高斯模糊
function DisplayUtil.setGaussian(node, params)
    params = params or {}
    local paramsFunc = function(pProgram, subNode)
        local sampleNum = pProgram:getUniformLocationForName("sampleNum");
        pProgram:setUniformLocationWith1f(sampleNum, params.sampleNum or 3.75)
        
        local radius = pProgram:getUniformLocationForName("blurRadius");
        pProgram:setUniformLocationWith1f(radius, params.radius or 4)
        
        local sz = params.size or subNode:getContentSize()
        local resolution = pProgram:getUniformLocationForName("resolution");
        pProgram:setUniformLocationWith2fv(resolution, {sz.width, sz.height}, 1)
    end
    node.paramsFunc = paramsFunc
	DisplayUtil.setShader(DisplayUtil.drawGaussianNode, node, params)
end
-- 
function DisplayUtil.setFastBlur(node, v, params)
    params = params or {}
    local paramsFunc = function(pProgram, subNode)        
        local radius = pProgram:getUniformLocationForName("radius");
        pProgram:setUniformLocationWith1f(radius, params.radius or 4)
        
        local dir = pProgram:getUniformLocationForName("dir");
        pProgram:setUniformLocationWith2fv(dir, {1, 1}, 1)

        local sz = params.size or subNode:getContentSize()
        local resolution = pProgram:getUniformLocationForName("resolution");
        pProgram:setUniformLocationWith2fv(resolution, {sz.width, sz.height}, 1)
        
    end
    node.paramsFunc = paramsFunc
    DisplayUtil.setShader(DisplayUtil.fastBlurNode, node, v)
end

function DisplayUtil.setShader(func, node, v)
	if type(node) ~= "userdata" then
        return
    end
    -- 
    if v == nil then
        v = true
    end
    -- 
    if not node.__isShader__ then
        node.__isShader__ = false
    end
    -- 
    if v == node.__isShader__ then
        return
    end
    -- 
    if v then
        if DisplayUtil.canShader(node) then
            local pProgram = node.__pProgram__ or func(node);
            local flag = pProgram:getUniformLocationForName("flag");
            pProgram:use()
            pProgram:setUniformLocationWith1i(flag,1.0) --着色器起效

            if node.paramsFunc then
                node.paramsFunc(pProgram, node)
            end

            node.__pProgram__ = pProgram
        end

        local children = node:getChildren()
        if children and children.count and children:count() > 0 then
            --遍历子对象设置
            local count = children:count();
            for i=0,count-1,1  do
                local val = tolua.cast(children:objectAtIndex(i), "CCNode")
                if DisplayUtil.canShader(val) then
                    DisplayUtil.setShader(func, val)
                end
            end
        end
    else
        DisplayUtil.removeShader(node)
    end
    node.__isShader__ = v
end
--取消着色器
function DisplayUtil.removeShader(node)
    if type(node) ~= "userdata" then
        printError("node must be a userdata")
        return
    end
    if not node.__isShader__ then
        return
    end
    if DisplayUtil.canShader(node) then
        local pProgram = node.__pProgram__;
        if pProgram then
            local flag = pProgram:getUniformLocationForName("flag");
            pProgram:use()
            pProgram:setUniformLocationWith1i(flag, 0) --恢复
        end
    end
    --children
    local children = node:getChildren()
    if children and children.count and children:count() > 0 then
        --遍历子对象设置
        local count = children:count();
        for i=0,count-1,1  do
            local val = tolua.cast(children:objectAtIndex(i), "CCNode")
            if DisplayUtil.canShader(val) then
                DisplayUtil.removeShader(val)
            end
        end
    end
    node.__isShader__ = false
end
-- 使用冰封效果着色器
function DisplayUtil.drawIceNode(node)
    local pProgram = cc.GLProgram:createWithFilenames("res/shaders/ice.vsh","res/shaders/ice.fsh")
	pProgram:addAttribute("a_position", 0) --对应vs里面的顶点坐标
	pProgram:addAttribute("a_color", 1) --对应vs里面的顶点颜色
	pProgram:addAttribute("a_texCoord", 2)--对应vs里面的顶点纹理坐标
	pProgram:link() -- 因为绑定了属性，所以需要link一下，否则vs无法识别属性
	pProgram:updateUniforms() -- 绑定了纹理贴图
	node:setGLProgram(pProgram)
	return pProgram
end
-- 使用灰色效果着色器
function DisplayUtil.drawGrayNode(node)
    local pProgram = cc.GLProgram:createWithFilenames("res/shaders/gray.vsh","res/shaders/gray.fsh")
    pProgram:addAttribute("a_position", 0) --对应vs里面的顶点坐标
    pProgram:addAttribute("a_color", 1) --对应vs里面的顶点颜色
    pProgram:addAttribute("a_texCoord", 2)--对应vs里面的顶点纹理坐标
    pProgram:link() -- 因为绑定了属性，所以需要link一下，否则vs无法识别属性
    pProgram:updateUniforms() -- 绑定了纹理贴图
    node:setGLProgram(pProgram)
    return pProgram;
end
-- 高斯模糊
function DisplayUtil.drawGaussianNode(node)
    local pProgram = cc.GLProgram:createWithFilenames("res/shaders/blur.vsh","res/shaders/blur.fsh")
    pProgram:addAttribute("a_position", 0) --对应vs里面的顶点坐标
    pProgram:addAttribute("a_color", 1) --对应vs里面的顶点颜色
    pProgram:addAttribute("a_texCoord", 2)--对应vs里面的顶点纹理坐标
    pProgram:link() -- 因为绑定了属性，所以需要link一下，否则vs无法识别属性
    pProgram:updateUniforms() -- 绑定了纹理贴图
    node:setGLProgram(pProgram)
    return pProgram;
end
-- 快速模糊
function DisplayUtil.fastBlurNode(node)
    local pProgram = cc.GLProgram:createWithFilenames("res/shaders/fasterblur.vsh","res/shaders/fasterblur.fsh")
    pProgram:addAttribute("a_position", 0) --对应vs里面的顶点坐标
    pProgram:addAttribute("a_color", 1) --对应vs里面的顶点颜色
    pProgram:addAttribute("a_texCoord", 2)--对应vs里面的顶点纹理坐标
    pProgram:link() -- 因为绑定了属性，所以需要link一下，否则vs无法识别属性
    pProgram:updateUniforms() -- 绑定了纹理贴图
    node:setGLProgram(pProgram)
    return pProgram;
end
--判断能否使用着色器
function DisplayUtil.canShader(node)
    for i,v in ipairs(DisplayUtil.LIST_DONT_SHADER) do
        if node[v] then
            return false
        end
    end
    return true
end

return DisplayUtil;