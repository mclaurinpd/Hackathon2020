--
-- Created by IntelliJ IDEA.
-- User: mattr
-- Date: 10/14/2020
-- Time: 10:51 AM
-- To change this template use File | Settings | File Templates.
--

function Split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

--Main Script Loop
x = 1
testTable = Split("Right, Right, Right+A, Right", ",")

while true do
    gui.text(50, 50, testTable[x])
    --x = x + 1

    if testTable[x] == nil then
        gui.text(50, 75, "If became true")
        x = 1
    end

    emu.frameadvance()
end

