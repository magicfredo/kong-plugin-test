


local _M = {}

function _M:new(api_name)
    self._api_name = api_name
end

function _M:get_api_name()
    return self._api_name
end

return _M
