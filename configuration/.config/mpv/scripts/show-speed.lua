local timer = nil

function hide_speed()
    mp.set_osd_ass(0, 0, "")
    if timer then
        timer:kill()
        timer = nil
    end
end

function show_speed_on_change()
    local speed = mp.get_property_osd("speed")
    -- Style: Top-right (\an9), Font size 15 (\fs15), Bold (\b1)
    mp.set_osd_ass(0, 0, "{\\an9\\fs15\\b1\\c&HFFFFFF&\\border=1\\3c&H000000&}" .. speed .. "x")
    -- Reset the timer if it's already running
    if timer then timer:kill() end
    -- Hide the text after 2 seconds
    timer = mp.add_timeout(2, hide_speed)
end

-- Only trigger when the "speed" property actually changes
mp.observe_property("speed", "number", show_speed_on_change)
