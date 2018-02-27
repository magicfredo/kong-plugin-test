local Object = require "kong.vendor.classic";
local Tools = Object:extend();

function Tools:new(apiName)
    self.apiName = apiName;
end

function Tools:getApiName()
    return self.apiName;
end

--- Print
-- @param table Table to print
-- @param prefix Table to print
function Tools:print(value, prefix)

    prefix = prefix and prefix or 'Tools:print';
    print(type(value) .. ' - ' .. prefix)
    value = type(value) == 'table' and value or {value = value}

    for key, value in pairs(value) do
        if type(value) == 'string' then
            print(prefix .. ': ' .. key .. ': ' .. value)
        elseif type(value) == 'boolean' then
            print(prefix .. ': ' .. key .. ': ' .. (value and 'TRUE' or 'FALSE'))
        elseif type(value) == 'table' then
            print_table(value, prefix .. ' >> ' .. key)
        else
            print(prefix .. ': ' .. key .. ': type: ' .. type(value))
        end
    end
end

return Tools
