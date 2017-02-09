id = ...
id = id or 'unknown'

gui = require 'gui'

function istrue(v)
    return v ~= nil and v ~= false and v ~= 0
end

function K(k)
    return df.interface_key[k]
end

function create_new_world(params)
    if #params ~= 7 then
    	print 'wrong params'
        return
    end

    local ws = dfhack.gui.getCurViewscreen()

    -- Check that we're on title screen or its subscreens
    while ws and ws.parent and ws._type ~= df.viewscreen_titlest do
        ws = ws.parent
    end
    if ws._type ~= df.viewscreen_titlest then
    	print 'wrong screen'
        return
    end

    -- Return to title screen
    ws = dfhack.gui.getCurViewscreen()
    while ws and ws.parent and ws._type ~= df.viewscreen_titlest do
        local parent = ws.parent
        parent.child = nil
        ws:delete()
        ws = parent
    end
    ws.breakdown_level = df.interface_breakdown_types.NONE
    
    local titlews = ws --as:df.viewscreen_titlest

    titlews.sel_subpage = df.viewscreen_titlest.T_sel_subpage.None
    -- whether there's a 'continue playing' and/or 'start playing' menu items
    titlews.sel_menu_line = (#titlews.arena_savegames-#titlews.start_savegames > 1 and 1 or 0) + (#titlews.start_savegames > 0 and 1 or 0)
    gui.simulateInput(titlews, 'SELECT')

    worldgen_params = params

    --todo: temporary
    df.global.world.worldgen_status.state = 0    

    --native.set_timer(2, 'progress_worldgen')
    dfhack.timeout(2, 'frames', progress_worldgen)
end

function progress_worldgen()
    local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_new_regionst

    if ws._type ~= df.viewscreen_new_regionst then
        print('check', ws._type)
        worldgen_params = nil
        return
    end    

    -- If finished loading raws
    if ws.unk_b4 == 0 then
        -- Close 'Welcome to ...' message
        if #ws.welcome_msg > 0 then
            gui.simulateInput(ws, 'LEAVESCREEN')
        end    

        --xxx: the second condition is for the advanced worldgen mode which isn't supported
        if istrue(ws.simple_mode) or istrue(ws.in_worldgen) then
            if worldgen_params then
                local world_size, history, number_civs, number_sites, number_beasts, savagery, mineral_occurence = table.unpack(worldgen_params)
                ws.world_size = world_size
                ws.history = history
                ws.number_civs = number_civs
                ws.number_beasts = number_beasts
                ws.savagery = savagery
                ws.mineral_occurence = mineral_occurence

                gui.simulateInput(ws, 'MENU_CONFIRM')
				_start = os.time()
                worldgen_params = nil
            end

            dfhack.timeout(100, 'frames', check_worldgen_done)
            return
        end    
    end

	dfhack.timeout(2, 'frames', progress_worldgen)
end

function get_load_game_screen()
    local ws = dfhack.gui.getCurViewscreen()

    if ws._type == df.viewscreen_loadgamest then
        return ws
    end

    -- Check that we're on title screen or its subscreens
    while ws and ws.parent and ws._type ~= df.viewscreen_titlest do
        ws = ws.parent
    end
    if ws._type ~= df.viewscreen_titlest then
        return nil
    end

    -- Return to title screen
    ws = dfhack.gui.getCurViewscreen()
    while ws and ws.parent and ws._type ~= df.viewscreen_titlest do
        local parent = ws.parent
        parent.child = nil
        ws:delete()
        ws = parent
    end
    ws.breakdown_level = df.interface_breakdown_types.NONE
    
    local titlews = ws --as:df.viewscreen_titlest
    
    if #titlews.arena_savegames-#titlews.start_savegames == 1 then
        return nil, true
    end

    titlews.sel_subpage = df.viewscreen_titlest.T_sel_subpage.None
    titlews.sel_menu_line = 0
    gui.simulateInput(titlews, K'SELECT')

    -- This is to deal with the custom dfhack load screen
    ws = dfhack.gui.getCurViewscreen()
    while ws and ws.parent and ws._type ~= df.viewscreen_loadgamest do
        ws = ws.parent
    end

    return ws
end

function savegame_load(folder)
    local ws = get_load_game_screen() --as:df.viewscreen_loadgamest
    if not ws then
        print 'no game list screen'
    end

    for i,s in ipairs(ws.saves) do
        if s.folder_name == folder then
            ws.sel_idx = i
            gui.simulateInput(ws, K'SELECT')

            dfhack.timeout(10, 'frames', check_load_done)
            return true
        end
    end
end

function check_load_done()
    local ws = dfhack.gui.getCurViewscreen()
    if ws._type == df.viewscreen_dwarfmodest then
        dfhack.timeout(500, 'frames', function()
            --df.global.pause_state = false
            gui.simulateInput(ws, 'D_PAUSE')
            _start = os.time()

            dfhack.timeout(sim_days, 'days', function()
                _end = os.time()

                submit((_end - _start))
            end)
        end)
        
        return
    end

    dfhack.timeout(10, 'frames', check_load_done)
end

function check_worldgen_done()
	if df.global.world.worldgen_status.state == 10 then
		_end = os.time()

        submit((_end - _start))

    	local ws = dfhack.gui.getCurViewscreen() --as:df.viewscreen_new_regionst		
	    gui.simulateInput(ws, 'WORLD_GEN_ABORT')

        dfhack.timeout(500, 'frames', function()
            progress_benchmark()
        end)
		return
	end

	dfhack.timeout(10, 'frames', check_worldgen_done)
end

step = 0
testname = ''
function progress_benchmark()
    step = step + 1
    if step == 1 then
        testname = 'worldgen-smaller-verylong'
        create_new_world({ 1, 4, 2, 2, 2, 2, 2 }) --smaller, very long
    elseif step == 2 then
        testname = 'worldgen-large-short'
        create_new_world({ 4, 1, 2, 2, 2, 2, 2 }) --large, short

    elseif step == 3 then
        testname = 'simulation-20days'
        sim_days = 20
        savegame_load('gloveloved')

    else
        os.execute('wget --spider mifki.com/bench/'..id..'/done')

    end
end

function submit(result)
    print(testname .. ' ' .. tostring(result) .. ' sec')

    os.execute('wget --spider mifki.com/bench/'..id..'/'..testname..'/'..tostring(result))
end

os.execute('wget --spider mifki.com/bench/'..id..'/started')

progress_benchmark()