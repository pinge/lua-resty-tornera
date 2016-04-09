local str_find = string.find
local str_upper = string.upper
local tbl_concat = table.concat
local ngx_socket_tcp = ngx.socket.tcp

local _M = {
    _VERSION = '1.0.0'
}
_M._USER_AGENT = "lua-resty-tornera/" .. _M._VERSION .. " (Lua) ngx_lua/" .. ngx.config.ngx_lua_version

local mt = {
    __index = _M
}

local HTTP = {
    [1.0] = " HTTP/1.0\r\n",
    [1.1] = " HTTP/1.1\r\n",
}

-- from https://github.com/pintsized/lua-resty-http/blob/master/lib/resty/http.lua
local function _format_request(params)
    local version = params.version
    local headers = params.headers or {}
    local query = params.query or ""
    local req = {str_upper(params.method), " ", params.path, query, HTTP[version], true, true, true}
    local c = 6
    for key, values in pairs(headers) do
        if type(values) ~= "table" then
            values = {values}
        end
        key = tostring(key)
        for _, value in pairs(values) do
            req[c] = key .. ": " .. tostring(value) .. "\r\n"
            c = c + 1
        end
    end
    req[c] = "\r\n"
    return tbl_concat(req)
end

local function _send_body(sock, body)
    if type(body) == 'function' then
        repeat
            local chunk, err, partial = body()
            if chunk then
                local ok,err = sock:send(chunk)
                if not ok then
                    return nil, err
                end
            elseif err ~= nil then
                return nil, err, partial
            end
        until chunk == nil
    elseif body ~= nil then
        local bytes, err = sock:send(body)
        if not bytes then
            return nil, err
        end
    end
    return true, nil
end

function _M:new(shared_memory_handle)
    local tornera = {}
    tornera.config = loadstring("return ngx.shared." .. shared_memory_handle)()
    return setmetatable(tornera, mt)
end

function _M:replay_is_enabled()
    local host = self.config:get("host")
    local port = self.config:get("port")
    local duration = self.config:get("duration")
    return host ~= nil and port ~= nil and duration ~= nil
end

function _M:request(http_version, host, port, url_path, method, headers, query_string)
    local sock, err = ngx_socket_tcp()
    if not sock then
        return nil, err
    end
    headers = headers or {}
    if query_string ~= nil then
        url_path = url_path .. "?" .. query_string
    end
    sock:settimeout(250)
    local host = select(1, host, port)
    sock:connect(host, port)
    local params = {version = http_version, method = method, path = url_path, headers = headers}
    local body = params.body
    if type(body) == 'string' and not headers["Content-Length"] then
        headers["Content-Length"] = #body
    end
    if not headers["Host"] then
        headers["Host"] = host
    end
    if not headers["User-Agent"] then
        headers["User-Agent"] = _M._USER_AGENT
    end
    if params.version == 1.0 and not headers["Connection"] then
        headers["Connection"] = "Keep-Alive"
    end
    params.headers = headers
    local req = _format_request(params)
    local bytes, err = sock:send(req)
    if not bytes then
        return nil, err
    end
    if headers["Expect"] ~= "100-continue" then
        local ok, err, partial = _send_body(sock, body)
        if not ok then
            return nil, err, partial
        end
    end
    -- reading the status and the headers seems to be enough to avoid a broken pipe on the replay target host
    local line, err = sock:receive("*l")
    if not line then
        return nil, nil, err
    end
    repeat
        local line, err = sock:receive("*l")
        if not line then
            return nil, err
        end
    until str_find(line, "^%s*$")
    sock:setkeepalive(5000, 1000)
end

-- TODO add support for replaying the request body
function _M:replay_request()

    local function replay(premature, http_version, host, port, url_path, method, headers, query_string)
        if self:replay_is_enabled() then
            self:request(http_version, host, port, url_path, method, headers, query_string)
        end
    end

    ngx.timer.at(0.001, replay, ngx.req.http_version(), self.config:get("host"), self.config:get("port"),
        ngx.var.uri, ngx.var.request_method, ngx.req.get_headers(100, true), ngx.var.query_string)

end

return _M
