InputController = {input = {}}

function InputController:create (o)
    o.parent = self
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
    return o
end

function InputController:setInput(button)
    success = false

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

    return success
end

function InputController:clearInputs()
    for key,value in pairs(input) do
        input[key] = false
    end
end