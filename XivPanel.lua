-- XivPanel.lua
local texts,images=require('texts'),require('images')
local XivBar={}
XivBar.__index=XivBar
local BG_SIZES={bg_top={w=377,h=21},bg_mid={w=377,h=12},bg_bottom={w=377,h=21}}
local BAR_PART_SIZES={bg={w=128,h=64},fill={w=102,h=64},fg={w=128,h=64},glow={w=6,h=64},glow_sides={w=2,h=64}}
local BAR_PART_FILES={bg='BarBG.png',fill='Bar.png',fg='BarFG.png',glow='BarGlow.png',glow_sides='BarGlowSides.png'}
local BAR_PART_ORDER={'bg','fill','fg','glow','glow_sides'}
local function make_image(assets,file,w,h)
return images.new{pos={x=0,y=0},visible=false,color={alpha=255,red=255,green=255,blue=255},size={width=w,height=h},texture={path=assets..file,fit=true},draggable=false}
end
function XivBar.new(config)
local self=setmetatable({},XivBar)
    self.assets=config.assets
    self.settings=config.settings
    self.defaults=config.defaults
    self.stats=config.stats or {'hp'}
    self.stat_colors=config.stat_colors or {}
    self.position_text_fn=config.position_text
    self.preview=config.preview or {}
    self.value_align_right=config.value_align_right
    if self.value_align_right==nil then self.value_align_right=true end
    self.root_x=self.settings.pos.x
    self.root_y=self.settings.pos.y
    self.dragging=false
    self.drag_offset_x=0
    self.drag_offset_y=0
    self.visible=false
    self.stat_enabled={}
    for _,stat in ipairs(self.stats) do self.stat_enabled[stat]=true end
    self.image_sizes={}
    self.image_objects={}
    self.image_objects.bg_top=make_image(self.assets,'BgTop.png',BG_SIZES.bg_top.w,BG_SIZES.bg_top.h)
    self.image_objects.bg_mid=make_image(self.assets,'BgMid.png',BG_SIZES.bg_mid.w,BG_SIZES.bg_mid.h)
    self.image_objects.bg_bottom=make_image(self.assets,'BgBottom.png',BG_SIZES.bg_bottom.w,BG_SIZES.bg_bottom.h)
    for key,size in pairs(BG_SIZES) do self.image_sizes[key]=size end
    self.bars={}
    for _,stat in ipairs(self.stats) do
        self.bars[stat]={}
        for _,part in ipairs(BAR_PART_ORDER) do
local size=BAR_PART_SIZES[part]
local key=stat..'_'..part
local obj=make_image(self.assets,BAR_PART_FILES[part],size.w,size.h)
            self.image_sizes[key]=size
            self.bars[stat][part]=obj
            self.image_objects[key]=obj
        end
    end
    self.name_text=texts.new('',{pos={x=0,y=0},bg={visible=false},flags={draggable=false},text={font='Arial',size=15,alpha=240,red=255,green=255,blue=255,stroke={width=2,alpha=200,red=6,green=45,blue=84}}})
    self.value_text={}
    self.label_text={}
    for _,stat in ipairs(self.stats) do
        self.value_text[stat]=texts.new('',{pos={x=0,y=0},bg={visible=false},flags={right=self.value_align_right,draggable=false},text={font='Grammara',size=11,alpha=240,red=255,green=255,blue=255,stroke={width=2,alpha=200,red=6,green=45,blue=84}}})
        self.label_text[stat]=texts.new(stat:upper(),{pos={x=0,y=0},bg={visible=false},flags={draggable=false},text={font='Arial',size=9,alpha=220,red=255,green=255,blue=255,stroke={width=1,alpha=180,red=6,green=45,blue=84}}})
    end
    return self
end
function XivBar:all_objects()
local out={}
    for _,obj in pairs(self.image_objects) do table.insert(out,obj) end
    table.insert(out,self.name_text)
    for _,stat in ipairs(self.stats) do
        table.insert(out,self.value_text[stat])
        table.insert(out,self.label_text[stat])
    end
    return out
end
function XivBar:apply_scale()
    for key,obj in pairs(self.image_objects) do
local base=self.image_sizes[key]
local layout=self.settings.image_layout[key]
        if layout then
local s=layout.scale or 1.0
            obj:size(base.w*s,base.h*s)
        end
    end
local s=self.settings.scale or 0.85
    self.name_text:size(math.max(1,math.floor(15*s+0.5)))
    for _,stat in ipairs(self.stats) do
        self.value_text[stat]:size(math.max(1,math.floor(11*s+0.5)))
        self.label_text[stat]:size(math.max(1,math.floor(9*s+0.5)))
    end
end
function XivBar:position_images()
    for key,obj in pairs(self.image_objects) do
local p=self.settings.image_layout[key]
        if p then obj:pos(self.root_x+p.x,self.root_y+p.y) end
    end
end
function XivBar:position_text()
    if self.position_text_fn then self.position_text_fn(self,self.settings.scale or 0.85) end
end
function XivBar:set_visible(v)
    self.visible=v
    self.image_objects.bg_top:visible(v)
    self.image_objects.bg_mid:visible(v)
    self.image_objects.bg_bottom:visible(v)
    self.name_text:visible(v)
    for _,stat in ipairs(self.stats) do
local show=v and self.stat_enabled[stat]
        for _,obj in pairs(self.bars[stat]) do obj:visible(show) end
        self.label_text[stat]:visible(show)
        self.value_text[stat]:visible(show)
    end
end
function XivBar:set_active_stats(list)
local active={}
    for _,stat in ipairs(list) do active[stat]=true end
    for _,stat in ipairs(self.stats) do self.stat_enabled[stat]=active[stat] or false end
end
function XivBar:set_name(text)
    self.name_text:text(text or '')
end
function XivBar:set_stat_text(stat,text)
    if self.value_text[stat] then self.value_text[stat]:text(text or '') end
end
function XivBar:set_stat_percent(stat,percent)
local bar=self.bars[stat]
    if not bar then return end
    percent=math.max(0,math.min(100,percent or 0))
local fill_key=stat..'_fill'
local base=self.image_sizes[fill_key]
local layout=self.settings.image_layout[fill_key]
    if not base or not layout then return end
local s=layout.scale or 1.0
local fill_width=math.max(1,base.w*percent/100)*s
local color=self.stat_colors[stat]
    if color then
        bar.fill:color(color.red,color.green,color.blue)
        bar.glow:color(color.red,color.green,color.blue)
        bar.glow_sides:color(color.red,color.green,color.blue)
    end
    bar.fill:size(fill_width,base.h*s)
end
function XivBar:mouse_over(x,y)
local s=self.settings.scale or 0.8515
local left=self.root_x
local top=self.root_y-12*s
local right=self.root_x+377*s
local bottom=self.root_y+64*s
    return x>=left and x<=right and y>=top and y<=bottom
end
function XivBar:handle_mouse(kind,x,y,delta,on_change)
    if kind==1 and self:mouse_over(x,y) then
        self.dragging=true
        self.drag_offset_x=x-self.root_x
        self.drag_offset_y=y-self.root_y
        return true
    elseif kind==0 and self.dragging then
        self.root_x=x-self.drag_offset_x
        self.root_y=y-self.drag_offset_y
        self.settings.pos.x=self.root_x
        self.settings.pos.y=self.root_y
        self:position_images()
        self:position_text()
        return true
    elseif kind==2 and self.dragging then
        self.dragging=false
        self.settings.pos.x=self.root_x
        self.settings.pos.y=self.root_y
        if on_change then on_change() end
        return true
    elseif kind==10 and self:mouse_over(x,y) then
        self.settings.scale=math.max(0.25,(self.settings.scale or 0.85)+delta/100)
        self:apply_scale()
        self:position_images()
        self:position_text()
        if on_change then on_change() end
        return true
    end
    return false
end
function XivBar:show_setup()
    self:set_active_stats(self.stats)
    self:apply_scale()
    self:position_images()
    self:position_text()
    self:set_name(self.preview.name or 'TEST')
    for _,stat in ipairs(self.stats) do
local p=self.preview[stat] or {}
        self:set_stat_text(stat,p.text or '')
        self:set_stat_percent(stat,p.percent or 0)
    end
    self:set_visible(true)
end
function XivBar:reset()
    self.root_x=self.defaults.pos.x
    self.root_y=self.defaults.pos.y
    self.settings.pos.x=self.root_x
    self.settings.pos.y=self.root_y
    self.settings.scale=self.defaults.scale
    self.settings.image_layout=T{}
    for key,value in pairs(self.defaults.image_layout) do self.settings.image_layout[key]={x=value.x,y=value.y,scale=value.scale} end
    self:apply_scale()
    self:position_images()
    self:position_text()
end
function XivBar:destroy()
    for _,obj in ipairs(self:all_objects()) do
        if obj.destroy then obj:destroy() end
    end
end
return XivBar