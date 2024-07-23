local cjson = require "cjson"
local _M = {}

_M.name = "balancer-utils"
_M.version = "0.03"

local new_tab
do
    local ok
    ok, new_tab = pcall(require, "table.new")
    if not ok or type(new_tab) ~= "function" then
        new_tab = function (narr, nrec) return {} end
    end
end
_M.new_tab = new_tab


local nkeys, tab_nkeys
do
    local ok
    ok, nkeys = pcall(require, "table.nkeys")
    if not ok or type(nkeys) ~= "function" then
        nkeys = function(tab)
            local count = 0
            for _, _ in pairs(tab) do
                count = count + 1
            end
            return count
        end

    else
        tab_nkeys = nkeys
    end
end
_M.nkeys = nkeys


function _M.copy(nodes)
    local newnodes = new_tab(0, tab_nkeys and tab_nkeys(nodes) or 4)
    for id, weight in pairs(nodes) do
        newnodes[id] = tonumber(weight)
    end

    return newnodes
end


function _M.read_file(path)
    local file, err = io.open(path, "r") -- Open the file in read mode
    if not file then
        return nil, "Unable to open file: " .. (err or "unknown error")
    end
    local content = file:read("*a") -- Read the entire file
    file:close()
    return content
end

function _M.read_config(path)
    local content, err = _M.read_file(path)
    if not content then
        ngx.log(ngx.ERR, err)
        return nil, err
    end
    local config, decode_err = cjson.decode(content)
    if not config then
        ngx.log(ngx.ERR, "Error parsing JSON: " .. decode_err)
        return nil, decode_err
    end
    ngx.log(ngx.INFO, "Successfully read and parsed config file")
    return config
end


return _M