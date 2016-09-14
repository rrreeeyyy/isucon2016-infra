# NariWiki 〜Tuning 秘伝の書〜

以下、ISUCON 決勝に向けてチューニングの勘所を示す。  
わからないことがあれば、tkmr までご連絡を。

## 最初にやれ

*   netstat でパケットの流れを追う
    *   MySQL の memcache プラグインとかに引っかからない
        *   show plugins;
    *   80, 11211, 3306, 8080 など有名ドコロを確認しとく
*   sudo nopasswd 設定
*   MySQL のデータディレクトリのバックアップ
*   yum install iotop dstat etckeeper
    *   etckeeper で コミットしとく
*   postfix とかいらないの切る
*   sinatra の初期ベンチ取得
*   MySQL のバージョン確認
*   README.md を読む
    *   `--workload` みたいなオプションを見逃さない
*   command history の設定

    HISTSIZE=10000
    HISTFILESIZE=20000

*   ボトルネックの測定
    *   [ロギング設定](#logging)
*   ruby が2つ以上インストールされていないか
    *   which -a ruby

## MySQL

### slow log

    slow_query_log=ON
    slow_query_log_file=db-01-slow.log
    long_query_time=0.1

### my.cnf

基本的にmy.cnf の最終調整は、アプリのチューニングが終わったあとに行う。  
初めはざっくりでよい。

`innodb_buffer_pool_size` と `query_cache_size` と `table_cache` だけ  
適当に合わせて他のチューニングにうつる。

ベストを尽くしても5000 程度しかスコアが変わらないのであんまり頑張りすぎないこと。

#### 設定したいパラメタ

    innodb_buffer_pool_size=512M
    key_buffer_size=256M
    query_cache_size=64M
    table_open_cache=512
    thread_cache_size=32
    innodb_log_file_size=256M
    innodb_log_files_in_group = 2
    innodb_log_group_home_dir = /dev/shm/
    sort_buffer_size=2M
    join_buffer_size=256k
    transaction-isolation = READ-UNCOMMITTED
    loose_performance_schema = OFF
    innodb_autoinc_lock_mode = 2
    max_connections=150
    innodb_write_io_threads = 8
    innodb_read_io_threads = 8
    tmp_table_size = 200M

#### 適した値が見つかれば使いたいけど無理したくないパラメタ

    innodb_log_buffer_size=8M
    innodb_additional_mem_pool_size=20M
    read_buffer_size=2M
    thread_concurrency = 8
    read_rnd_buffer_size=2M
    binlog_cache_size=1M
    max_heap_table_size = 300M

#### 前日 AWS で最適と思われた値達

    innodb_buffer_pool_size=2G
    key_buffer_size=256M
    query_cache_size=128M
    table_open_cache=512
    thread_cache_size=32
    tmp_table_size = 1G
    innodb_log_file_size=1G
    innodb_log_files_in_group = 4
    innodb_log_group_home_dir = /dev/shm/
    sort_buffer_size=2M
    join_buffer_size=256k
    transaction-isolation = READ-UNCOMMITTED
    loose_performance_schema = OFF
    innodb_autoinc_lock_mode = 2
    thread_concurrency = 8
    innodb_read_io_threads = 8
    innodb_additional_mem_pool_size=20M
    loose_table_open_cache_instances = 8
    innodb_io_capacity = 2000
    innodb_io_capacity_max = 6000
    innodb_lru_scan_depth = 2000
    skip-name-resolve
    max_heap_table_size = 1G
    innodb_log_buffer_size = 32M
    myisam_sort_buffer_size = 1M
    query_cache_limit = 64M
    loose_explicit_defaults_for_timestamp
    innodb_autoinc_lock_mode = 2
    max_connections=150

### Index

基本的に `EXPLAIN` しながらペタペタする。 `WHERE` 句, `ORDER BY` 句 がある場合は、  
扱われているフィールドに着目しながら複合INDEXを張る。

#### EXAMPLE

##### SQL

    SELECT id FROM memos where is_private=0 ORDER BY created_at DESC 

##### INDEX

    CREATE INDEX `memos_idx` ON memos (`is_private`,`created_at`);

### スキーマ変更 tips

#### init スクリプトから MySQL にQueryを投げたい時の記法

    echo 'SQL' | mysql -u isucon isucon

#### 既存のテーブルを利用してテーブルを作成

    CREATE TABLE private_memos (SELECT * FROM memos WHERE is_private=1);

## redis

### install

    rpm -i http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
    yum install redis --enablerepo=remi

### /etc/redis.conf

save と書かれているところをコメントアウト

    # save 900 1
    # save 300 10
    # save 60 10000

### コマンドラインからのキャッシュクリア

    echo "FLUSHALL" | redis-cli

## Varnish

### install

[ここ読め](https://www.varnish-cache.org/installation/redhat)

### /etc/sysconfig/varnish

ストレージファイルとかに書き出さない。  
ワーキングディレクトリは on memory

    DAEMON_OPTS="-a ${VARNISH_LISTEN_ADDRESS}:${VARNISH_LISTEN_PORT} \
                 -f ${VARNISH_VCL_CONF} \
                 -T ${VARNISH_ADMIN_LISTEN_ADDRESS}:${VARNISH_ADMIN_LISTEN_PORT} \
                 -t ${VARNISH_TTL} \
                 -w ${VARNISH_MIN_THREADS},${VARNISH_MAX_THREADS},${VARNISH_THREAD_TIMEOUT} \
                 -u varnish -g varnish \
                 -S ${VARNISH_SECRET_FILE} \
                 -p thread_pool_add_delay=2 \
                 -p session_linger=30 \
                 -n /dev/shm/varnish/ \
                 -s malloc,1G"

### /etc/varnish/default.vcl

ハッシュの生成方法ではキャッシュキーがかなり重要になってくる。  
ポイントはユーザごとなのか、全ユーザ共通なのか。  
見極めて key を作る。

しっかりと指定できれば、GETリクエストをすべてキャッシュできる。  
ここは内容が細かいので高村が担当。

    sub vcl_hash {
       if (req.url == "/" || req.url ~ "/recent" || req.url ~ "/css"
           || req.url ~ "/js" || req.url ~ "/img" || req.url ~ "/memo") {
         hash_data(req.url);
       } else {
         if (req.http.cookie) {
           hash_data(req.url + regsub(req.http.cookie, "^.*?isucon_session=([^;]*);*.*$", "\1"));
         }
       }
     }

### コマンドラインからのキャッシュクリア

== は、その URI のキャッシュのみ削除。  
~ は、そのURI 配下のキャッシュをすべて削除。

    varnishadm "ban req.url == / && req.url ~ /recent"

## supervisord

### 落とし穴

なぜだか知らんが、`directory`は`[supervisord]` ディレクティブに書かないと反映されない。

    [supervisord]
    directory=/home/isucon/webapp/ruby

## unicorn

### worker_processes, preload_app

    worker_processes 4
    preload_app true

### GC disable

#### config.ru

    require 'unicorn/oob_gc'
    require 'unicorn/worker_killer'

    use Unicorn::OobGC, 10
    use Unicorn::WorkerKiller::MaxRequests, 3072, 4096

#### unicorn_config.rb

    after_fork do |server, worker|
      GC.disable
    end

### 直起動

    . /home/isucon/env.sh && bundle exec unicorn -c unicorn_config.rb -p 5000

### <a name="logging">直起動しながらロギング</a>

    . /home/isucon/env.sh && bundle exec unicorn -c unicorn_config.rb -p 5000 2>&1 | tee /tmp/access.log

### access_log 集計

#### 処理速度順に集計

リクエストメソッド, URI, 処理時間

    # cat /tmp/access.log | cut -d ' ' -f 6,7,11 | tr -d \" | sort -nk3
    GET /mypage 0.0440
    GET /mypage 0.0454
    GET /memo/43150 0.0456
    GET /mypage 0.0456
    GET /mypage 0.0461
    GET /mypage 0.0470
    GET /mypage 0.0513
    GET /mypage 0.0527
    POST /memo 0.0540
    GET /memo/43312 0.0658
    POST /memo 0.095

#### 処理が遅い 150 uriをソート

    # cat /tmp/access.log | cut -d ' ' -f 6-7,9- | tr -d \" | sort -nk5 | tail -150 | cut -d ' ' -f 2 | sort | uniq -c
         23 /recent/214
          5 /recent/215
          1 /recent/23
          1 /recent/34
          1 /recent/50
    ...

## Ruby

### redis を ｺﾞﾆｮｺﾞﾆｮ

    require 'redis'
    require 'mysql2-cs-bind'
    require 'json'

    def connection
      config = JSON.parse(IO.read(File.dirname(__FILE__) + "/../config/#{ ENV['ISUCON_ENV'] || 'local' }.json"))['database']
      return $mysql if $mysql
      $mysql = Mysql2::Client.new(
        :host => config['host'],
        :port => config['port'],
        :username => config['username'],
        :password => config['password'],
        :database => config['dbname'],
        :reconnect => true,
      )
    end

    redis = Redis.new
    mysql = connection
    count = mysql.query("SELECT count(*) AS c FROM memos WHERE is_private=0").first["c"]
    redis.set("count", count)

    result = mysql.query("select id, is_private from memos where is_private=0 order by id desc")
    result.each do |m|
      redis.rpush('memo', m["id"])
    end

### session データに格納

    session["username"] = user

### redis

    redis = Redis.new(:host => "localhost", :port => 6379)

## init.sh

### リソース落ち着くまでsleep

    sleep 50

### BH で暖機運転

    CREATE TABLE memos_bh LIKE memos;
    ALTER TABLE memos_bh2 ENGINE = BLACKHOLE;

    echo 'INSERT INTO memos_bh (SELECT * FROM memos);' | mysql -u isucon isucon

### curl で暖機運転

    #!/bin/bash
    set +o posix
    echo 'select id from memos where is_private=0' | mysql isucon > /tmp/is_private_id.txt
    while read LINE
    do
        curl  http://localhost/memo/$LINE > /dev/null 2>&1
    done < <(tail -5000 /tmp/is_private_id.txt)

### 不要なフィールド削除

    echo 'ALTER TABLE memos DROP updated_at;' | mysql -u isucon isucon

## Kernel

    net.ipv4.ip_local_port_range = 1024 65535
    net.core.rmem_max=16777216
    net.core.wmem_max=16777216
    net.ipv4.tcp_rmem=4096 87380 16777216
    net.ipv4.tcp_wmem=4096 65536 16777216
    net.ipv4.tcp_fin_timeout = 30
    net.core.netdev_max_backlog = 30000
    net.ipv4.tcp_no_metrics_save=1
    net.core.somaxconn = 262144
    net.ipv4.tcp_syncookies = 0
    net.ipv4.tcp_max_orphans = 65535
    net.ipv4.tcp_max_syn_backlog = 65535
    net.ipv4.tcp_synack_retries = 2
    net.ipv4.tcp_syn_retries = 2
    net.ipv4.tcp_tw_reuse = 1
    net.ipv4.tcp_tw_recycle = 1
