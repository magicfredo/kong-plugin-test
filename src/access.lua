local ak_tools     = require 'kong.plugins.ankama.tools'
local cURL         = require 'cURL'
local json         = require 'cjson'
-- local jwt_decoder  = require 'kong.plugins.jwt.jwt_parser'
local jwt          = require 'resty.jwt'
local responses    = require 'kong.tools.responses'
local singletons   = require "kong.singletons"

local jwt_secret_private = [[-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----]]

local token_ankama_ms = [[COPY_AND_PASTE]]

local AUTHORIZATION_TYPES = {
    BASIC = 'Basic Authorization',
    JWT = 'JSON Web Token'
}

local _M = {}

function _M.execute(conf)

    ak_tools:new() -- conf.api_name
    ngx.header['X-Ankama-Api-Name'] = ak_tools:get_api_name()

    -- TEST CASSANDRA --------------------------------------------------------------------------------------------------

    local result, err

    result, err = singletons.dao.tbl_ankama:insert({
        username = 'magicfredo',
        consumer_id = '0c9d0a88-0e58-446a-b062-50082167de86'
    }, {ttl = 300})

    ak_tools:print(err, 'INSERT_ERR')
    ak_tools:print(result_set, 'INSERT_RESULT')

    result, err = singletons.dao.tbl_ankama:find({
        username = 'magicfredo'
    })

    ak_tools:print(err, 'FIND_ERR')
    ak_tools:print(result_set, 'FIND_RESULT')

    -- TEST CASSANDRA --------------------------------------------------------------------------------------------------

    local authorization_type;

    -- JSON Web Token
    local token, err = ak_tools:retrieve_token(ngx.req)
    if token then
        authorization_type = AUTHORIZATION_TYPES.JWT
        ak_tools:print(token, 'JWT Token')
    else
        -- Basic Authorization
        local given_username, given_password = ak_tools:retrieve_credentials(ngx.req)
        if given_username then
            authorization_type = AUTHORIZATION_TYPES.BASIC
            ak_tools:print({
                given_username,
                given_password
            }, 'Basic Authorization')
        else
            responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
        end
    end

    if authorization_type == AUTHORIZATION_TYPES.JWT then
        local jwt_obj, jwt_error = nil, nil
        local user, company, roles = nil, nil, nil

        -- Version 1 - resty jwt
        jwt_obj = jwt:verify(conf.jwt_secret_public, token)

        user = jwt_obj.payload.user and jwt_obj.payload.user or nil
        company = jwt_obj.payload.company and jwt_obj.payload.company or nil
        roles = jwt_obj.payload.roles and jwt_obj.payload.roles or nil

        ngx.header['X-Ankama-User'] = user .. ' (company: ' .. company .. ', roles: ' .. roles .. ')'

        ---- Version 2 - jwt kong plugin
        --jwt_obj, jwt_error = jwt_decoder:new(token)
        --if err then
        --    responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
        --end
        --
        --user = jwt_obj.claims.user and jwt_obj.claims.user or nil
        --company = jwt_obj.claims.company and jwt_obj.claims.company or nil
        --roles = jwt_obj.claims.roles and jwt_obj.claims.roles or nil
        --
        --ngx.header['X-Ankama-User-2'] = user .. ' (company: ' .. company .. ', roles: ' .. roles .. ')'
    end

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
    ak_tools:print(cURL_response, 'CURL RESPONSE')

    -- CREATE JWT
    local jwt_token = jwt:sign(jwt_secret_private, {
        header = {
            typ = 'JWT',
            alg = 'RS256'
        },
        payload = {
            iss = 'ISS-PASSPHRASE',
            user = user,
            company = company,
            roles = roles,
            others = 'foo,bar'
        }
    })

    -- Ajout de l'autorisation JWT nécessaire pour appeller avatar ou esport
    --ngx.req.set_header('Authorization', 'Bearer ' .. jwt_token)
    ngx.req.set_header('Authorization', 'Bearer ' .. token_ankama_ms)

end

return _M
