-- This function intercepts the command before it runs
function sfsu_interceptor_filter(line)
    -- Check if the command starts with 'scoop'
    local first_word = line:match("^%s*(%S+)")
    if first_word == "scoop" then
        -- Extract the subcommand (the word after 'scoop')
        local subcommand = line:match("^%s*%S+%s+(%S+)")
        
        -- If the subcommand is 'search' or 'list', swap 'scoop' for 'sfsu'
        if subcommand == "search" or subcommand == "list" then
            return line:gsub("^%s*scoop", "sfsu", 1)
        end
    end
    
    -- For install, update, etc., return the line unchanged so the real scoop runs
    return line
end

-- Register the filter with Clink
if clink.onbeginedit then
    clink.onfilterinput(sfsu_interceptor_filter)
end
