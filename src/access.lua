local cURL = require "cURL"
local json = require 'cjson'
local responses = require 'kong.tools.responses'

local _M = {}

function _M.execute(conf)

    -- Simulation de l'autorisation via la configuration
    if conf.authorization then
        print('conf.authorization: SUCCESS')
    else
        print('conf.authorization: FAILED')
    end

    -- JWT plugin
    -- username / key / game
    local authorization_header = ngx.req.get_headers()["authorization"]
    print(authorization_header)

    -- Curl request to user authorization
    local cURL_response = '';
    local m = cURL.easy({
        url = 'https://dofus-esport.ankama-api.com/v1/status'
    }):perform({
        writefunction = function(str)
            cURL_response = str
        end
    })
    print('>> cURL_response (json): ' .. cURL_response);

    local cURL_response_code = m:getinfo(cURL.INFO_RESPONSE_CODE)
    print('>> cURL_response_code: ' .. cURL_response_code);

    m:close()

    if cURL_response_code ~= 200 then
        responses.send_HTTP_UNAUTHORIZED()
    end

    cURL_response = json.decode(cURL_response);
    for key, value in pairs(cURL_response) do
        print('>> cURL_response: ' .. key .. ': ' .. value)
    end

    -- JWT

    -- Ajout de l'autorisation JWT nécessaire pour appeller avatar ou esport
    ngx.req.set_header('Authorization', 'Bearer ...')

end

return _M
