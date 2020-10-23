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

--Level
levelName = 'YoshisIsland3'                 --Name of level
distanceBuffer = 0                        --Distance that must be travelled before speed affects grading function (helps Mario learn survival before speed)

--System
Filename = levelName..'.State'              --Save state filename
seedFilename = 'seed.txt'                   --Filename to load input string seed from
shouldSeed = true                          --Whether initial population should contain seed from file (if false, will be entirely random)
seed2Filename = 'seed2.txt'                 --Filename to load second input string seed from
doubleSeed = false                          --Whether initial population should contain two seeds from files
fps = 60                                    --SMW fps
maxTime = 90                                --Time to run per level
framesPerSequence = 5                       --Number of frames inputs will be held for
framesBetweenSequence = 0                   --Number of frames inputs will be released between instructions

--Genetic Algorithm
populationSize = 128                         --Size of population used by genetic algorithm
generations = 15                            --Number of generations before seeding new, random population
mutationChance = .12                        --Chance child will mutate
sprintMutateChance = .75                    --Chance child of winning parent will try to hold sprint and right
sprintMutateCount = 2                       --Maximum number of inputs to change to 'Right+X' on mutate
numRandomMutations = 2                      --Number of places in sequence to create random mutations
randomMutationRange = 3                     --Number of inputs that will be changed per random mutation
mutationsAllowed = 550                      --Number of inputs that will be altered with mutation
deathBuffer = 18                            --Maximum number of inputs before death to start crossover
pivotRange = 35                             --Maximum number of inputs away from midpoint to start crossover

--Bonuses/Biases
rightBias = 0.0                             --Percentage chance that initial input will be changed to contain 'Right'
sprintBias = 0.5                           --Percentage chance that initial input will be changed to contain 'X'
speedBias = 1                               --Bonus applied for average speed of solution
victoryBonus = 0                            --Flat bonus applied to ensure success is favored above everything else
biasValue = 0                               --Penalty applied for number of 'Left' inputs
distanceBonus = 0.5                         --Bonus applied based on distance travelled
timeBias = 0.0                              --Bonus applied based on elapsed time if victory

sequenceLength = fps * (maxTime * (2/3)) / (framesPerSequence + framesBetweenSequence)            --Calculates length of input sequence

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
    solution.time = 0
    solution.speed = 0
    solution.position = 0
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
    timerWhole = tonumber(timerHundreds..timerTens..timerOnes)
    timerDecimals = tonumber(memory.readbyte(0xF30))/40
    timerValue = timerWhole+timerDecimals
    elapsedTime = initialTime - timerValue
end

function readGameData()
    currPos = memory.read_s16_le(0x94)
    marioX = currPos - initialPos
    animation = memory.readbyte(0x71)
    gameMode = memory.readbyte(0x13D6)
    paused = memory.readbyte(0x1B89)
    yoshi = memory.readbyte(0x18E8)
    readTime()
end

function displayGameData()
    gui.text(50, 50, grade)
    gui.text(50, 75, "Animation: "..animation)          --if animation == 09 -> death
    gui.text(50, 100, "Game Mode: "..gameMode)          --if game mode == 8204 w/out death animation -> victory
    gui.text(50, 125, "Timer Value: "..timerValue)
    gui.text(50, 150, "Initial Time: "..initialTime)
    gui.text(50, 200, "Elapsed Time: "..elapsedTime)
    gui.text(50, 225, "Average Speed: "..(marioX/elapsedTime))
    gui.text(50, 250, "Pause Flag: "..paused)
    gui.text(50, 275, "Yoshi Text: "..yoshi)
    calculateGrade()
end

function calculateGrade()
    averageSpeed = marioX / elapsedTime
    grade = marioX * distanceBonus
    if marioX > distanceBuffer then
        grade = grade + (speedBias * averageSpeed)
    end
end

function advanceFrames(num)
    if num ~= 0 then
        i = 1
        while i <= num do
            joypad.set(input, 1)
            readGameData()
            displayGameData()

            if animation == 9 then
                death = true
                calculateGrade()
                break
            end

            if gameMode == 79 then
                finish = true
                calculateGrade()
                break
            end

            frameNum = frameNum + 1

            beforeValue = timerDecimals
            emu.frameadvance()
            afterValue = timerDecimals

            if beforeValue == afterValue then
                i = i + 1
            end
        end
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

    if firstInput == 'Right' and secondInput ~= 'X' then
        if shouldChangeSprint() then
            secondInput = 'X'
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

function shouldChangeSprint()
    local chance = math.random()

    if (chance < sprintBias) then
        return true
    end

    return false
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

    if not death and not finish then
        solution.lastInput = index
    end

    solution.grade = grade
    solution.time = (initialTime -  timerValue)
    solution.speed = averageSpeed
    solution.position = marioX

    if finish == true then
        solution.grade = solution.grade + victoryBonus
        solution.grade = solution.grade + timerValue * timeBias
    end

    applyBiasMR(solution)
    print("Average Speed: "..averageSpeed)
    console.log("Position: "..marioX)
    console.log("Grade: "..solution.grade)
    console.log("Last Input: "..solution.lastInput)
    console.log("Died: "..(solution.died and 'true' or 'false'))
    console.log("Elapsed Time: "..(initialTime -  timerValue))

    if finish == true then
        console.log("SUCCESS!!!")
    end
end

function applyBiasMR(solution)
    local wholeSeq = mysplit(solution.inputString, ",")
    local usedSeq = {}

    for i = 1, solution.lastInput do
        usedSeq[i] = wholeSeq[i]
    end

    numLefts = countLefts(usedSeq)
    console.log("Number of Lefts:"..numLefts)
    solution.grade = solution.grade - (numLefts * biasValue)
end

function countLefts(str)
    count = 0
    for i = 1, table.getn(str) - 1 do
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

function shouldSprintMutate()
    local chance = math.random()

    if not (chance < sprintMutateChance) then
        return true
    end

    return false
end

--Will change randomMutationRange inputs at numRandomMutations places in given sequence
function randomSequenceMutation(original, lastInput)
    local origSeq = mysplit(original, ',')
    local result = ""

    for i = 1, numRandomMutations do
        mutationStart = math.random(1, lastInput)
        mutationEnd = mutationStart + randomMutationRange

        for j = mutationStart, mutationEnd do
            origSeq[j] = generateInputElement()
        end
    end

    for i = 1, sequenceLength do
        result = result..origSeq[i]..','
    end

    return result
end

--Will add a 'Right+X' input in a random position before lastInput
function sprintMutate(original, lastInput)
    local origSeq = mysplit(original, ',')
    local result = ""
    local index = math.random(1, lastInput)
    local maxSprintMutates = math.random(1, sprintMutateCount)

    for i = index, index + maxSprintMutates do
        origSeq[i] = 'Right+X'
    end

    for i = 1, sequenceLength do
        result = result..origSeq[i]..','
    end

    return result
end

function createChildMR(sln1, sln2)
    local solution = newSolution()
    local sequence = ""
    local sln1Seq = mysplit(sln1.inputString, ',')
    local sln2Seq = mysplit(sln2.inputString, ',')
    local randDeathBuffer = math.random(3, deathBuffer)
    local deathBufferStart = sln1.lastInput - randDeathBuffer
    local deathBufferEnd = sln1.lastInput + randDeathBuffer
    local lessTime = false

    if table.getn(sln2Seq) < table.getn(sln1Seq) then
        lessTime = true
    end

    if deathBufferStart < 0 then
        deathBufferStart = 0
    end

    if deathBufferEnd > sequenceLength then
        deathBufferEnd = sequenceLength
    end

    if sln1.died then
        for i = 1, deathBufferStart do
            sequence = sequence..sln1Seq[i]..','
        end

        for i = deathBufferStart + 1, deathBufferEnd do
            sequence = sequence..generateInputElement()..','
        end

        if not lessTime then
            for i = deathBufferEnd + 1, sequenceLength do
                sequence = sequence..sln2Seq[i]..','
            end
        else
            for i = deathBufferEnd + 1, table.getn(sln2Seq) do
                sequence = sequence..sln2Seq[i]..','
            end

            for i = table.getn(sln2Seq) + 1, sequenceLength do
                sequence = sequence..generateInputElement()..','
            end
        end
    else
        midSequence = math.random(1, sln1.lastInput)

        if sln1.grade ~= sln2.grade then
            for i = 1, midSequence do
                sequence = sequence..sln1Seq[i]..','
            end

            for i = midSequence + 1, sequenceLength do
                sequence = sequence..sln2Seq[i]..','
            end
        else
            for i = 1, midSequence - randDeathBuffer do
                sequence = sequence..sln1Seq[i]..','
            end

            for i = midSequence - randDeathBuffer + 1, midSequence + randDeathBuffer do
                sequence = sequence..generateInputElement()..','
            end

            for i = midSequence +randDeathBuffer + 1, sequenceLength do
                sequence = sequence..sln2Seq[i]..','
            end
        end

        if shouldSprintMutate() then
            sequence = sprintMutate(sequence, sln1.lastInput)
        end
    end

    if shouldMutate() then
        sequence = randomSequenceMutation(sequence, sln1.lastInput)
    end

    seqTbl = mysplit(sequence, ',')

    if do_tables_match(slice(seqTbl, 1, sln1.lastInput), slice(sln1Seq, 1, sln1.lastInput)) or do_tables_match(slice(seqTbl, 1, sln2.lastInput), slice(sln1Seq, 1, sln2.lastInput)) then
        solution = generateEntireInput()
    else
        solution.inputString = sequence
    end

    return solution
end

function do_tables_match( a, b )
    return table.concat(a) == table.concat(b)
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

--"Chosen Ones" set crossover algorithm (requires populationSize > 4)
--Starts new generation with best 2 from previous generation
--Creates new children by crossing 2 parents both ways
--Repeatedly adds new parents and creates new children by permutating until population full
--{1, 2, (1,2), (2,1), 3, (1,3), (2,3), (3,1), (3,2), 4, (1,4), (2,4)...}
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

function slice (tbl, s, e)
    local pos, new = 1, {}

    for i = s, e do
        new[pos] = tbl[i]
        pos = pos + 1
    end

    return new
end

-- Write a string to a file.
function write(filename, contents)
  local fh = assert(io.open(filename, "wb"))
  fh:write(contents)
  fh:flush()
  fh:close()
end

-- Read an entire file.
-- Use "a" in Lua 5.3; "*a" in Lua 5.1 and 5.2
function readall(filename)
  local fh = assert(io.open(filename, "rb"))
  local contents = assert(fh:read(_VERSION <= "Lua 5.2" and "*a" or "a"))
  fh:close()
  return contents
end

--Initialization
math.randomseed(os.time())
initializePopulation()
generation = 1
console.clear()
xSpeed = 0
avgXSpeed = 0

if shouldSeed then
    population[1].inputString = readall(seedFilename)
    if doubleSeed then
        population[2].inputString = readall(seed2Filename)
    end
end

--Main Loop
while true do
    survived = false

    for j = 1, generations do
        parentNum = 1

        console.log("")
        console.log("")
        console.log("Generation: "..generation)

        for solNum = 1, populationSize do
            console.log("\n")
            savestate.load(Filename)
            readTime()
            initialPos = memory.read_s16_le(0x94)
            initialTime = timerValue
            frameNum = 0
            totalXSpeed = 0

            if population[solNum].grade == 0 then
                print("Solution "..solNum)
                runSolution(population[solNum])
            else
                died = tostring(population[solNum].died)
                lastInput = tostring(population[solNum].lastInput)
                pGrade = tostring(population[solNum].grade)
                console.log("Parent "..parentNum.."\nAverage Speed: "..population[solNum].speed.."\nParent Position: "..population[solNum].position.."\nParent Grade: "..pGrade.."\nParent Last Input: "..lastInput.."\nDied: "..died.."\nElapsed Time: "..population[solNum].time)
                parentNum = parentNum + 1
            end
        end

        sortPopulationByScore()
        bestInput = population[1].inputString
        if not population[1].died then
            survived = true
            bestTime = math.floor(population[1].time)
            write(levelName.."/Generation "..generation.."-"..levelName.."-"..bestTime..".txt", bestInput)
        else
            intGrade = math.floor(population[1].position)
            trainFilename = "training/"..levelName.."-training-"..intGrade..".txt"
            write(trainFilename, bestInput)
        end

        crossoverMR1()

        if (generation % 1 == 0) then
            console.clear()
        end
        generation = generation + 1
        parentNum = 0
    end

    if survived then
        bestFilename = levelName.."-overall-"..bestTime..".txt"
    else
        bestFilename = "training/"..levelName.."-training-"..intGrade..".txt"
    end
    write(bestFilename, bestInput)

    --Re-Initialization
    math.randomseed(os.time())
    initializePopulation()
    generation = 1
    console.clear()

    population[1].inputString = readall(bestFilename)
end
