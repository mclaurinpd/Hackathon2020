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
maxTime = 30
framesPerSequence = 5
framesBetweenSequence = 3
populationSize = 50
sequenceLength = fps * maxTime / (framesPerSequence + framesBetweenSequence)

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
    applyBiasMR(solution)
    console.log("Grade: "..solution.grade)
end

function applyBiasMR(solution)
    countLefts(solution.inputString)
end

--Creates new solution by grabbing every other instruction from each given solution
function createChild(sln1, sln2)
    local solution = newSolution()
    local sequence = ""
    local sln1Seq = mysplit(sln1.inputString, ',')
    local sln2Seq = mysplit(sln2.inputString, ',')
    local flag = true

    for i = 1, sequenceLength do
        if flag then
            --print(sln1Seq[i])
            sequence = sequence .. ',' .. sln1Seq[i]
        else
            --print(sln2Seq[i])
            sequence = sequence .. ',' .. sln2Seq[i]
        end

        flag = not flag
    end

    solution.inputString = sequence
    --print(sequence)

    return solution

end

function sortPopulationByScore()
    table.sort(population, function(a, b) return a.grade > b.grade end)
end

function initializePopulation()
    for i = 1, populationSize do
        population[i] = generateEntireInput()
    end
end

--Small scale testing crossover algorithm (requires populationSize > 4)
--Starts new generation with best 2 from previous generation
--
function crossoverMR1()
    local newPop = {}
    newPop[1] = population[1]
    newPop[2] = population[2]

    newPop[3] = createChild(population[1], population[2])
    newPop[4] = createChild(population[2], population[1])

    newParentIndex = 3
    newPopIndex = 5
    while table.getn(newPop) < populationSize do
        newPop[newPopIndex] = population[newParentIndex]
        newPopIndex = newPopIndex + 1

        for i = 1, newParentIndex - 1 do
            newPop[newPopIndex] = createChild(population[i], population[newParentIndex])
            newPopIndex = newPopIndex + 1

            if table.getn(newPop) > populationSize then
                break
            end
        end
    end

    population = newPop
end

--Initialization
math.randomseed(os.time())
initializePopulation()
generation = 1

--Main Loop
while true do
    print("Generation: "..generation)

    for i = 1, populationSize do
        savestate.load(Filename)
        runSolution(population[i])
    end

    sortPopulationByScore()
    crossoverMR1()
    generation = generation + 1
end
