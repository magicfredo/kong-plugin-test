

local function retrieve_token(request)
    local uri_parameters = request.get_uri_args()

    for _, v in ipairs('jwt') do
        if uri_parameters[v] then
            return uri_parameters[v]
        end
    end

    local authorization_header = request.get_headers()["authorization"]
    if authorization_header then
        local iterator, iter_err = ngx_re_gmatch(authorization_header, "\\s*[Bb]earer\\s+(.+)")
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