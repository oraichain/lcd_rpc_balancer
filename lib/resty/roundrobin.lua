local pairs = pairs
local next = next
local tonumber = tonumber
local setmetatable = setmetatable
local math_random = math.random
local error = error
local cjson = require "cjson"
local utils = require "resty.balancer.utils"
local resty_env = require 'resty.env'

local read_config = utils.read_config
local read_file = utils.read_file
local copy = utils.copy
local nkeys = utils.nkeys

local _M = {}
local mt = { __index = _M }

local _gcd
_gcd = function(a, b)
    if b == 0 then
        return a
    end

    return _gcd(b, a % b)
end


local function get_gcd(nodes)
    local first_id, max_weight = next(nodes)
    if not first_id then
        return error("empty nodes")
    end

    local only_key = first_id
    local gcd = max_weight
    for _, weight in next, nodes, first_id do
        only_key = nil
        gcd = _gcd(gcd, weight)
        max_weight = weight > max_weight and weight or max_weight
    end

    return only_key, gcd, max_weight
end

local function get_block_height(response)
    local lua_table, err = cjson.decode(response)
    if not lua_table then
        return 0
    else
        return tonumber(lua_table.result.response.last_block_height)
    end
end

local function get_max_height(self)
    local max_height = 0
    for _, height in next, self.heights do
        if height > max_height then
            max_height = height
        end
    end
    return max_height
end

local function get_random_node_id(nodes)
    local count = nkeys(nodes)

    local id = nil
    local random_index = math_random(count)

    for _ = 1, random_index do
        id = next(nodes, id)
    end

    return id
end


function _M.new(_, filePath)
    local nodes = read_config(filePath)
    local newnodes = copy(nodes)
    -- by default height is weight
    local heights = copy(nodes)
    local response_time = copy(nodes)
    local only_key, gcd, max_weight = get_gcd(newnodes)
    local last_id = get_random_node_id(nodes)

    local self = {
        response_time = response_time, -- ip => block_height
        heights = heights, -- ip => block_height
        nodes = newnodes, -- it's safer to copy one
        only_key = only_key,
        max_weight = max_weight,
        gcd = gcd,
        cw = max_weight,
        last_id = last_id,
    }
    return setmetatable(self, mt)
end

function _M.reinit(self, nodes)
    local newnodes = copy(nodes)
    self.only_key, self.gcd, self.max_weight = get_gcd(newnodes)

    self.nodes = newnodes
    self.last_id = get_random_node_id(nodes)
    self.cw = self.max_weight
end

local function _delete(self, id)
    local nodes = self.nodes

    nodes[id] = nil

    self.only_key, self.gcd, self.max_weight = get_gcd(nodes)

    if id == self.last_id then
        self.last_id = nil
    end

    if self.cw > self.max_weight then
        self.cw = self.max_weight
    end
end
_M.delete = _delete


local function _decr(self, id, w)
    local weight = tonumber(w) or 1
    local nodes = self.nodes

    local old_weight = nodes[id]
    if not old_weight then
        return
    end

    if old_weight <= weight then
        return _delete(self, id)
    end

    nodes[id] = old_weight - weight

    self.only_key, self.gcd, self.max_weight = get_gcd(nodes)

    if self.cw > self.max_weight then
        self.cw = self.max_weight
    end
end
_M.decr = _decr


local function _incr(self, id, w)
    local weight = tonumber(w) or 1
    local nodes = self.nodes

    nodes[id] = (nodes[id] or 0) + weight

    self.only_key, self.gcd, self.max_weight = get_gcd(nodes)
end
_M.incr = _incr



function _M.set(self, id, w)
    local new_weight = tonumber(w) or 0
    local old_weight = self.nodes[id] or 0

    if old_weight == new_weight then
        return
    end

    if old_weight < new_weight then
        return _incr(self, id, new_weight - old_weight)
    end

    return _decr(self, id, old_weight - new_weight)
end

local function update(self, port)
    local httpc = require("resty.http").new()
    -- timeout 5 seconds for reading
    httpc:set_timeouts(2000, 2000, 5000)
    for id, _ in next, self.heights do
        -- query block height to update the heights
        local start_time = ngx.now()
        local res, _ = httpc:request_uri('http://' .. id .. ':' .. port .. '/abci_info', {
                method = "GET",
            })
        local end_time = ngx.now()
        local response_time = end_time - start_time
        if res then
            local new_block_height = get_block_height(res.body)
            if new_block_height > 0 then
                self.heights[id] = new_block_height
                self.response_time[id] = math.floor(response_time * 1000 + 0.5)
            end
        end
    end
end

local function find(self)
    local only_key = self.only_key
    if only_key then
        return only_key
    end

    local nodes = self.nodes
    local last_id, cw, weight = self.last_id, self.cw, 0
    local max_height = self:get_max_height()

    while true do
        while true do
            last_id, weight = next(nodes, last_id)
            if not last_id then
                break
            end
	
            if self.heights[last_id] >= max_height - self.gcd and weight >= cw then
                self.cw = cw
                self.last_id = last_id
                return last_id
            end
        end

        cw = cw - self.gcd
        if cw <= 0 then
            cw = self.max_weight
        end
    end
end
_M.next = find
_M.update = update
_M.get_max_height = get_max_height
return _M