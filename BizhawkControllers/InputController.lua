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

Filename = 'DP1.State'
fps = 60
maxTime = 10
framesPerSequence = 5
framesBetweenSequence = 3
populationSize = 10

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

function newSolution()
    local solution = {}

    solution.inputString = ""
    solution.grade = 0

    return solution
end

function clearInput()
    for key,value in pairs(input) do
        input[key] = false
    end
end

function readGameData()
    marioX = memory.read_s16_le(0x94)
    animation = memory.read_s16_le(0x71)
    gameMode = memory.read_s16_le(0x0100)
end

function displayGameData()
    calculateGrade()
    gui.text(50, 50, grade)
    gui.text(50, 75, "Animation: "..animation)          --if animation == 09 -> death
    gui.text(50, 100, "Game Mode: "..gameMode)          --if game mode == 8204 w/out death animation -> victory
end

function calculateGrade()
    grade = marioX
end

function advanceFrames(num)
    for i = 1, num do
        joypad.set(input, 1)
        readGameData()
        displayGameData()

        if animation == 09 or animation == 9225 then
            death = true
            break
        end

        if gameMode == 8204 then
            finish = true
            break
        end

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

function generateEntireInput()
    local sequenceLength = fps * maxTime / (framesPerSequence + framesBetweenSequence)
    local solution = newSolution()

    for i = 0, sequenceLength do
        solution.inputString = solution.inputString .. generateInputElement()
    end

    return solution
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

function runSolution(solution)
    death = false
    finish = false

    --running input string
    for key,value in pairs(mysplit(solution.inputString, ',')) do
        for key2,value2 in pairs(mysplit(value, '+')) do
            setInput(value2)
        end
        advanceFrames(framesPerSequence)
        clearInput()
        advanceFrames(framesBetweenSequence)

        if death or finish then
            break
        end
    end

    solution.grade = grade
    console.log("Grade: "..solution.grade)
end

function sortPopulationByScore()
    table.sort(population, function(a, b) return a.grade > b.grade end)
end

function initializePopulation()
    for i = 1, populationSize do
        population[i] = generateEntireInput()
    end
end

--Small scale testing crossover algorithm
--Starts new generation with best 2 from previous generation
--
function crossoverMR1()

end

--Initialization
math.randomseed(os.time())
initializePopulation()

--Main Loop
while true do

    for i = 1, populationSize do
        savestate.load(Filename)
        runSolution(population[i])
    end

    sortPopulationByScore()

    for i=1,populationSize do
        crossoverMR1()
        print(population[i].grade)
    end

end
