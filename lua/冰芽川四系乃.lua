-- 导入必要的库
local material3 = require 'material3'
import('android.content.res.ColorStateList')
local context = material3:getContext() 
vibra = context:getSystemService(Context.VIBRATOR_SERVICE)
changan = {}
local changan = changan
local android = import('android.*')
local context = app.context
local MediaPlayer = luajava.bindClass("android.media.MediaPlayer")

local 资源基地址 = {
    "https://raw.githubusercontent.com/ThirteenSpices/ThirteenSpicesYoshino/main/资源/",
    "https://cdn.jsdelivr.net/gh/ThirteenSpices/ThirteenSpicesYoshino@main/资源/"
}

local 必要资源 = {
    {
        本地路径 = "/sdcard/四系乃/图片/Logo.png",
        文件名 = "Logo.png",
        类型 = "图片",
        最小大小 = 1700000
    },
    {
        本地路径 = "/sdcard/四系乃/图片/Back.png",
        文件名 = "Back.png", 
        类型 = "图片",
        最小大小 = 200000
    },
    {
        本地路径 = "/sdcard/四系乃/图片/SQ.png",
        文件名 = "SQ.png",
        类型 = "图片",
        最小大小 = 2000
    },
    {
        本地路径 = "/sdcard/四系乃/音效/选择进程.mp3",
        文件名 = "选择进程.mp3",
        类型 = "音效",
        最小大小 = 390000
    },
    {
        本地路径 = "/sdcard/四系乃/音效/曼波.mp3",
        文件名 = "曼波.mp3",
        类型 = "音效",
        最小大小 = 40000 
    },
    {
        本地路径 = "/sdcard/四系乃/音效/嘿.mp3",
        文件名 = "嘿.mp3",
        类型 = "音效",
        最小大小 = 200000
    }
}

-- 检查文件是否完整下载的函数
function 检查文件完整性(文件路径, 最小大小)
    最小大小 = 最小大小 or 1024 -- 默认最小1KB
    if not panduan(文件路径) then
        return false
    end
    
    local 文件信息 = io.open(文件路径, "rb")
    if not 文件信息 then
        return false
    end
    
    local 文件大小 = 文件信息:seek("end")
    文件信息:close()
    
    return 文件大小 >= 最小大小
end

-- 下载资源函数
function 下载资源(资源信息)
    local 下载成功 = false
    local 最大重试次数 = 2 -- 每个源重试2次
    local 超时时间 = 10000 -- 10秒
    
    for i, 基地址 in ipairs(资源基地址) do
        local 远程URL = 基地址 .. 资源信息.文件名
        
        for 重试次数 = 1, 最大重试次数 do
            gg.toast("尝试从源"..i.."下载("..重试次数.."/"..最大重试次数.."): "..资源信息.文件名)
            
            -- 记录开始时间
            local 开始时间 = os.time()
            
            -- 启动下载
            local 下载线程 = luajava.newThread(function()
                file.download(远程URL, 资源信息.本地路径)
            end)
            下载线程:start()
            
            -- 等待下载完成或超时
            local 已超时 = false
            while 下载线程:isAlive() do
                gg.sleep(500) -- 每0.5秒检查一次
                
                -- 检查是否超时
                if os.time() - 开始时间 > 超时时间 / 1000 then
                    已超时 = true
                    下载线程:interrupt()
                    break
                end
                
                -- 检查文件是否已完整下载
                if 检查文件完整性(资源信息.本地路径, 资源信息.最小大小) then
                    break
                end
            end
            
            -- 检查下载结果
            if 检查文件完整性(资源信息.本地路径, 资源信息.最小大小) then
                下载成功 = true
                gg.toast("下载成功: "..资源信息.文件名)
                break
            else
                if 已超时 then
                    gg.toast("下载超时: "..资源信息.文件名)
                else
                    gg.toast("下载失败: "..资源信息.文件名)
                end
                
                -- 删除可能损坏的文件
                if panduan(资源信息.本地路径) then
                    os.remove(资源信息.本地路径)
                end
            end
        end
        
        if 下载成功 then
            break
        end
    end
    
    return 下载成功
end

-- 添加资源预加载函数
function 预加载必要资源()
    gg.toast("正在检查必要资源...")
    
    -- 创建必要的目录
    os.execute("mkdir -p /sdcard/四系乃/图片")
    os.execute("mkdir -p /sdcard/四系乃/音效")
    
    local 下载数量 = 0
    local 失败文件 = {}
    
    for i, 资源信息 in ipairs(必要资源) do
        -- 检查文件完整性
        if not 检查文件完整性(资源信息.本地路径, 资源信息.最小大小) then
            gg.toast("下载"..资源信息.类型..": "..资源信息.文件名)
            local 下载结果 = 下载资源(资源信息)
            if 下载结果 then
                下载数量 = 下载数量 + 1
            else
                table.insert(失败文件, 资源信息.文件名)
            end
        end
    end
    
    if #失败文件 > 0 then
        gg.alert("以下文件下载失败，部分功能可能无法正常使用:\n" .. table.concat(失败文件, "\n"))
    end
    
    if 下载数量 > 0 then
        gg.toast(string.format("资源下载完成 (%d/6)", 下载数量))
    else
        gg.toast("所有必要资源已就绪")
    end
    
    return 下载数量, 失败文件
end

-- 播放音效函数
function playSound(filePath)
    -- 查找对应的资源信息
    local 对应资源 = nil
    for i, 资源信息 in ipairs(必要资源) do
        if 资源信息.本地路径 == filePath then
            对应资源 = 资源信息
            break
        end
    end
    
    -- 检查文件是否存在且完整
    local 最小大小 = 对应资源 and 对应资源.最小大小 or 1024
    if not 检查文件完整性(filePath, 最小大小) then
        if 对应资源 then
            gg.toast("音效文件不存在或损坏，正在下载...")
            if 下载资源(对应资源) then
                gg.toast("音效文件下载完成")
            else
                return false
            end
        else
            return false
        end
    end
    
    local mediaPlayer = luajava.new(MediaPlayer)
    local fileDescriptor = io.open(filePath, "rb")
    if fileDescriptor then
        mediaPlayer:setDataSource(filePath)
        mediaPlayer:prepare()
        mediaPlayer:start()
        fileDescriptor:close()
        mediaPlayer:setOnCompletionListener(luajava.createProxy("android.media.MediaPlayer$OnCompletionListener", {
            onCompletion = function(mp)
                mp:release()
            end
        }))
        return true
    else
        mediaPlayer:release()
        return false
    end
end

-- 文件操作函数
function write(fileName, content)
    file.write(fileName, content)
end

function panduan(rec)
    fille,err = io.open(rec)
    if fille == nil then
        return false
    else
        return true
    end
end

function read(fileName)
    f = assert(io.open(fileName, 'r'))
    content = f:read("*all")
    f:close()
    return content
end

function wtcf(lujing,neirong)
    write("/sdcard/长安/配置文件/"..lujing,neirong)
end

function rdcf(lujing)
    return read("/sdcard/长安/配置文件/"..lujing)
end

-- UI绘制工具函数
local function getBG(DrawableColor,Radius,StrokeWidth,StrokeColor)
    if type(DrawableColor)~='table' then
       DrawableColor={DrawableColor,DrawableColor} 
    end
    local jianbians = luajava.loadlayout({
        GradientDrawable,
        color = 0xff000000,
        gradientType = GradientDrawable.LINEAR_GRADIENT,
        orientation = GradientDrawable.Orientation.TOP_BOTTOM ,
    })
    jianbians:setColors(DrawableColor)
    jianbians:setStroke(StrokeWidth or 0,StrokeColor or 0xffffffff)
    if type(Radius)=='table' then
        jianbians:setCornerRadii({Radius[1],Radius[1],Radius[2],Radius[2],Radius[3],Radius[3],Radius[4],Radius[4]})
    else
        jianbians:setCornerRadius(Radius or 0)
    end
    return jianbians
end

开 = "开"
关 = "关"

function 获取图片(txt)
    txt = string.url(txt,"de")
    ntxt = string.sub(string.gsub(txt,"/","-"),-10,-1)
    if string.find(tostring(txt),"http") ~= nil then
        if panduan("/sdcard/四系乃/图片/"..ntxt) == false then
            file.download(txt,"/sdcard/四系乃/图片/"..ntxt)
        end
        txt = "/s/四系乃/图片/"..ntxt
    else
        -- 检查本地文件是否存在且完整
        local 本地路径 = "/sdcard/四系乃/图片/"..txt
        local 对应资源 = nil
        for i, 资源信息 in ipairs(必要资源) do
            if 资源信息.本地路径 == 本地路径 then
                对应资源 = 资源信息
                break
            end
        end
        
        -- 检查文件完整性
        local 最小大小 = 对应资源 and 对应资源.最小大小 or 1024
        if not 检查文件完整性(本地路径, 最小大小) then
            if 对应资源 then
                gg.toast("图片文件不存在或损坏，正在下载...")
                下载资源(对应资源)
            else
            end
        end
    end
    return luajava.getBitmapDrawable(txt)
end

function getRes(x)
    return 获取图片("/sdcard/四系乃/图片/"..x)
end

function getVerticalBG(gtvb1, gtvb3, gtvb4, gtvb5)
    if not gtvb4 then 
        gtvb4 = 0 
        gtvb5 = 0xff000000 
    end
    local jianbians = luajava.new(GradientDrawable)
    jianbians:setCornerRadius(tonumber(gtvb3))
    jianbians:setGradientType(GradientDrawable.LINEAR_GRADIENT)
    jianbians:setColors(gtvb1)
    jianbians:setStroke(tonumber(gtvb4), tonumber(gtvb5))
    return jianbians
end

function getCorner(gtvb1, gtvb3, gtvb4, gtvb5, g1, g2, g3, g4)
    if not gtvb4 then 
        gtvb4 = 0 
        gtvb5 = 0xff000000 
    end
    local jianbians = luajava.new(GradientDrawable)
    jianbians:setCornerRadius(tonumber(gtvb3))
    jianbians:setGradientType(GradientDrawable.LINEAR_GRADIENT)
    jianbians:setColors(gtvb1)
    jianbians:setStroke(tonumber(gtvb4), tonumber(gtvb5))
    jianbians:setCornerRadii({
        tonumber(g1), tonumber(g1),
        tonumber(g2), tonumber(g2),
        tonumber(g3), tonumber(g3),
        tonumber(g4), tonumber(g4)
    })
    return jianbians
end

function getHorizontalBG(gtvb1, gtvb3, gtvb4, gtvb5)
    if not gtvb4 then 
        gtvb4 = 0 
        gtvb5 = 0xff000000 
    end
    local jianbians = luajava.new(GradientDrawable)
    jianbians:setCornerRadius(tonumber(gtvb3))
    jianbians:setOrientation(GradientDrawable.Orientation.LEFT_RIGHT)
    jianbians:setGradientType(GradientDrawable.LINEAR_GRADIENT)
    jianbians:setColors(gtvb1)
    jianbians:setStroke(tonumber(gtvb4), tonumber(gtvb5))
    return jianbians
end

-- 悬浮窗管理
context = app.context
window = context:getSystemService("window")

function getLayoutParams()
    LayoutParams = WindowManager.LayoutParams
    layoutParams = luajava.new(LayoutParams)
    if (Build.VERSION.SDK_INT >= 26) then
        layoutParams.type = LayoutParams.TYPE_APPLICATION_OVERLAY
    else
        layoutParams.type = LayoutParams.TYPE_PHONE
    end
    layoutParams.format = PixelFormat.RGBA_8888
    layoutParams.flags = LayoutParams.FLAG_NOT_TOUCH_MODAL
    layoutParams.gravity = Gravity.TOP|Gravity.LEFT
    layoutParams.width = LayoutParams.WRAP_CONTENT
    layoutParams.height = LayoutParams.WRAP_CONTENT
    return layoutParams
end

slctb = getVerticalBG({0xffA0D1FF,0xffA0D1FF},10)
slcta = getHorizontalBG({0xffA0D1FF,0xffAFF},10,4,0xffffffff)

function getButtonBG()
    local selector = luajava.getStateListDrawable()
    selector:addState({
        -android.R.attr.state_pressed
    }, getVerticalBG({0x55ffffff,0x55ffffff},20,2,0xaaA0D1FF))
    selector:addState({
        android.R.attr.state_pressed
    }, getVerticalBG({0x22A0D1FF,0x22A0D1FF},20,2,0xaaA0D1FF))
    return selector
end

function getSwitchOuterBG()
    return getVerticalBG({0xffffffff,0xffffffff}, 360, 2, 0xffA0D1FF)
end

function getSwitchInnerBG()
    return getVerticalBG({0xffA0D1FF,0xffA0D1FF}, 360)
end

function getSelector()
    selector = luajava.getStateListDrawable()
    selector:addState({
        android.R.attr.state_pressed
    }, slcta)
    selector:addState({
        -android.R.attr.state_pressed
    }, slctb)
    return selector
end

hanshu = function(v, event)
    local Action = event:getAction()
    if Action == MotionEvent.ACTION_DOWN then
        isMove = false
        RawX = event:getRawX()
        RawY = event:getRawY()
        x = mainLayoutParams.x
        y = mainLayoutParams.y
    elseif Action == MotionEvent.ACTION_MOVE then
        isMove = true
        mainLayoutParams.x = tonumber(x) + (event:getRawX() - RawX)
        mainLayoutParams.y = tonumber(y) + (event:getRawY() - RawY)
        window:updateViewLayout(floatWindow, mainLayoutParams)
    end
end

-- UI组件系统
YoYoImpl = luajava.getYoYoImpl()

changan.controlRotation9 = function(control, startAngle, endAngle)
    if not control then 
        gg.toast("controlRotation9: 控件为空")
        return 
    end
    
    luajava.runUiThread(function()
        import "android.animation.ObjectAnimator"
        
        local anim = ObjectAnimator.ofFloat(control, "rotation", {
            startAngle, endAngle
        })
        anim:setDuration(400)
        anim:start()
    end)
end

changan.menu = function(sview)
    菜单页数=#sview
    当前分区={} 分区页数={}
    侧边={} 功能区={} 

    顶边={
        LinearLayout,
        layout_height='match_parent',
        layout_width='match_parent',
        orientation='vertical',
        onClick=function() end,
        onTouch=hanshu,
    }
    beij=getBG('0xFFA0D1FF',25)
    dbback=getVerticalBG({0xffffffff,0xffffffff},90)
    
    for i = 1,菜单页数 do
        分区页数[i]= #sview[i]
        table.insert(顶边,{
            FrameLayout,
            orientation='vertical',
            layout_height='wrap_content',
            layout_width='match_parent',
            gravity='center_horizontal',
            {
                TextView,
                layout_height='wrap_content',
                layout_width='match_parent',
                padding={'25dp','4dp','15dp','4dp'},
                text=sview[i]['分页名字'],
                textColor='#000000',
                textSize='10sp',
                gravity='center',
                __onCreate=function(v)
                    _ENV['ding'..i]=v
                end,
                elevation='2dp',
                layout_margin='4dp',
                background=slctb,
                onClick=function() 切换(i) end,
                onTouch=hanshu,
            },
            {ImageView,
            src=获取图片(sview[i]['侧边图标']),
            layout_gravity='center_vertical',
            layout_height='25dp',
            layout_width='25dp',
            elevation='4dp',
            },
            {LinearLayout,
                layout_marginTop='25dp',
                layout_marginLeft='35dp',
                layout_width='27dp',
                layout_height='3dp',
                __onCreate=function(v)
                    _ENV['dingbar'..i]=v
                end
            }
        })
        功能区[i]={}
        local layoutm={
                LinearLayout,
                id = "layoutm"..i,
                padding='4dp',
                layout_width = "match_parent",
                orientation = "vertical",
                gravity = "center_horizontal",
            }
            local menulayout={
                LinearLayout,
                layout_width='match_parent',
                layout_height='wrap_content',
                visibility = "gone",
                orientation = "vertical",
                id='menu'..i..1,
                
            }
            
        for k,v in pairs(sview[i]['功能配置']) do
            table.insert(menulayout,v)
        end
        
        local menulayout=luajava.loadlayout(menulayout)
        功能区[i][1]=menulayout
        table.insert(layoutm,menulayout)
        local menus={
            LinearLayout,
            layout_width = "270dp",
            layout_height = "270dp",
            visibility = "gone",
            orientation = "vertical",
            padding={'0dp','0dp','0dp','0dp'},
            background=获取图片(背景图片),
            elevation='3dp',
            {
                ScrollView,
                fillViewport = "true",
                background=getBG({0x33ffffff,0x33ffffff},{0,0,25,25}),
                gravity = "center",
                layout_width = "match_parent",
                layout_height = "match_parent",
                orientation = "horizontal",
                layoutm
            }}

        _ENV["layout"..i] = luajava.loadlayout(menus)
    end
    
    ckou = {
        LinearLayout,
        orientation='vertical',
        layout_width = "wrap_content",
        layout_height = "wrap_content",
        {--顶部栏
            FrameLayout,
            orientation = "horizontal",
            padding = "2dp",
            layout_height='wrap_content',
            elevation='3dp',
            layout_width="fill_parent",
            background=getCorner({0xffffffff,0xffffffff},20,0,0xffFFE543,25,25,0,0),
            {
                TextView,
                layout_width='match_parent',
                layout_height='match_parent',
                gravity='center',
                layout_gravity='center_vertical',
                textSize='14sp',
                textColor='#000000',
                text=标题,
            },
            {
                LinearLayout,
                layout_gravity="center_vertical|right",
                padding={"2dp","2dp","2dp","2dp"},
                layout_marginLeft='2dp',
                layout_marginRight='2dp',
                layout_marginTop='2dp',
                layout_marginBottom='2dp',
                
                layout_width = "40dp",
                layout_height = "24dp",
                gravity = "center",
                onClick = 隐藏,
                onTouch = hanshu,
{
    ImageView,
    layout_height='17dp',
    layout_width='17dp',
    src=获取图片("/sdcard/四系乃/图片/SQ.png"),
    colorFilter=0xffA0D1FF
},
                }
            }
        }
    
    for i = 1,菜单页数 do
        ckou[#ckou+1] = _ENV["layout"..i]
    end
    
    headicon=luajava.loadlayout({ImageView,
                src=获取图片(悬浮窗图标),
                layout_height="42dp",
                layout_width="42dp",
                padding='1dp',
            })

    ckou = luajava.loadlayout(ckou)
    floatWindow = {
        FrameLayout,
        id = "motion",
        elevation = "10dp",
        onTouch = hanshu,
        onClick = function() end,
        layout_width = "wrap_content",
        orientation = "vertical",
        gravity = "center_vertical",
        layout_height = "wrap_content",
        {
            LinearLayout,
            id = 'chuangk',
            visibility = 'gone',
            layout_height = 'wrap_content',
            {
                LinearLayout,
                layout_height = 'match_parent',
                layout_width = '80dp',
                onClick = function() end,
                onTouch = hanshu,
                orientation = 'vertical',
                {
                    FrameLayout,
                    id = 'canv',
                    layout_marginLeft = '19dp',
                    layout_marginTop = '10dp',
                    layout_height = "42dp",
                    layout_width = "42dp",
                    gravity = 'center',
                    onClick = 隐藏,
                    onTouch = hanshu,
                    headicon
                },
                {
                    LinearLayout,
                    layout_width='match_parent',
                    layout_weight = 1,
                    layout_height='match_parent',
                    elevation='3dp',
                    background=getBG(0xffffffff,20),
                    layout_margin='5dp',
                    onClick=function() end,
                    onTouch=hanshu,
                    顶边
                }
            },
            ckou,
        },
        {
            ImageView,
            id = "control",
            background = 获取图片(悬浮窗图标),
            layout_width = "40dp",
            layout_height = "40dp",
            onTouch = hanshu,
            onClick = 隐藏,
        }
    }
    
    totouch=luajava.loadlayout({
        LinearLayout,
        layout_height='42dp',
        layout_width='42dp',
        onClick=隐藏,
        onTouch=hanshu
    })
    
    local function invoke()
        local ok
        local RawX, RawY, x, y
        mainLayoutParams = getLayoutParams()
        floatWindow = luajava.loadlayout(floatWindow)
        
        floatWindow:setMinimumWidth(400)
        floatWindow:setMinimumHeight(400)
        
        local function invoke2()
            window:addView(floatWindow, mainLayoutParams)
            block('end')
        end

        local runnable = luajava.getRunnable(invoke2)
        local handler = luajava.getHandler()
        handler:post(runnable)
        block('join')
    end

    invoke()
    切换(1)
    分区(1)
    隐藏()
    gg.setVisible(false)
    luajava.setFloatingWindowHide(true)
    qhkai = 0
    
    qiehuan = function()
        if qhkai == 0 then
            qhkai = 1
            draw.remove()
            luajava.runUiThread(function()
                changan.controlSmall(floatWindow,400)
            end)
            gg.sleep(400)
            luajava.runUiThread(function()
                floatWindow:setVisibility(View.GONE)
            end)
        else
            qhkai = 0
            huiz()
            draw.text('.', -9200,-9200)
            luajava.runUiThread(function() 
                floatWindow:setVisibility(View.VISIBLE)
                floatWindow:setAlpha(1.0)
            end)
            luajava.runUiThread(function()
                changan.controlBig(floatWindow,400)
            end)
        end
    end

    huiz()
    draw.text('.', -9200,-9200)

    while true do
    if tuichu == 1 then 
        break 
    end
    if 启用音量键隐藏 then
        jianting3(qiehuan)
    else
        gg.sleep(100)
    end
    gg.sleep(200)
end

    luajava.setFloatingWindowHide(false)
end

-- 动画效果
changan.controlWater = function(control,time)
    luajava.runUiThread(function()
        import "android.animation.ObjectAnimator"
        ObjectAnimator():ofFloat(control,"scaleX", {
            1, 0.8, 0.9, 1
        }):setDuration(time):start()
        ObjectAnimator():ofFloat(control,"scaleY", {
            1,0.8,0.9,1
        }):setDuration(time):start()
    end)
end

-- 启动游戏函数
function launch(appstart)
    local loadBox = getLoadingBox('正在启动游戏\n'..appstart)
    loadBox['显示']()
    if appstart ~= nil then
        gg.setProcess(appstart)
        gg.sleep(500)
        if tostring(gg.getTargetPackage()) == appstart then
            gg.toast("正在启动游戏")
            gg.processKill()
            tuichu=true
            luajava.setFloatingWindowHide(false)
            os.exit()
        end
        gg.toast("正在启动游戏...")
        app.startActivity(appstart)
        jci=0
        while true do
            gg.setProcess(appstart)
            gg.sleep(400)
            if tostring(gg.getTargetPackage()) == appstart then
                loadBox['关闭']()
                gg.alert("启动成功")
            else
                jci=jci+1
                if jci==14 then
                    loadBox['关闭']()
                    gg.alert("自动获取进程失败\n请手动选择游戏进程")
                    gg.setProcessX()
                    break
                end
            end
            gg.sleep(100)
        end
    end
end

-- 卡片组件
function card(cdv)
    logo=cdv[1]
    name=cdv[2]
    tags=cdv[3]
    func=cdv[4]
    if not x then x = 2 end
    tag = {
        LinearLayout,
    }
    for i = 1,#tags do
        tag[#tag+1] = {
            TextView,
            background = getHorizontalBG({0x00FF9700,0x00FF9700},45,2,0xffFF9700),
            layout_height = "20dp",
            padding = "2dp",
            textColor = 0xffFF9700,
            layout_marginLeft = "10dp",
            gravity = "center_vertical",
            text = " "..tags[i].." ",
            textSize = "9sp",
        }
    end
    tags = tag
    tmp = luajava.loadlayout(
        {
            FrameLayout,
            layout_height = "wrap_content",
            layout_width = "fill_parent",
            {
                LinearLayout,
                orientation = "vertical",
                layout_height = "100dp",
                layout_marginLeft = "4dp",
                layout_marginRight = "4dp",
                layout_marginTop = "2dp",
                layout_marginBottom = "2dp",
                layout_width = "match_parent",
                background=getVerticalBG({0xffffffff,0xffffffff},10,3,0xffe79268),
                {
                    LinearLayout,
                    layout_marginLeft = "10dp",
                    layout_marginRight = "10dp",
                    layout_marginTop = "10dp",
                    layout_marginBottom = "10dp",
                    layout_width = "match_parent",
                    layout_height = "40dp",
                    {
                        ImageView,
                        layout_width = "40dp",
                        layout_height = "40dp",
                        src = 获取图片(logo),
                    },
                    {
                        TextView,
                        layout_height = "40dp",
                        layout_marginLeft = "10dp",
                        gravity = "center_vertical",
                        text = name,
                        textColor="#161616",
                        textSize = "13sp",
                    }
                },
                tags
            },
            {
                LinearLayout,
                onClick = function()
                    luajava.newThread(function() 隐藏() func() end):start()
                end,
                background = getHorizontalBG({0xffe79268,0xffe79268},90),
                layout_height = "25dp",
                layout_width = "55dp",
                layout_gravity = "right",
                layout_marginRight = "10dp",
                layout_marginTop = "70dp",
                gravity = "center",
                {
                    ImageView,
                    layout_height = "20dp",
                    layout_width = "15dp",
                    src = getRes("rw1"),
                    colorFilter=0xffffffff
                },
                {
                    TextView,
                    textColor = "#ffffff",
                    text = "启动",
                    textSize = "10sp",
                    layout_height = "20dp",
                    gravity = "center",
                    layout_width = "30dp",
                }
            }
        })
    return tmp
end

-- 菜单管理函数

boxes = {} 
boxpic = {}
boxInnerCircles = {}

function visi (tid , ttid)
    vibra:vibrate(4)
    local tview = luajava.getIdValue (tid)
    local ttview = luajava.getIdValue (ttid)
    if not tview then
        return 0
    end
    
    luajava.runUiThread(function()
        boxInnerCircles = boxInnerCircles or {}
        local innerCircle = boxInnerCircles[tid]
        
        if tonumber (tostring (tview:getVisibility ())) == 8.0 then
            tview:setVisibility (View.VISIBLE)
            YoYoImpl:with("FadeIn"):duration(200):playOn(boxes[tid])
            if innerCircle then
                innerCircle:setVisibility(View.VISIBLE)
                changan.controlWater(innerCircle, 200)
            end
        else
            tview:setVisibility (View.GONE)
            changan.controlWater (_ENV [tid.."6"] , 200)
            if innerCircle then
                innerCircle:setVisibility(View.GONE)
                changan.controlWater(innerCircle, 200)
            end
        end
    end)
end

function changan.box (views)
    local tid = "box"..guid()
    
    local switchIndicator = luajava.loadlayout({
        LinearLayout,
        layout_width = "24dp",
        layout_height = "24dp",
        gravity = "center",
        background = getVerticalBG({0xffffffff,0xffffffff}, 360, 2, 0xffA0D1FF),
        id = luajava.newId(tid .. "_outer")
    })
    
    local innerCircle = luajava.loadlayout({
        View,
        layout_width = "15dp",
        layout_height = "15dp",
        background = getVerticalBG({0xffA0D1FF,0xffA0D1FF}, 360),
        visibility = "gone",
        id = luajava.newId(tid .. "_inner")
    })
    
    switchIndicator:addView(innerCircle)
    
    local ttid = tid.."6"
    local t1id = guid()
    
    firadio = {
        LinearLayout,
        layout_width = 'match_parent',
        layout_height = "wrap_content",
        layout_marginTop = "2dp",
        layout_marginBottom = "2dp",
        orientation = "vertical",
    }
    
    if type (views [1]) == "string" or type (views [1]) == "number" then
        firadio [# firadio + 1] = {
            LinearLayout,
            layout_width = 'match_parent',
            layout_height = "30dp",
            gravity = "center_vertical",
            layout_margin='5dp',
            elevation='2dp',
            onClick = function ()
                visi (tid , ttid)
            end,
            background = getButtonBG(),
            {
                LinearLayout,
                layout_width = "30dp",
                layout_height = "30dp",
                gravity = "center",
                layout_marginLeft = "1dp",
                switchIndicator
            },
            {
                TextView, 
                text = views [1],
                textSize = "13sp",
                layout_width = "0dp",
                layout_weight = 1,
                textColor = "#000000",
                gravity = "center",
                layout_marginLeft = "10dp", 
                layout_marginRight = "40dp",
            }
        }
    else
        gg.alert ("changan.box的table内第一个元素必须是string")
        os.exit ()
    end
    
    radios = {
        LinearLayout,
        layout_marginLeft = "0dp",
        layout_marginRight = "0dp",
        orientation = "vertical",
        visibility = "gone",
        id = luajava.newId (tid),
        padding = "0dp",
        layout_width = 'match_parent',
    }
    
    for i = 2 , # views do
        radios [# radios + 1] = views [i]
    end
    
    boxes[tid] = luajava.loadlayout(radios)
    firadio [# firadio + 1] = boxes[tid]
    
    boxInnerCircles = boxInnerCircles or {}
    boxInnerCircles[tid] = innerCircle
    
    return luajava.loadlayout(firadio)
end

switchs = {}

function changan.switch(name, funcOn, funcOff)
    local switchId = "switch_" .. guid()
    
    _ENV[switchId] = "关"
    
    local switchIndicator = luajava.loadlayout({
        LinearLayout,
        layout_width = "24dp",
        layout_height = "24dp",
        gravity = "center",
        background = getVerticalBG({0xffffffff,0xffffffff}, 360, 2, 0xffA0D1FF),
        id = luajava.newId(switchId .. "_outer")
    })
    
    local innerCircle = luajava.loadlayout({
        View,
        layout_width = "15dp",
        layout_height = "15dp",
        background = getVerticalBG({0xffA0D1FF,0xffA0D1FF}, 360),
        visibility = "gone",
        id = luajava.newId(switchId .. "_inner")
    })
    
    switchIndicator:addView(innerCircle)
    
    local switchLayout = luajava.loadlayout({
        LinearLayout,
        layout_width = 'match_parent',
        layout_height = "wrap_content", 
        {
            LinearLayout,
            layout_height='30dp',
            layout_width = "fill_parent",
            gravity = "center_vertical",
            layout_margin='5dp',
            elevation='3dp',
            background = getButtonBG(),
            padding="3dp",
            onClick = function()
                if _ENV[switchId] == "关" then
                    _ENV[switchId] = "开"
                    innerCircle:setVisibility(View.VISIBLE)
                    changan.controlWater(switchIndicator, 200)
                    if funcOn then
                        luajava.newThread(funcOn):start()
                    end
                else
                    _ENV[switchId] = "关"
                    innerCircle:setVisibility(View.GONE)
                    changan.controlWater(switchIndicator, 200)
                    if funcOff then
                        luajava.newThread(funcOff):start()
                    end
                end
            end,
            {
                TextView,
                textColor = "#000000",
                text = name,
                textSize = "13sp",
                gravity='center',
                layout_height = "20dp",
                layout_width = "0dp",
                layout_weight = 1,
                layout_marginLeft='30dp',
            },
            {
                LinearLayout,
                layout_width = "30dp",
                layout_height = "30dp",
                gravity = "center",
                switchIndicator
            }
        }
    })
    
    switchs[switchId] = switchLayout
    return switchLayout
end

corbk = true
当前ui = 1

function 分区(x)
    当前分区[当前ui]=x
    luajava.runUiThread(function()
        for i=1,分区页数[当前ui] do
            _ENV['menu'..当前ui..i]:setVisibility(View.GONE)
        end
        _ENV['menu'..当前ui..当前分区[当前ui]]:setVisibility(View.VISIBLE)
    end)
end

function 切换(x)
当前ui = x
    luajava.runUiThread(function()
        if 当前分区[当前ui]==nil then
            分区(1)
        end
        for i = 1,菜单页数 do
            _ENV["ding"..i]:setTextColor(0xff483C2E)
            _ENV['dingbar'..i]:setBackground(empty)
            _ENV['ding'..i]:setBackground(slctb)
            _ENV["layout"..i]:setVisibility(View.GONE)
        end
        _ENV["ding"..当前ui]:setTextColor(0xff000000)
        _ENV["layout"..当前ui]:setVisibility(View.VISIBLE)
        _ENV['ding'..当前ui]:setBackground(slcta)
        _ENV['dingbar'..当前ui]:setBackground(dbback)
        changan.controlWater(_ENV['ding'..当前ui],400)
        changan.controlBigX(_ENV['dingbar'..当前ui],700)
    end)
end

显示 = 0
beij2 = luajava.loadlayout({
    GradientDrawable,
    color = "#001E1C27",
    cornerRadius = 10
})

function changan.text(txt,color,size)
    if not txt then txt = "未设置文字" end
    if not color then color = "#545454" end
    if not size then size = "12 sp" end
    return luajava.loadlayout(
        {
            TextView,
            text = txt,
            textSize = size,
            textColor = color,
            layout_width = "match_parent",
            padding={'10dp','0dp','0dp','0dp'}
        })
end

显示 = 0
function 隐藏()
    luajava.runUiThread(function()
        if tonumber(tostring(chuangk:getVisibility())) == 8.0 then
            control:setVisibility(View.GONE)
            显示 = 1
            chuangk:setVisibility(View.VISIBLE)
            _ENV["layout"..当前ui]:setVisibility(View.VISIBLE)
            changan.controlBigX(floatWindow,800)
            floatWindow:setBackground(beij)
            mainLayoutParams.flags = LayoutParams.FLAG_NOT_TOUCH_MODAL
            window : updateViewLayout (floatWindow , mainLayoutParams)
        else
            luajava.startThread(function()
                luajava.runUiThread(function()
                    YoYoImpl:with("FadeOut"):duration(300):playOn(floatWindow)
                end)
                gg.sleep(300)
                luajava.runUiThread(function()
                    chuangk:setVisibility(View.GONE)
                    floatWindow:setBackground(beij2)
                    control:setVisibility(View.VISIBLE)
                    显示 = 0
                    _ENV["layout"..当前ui]:setVisibility(View.GONE)
                    YoYoImpl:with("FadeIn"):duration(300):playOn(floatWindow)
                    mainLayoutParams.flags = LayoutParams.FLAG_NOT_FOCUSABLE
                    window : updateViewLayout (floatWindow , mainLayoutParams)
                end)
            end)
        end
    end)
end

-- 音频管理
import("android.media.AudioManager")
audi = context:getSystemService("audio")
audiotype = {
    AudioManager.STREAM_ALARM,
    AudioManager.STREAM_MUSIC,
    AudioManager.STREAM_NOTIFICATION,
    AudioManager.STREAM_RING,
    AudioManager.STREAM_SYSTEM,
    AudioManager.STREAM_VOICE_CALL,
    AudioManager.STREAM_DTMF,
}
yinl = {}
for i = 1,#audiotype do
    yinl[i] = {}
    yinl[i].type = audiotype[i]
    yinl[i].min = audi:getStreamMinVolume(audiotype[i])
    yinl[i].max = audi:getStreamMaxVolume(audiotype[i])
    yinl[i].now = audi:getStreamVolume(audiotype[i])
end

-- 工具函数
function jianting2()
    yinln = {}
    for i = 1,#audiotype do
        yinln[i] = {}
        yinln[i].type = audiotype[i]
        yinln[i].min = audi:getStreamMinVolume(audiotype[i])
        yinln[i].max = audi:getStreamMaxVolume(audiotype[i])
        yinln[i].now = audi:getStreamVolume(audiotype[i])
        if yinln[i].now > yinl[i].now then
            audi:adjustStreamVolume(yinln[i].type,AudioManager.ADJUST_LOWER,0)
        elseif yinln[i].now < yinl[i].now then
            audi:adjustStreamVolume(yinln[i].type,AudioManager.ADJUST_RAISE,0)
        end
    end
end

yltype = 0
function jianting3(func)
    yinln = {}
    for i = 1,#audiotype do
        yinln[i] = {}
        yinln[i].type = audiotype[i]
        yinln[i].now = audi:getStreamVolume(audiotype[i])
        if yinln[i].now > yinl[i].now then
            yinl[i].now = yinln[i].now
            if yltype == 1 then
                yltype = 0
                func()
            end
        elseif yinln[i].now < yinl[i].now then
            yinl[i].now = yinln[i].now
            if yltype == 0 then
                yltype = 1
                func()
            end
        end
    end
end

function jianting(func)
    yinln = {}
    for i = 1,#audiotype do
        yinln[i] = {}
        yinln[i].type = audiotype[i]
        yinln[i].now = audi:getStreamVolume(audiotype[i])
        if yinln[i].now >= yinl[i].max then
            audi:adjustStreamVolume(yinln[i].type,AudioManager.ADJUST_LOWER,0)
        end
        if yinln[i].now > yinl[i].now then
            audi:setStreamVolume(yinln[i].type,yinl[i].now,0)
            func()
        end
    end
end

function guid()
    seed = {
        'e','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'
    }
    tb = {}
    for i = 1,32 do
        table.insert(tb,seed[math.random(1,16)])
    end
    sid = table.concat(tb)
    return string.format('%s%s%s%s%s',
        string.sub(sid,1,8),
        string.sub(sid,10,12),
        string.sub(sid,21,22))
    ..string.format('%s%s%s%s%s',
        string.sub(sid,1,6),
        string.sub(sid,21,25)
    )
end

-- 退出函数
local function exit()
    tuichu = 1
    luajava.setFloatingWindowHide(false)
    luajava.post(function()
        if floatWindow and window then
            window:removeView(floatWindow)
        end
    end)
    gg.toast("正在退出...")
    os.exit()
end

setExitEvent(exit)

setExitEvent(exit)

-- 动画效果
changan.controlWater = function(control,time)
    luajava.runUiThread(function()
        import "android.animation.ObjectAnimator"
        ObjectAnimator():ofFloat(control,"scaleX", {
            1, 0.8, 0.9, 1
        }):setDuration(time):start()
        ObjectAnimator():ofFloat(control,"scaleY", {
            1,0.8,0.9,1
        }):setDuration(time):start()
    end)
end

changan.controlSmall = function(control,time)
    luajava.runUiThread(function()
        import "android.animation.ObjectAnimator"
        ObjectAnimator():ofFloat(control,"scaleX", {
            1, 0.7, 0.4, 0
        }):setDuration(time):start()
        ObjectAnimator():ofFloat(control,"scaleY", {
            1, 0.7, 0.4, 0
        }):setDuration(time):start()
    end)
end

changan.controlBig = function(control,time)
    luajava.runUiThread(function()
        import "android.animation.ObjectAnimator"
        ObjectAnimator():ofFloat(control,"scaleX", {
            0, 0.4, 0.7, 1
        }):setDuration(time):start()
        ObjectAnimator():ofFloat(control,"scaleY", {
            0, 0.4, 0.7, 1
        }):setDuration(time):start()
    end)
end

changan.controlBigX = function(control,time)
    luajava.runUiThread(function()
        import "android.animation.ObjectAnimator"
        ObjectAnimator():ofFloat(control,"scaleX", {
            0, 0.4, 0.7, 1
        }):setDuration(time):start()
    end)
end

-- 按钮组件
buts={}
heir=getRes("heir")
function changan.button(txt,func,txtc)
    if not txt then txt = "未设置" end
    if not txtc then txtc="#000000" end
    local tid="Cbutton"..guid()
    buts[tid]=luajava.loadlayout(
        {
            LinearLayout,
            layout_width = 'match_parent',
            layout_height = "wrap_content", {
                LinearLayout,
                layout_height='30dp',
                layout_width = "fill_parent",
                gravity = "center_vertical",
                layout_margin='5dp',
                elevation='3dp',
                background = getButtonBG(),
                padding="3dp",
                onClick = function() 
                    changan.controlWater(buts[tid],300)
                    luajava.newThread(func):start()
                end,
                {
                    TextView,
                    textColor = txtc,
                    text = txt,
                    textSize = "13sp",
                    gravity='center',
                    layout_height = "20dp",
                    layout_width = "fill_parent",
                }
            }})
    return buts[tid]
end

-- 复选框组件
checkbg1 = getRes("bbts_checkoff")
checkbg2 = getRes("bbts_check")
checkbg3 = getVerticalBG({0x00aaaaaa,0x00aaaaaa},360,7,0xff999999)
checkbg4 = getVerticalBG({0x00000000,0x00000000},360,11,0xffe79268)
radoff = getVerticalBG({0xaaBDC7CD,0xaaBDC7CD},360)
radon = getRes("dz_check")

radiog={}
function changan.intradio(nid,name,func)
    return {
        LinearLayout ,
        layout_width = 'match_parent' ,
        layout_height = "wrap_content" ,
        layout_weight=1,
        layout_marginLeft = "2dp" ,
        layout_marginRight = "5dp" ,
        layout_marginTop='2dp',
        layout_marginBottom='8dp',
        gravity = "center_vertical" ,
        onClick = function ()
            func()
        end,
        {
            ImageView ,
            id = luajava.newId (nid) ,
            layout_width = '15dp' ,
            layout_height = "15dp" ,
            layout_marginLeft = "2dp" ,
            layout_marginRight = "4dp" ,
            src =radoff ,
            padding='0dp',
        } , {
            TextView ,
            gravity = "top" ,
            text = name ,
            textSize= "12sp" ,
            textColor = '#000000' ,
            layout_width = 'wrap_content' ,
            layout_height = 'wrap_content' ,
            
        }
    }
end

local RadTint=ColorStateList({
    {android.R.attr.state_checked},
    {-android.R.attr.state_checked},
    {},}, {
        0xff5AA7FF,
        0xff545454,
        0xff545454
    })

function changan.intcheck(name,func1,func2)
    local nid = name..guid()
    local func = 开关(name,func1,func2,nid)
    if not name then name = "未设置" end
    return {
        LinearLayout,
        layout_width = 'match_parent',
        layout_weight=1,
        layout_height = "42dp",
        layout_marginTop = "1dp",
        layout_marginBottom = "1dp",
        padding = "1dp",
        {
            LinearLayout,
            padding="3dp",
            layout_width = 'match_parent',
            layout_height = "wrap_content",
            gravity = "center_vertical",
            {
                CheckBox,
                id=luajava.newId(nid.."t"),
                layout_width = '32dp',
                layout_height = '32dp',
                padding = "0dp",
                __onFinish=function(v)
                    v:setButtonTintList(RadTint)
                end,
                onClick = function() luajava.newThread(function() func() end):start() end,
            },{
                TextView,
                gravity = "left",
                text = name,
                textColor=0xff000000,
                textSize = "14sp",
                layout_width = 'match_parent',
                layout_weight=1,
                onClick = function()
                    local v=luajava.getIdView(nid..'t')
                    if v:isChecked() then
                        v:setChecked(false)
                    else
                        v:setChecked(true)
                    end
                    luajava.newThread(function() func() end):start() 
                end,
            },
        }
    }
end

开关 = function(name , func1 , func2 )
    local localname=name
    local tname=name..guid()
    if func1 == nil then
        func1 = ""
    end
    if func2 == nil then
        func2 = ""
    end
    if type(func1 ) == "function" then
        return function()
            namers = _ENV [ tname ]
            if namers ~= "开" then
                _ENV [ tname ] = "开"
                pcall(func1 )
            else
                _ENV [ tname ] = "关"
                pcall(func2 )
            end
        end
    end
end

swfuncs,buts,sliders,boxes,textvs={},{},{},{},{}

function changan.check(cklist)
    if #cklist==0 then return nil end
    local rest = {
        LinearLayout,
        layout_width = 'match_parent',
        layout_height = "wrap_content",
        gravity = "center",
        orientation="vertical",
    }
    
    for i = 1, #cklist,2 do
        local tempTable = {LinearLayout,
            layout_width = 'match_parent',
            layout_height = "wrap_content",
            gravity = "left",
            orientation="horizontal"
        }
        for j = 0, 1 do
            if cklist[i + j] ~= nil then
                local name = cklist[i + j][1]
                local func1 = cklist[i + j][2]
                local func2 = cklist[i + j][3]
                if not name then name = "未设置" end
                rstt = changan.intcheck(name,func1,func2)
                table.insert(tempTable, rstt)
            else
                table.insert(tempTable, {LinearLayout,
                layout_width = 'match_parent',
                layout_weight=1,})
            end
        end
        table.insert(rest, tempTable)
    end
    return rest
end

function changan.radio(cklist)
    local rid=guid()
    radiog[rid]={}
    rest = {
        LinearLayout ,
        layout_width = 'match_parent' ,
        layout_height = "wrap_content" ,
        layout_marginTop = "10dp" ,
    }
    local restt={
        LinearLayout ,
        layout_width = 'match_parent' ,
        layout_weight=1,
        layout_height = "wrap_content" ,
        gravity = "left" ,
        orientation='vertical',
    }

    for i = 1, #cklist,4 do
        local tempTable = {LinearLayout,
            layout_width = 'fill_parent',
            layout_height = "wrap_content",
            gravity = "left",
            orientation="horizontal"
        }
        for j = 0, 3 do
            if cklist[i + j] ~= nil then
                local nid = name..guid ()
                local name = cklist[i + j][1]
                radiog[rid][nid]=false
                local func1 = radin(rid,nid,cklist[i + j][2],name)
                if not name then name = "未设置" end
                local rstt = changan.intradio(nid,name,func1)
                table.insert(tempTable, rstt)
            else
                table.insert(tempTable, {LinearLayout,
                layout_width = 'match_parent',
                layout_weight=1,})
            end
        end
        table.insert(restt, tempTable)
    end

    rest [# rest + 1] = restt
    return luajava.loadlayout (rest)
end

switchs={}

无=function() end

-- 页面配置
标题='冰芽川四系乃'
背景图片="/sdcard/四系乃/图片/Back.png"
悬浮窗图标 = "/sdcard/四系乃/图片/Logo.png"

启用音量键隐藏 = false

function huiz()

end

第一页 = {
    ['分页名字']="主页",
    ['侧边图标']="/sdcard/四系乃/图片/Logo.png",
    ['功能配置']={
changan.button('显示公告', function()
gg.alert("TG@YoshinoBypass\n反馈@ThirteenSpices_Bot")
end),
    changan.button('选择进程', function()
    gg.setProcessX()
    local soundPath = "/sdcard/四系乃/音效/选择进程.mp3"
    playSound(soundPath)
end),
    }
}

防封页 = {
    ['分页名字']='防封',
    ['侧边图标']="/sdcard/四系乃/图片/Logo.png",
    ['功能配置']={
        changan.button('选择进程', function()
            gg.setProcessX()
            local soundPath = "/sdcard/四系乃/音效/选择进程.mp3"
            playSound(soundPath)
        end),
        
        changan.button("Logo防闪", function()
            local function S_Pointer(t_So, t_Offset, _bit)
                -- S_Pointer函数
                local function getRanges()
                    local ranges = {}
                    local t = gg.getRangesList('^/data/*.so*$')
                    for i, v in pairs(t) do
                        if v.type:sub(2, 2) == 'w' then
                            table.insert(ranges, v)
                        end
                    end
                    return ranges
                end

                local function Get_Address(N_So, Offset, ti_bit)
                    local ti = gg.getTargetInfo()
                    local S_list = getRanges()
                    local _Q = tonumber(0x167ba0fe)
                    local t = {}

                    local _t
                    local _S = nil
                    if ti_bit then
                        _t = 32
                     else
                        _t = 4
                    end

                    for i in pairs(S_list) do
                        local _N = S_list[i].internalName:gsub('^.*/', '')
                        if N_So[1] == _N and N_So[2] == S_list[i].state then
                            _S = S_list[i]
                            break
                        end
                    end

                    if _S then
                        t[#t + 1] = {}
                        t[#t].address = _S.start + Offset[1]
                        t[#t].flags = _t
                        if #Offset ~= 1 then
                            for i = 2, #Offset do
                                local S = gg.getValues(t)
                                t = {}
                                for _ in pairs(S) do
                                    if not ti.x64 then
                                        S[_].value = S[_].value & 0xFFFFFFFF
                                    end
                                    t[#t + 1] = {}
                                    t[#t].address = S[_].value + Offset[i]
                                    t[#t].flags = _t
                                end
                            end
                        end
                        _S = t[#t].address
                    end
                    return _S
                end

                local _A = string.format('0x%X', Get_Address(t_So, t_Offset, _bit))
                return _A
            end

        -- 防闪
            local t = {"libanogs.so:bss", "Cb"}
            local tt = {0x4F0}
            local ttt = S_Pointer(t, tt, true)
            gg.addListItems({{address = ttt, flags = 4, value = 4096, freeze = true}})

            local t = {"libanogs.so:bss", "Cb"}
            local tt = {0x578}
            local ttt = S_Pointer(t, tt, true)
            gg.addListItems({{address = ttt, flags = 4, value = 4096, freeze = true}})
            
            playSound("/sdcard/四系乃/音效/曼波.mp3")
        end),
        
        changan.button("Logo防", function()
            -- Logo杀67
            if gg.getRangesList("libUE4.so")[1] then
                local t = {}
                t[1] = gg.getRangesList("libUE4.so")[1]["start"] + 0x71768FC; -- 数值地址:0x7D4FA188FC
                gg.addListItems({
                    [1] = { 
                        address = t[1],
                        flags = 4,
                        value = -698416192,
                        freeze = true,
                    },
                })
                gg.toast("开启成功")
            end
            if gg.getRangesList("libUE4.so")[1] then
                local t = {}
                t[1] = gg.getRangesList("libUE4.so")[1]["start"] + 0x715EDAC; -- 数值地址:0x7D4FA00DAC
                t[2] = gg.getRangesList("libUE4.so")[1]["start"] + 0x7162C64; -- 数值地址:0x7D4FA04C64
                gg.addListItems({
                    [1] = { 
                        address = t[1],
                        flags = 4,
                        value = -698416192,
                        freeze = true,
                    },
                    [2] = { 
                        address = t[2],
                        flags = 4,
                        value = -698416192,
                        freeze = true,
                    },
                })
                gg.toast("开启成功")
            end
            if gg.getRangesList("libUE4.so")[1] then
                local t = {}
                t[1] = gg.getRangesList("libUE4.so")[1]["start"] + 0x71BFE74; -- 数值地址:0x7D4FA61E74
                t[2] = gg.getRangesList("libUE4.so")[1]["start"] + 0x7F502A0; -- 数值地址:0x7D507F22A0
                t[3] = gg.getRangesList("libUE4.so")[1]["start"] + 0x7F514F0; -- 数值地址:0x7D507F34F0
                gg.addListItems({
                    [1] = { 
                        address = t[1],
                        flags = 4,
                        value = -698416192,
                        freeze = true,
                    },
                    [2] = { 
                        address = t[2],
                        flags = 4,
                        value = -698416192,
                        freeze = true,
                    },
                    [3] = { 
                        address = t[3],
                        flags = 4,
                        value = -698416192,
                        freeze = true,
                    },
                })
                gg.toast("开启成功")
            end
            if gg.getRangesList("libUE4.so:bss")[1] then
                local t = {}
                t[1] = gg.getRangesList("libUE4.so:bss")[1]["start"] + 0x1A2238; -- 数值地址:0x7D56EC2238
                gg.addListItems({
                    [1] = { 
                        address = t[1],
                        flags = 4,
                        value = 0,
                        freeze = true,
                    },
                })
                gg.toast("开启成功")
            end
            gg.toast("Logo防功能已启用")
            playSound("/sdcard/四系乃/音效/曼波.mp3")
        end),
        
        changan.button("大厅防", function()
            -- 内存修改工具函数
            local function findExecutableSegment(lib)
                local ranges=gg.getRangesList(lib)
                for _,v in ipairs(ranges) do
                    if v.type:find("-x") then return v.start end
                end
                return nil
            end
            
            local function readValue(address,flags)
                return gg.getValues({[1]={address=address,flags=flags}})[1].value
            end
            
            local function writeValue(address,flags,value,freeze)
                local item={address=address,flags=flags,value=value,freeze=freeze}
                if freeze then gg.addListItems({item}) else gg.setValues({item}) end
            end

            function setvalue(address,flags,value,freeze) 
                if address == 0 then return end 
                local tt={} 
                tt[1]={} 
                tt[1].address=address 
                tt[1].flags=flags 
                tt[1].value=value 
                tt[1].freeze=freeze 
                if freeze==false then gg.setValues(tt) end 
                gg.addListItems(tt) 
            end
            
            -- 增强版S_Pointer函数
            function S_Pointer(t_So, t_Offset, _bit)
                local function getRanges()
                    local ranges = {}
                    local t = gg.getRangesList('^/data/*.so*$')
                    for i, v in pairs(t) do
                        if v.type:sub(2, 2) == 'w' then
                            table.insert(ranges, v)
                        end
                    end
                    return ranges
                end
                
                local function Get_Address(N_So, Offset, ti_bit)
                    local ti = gg.getTargetInfo()
                    local t = {}
                    local _t
                    local _S = nil
                    if ti_bit then
                        _t = 32
                     else
                        __t = 4
                    end
                    local _S = gg.getRangesList(N_So[1])[1]
                    if _S then
                        t[#t + 1] = {}
                        t[#t].address = _S.start + Offset[1]
                        t[#t].flags = _t
                        if #Offset ~= 1 then
                            for i = 2, #Offset do
                                local S = gg.getValues(t)
                                t = {}
                                for _ in pairs(S) do
                                    if not ti.x64 then
                                        S[_].value = S[_].value & 0xFFFFFFFF
                                    else
                                        S[_].value = S[_].value & 0xFFFFFFFFFF
                                    end
                                    t[#t + 1] = {}
                                    t[#t].address = S[_].value + Offset[i]
                                    t[#t].flags = _t
                                end
                            end 
                        end
                        _S = t[#t].address
                    end
                    return _S
                end
                
                local ttt = Get_Address(t_So, t_Offset, _bit)
                if ttt ~= nil then
                    local _A = string.format('0x%X', ttt)
                    return _A
                end
                return 0
            end

            -- 执行修改
            gg.toast("正在开启大厅防...")
            
            local t = {"libanogs.so"}
            
            -- 完整性memcpy
            local tt = {0x3359B0} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 NOP", false)
            
            -- 异常扫描
            local tt = {0x2FA498} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 NOP", false)
            local tt = {0x40BA34} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 RET", false)
            
            -- 断点检测
            local tt = {0x363474} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 B [PC,#0x40]", false)
            local tt = {0x332804} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 NOP", false)
            local tt = {0x335958} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 MOV W8, WZR", false)
            local tt = {0x3284C8} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 AND W9, WZR, #0x1", false)
            local tt = {0x3266F0} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 B [PC,#0x160]", false)
            local tt = {0x3247E0} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 NOP", false)
            local tt = {0x323378} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 MOV W9, #0x1", false)
            local tt = {0x3231E8} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 AND W8, W8, WZR", false)
            local tt = {0x466018} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 MOV W8, WZR", false)
            local tt = {0x332804} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 NOP", false)
            local tt = {0x378C98} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 B [PC,#0x74]", false)
            
            -- initmrpcs创造线程
            local tt = {0x2EDDC4} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 B [PC,#0x1C]", false)
            local tt = {0x469B64} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 B [PC,#0x18]", false)
            
            -- hash校验
            local tt = {0x3EE0D8} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 B [PC,#0x368]", false)
            local tt = {0x4399E4} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 B [PC,#0x90]", false)
            local tt = {0x439AC0} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 B [PC,#0x90]", false)
            local tt = {0x4409F4} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 B [PC,#0x90]", false)
            
            -- hash验证上下文
            local tt = {0x40E088} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 MOV W9, WZR", false)
            
            -- 段校验
            local tt = {0x218DE8} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 RET", false)
            
            -- mrpcs发送线程
            local tt = {0x368334} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 RET", false)
            
            -- 第二局crc32校验
            local tt = {0x3438EC} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 MOV W0, #0x1", false)
            local tt = {0x4C4438} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 LDRB W10, [X19]", false)
            
            -- 异常上报
            local tt = {0x378C98} local ttt = S_Pointer(t,tt,true)
            setvalue(ttt,4, "~A8 B [PC,#0x74]", false)
            
            gg.toast("大厅防保护已应用")
            playSound("/sdcard/四系乃/音效/曼波.mp3")
        end),
        
        changan.switch("全局离线", 
            function()
                -- 开启
                if gg.getRangesList("libgcloud.so")[1] then
                    local t = {}
                    t[1] = gg.getRangesList("libgcloud.so")[1]["start"] + 0x89B50; -- 数值地址:0x7B208A2B50
                    gg.addListItems({
                        [1] = { 
                            address = t[1],
                            flags = 4,
                            value = -698416192,
                            freeze = true,
                        },
                    })
                    gg.toast("全局离线已开启")
                    playSound("/sdcard/四系乃/音效/曼波.mp3")
                else
                    gg.toast("未找到libgcloud.so模块")
                end
            end,
            function()
                -- 关闭
                if gg.getRangesList("libgcloud.so")[1] then
                    local t = {}
                    t[1] = gg.getRangesList("libgcloud.so")[1]["start"] + 0x89B50; -- 数值地址:0x7B208A2B50
                    gg.addListItems({
                        [1] = { 
                            address = t[1],
                            flags = 4,
                            value = -1342166224,
                            freeze = true,
                        },
                    })
                    gg.toast("全局离线已关闭")
                    playSound("/sdcard/四系乃/音效/曼波.mp3")
                else
                    gg.toast("未找到libgcloud.so模块")
                end
            end
        ),
    }
}

功能页 = {
    ['分页名字']='功能',
    ['侧边图标']="/sdcard/四系乃/图片/Logo.png",
    ['功能配置']={
        changan.button('选择进程', function()
            gg.setProcessX()
            local soundPath = "/sdcard/四系乃/音效/选择进程.mp3"
            playSound(soundPath)
        end),
        
        -- 人物功能box
        changan.box({
            "人物功能",
            changan.button("静态广角", function()
                -- 静态广角
                local input = gg.prompt(
                    {"静态广角大小 (1~3)"},
                    {1.5},  -- 默认值
                    {"number"}
                )
                
                if not input then return end
                
                local value = input[1]
                
                gg.clearResults()
                gg.setRanges(gg.REGION_CODE_APP)
                
                local libUE4 = gg.getRangesList('libUE4.so')[1]
                if not libUE4 then
                    gg.alert("未找到 libUE4.so 模块")
                    return
                end
                
                local targetAddress = libUE4.start + 0x32EFCF8
                
                gg.setValues({
                    {
                        address = targetAddress,
                        flags = gg.TYPE_FLOAT,
                        value = value
                    }
                })
                
                gg.toast(string.format("静态广角已设置为 %.1f", value))
                playSound("/sdcard/四系乃/音效/嘿.mp3")
            end),
            
            changan.button("动态广角", function()
                -- 动态广角
                local function S_Pointer(t_So, t_Offset, _bit)
                    local function getRanges()
                        local ranges = {}
                        local t = gg.getRangesList('^/data/*.so*$')
                        for i, v in pairs(t) do
                            if v.type:sub(2, 2) == 'w' then
                                table.insert(ranges, v)
                            end
                        end
                        return ranges
                    end

                    local function Get_Address(N_So, Offset, ti_bit)
                        local ti = gg.getTargetInfo()
                        local S_list = getRanges()
                        local _Q = tonumber(0x167ba0fe)
                        local t = {}

                        local _t
                        local _S = nil
                        if ti_bit then
                            _t = 32
                         else
                            _t = 4
                        end

                        for i in pairs(S_list) do
                            local _N = S_list[i].internalName:gsub('^.*/', '')
                            if N_So[1] == _N and N_So[2] == S_list[i].state then
                                _S = S_list[i]
                                break
                            end
                        end

                        if _S then
                            t[#t + 1] = {}
                            t[#t].address = _S.start + Offset[1]
                            t[#t].flags = _t
                            if #Offset ~= 1 then
                                for i = 2, #Offset do
                                    local S = gg.getValues(t)
                                    t = {}
                                    for _ in pairs(S) do
                                        if not ti.x64 then
                                            S[_].value = S[_].value & 0xFFFFFFFF
                                        end
                                        t[#t + 1] = {}
                                        t[#t].address = S[_].value + Offset[i]
                                        t[#t].flags = _t
                                    end
                                end
                            end
                            _S = t[#t].address
                        end
                        return _S
                    end

                    local _A = string.format('0x%X', Get_Address(t_So, t_Offset, _bit))
                    return _A
                end

                local k = gg.prompt({
                    "动态广角大小(90~150)"
                }, {"103"}, {"number"})
                
                if k == nil then
                    return
                end
                
                local Q = k[1]
                
                local address = S_Pointer({
                    "libUE4.so:bss",
                    "Cb"
                }, {
                    6122096,
                    48,
                    1104,
                    776,
                    400,
                    828
                }, true)
                
                if address then
                    gg.setValues({
                        {
                            address = address,
                            flags = 16,
                            value = tonumber(Q)
                        }
                    })
                    gg.toast("动态广角已设置为 " .. Q)
                    playSound("/sdcard/四系乃/音效/嘿.mp3")
                else
                    gg.toast("动态广角设置失败")
                end
            end),
            
            changan.button("微加速", function()
                local function S_Pointer(t_So, t_Offset, _bit)
                    local function getRanges()
                        local ranges = {}
                        local t = gg.getRangesList('^/data/*.so*$')
                        for i, v in pairs(t) do
                            if v.type:sub(2, 2) == 'w' then
                                table.insert(ranges, v)
                            end
                        end
                        return ranges
                    end

                    local function Get_Address(N_So, Offset, ti_bit)
                        local ti = gg.getTargetInfo()
                        local S_list = getRanges()
                        local _Q = tonumber(0x167ba0fe)
                        local t = {}

                        local _t
                        local _S = nil
                        if ti_bit then
                            _t = 32
                         else
                            _t = 4
                        end

                        for i in pairs(S_list) do
                            local _N = S_list[i].internalName:gsub('^.*/', '')
                            if N_So[1] == _N and N_So[2] == S_list[i].state then
                                _S = S_list[i]
                                break
                            end
                        end

                        if _S then
                            t[#t + 1] = {}
                            t[#t].address = _S.start + Offset[1]
                            t[#t].flags = _t
                            if #Offset ~= 1 then
                                for i = 2, #Offset do
                                    local S = gg.getValues(t)
                                    t = {}
                                    for _ in pairs(S) do
                                        if not ti.x64 then
                                            S[_].value = S[_].value & 0xFFFFFFFF
                                        end
                                        t[#t + 1] = {}
                                        t[#t].address = S[_].value + Offset[i]
                                        t[#t].flags = _t
                                    end
                                end
                            end
                            _S = t[#t].address
                        end
                        return _S
                    end

                    local _A = string.format('0x%X', Get_Address(t_So, t_Offset, _bit))
                    return _A
                end

                local input = gg.prompt(
                    {"微加速大小 (1~3)"},
                    {3},  -- 默认值
                    {"number"}
                )
                
                if not input then return end
                
                local value = input[1]
                
                local address = S_Pointer({
                    "libUE4.so:bss",
                    "Cb"
                }, {
                    6122096,
                    48,
                    1104,
                    4256
                }, true)
                
                if address then
                    gg.addListItems({
                        {
                            address = address,
                            flags = 16,
                            value = value,
                            freeze = true
                        }
                    })
                    gg.toast(string.format("微加速已设置为 %.1f", value))
                    playSound("/sdcard/四系乃/音效/嘿.mp3")
                else
                    gg.toast("微加速设置失败")
                end
            end)
        }),
        
        -- 枪械功能box
        changan.box({
            "枪械功能",
            changan.button("手持聚点", function()
                local t = {"libUE4.so:bss", "Cb"}
                local tt = {0x5D6A70,0x30,0x450,0x29F0,0x780,0xB8C}
                local ttt = S_Pointer(t, tt, true)
                if ttt and ttt ~= 0 then
                    gg.setValues({{address = ttt, flags = 16, value = 0}})
                    gg.toast("手持聚点已开启")
                    playSound("/sdcard/四系乃/音效/嘿.mp3")
                else
                    gg.toast("手持聚点开启失败")
                end
            end),
            
            changan.button("手持无后", function()
                local t = {"libUE4.so:bss", "Cb"}
                local tt = {0x5D6A70,0x30,0x450,0x29F0,0xF08,0x168}
                local ttt = S_Pointer(t, tt, true)
                if ttt and ttt ~= 0 then
                    gg.setValues({{address = ttt, flags = 4, value = 0}})
                    gg.toast("手持无后已开启")
                    playSound("/sdcard/四系乃/音效/嘿.mp3")
                else
                    gg.toast("手持无后开启失败")
                end
            end),
            
            changan.button("手持防抖", function()
                local t = {"libUE4.so:bss", "Cb"}
                local tt = {0x5D6A70,0x30,0x450,0x29F0,0x780,0xC4C}
                local ttt = S_Pointer(t, tt, true)
                if ttt and ttt ~= 0 then
                    gg.setValues({{address = ttt, flags = 16, value = 0}})
                end
                
                local t = {"libUE4.so:bss", "Cb"}
                local tt = {0x5D6A70,0x30,0x450,0x29F0,0x780,0xC50}
                local ttt = S_Pointer(t, tt, true)
                if ttt and ttt ~= 0 then
                    gg.setValues({{address = ttt, flags = 16, value = 0}})
                end
                
                local t = {"libUE4.so:bss", "Cb"}
                local tt = {0x5D6A70,0x30,0x450,0x29F0,0x780,0xC54}
                local ttt = S_Pointer(t, tt, true)
                if ttt and ttt ~= 0 then
                    gg.setValues({{address = ttt, flags = 16, value = 0}})
                end
                
                gg.toast("手持防抖已开启")
                playSound("/sdcard/四系乃/音效/嘿.mp3")
            end)
        })
    }
}

设置页 = {
    ['分页名字']="设置",
    ['侧边图标']="/sdcard/四系乃/图片/Logo.png",
    ['功能配置']={
        changan.switch("音量键隐藏", 
            function()
                启用音量键隐藏 = true
            end,
            function()
                启用音量键隐藏 = false
            end
        ),
        
        changan.button("退出", function()
            exit()
        end),
    }
}

预加载必要资源()

changan.menu({
    第一页,   -- 主页
    防封页,   -- 防封
    功能页,   -- 功能
    设置页,   -- 设置
})