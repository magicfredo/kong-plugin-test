local cURL = require 'cURL'
local json = require 'cjson'
local jwt_decoder  = require 'kong.plugins.jwt.jwt_parser'
local responses = require 'kong.tools.responses'

local _M = {}

-- @param table Table to print
-- @param prefix Table to print
local function print_table(table, prefix)
    prefix = prefix and prefix or '';

    for key, value in pairs(table) do
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

--- Retrieve a JWT in a request.
-- Checks for the JWT in URI parameters, then in cookies, and finally
-- in the `Authorization` header.
-- @param request ngx request object
-- @return token JWT token contained in request (can be a table) or nil
-- @return err
local function retrieve_token(request)
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

function _M.execute(conf)

    -- Simulation de l'autorisation via la configuration
    if conf.authorization then
        print('conf.authorization: SUCCESS')
    else
        print('conf.authorization: FAILED')
    end

    -- JWT plugin
    local token, err = retrieve_token(ngx.req)
    if err then
        responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
    end

    local jwt, err = jwt_decoder:new(token)
    if err then
        responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
    end

    local user = jwt.claims.user and jwt.claims.user or nil
    local company = jwt.claims.company and jwt.claims.company or nil
    local roles = jwt.claims.roles and jwt.claims.roles or nil

    ngx.header['X-Ankama-User'] = user .. ' (company: ' .. company .. ', roles: ' .. roles .. ')'

    -- Curl request to user authorization
    local cURL_response = ''
    local m = cURL.easy({
        url = 'https://slack.com/api/api.test',
        post = true,
        httppost = cURL.form({
            user = user,
            company = company,
            roles = roles
        })
    }):perform({
        writefunction = function(str)
            cURL_response = str
        end
    });
    print('>> cURL_response (json): ' .. cURL_response);

    local cURL_response_code = m:getinfo(cURL.INFO_RESPONSE_CODE)
    print('>> cURL_response_code: ' .. cURL_response_code);

    m:close()

    if cURL_response_code ~= 200 then
        responses.send_HTTP_UNAUTHORIZED()
    end

    cURL_response = json.decode(cURL_response);
    print_table(cURL_response, 'CURL RESPONSE')

    -- CREATE JWT

    -- Ajout de l'autorisation JWT nécessaire pour appeller avatar ou esport
    ngx.req.set_header('Authorization', 'Bearer ...')

end

return _M
