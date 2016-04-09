local tbl_concat = table.concat

local _M = {
    _VERSION = '1.0.0'
}

local mt = {
    __index = _M
}

function _M:new(shared_memory_handle)
    local api = {}
    api.config = loadstring("return ngx.shared." .. shared_memory_handle)()
    return setmetatable(api, mt)
end

function _M:process_api_request()
    local method = ngx.var.request_method
    if method == "GET" then
        return self:show_config()
    elseif method == "POST" then
        return self:create_replay(ngx.req.get_uri_args())
    elseif method == "DELETE" then
        return self:destroy_replay()
    else
        return self:respond_with(nil, ngx.HTTP_NOT_FOUND)
    end
end

-- GET /_replay
function _M:show_config()
    return self:respond_with(self:json_config(), ngx.OK)
end

-- POST /_replay
function _M:create_replay(query_parameters)
    local host
    local port
    local duration
    for p, v in pairs(query_parameters) do
        if p == "host" and self:trim(v) ~= "" then
            host = v
        elseif p == "port" and tonumber(self:trim(v)) ~= nil then
            port = v
        elseif p == "duration" and self:trim(v) ~= "" then
            duration = v
        end
    end
    if host == nil or duration == nil then
        return self:respond_with("", ngx.HTTP_BAD_REQUEST)
    end
    if host ~= nil then
        self:set("host", host)
    end
    if port == nil then
        port = 80
    end
    self:set("port", port)
    if duration ~= nil then
        self:set("duration", duration)
    end
    return self:respond_with(self:json_config(), ngx.HTTP_CREATED)
end

-- DELETE /_replay
function _M:destroy_replay()
    self.config:flush_all()
    return self:respond_with("{}", ngx.HTTP_OK)
end

function _M:respond_with(body, status_code, content_type)
    status_code = status_code or ngx.HTTP_OK
    content_type = content_type or 'application/json'
    ngx.status = status_code
    ngx.header["Content-Type"] = content_type
    if body ~= nil then
        ngx.print(body)
    end
    ngx.eof()
    return ngx.exit(status_code)
end

function _M:get(parameter)
    return self.config:get(parameter)
end

function _M:set(parameter, value)
    local succ, err, forcible = self.config:set(parameter, value)
    if err ~= nil then
        return self:respond_with("{}", ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
    return value
end

function _M:json_config()
    local parameters = {}
    local host = self:get("host")
    if host ~= nil then
        table.insert(parameters, '"host":"' .. host .. '"')
    end
    local port = self:get("port")
    if port ~= nil then
        table.insert(parameters, '"port":' .. port)
    end
    local duration = self:get("duration")
    if duration ~= nil then
        table.insert(parameters, '"duration":' .. duration)
    end
    return "{" .. tbl_concat(parameters, ",") .. "}"
end

function _M:trim(s)
    return s:match"^%s*(.*%S)" or ""
end

return _M
