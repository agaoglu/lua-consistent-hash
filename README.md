lua-consistent-hash
===================

A reimplementation of consistent hash in lua based on yaoweibin's fork of consistent hash (https://github.com/yaoweibin/ngx_http_consistent_hash)

Usage
-----

In nginx define two shared dicts as 

```
lua_shared_dict hashpeers 1m;
lua_shared_dict buckets 25m;
```

Then possibly in content_by_lua

```lua
local chash = require "chash"

chash.add_upstream("192.168.0.251")
chash.add_upstream("192.168.0.252")
chash.add_upstream("192.168.0.253")

local upstream = chash.get_upstream("my_hash_key")
```
