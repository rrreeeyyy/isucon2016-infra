# nginx のキャッシュとパージ

```
http {
    proxy_cache_path  /tmp/cache  keys_zone=tmpcache:10m;

    server {
        location / {
            proxy_pass         http://127.0.0.1:8000;
            proxy_cache        tmpcache;
            proxy_cache_key    $uri$is_args$args;
        }

        location ~ /purge(/.*) {
            allow              127.0.0.1;
            deny               all;
            proxy_cache_purge  tmpcache $1$is_args$args;
        }
    }
}
```

これで、`purge/uri` にアクセスした時には当該のパスのキャッシュを消すことが出来る。

## 参考文献

- https://github.com/FRiCKLE/ngx_cache_purge
