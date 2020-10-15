input = {}

input['A'] = false
input['B'] = false
input['Down'] = false
input['L'] = false
input['Left'] = false
input['R'] = false
input['Right'] = false
input['Select'] = false
input['Start'] = false
input['Up'] = false
input['X'] = false
input['Y'] = false

inputString="Left,Right+A,Right,A,Right+A,Right"

function setInput(button)

    if button == 'A' then
        input['A'] = true
    elseif button == 'B' then
        input['B'] = true
    elseif button == 'Down' then
        input['Down'] = true
    elseif button == 'L' then
        input['L'] = true
    elseif button == 'R' then
        input['R'] = true
    elseif button == 'Right' then
        input['Right'] = true
    elseif button == 'Select' then
        input['Select'] = true
    elseif button == 'Start' then
        input['Start'] = true
    elseif button == 'Up' then
        input['Up'] = true
    elseif button == 'X' then
        input['X'] = true
    elseif button == 'Y' then
        input['Y'] = true
    else
        success = false
    end

end

function clearInput()
    for key,value in pairs(input) do
        input[key] = false
    end
end

function displayPosition()
    marioX = memory.read_s16_le(0x94)
    animation = memory.read_s16_le(0x71)
    gameMode = memory.read_s16_le(0x0100)
    gui.text(50, 50, marioX)
    gui.text(50, 75, "Animation: "..animation)          --if animation == 09 -> death
    gui.text(50, 100, "Game Mode: "..gameMode)          --if game mode == 8204 w/out death animation -> victory
end

function calculateGrade()
    grade = marioX
end

function advanceFrames(num)
    for i = 1, num do
        Njoypad.set(input, 1)
        displayPosition()
        emu.frameadvance()
    end
end

function mysplit (inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end

--Main Loop
while true do

    --running input string
    for key,value in pairs(mysplit(inputString, ',')) do
        for key2,value2 in pairs(mysplit(value, '+')) do
            setInput(value2)
            print(value2)
        end
        advanceFrames(10)
        clearInput()
        advanceFrames(20)
    end

    --grading input string
    calculateGrade()
end
