# Sinatra のプロファイリングやっていくやつ

## ログ

- kataribe

Rack

```
logger = Logger.new("/tmp/app.log")
use Rack::CommonLogger, logger
```

## プロファイラ

### `rack-lineprof`

https://github.com/kainosnoema/rack-lineprof

- インストール

```
gem 'rack-lineprof', group: :development
```

- 全部プロファイル

```
class App < Sinatra::Base
  use Rack::Lineprof
end
```

- ファイル指定

```
class App < Sinatra::Base
  use Rack::Lineprof, profile: 'app.rb'
end
```
