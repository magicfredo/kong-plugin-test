local Object = require "kong.vendor.classic"
local Tools = Object:extend()

Tools.AUTHORIZATION_TYPES = {
    BASIC = 'Basic Authorization',
    JWT = 'JSON Web Token'
}

function Tools:new(api_name)
    self.api_name = api_name
end

function Tools:get_api_name()
    if not self.api_name then
        local m, err = ngx.re.match(ngx.var.uri, '\\/([^\\/]*)\\/(.*)')
        if err then
            return nil, err
        end

        if m and #m > 0 then
            self.api_name = m[1]
        end
    end

    return self.api_name, nil
end

--- Print
-- @param expression Expression to print
-- @param prefix Prefix
function Tools:print(expression, prefix)
    if expression then
        prefix = prefix and prefix or 'Tools:print'
        expression = type(expression) == 'table' and expression or {['NO_KEY'] = expression}

        for key, value in pairs(expression) do
            if type(value) == 'string' then
                print(prefix .. ': ' .. (key ~= 'NO_KEY' and key .. ': ' or '') .. value)
            elseif type(value) == 'boolean' then
                print(prefix .. ': ' .. key .. ': ' .. (value and 'TRUE' or 'FALSE'))
            elseif type(value) == 'table' then
                self:print(value, prefix .. ' >> ' .. key)
            else
                print(prefix .. ': ' .. key .. ': type: ' .. type(value))
            end
        end
    elseif prefix then
        print(prefix .. ': NIL')
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

return Tools
