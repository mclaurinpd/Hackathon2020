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

--System
Filename = 'YoshisIsland1.State'
fps = 60                                    --SMW fps
maxTime = 300                               --Time to run per level
framesPerSequence = 10                      --Number of frames inputs will be held for
framesBetweenSequence = 0                   --Number of frames inputs will be released between instructions
sequenceLength = fps * maxTime / (framesPerSequence + framesBetweenSequence)            --Calculates length of input sequence

--Genetic Algorithm
populationSize = 20                         --Size of population used by genetic algorithm
generations = 10
mutationChance = .2                         --Chance child will mutate
mutationsAllowed = 550                      --Number of inputs that will be altered with mutation
deathBuffer = 20                            --Number of inputs before death to start crossover
pivotRange = 50                             --Maximum number of inputs away from midpoint to start crossover

--Bonuses/Biases
rightBias = 0.75                            --Percentage chance that initial input will contain 'Right'
speedBias = 5                               --Bonus applied for average speed of solution
victoryBonus = 10000                        --Flat bonus applied to ensure success is favored above everything else
biasValue = 10                              --Penalty applied for number of 'Left' inputs

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
    solution.lastInput = 0
    solution.died = false

    return solution
end

function clearInput()
    for key,value in pairs(input) do
        input[key] = false
    end
end

function hasValue(table, val)
    for index, value in ipairs(table) do
        if value == val then
            return true
        end
    end

    return false
end

function readTime()
    timerHundreds = memory.readbyte(0xF31)
    timerTens = memory.readbyte(0xF32)
    timerOnes = memory.readbyte(0xF33)
    timerValue = timerHundreds..timerTens..timerOnes
end

function readGameData()
    marioX = memory.read_s16_le(0x94)
    animation = memory.readbyte(0x71)
    gameMode = memory.readbyte(0x13D6)
    readTime()
end

function displayGameData()
    calculateGrade()
    gui.text(50, 50, grade)
    gui.text(50, 75, "Animation: "..animation)          --if animation == 09 -> death
    gui.text(50, 100, "Game Mode: "..gameMode)          --if game mode == 8204 w/out death animation -> victory
    gui.text(50, 125, "Timer Value: "..timerValue)
    gui.text(50, 150, "Initial Time: "..initialTime)
    gui.text(50, 200, "Elapsed Time: "..(initialTime -  timerValue))
    gui.text(50, 225, "Average Speed: "..(marioX/(initialTime - timerValue)))
end

function calculateGrade()
    averageSpeed = marioX/(initialTime - timerValue)
    grade = marioX + (speedBias * averageSpeed)
end

function advanceFrames(num)
    for i = 1, num do
        joypad.set(input, 1)
        readGameData()
        displayGameData()

        if animation == 9 then
            death = true
            break
        end

        if gameMode == 1 then
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

function applyBias(sln)
    local str = mysplit(sln.inputString, ',')
    local count = 0

    for i = 1, sequenceLength do
        if string.find(str[i], "Left") then
            count = count + 1
        end
    end

    sln.grade = sln.grade - .8 * count

end

function generateInputElement()
    local x = math.random(1,7)
    local y = math.random(1,4)
    local element = ""

    local firstInput = allInputs[x]
    local secondInput = buttonInputs[y]

    if firstInput ~= 'Right' then
        if shouldChangeInput() then
            firstInput = 'Right'
        end
    end

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

function shouldChangeInput()
    local chance = math.random()

    if (chance < rightBias) then
        return true
    end

    return false
end

function runSolution(solution)
    death = false
    finish = false
    index = 1

    --running input string
    for key,value in pairs(mysplit(solution.inputString, ',')) do
        for key2,value2 in pairs(mysplit(value, '+')) do
            setInput(value2)
        end
        advanceFrames(framesPerSequence)
        clearInput()
        advanceFrames(framesBetweenSequence)
        index = index + 1

        if death or finish then
            solution.lastInput = index
            if death then
                solution.died = true
            end
            break
        end
    end

    solution.grade = grade

    if finish == true then
        solution.grade = solution.grade + victoryBonus
    end

    applyBiasMR(solution)
    console.log("Average Speed: "..averageSpeed)
    console.log("Position: "..marioX)
    console.log("Grade: "..solution.grade)
    console.log("Last Input: "..solution.lastInput)
    console.log("Died: "..(solution.died and 'true' or 'false'))

    if finish == true then
        console.log("SUCCESS!!!")
    end
end

function applyBiasMR(solution)
    numLefts = countLefts(mysplit(solution.inputString, ","))
    print("Number of Lefts:"..numLefts)
    solution.grade = solution.grade - (numLefts * biasValue)
end

function countLefts(str)
    count = 0
    for i = 1, sequenceLength do
        if string.find(str[i], "Left") then
            count = count + 1
        end
    end
    return count
end

function getMutationIndices()
    local mutationIndices = {}
    for i = 1, mutationsAllowed do
        table.insert(mutationIndices, math.random(1, sequenceLength))
    end

    return mutationIndices
end

function shouldMutate()
    local chance = math.random()

    if not (chance < mutationChance) then
        return true
    end

    return false
end

function createChildMR(sln1, sln2)
    local solution = newSolution()
    local sequence = ""
    local sln1Seq = mysplit(sln1.inputString, ',')
    local sln2Seq = mysplit(sln2.inputString, ',')
    local pivot = math.random((-1 * pivotRange),pivotRange)

    if sln1.died then
        for i = 1, sln1.lastInput - deathBuffer do
            sequence = sequence..sln1Seq[i]..','
        end

        for i = sln1.lastInput - deathBuffer + 1, sln1.lastInput + deathBuffer do
            sequence = sequence..generateInputElement()..','
        end

        for i = sln1.lastInput + deathBuffer + 1, sequenceLength do
            sequence = sequence..sln2Seq[i]..','
        end
    else
        for i = 1, math.floor(sln1.lastInput/2) - pivot do
            sequence = sequence..sln1Seq[i]..','
        end

        for i = math.floor(sln1.lastInput/2) - pivot + 1, sequenceLength do
            sequence = sequence..sln2Seq[i]..','
        end
    end

    solution.inputString = sequence
    return solution
end

function createChild(sln1, sln2)
    local solution = newSolution()
    local sequence = ""
    local sln1Seq = mysplit(sln1.inputString, ',')
    local sln2Seq = mysplit(sln2.inputString, ',')
    local pivot = math.random((-1 * pivotRange),pivotRange)
    local mutate = shouldMutate()
    local mutationLocations = getMutationIndices()

    for i = 1, sequenceLength/2 - pivot do
        if mutate and hasValue(mutationLocations, i) then
            sequence = sequence .. ',' .. generateInputElement()
        else
            sequence = sequence .. ',' .. sln1Seq[i]
        end
    end

    for i = sequenceLength/2 - (pivot +1), sequenceLength do
        if mutate and hasValue(mutationLocations, i) then
            sequence = sequence .. ',' .. generateInputElement()
        else
            sequence = sequence .. ',' .. sln2Seq[i]
        end
    end

    solution.inputString = sequence

    return solution

end

function crossOver()
    local newPop = {}
    josephSmith = population[1]

    for i = 2, 6 do
        wife = population[i]
        table.insert(newPop, createChild(josephSmith, wife))
        table.insert(newPop, createChild(wife, josephSmith))
    end

    population = newPop

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

    newPop[3] = createChildMR(population[1], population[2])
    newPop[4] = createChildMR(population[2], population[1])

    newParentIndex = 3
    newPopIndex = 5
    while table.getn(newPop) < populationSize do
        newPop[newPopIndex] = population[newParentIndex]
        newPopIndex = newPopIndex + 1

        for i = 1, newParentIndex - 1 do
            newPop[newPopIndex] = createChildMR(population[i], population[newParentIndex])
            newPopIndex = newPopIndex + 1

            if table.getn(newPop) > populationSize then
                break
            end

            newPop[newPopIndex] = createChildMR(population[newParentIndex], population[i])
            newPopIndex = newPopIndex + 1

            if table.getn(newPop) > populationSize then
                break
            end
        end
        newParentIndex = newParentIndex + 1
    end

    population = newPop
end

--Initialization
math.randomseed(os.time())
initializePopulation()
generation = 1

--Main Loop
while true do
    parentNum = 1

    print("")
    print("")
    print("Generation: "..generation)

    for i = 1, populationSize do
        savestate.load(Filename)
        readTime()
        initialTime = timerHundreds..timerTens..timerOnes

        if population[i].grade == 0 then
            console.log("")
            console.log("Solution "..i)
            runSolution(population[i])
        else
            console.log("")
            console.log("Parent "..parentNum)
            console.log("Grade: "..population[i].grade)
            parentNum = parentNum + 1
        end
    end

    sortPopulationByScore()
    crossoverMR1()

    generation = generation + 1
    parentNum = 0
end
