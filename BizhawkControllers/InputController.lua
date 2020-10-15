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

fps = 60
maxTime = 200
framesPerSequence = 5
populationSize = 50

allInputs = {'A', 'B', 'X', 'Right', 'Left', 'Down', 'N'}
buttonInputs = {'A', 'B', 'X', 'N' }

population = {}

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
    elseif button == 'Left' then
        input['Left'] = true
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
        joypad.set(input, 1)
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
function generateEntireInput()
    sequenceLength = fps * maxTime / framesPerSequence
    sequence = ''

    for i = 0, sequenceLength do
        sequence = sequence .. generateInputElement()
    end

    return sequence
end

function generateInputElement()
    local x = math.random(1,7)
    local y = math.random(1,4)
    local element = ""

    local firstInput = allInputs[x]
    local secondInput = buttonInputs[y]

    if firstInput == 'N' then
        element = element .. firstInput .. ','
        return element
    end

    element = element .. firstInput

    if secondInput == 'N' then
        element = element .. ','
        return element
    end

    element = element .. '+' .. secondInput .. ','

    return element
end

function initializePopulation()
    for i = 1, populationSize do
        population[i] = generateEntireInput()
    end
end

while true do

    --running input string
    math.randomseed(os.time())
    inputString = generateEntireInput()
    for key,value in pairs(mysplit(inputString, ',')) do
        for key2,value2 in pairs(mysplit(value, '+')) do
            setInput(value2)
            print(value2)
        end
        advanceFrames(10)
        clearInput()
    end
end
