local cURL         = require 'cURL'
local json         = require 'cjson'
local jwt_decoder  = require 'kong.plugins.jwt.jwt_parser'
local jwt          = require 'resty.jwt'
local responses    = require 'kong.tools.responses'
local ak_tools        = require 'kong.plugins.ankama.tools'

local jwt_secret_private = [[-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEApCafAPfjZL7IaOm7E+UuAiT4YmmNJx2UC9amggGcCXyOcZUC
loZlfjl1PFtmvorDdNWwvtl239EBuEPFJ3uyxmabFOFHAI3TzDEIxmDRbF89Zgwp
KlCNN+fy05+FFJ/ee7guh8hNOaFGjhoWO3CdB40oAMYb4ThjLdo9c0HARBxXVEHe
0V2o/Zh7lysMdZzThhghMLG4O4poDkPR7nNcRRsHchqvH9PyQsYRgEj/q2QG607Z
kd98cZO6aAHwBZ23YyC4+Xf1M6ahcmkagmfsa4qerjKT5t1tGbmg+ap7ukdaT/F/
6AzyS3+gMacgHBmyC9gK8HfPWlZg9fLBdOX43wIDAQABAoIBACQc4wpBfuNhHZIH
KcMcvlx2abas5gLe/P0FwigD1qI3ptbSI3meI6H7XhFjQl1VBd8kS/gQu5hN0QUK
08r16cTAOgoD7azvhtL7TqTmE+y1nzpeHohSpF7SRpfMFmkNKtMpGAODS4oMMwt8
Lbvx8HoC0fQpoWSRFTC3PKGoq3XQNByYdxW9iI8wEt8ash+CjFtQao2csoTot8f9
KQhdeSaGp8E1uM7s2kDRi1n/g5t/RDxp09ofUxfqAZL9RjmKPdrHLLqt7zCF7nva
CYRNaJkYmNepse/iu7eEVYno4KLANNP7mVTuHb5mycKTK/I5xfwyXfBaPMhKhszS
srjqoEECgYEA1H/sNnaYyEdZsYA4ETXgt/qiWRBju/PmxYTzgOrctw96+RKhacAd
HfQCTXx9jz6yihAxUnylb/Z8lP6cXWyPD3Nfmki28zIv29PgT2OwtToEefN/mu+W
odTsFjXR/9pFe7vzEssaJN8K3blmYVfwph2EjtHoNl0s1OOE4sOo/c8CgYEAxcD4
hHwRSuCiZa28u+3McfIlCB3nNrz7TLqWJhblxdggtUcfUiV7XNqcfMCFawtgkACL
AP5fR0PsC290QLHV9JZIkXcSb/CuymrJC1qJGyqK5y8PRe0Sq7HkbZINNVIpJvtl
EM9m4GCfFgnwTZpVSi68s7eTTl7do/JxSXszp/ECgYB5SwtpiwhqSU/JIYbfTAGZ
Albov5IuFmoDFIBpdaXGV++5fAjmc+Iq1rz5vbVtrjv60oNUshE8d1VlNm/KY8zE
5PYM+rRy3JK0x5uhtSWITDWB5ptPtLImbYLUqqPThqNinUWB1Kx3n1h0dv8ZUTjr
mK2xV99UKJsOaU/QoB41wQKBgE4/iRaDMSR7tkaddGy4L4l20whfLLoQFS/LNNZl
gQ3D801HkzEh+6pGJl2GoEQ3AEJ6tIX0ISdFzQTJWSqwM4TQYm6MuxLoHYGit2Jy
tIW3U7cee+CjahveDBD/FZLfq8DtAJSiPIbUNJ632Aoc41qzG5/RJ8x+5RyWNhVp
VotBAoGAQD+g8TsNdMEYNxsL/FNLgU+PzhnuJLtVzDQyUyuHZ42Onjvbtr9H7VSQ
J4I6J32qu/abUE7uAYH9JkQIG85Nw93SR/sdP5eNObKZAjOfI6L5igeyDJe2+u9a
jgJsOwJ1/6bTKyknvYLIH8MJhGo8A+sj1FvF5WoemAoEjDOkDnw=
-----END RSA PRIVATE KEY-----]]

local token_ankama_ms = [[COPY_AND_PASTE]]

local AUTHORIZATION_TYPES = {
    BASIC = 'Basic Authorization',
    JWT = 'JSON Web Token'
}

local _M = {}

function _M.execute(conf)

    ak_tools:new(conf.api_name)
    ak_tools:get_api_name()

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
