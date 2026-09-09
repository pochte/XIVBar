-- XivBar.lua
-- Commands: /xivbar setup | show | hide | reset
_addon.name='XivBar'
_addon.author='XIVParty is required for this to work. Additional coding by Ulli'
_addon.version='1.0.0'
_addon.commands={'xivbar'}
require('tables')
local config=require('config')
local socket=require('socket')
local packets=require('packets')
local XivPanel=require('XivPanel')
--put your actual xivparty folder here if you need to.
local xiv_assets=windower.addon_path..'assets'
-- Settings/Default Pos
local defaults=T{
    pet=T{pos={x=18,y=525},scale=0.85,image_layout=T{
            bg_top={x=1,y=-6,scale=1.0},bg_mid={x=1,y=15,scale=1.0},bg_bottom={x=1,y=27,scale=1.0},
            hp_bg={x=20,y=1,scale=1.0},hp_fg={x=20,y=1,scale=0.92},hp_fill={x=30,y=0,scale=0.92},
            hp_glow={x=30,y=0,scale=0.92},hp_glow_sides={x=30,y=-1,scale=1.0},
            mp_bg={x=136,y=-1,scale=1.0},mp_fg={x=136,y=2,scale=0.91},mp_fill={x=150,y=1,scale=0.91},
            mp_glow={x=150,y=1,scale=0.91},mp_glow_sides={x=150,y=-3,scale=1.0},},},
    enemy=T{pos={x=18,y=425},scale=0.85,image_layout=T{
            bg_top={x=1,y=-6,scale=1.0},bg_mid={x=1,y=15,scale=1.0},bg_bottom={x=1,y=27,scale=1.0},
            hp_bg={x=20,y=1,scale=1.0},hp_fill={x=30,y=0,scale=0.92},hp_fg={x=20,y=1,scale=0.92},
            hp_glow={x=30,y=0,scale=0.92},hp_glow_sides={x=30,y=-1,scale=1.0},},},
    subtarget=T{pos={x=18,y=325},scale=0.85,image_layout=T{
            bg_top={x=1,y=-6,scale=1.0},bg_mid={x=1,y=15,scale=1.0},bg_bottom={x=1,y=27,scale=1.0},
            hp_bg={x=20,y=1,scale=1.0},hp_fill={x=30,y=0,scale=0.92},hp_fg={x=20,y=1,scale=0.92},
            hp_glow={x=30,y=0,scale=0.92},hp_glow_sides={x=30,y=-1,scale=1.0},},},}
local settings=config.load(defaults)
local function fill_defaults(section_name)
settings[section_name]=settings[section_name] or T{}
local s,d=settings[section_name],defaults[section_name]
    s.pos=s.pos or {x=d.pos.x,y=d.pos.y}
    s.scale=s.scale or d.scale
    s.image_layout=s.image_layout or T{}
    for key,value in pairs(d.image_layout) do
        if not s.image_layout[key] then
            s.image_layout[key]={x=value.x,y=value.y,scale=value.scale}
        end
    end
end
fill_defaults('pet')
fill_defaults('enemy')
fill_defaults('subtarget')
local function save_settings()
    config.save(settings)
end
-- Text layout
local function pet_position_text(panel,s)
    local x,y=panel.root_x,panel.root_y
    panel.name_text:pos(x+95*s,y+1*s)
    panel.label_text.hp:pos(x+22*s,y+28*s)
    panel.label_text.mp:pos(x+153*s,y+28*s)
    panel.value_text.hp:pos(x+139*s,y+28*s)
    panel.value_text.mp:pos(x+270*s,y+28*s)
end
local function enemy_position_text(panel,s)
    local x,y=panel.root_x,panel.root_y
    panel.name_text:pos(x+95*s,y+1*s)
    panel.label_text.hp:pos(x+22*s,y+28*s)
    panel.value_text.hp:pos(x+155*s,y+28*s)
end
-- Panels
local pet_panel=XivPanel.new{assets=xiv_assets,settings=settings.pet,defaults=defaults.pet,stats={'hp','mp'},position_text=pet_position_text,preview={name='TEST PET',hp={text='75%',percent=69},mp={text='50%',percent=67}}}
local enemy_panel=XivPanel.new{assets=xiv_assets,settings=settings.enemy,defaults=defaults.enemy,stats={'hp'},value_align_right=false,position_text=enemy_position_text,preview={name='TEST ENEMY',hp={text='69%',percent=69}}}
local subtarget_panel=XivPanel.new{assets=xiv_assets,settings=settings.subtarget,defaults=defaults.subtarget,stats={'hp'},value_align_right=false,position_text=enemy_position_text,preview={name='TEST SUBTARGET',hp={text='42%',percent=42}}}
-- State
local setup_mode=false
local last_update,update_interval=0,0.1
-- Pet-only data
local pup_exact=false
local pup_current_hp,pup_max_hp=0,0
local pup_current_mp,pup_max_mp=0,0
local PET_STATS_BY_JOB={
    GEO={'hp'},SMN={'hp','mp'},BST={'hp','mp'},PUP={'hp','mp'},}
local function pet_stats_for_current_job()
    local player=windower.ffxi.get_player()
    if not player then return {'hp','mp'} end
    if PET_STATS_BY_JOB[player.main_job] then
        return PET_STATS_BY_JOB[player.main_job]
    end
    if player.sub_job=='SMN' then return PET_STATS_BY_JOB.SMN end
    return {'hp','mp'}
end
local function update_pet()
    if setup_mode then return end
local pet=windower.ffxi.get_mob_by_target('pet')
    if not pet or pet.is_valid==false then
        pet_panel:set_visible(false)
        return
    end
local hp=pup_exact and pup_current_hp/math.max(1,pup_max_hp)*100 or pet.hpp or 0
local mp=pup_exact and pup_current_mp/math.max(1,pup_max_mp)*100 or pet.mpp or 0
pet_panel:set_active_stats(pet_stats_for_current_job())
pet_panel:apply_scale()
pet_panel:position_images()
pet_panel:set_name(pet.name or 'Pet')
pet_panel:set_stat_text('hp',pup_exact and string.format('%d/%d',pup_current_hp,pup_max_hp) or string.format('%d%%',hp))
pet_panel:set_stat_text('mp',pup_exact and string.format('%d/%d',pup_current_mp,pup_max_mp) or string.format('%d%%',mp))
pet_panel:set_stat_percent('hp',hp)
pet_panel:set_stat_percent('mp',mp)
pet_panel:position_text()
pet_panel:set_visible(true)
end
local function update_enemy()
    if setup_mode then return end
    local target=windower.ffxi.get_mob_by_target('t')
    if not target or target.is_valid==false then
        enemy_panel:set_visible(false)
        return
    end
local hp=math.max(0,math.min(100,target.hpp or 0))
    enemy_panel:apply_scale()
    enemy_panel:position_images()
    enemy_panel:set_name(target.name or 'Target')
    enemy_panel:set_stat_text('hp',string.format('%d%%',hp))
    enemy_panel:set_stat_percent('hp',hp)
    enemy_panel:position_text()
    enemy_panel:set_visible(true)
end
local function update_subtarget()
    if setup_mode then return end
local sub=windower.ffxi.get_mob_by_target('st')
    if not sub or sub.is_valid==false then
        subtarget_panel:set_visible(false)
        return
    end
local hp=math.max(0,math.min(100,sub.hpp or 0))
    subtarget_panel:apply_scale()
    subtarget_panel:position_images()
    subtarget_panel:set_name(sub.name or 'Subtarget')
    subtarget_panel:set_stat_text('hp',string.format('%d%%',hp))
    subtarget_panel:set_stat_percent('hp',hp)
    subtarget_panel:position_text()
    subtarget_panel:set_visible(true)
end
-- UI setup
windower.register_event('mouse',function(kind,x,y,delta,blocked)
    if blocked or not setup_mode then return end
    return pet_panel:handle_mouse(kind,x,y,delta,save_settings)
        or enemy_panel:handle_mouse(kind,x,y,delta,save_settings)
        or subtarget_panel:handle_mouse(kind,x,y,delta,save_settings)
end)
-- Pet packets
windower.register_event('incoming chunk',function(id,original,modified,injected,blocked)
    if injected then return end

    if id==0x44 and original:unpack('C',0x05)==0x12 then
local pet=windower.ffxi.get_mob_by_target('pet')
local hp,maxhp,mp,maxmp=original:unpack('HHHH',0x069)
local name=original:unpack('z',0x59)

        if pet and name==pet.name then
            pup_exact=true
            pup_current_hp,pup_max_hp=hp,maxhp
            pup_current_mp,pup_max_mp=mp,maxmp
        end
        return
    end
    if id==0x67 or id==0x68 then
local p=packets.parse('incoming',original)
local msg,pidx,oidx=p['Message Type'],p['Pet Index'],p['Owner Index']
        if msg==0x04 and id==0x67 then pidx,oidx=oidx,pidx end
        if msg==0x04 then
            if pidx==0 then
                pet_index,pup_exact=nil,false
                return
            end
local player=windower.ffxi.get_player()
            if player and oidx==player.index then
                pet_index=pidx
                update_pet()
            end
        end
    end
end) --fuck that's a lot of end.
windower.register_event('prerender',function()
local now=socket.gettime()
    if now-last_update>=update_interval then
        last_update=now
        update_pet()
        update_enemy()
        update_subtarget()
    end
end)
-- Commands
windower.register_event('addon command',function(...)
local args=T{...}
local command=args[1] and args[1]:lower() or ''
    if command=='show' then
        setup_mode=false
        update_pet();update_enemy();update_subtarget()
    elseif command=='hide' then
        setup_mode=false
        pet_panel:set_visible(false)
        enemy_panel:set_visible(false)
        subtarget_panel:set_visible(false)
    elseif command=='setup' then
        setup_mode=not setup_mode
        if setup_mode then
        pet_panel:show_setup()
        enemy_panel:show_setup()
        subtarget_panel:show_setup()
                windower.add_to_chat(207,'[XivBar] Setup mode ON - drag any bar to move it, mouse wheel over one to scale it.')
        else
            save_settings()
            update_pet();update_enemy();update_subtarget()
                windower.add_to_chat(207,'[XivBar] Setup mode OFF - layout saved.')
        end
    elseif command=='reset' then
        pet_panel:reset();enemy_panel:reset();subtarget_panel:reset()
        save_settings()
    if setup_mode then
        pet_panel:show_setup()
        enemy_panel:show_setup()
        subtarget_panel:show_setup()
        else
            update_pet();update_enemy();update_subtarget()
        end
        windower.add_to_chat(207,'[XivBar] All bars reset.')
    elseif command=='help' or command=='' then
        windower.add_to_chat(207,'[XivBar] /xivbar setup | show | hide | reset')
    end
end)
-- Load
        pet_panel:apply_scale();pet_panel:position_images();pet_panel:position_text();pet_panel:set_visible(false)
        enemy_panel:apply_scale();enemy_panel:position_images();enemy_panel:position_text();enemy_panel:set_visible(false)
        subtarget_panel:apply_scale();subtarget_panel:position_images();subtarget_panel:position_text();subtarget_panel:set_visible(false)
-- Unload
windower.register_event('unload',function()
    save_settings()
        pet_panel:destroy()
        enemy_panel:destroy()
        subtarget_panel:destroy()
end)