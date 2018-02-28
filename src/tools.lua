local Object = require "kong.vendor.classic"
local Tools = Object:extend()

Tools.AUTHORIZATION_TYPES = {
    BASIC = 'Basic Authorization',
    JWT = 'JSON Web Token'
}

function Tools:new(apiName)
    self.apiName = apiName
end

function Tools:get_api_name()
    return self.apiName
end

--- Print
--- @ param expression Table to print
--- @ param prefix Table to print
function Tools:print(expression, prefix)

    if not prefix then
        print('Coucou je passe ici')
        prefix = 'Tools:print'
    end

    if type(expression) == 'string' then
        print ('>>>>>>>>>><<' .. expression)
        expression = {expression}
    end

    for key, value in pairs(expression) do
        if type(value) == 'string' then
            print(prefix .. ': ' .. key .. ': ' .. value)
        elseif type(value) == 'boolean' then
            print(prefix .. ': ' .. key .. ': ' .. (value and 'TRUE' or 'FALSE'))
        elseif type(value) == 'table' then
            self:print(value, prefix .. ' >> ' .. key)
        else
            print(prefix .. ': ' .. key .. ': type: ' .. type(value))
        end
    end
end

--- Retrieve a JWT in a request.
-- @param request ngx request object
-- @param conf Plugin configuration
-- @return token JWT token contained in request (can be a table) or nil
-- @return err
function Tools:retrieve_token(request)

    local authorization_header = request.get_headers()['authorization']

    if authorization_header then
        local iterator, iter_err = ngx.re.gmatch(authorization_header, "\\s*[Bb]earer\\s+(.+)")
        if not iterator then
            return nil, iter_err
        end

        local m, err = iterator()
        if err then
            return nil, err
        end

        if m and #m > 0 then
            return m[1]
        end
    end
end

--- Fast lookup for credential retrieval depending on the type of the authentication
-- @param request ngx request object
-- @return {string} public_key
-- @return {string} private_key
function Tools:retrieve_credentials(request)

    local username, password
    local authorization_header = request.get_headers()['authorization']

    if authorization_header then
        local iterator, iter_err = ngx.re.gmatch(authorization_header, "\\s*[Bb]asic\\s*(.+)")
        if not iterator then
            return nil, iter_err
        end

        local m, err = iterator()
        if err then
            return nil, err
        end

        if m and m[1] then
            local decoded_basic = ngx.decode_base64(m[1])
            if decoded_basic then
                local basic_parts, err = ngx.re.match(decoded_basic, "([^:]+):(.+)", "oj")
                if err then
                    return nil, err
                end

                if not basic_parts then
                    return nil, '[basic-auth] header has unrecognized format'
                end

                username = basic_parts[1]
                password = basic_parts[2]
            end
        end
    end

    return username, password
end

--function Tools:format_information()
--
--end

return Tools
