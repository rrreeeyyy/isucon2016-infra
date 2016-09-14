%w(
  libreadline-dev
  libncurses5-dev
  libpcre3-dev
  libssl-dev
  libpq-dev
  perl
  make
  wget
  tar
).each { |p| package p }

SRC_DIR = "/usr/local/src/"
OPENRESTY_VERSION = "1.9.3.1"
CACHE_PURGE_VERSION = "2.3"

execute "wget https://openresty.org/download/ngx_openresty-#{OPENRESTY_VERSION}.tar.gz" do
  cwd SRC_DIR
  not_if "test -f #{SRC_DIR}ngx_openresty-#{OPENRESTY_VERSION}.tar.gz"
end

execute "wget http://labs.frickle.com/files/ngx_cache_purge-#{CACHE_PURGE_VERSION}.tar.gz" do
  cwd SRC_DIR
  not_if "test -f #{SRC_DIR}ngx_cache_purge-#{CACHE_PURGE_VERSION}.tar.gz"
end

execute "tar zxfv ngx_openresty-#{OPENRESTY_VERSION}.tar.gz" do
  cwd SRC_DIR
  not_if "test -d #{SRC_DIR}ngx_openresty-#{OPENRESTY_VERSION}"
end

execute "tar zxfv ngx_cache_purge-#{CACHE_PURGE_VERSION}.tar.gz" do
  cwd SRC_DIR
  not_if "test -d #{SRC_DIR}ngx_cache_purge-#{CACHE_PURGE_VERSION}"
end

execute "execute openresty configure script" do
  cwd "#{SRC_DIR}ngx_openresty-#{OPENRESTY_VERSION}/"
  command <<-EOS
./configure \
--sbin-path=/usr/sbin/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-client-body-temp-path=/var/lib/nginx/body \
  --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
  --http-log-path=/var/log/nginx/access.log \
  --http-proxy-temp-path=/var/lib/nginx/proxy \
  --http-scgi-temp-path=/var/lib/nginx/scgi \
  --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
  --lock-path=/var/lock/nginx.lock \
  --pid-path=/var/run/nginx.pid \
  --with-luajit \
  --with-http_dav_module \
  --with-http_gzip_static_module \
  --with-http_stub_status_module \
  --with-http_ssl_module \
  --with-http_sub_module \
  --with-sha1=/usr/include/openssl \
  --with-md5=/usr/include/openssl \
  --with-http_stub_status_module \
  --with-http_secure_link_module \
  --with-http_sub_module
  EOS
  not_if "test -f #{SRC_DIR}ngx_openresty-#{OPENRESTY_VERSION}/Makefile"
end

execute "make && make install openresty" do
  cwd "#{SRC_DIR}ngx_openresty-#{OPENRESTY_VERSION}/"
  command "make && make install"
  not_if "nginx -v 2>&1 | grep openresty"
end

remote_file "/etc/init.d/nginx" do
  owner "root"
  group "root"
  mode "0755"
end

remote_file "/etc/nginx/nginx.conf.sample" do
  owner "root"
  group "root"
  mode "0644"
end
