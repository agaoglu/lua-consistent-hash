local M = {}

local MMC_CONSISTENT_BUCKETS = 65536

local function hash_fn(key)
	local md5 = ngx.md5_bin(key) --nginx only
	return ngx.crc32_long(md5) --nginx only
end

local function chash_find(point, map)
	local mid, lo, hi = 1, 1, #map
	while 1 do
		if point <= map[lo][2] or point > map[hi][2] then
			return map[lo][1]
		end

		mid = math.floor(lo + (hi-lo)/2)
		if point <= map[mid][2] and point > (mid and map[mid-1][2] or 0) then
			return map[mid][1]
		end

		if map[mid][2] < point then
			lo = mid + 1
		else
			hi = mid - 1
		end
	end
end

local function comp(p, c) return p[2] < c[2] end

local function chash_init()
	
	local ppn = math.floor(MMC_CONSISTENT_BUCKETS / 10)

	local C = {}
	for i,peer in ipairs(ngx.shared.hashpeers:get_keys()) do
		for k=1, math.floor(ppn) do
			local hash_data = peer .. "-"..tostring(math.floor(k - 1))
			table.insert(C, {peer , hash_fn(hash_data)})
		end
	end

	table.sort(C, comp)

	local step = math.floor(0xFFFFFFFF / MMC_CONSISTENT_BUCKETS)

	ngx.shared.buckets:flush_all()
	for i=1, MMC_CONSISTENT_BUCKETS do
		ngx.shared.buckets:set(i-1, chash_find(math.floor(step * (i - 1)), C))
	end

end

local function chash_get_upstream(key)
	local point = hash_fn(key) --nginx only
	return	ngx.shared.buckets:get(point % MMC_CONSISTENT_BUCKETS)
end
M.get_upstream = chash_get_upstream

local function chash_add_upstream(upstream)
	local before_count = table.getn(ngx.shared.hashpeers:get_keys())
	ngx.shared.hashpeers:set(upstream, upstream)
	local after_count = table.getn(ngx.shared.hashpeers:get_keys())
	if after_count ~= before_count then
		chash_init()
	end
end
M.add_upstream = chash_add_upstream

local function chash_remove_upstream(upstream)
	local before_count = table.getn(ngx.shared.hashpeers:get_keys())
	ngx.shared.hashpeers:delete(upstream)
	local after_count = table.getn(ngx.shared.hashpeers:get_keys())
	if after_count ~= before_count then
		chash_init()
	end
end
M.remove_upstream = chash_remove_upstream

return M
