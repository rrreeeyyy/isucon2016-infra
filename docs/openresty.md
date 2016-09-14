# Openresty

## HTTP ディレクティブ

### グローバルに書く奴

- 初期設定系

```
    lua_package_path        '/usr/local/openresty/lualib/resty/?.lua;;';
    lua_check_client_abort  on;
    lua_code_cache          on;
```

- lua-nginx-module を良い感じに JIT で早くしてくれる
    - HTTP ディレクティブの内側にかく

```
    init_by_lua_block {
        require "resty.core"
        collectgarbage("collect")  -- just to collect any garbage
    }
```

### location ディレクティブに書く奴

大体こんな感じ

```
location /get {
  content_by_lua_block {
    local redis = require "resty.redis"
    local red = redis:new()

    red:set_timeout(1000)

    local ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
      ngx.say("failed to connect", err)
      return
    end

    ok, err = red:set("dog", "an animal")
    if not ok then
      ngx.say("failed to set dog", err)
      return 
    end

    local res, err = red:get("dog")
    if not res then
        ngx.say("failed to get dog: ", err)
        return
    end

    if res == ngx.null then
        ngx.say("dog not found.")
        return
    end
  }
}
```

unix domain socket も書ける

```
ok, err = red:connect("unix:/path/to/unix.sock")
```

インクリメントする

```
res, err = red:incr("count")
```

## Tips

- リクエストボディの読み込み関数

```
function ngx_lua_read_body()
   local body = ngx.req.get_body_data()
   if not body then
      local path = ngx.req.get_body_file()
      if not path then
         return nil
      end
      local fh = io.open(path, "r")
      if not fh then
         return nil
      end
      body = fh:read("*all")
      io.close(fh)
   end
   return body
end
```

- サブリクエストのノンブロッキング発行

```
local res = ngx.location.capture("/external_service")
ngx.say(res.body)
```

## 参考文献

- http://yokoninaritai.hatenablog.jp/entry/2013/11/25/184802
- http://ijin.github.io/blog/2013/12/13/serverfesta-2013-autumn/
- http://tech.mercari.com/entry/2015/11/25/170049
