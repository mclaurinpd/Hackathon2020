--
-- Created by IntelliJ IDEA.
-- User: mattr
-- Date: 10/14/2020
-- Time: 10:51 AM
-- To change this template use File | Settings | File Templates.
--

--Main Script Loop
x = 0

while true do
    gui.text(50, 50, 'Hello World!')

    if x > 100 then
        gui.text(50, 75, "If became true")
        x = 0
    end

    emu.frameadvance()
    x = x + 1
end

