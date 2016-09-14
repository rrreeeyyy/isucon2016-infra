%w(
  build-essential
  cmake
  libssl-dev
  libyaml-dev
  libuv-dev
  sysstat
  tmux
  git-core
  etckeeper
).each { |p| package p }

execute 'apply /etc/sysctl.conf' do
  action :nothing
  command 'sysctl -p'
end

remote_file '/etc/sysctl.conf' do
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'execute[apply /etc/sysctl.conf]'
end

remote_file '/etc/security/limits.conf' do
  owner 'root'
  group 'root'
  mode '0644'
end

remote_file '/usr/local/bin/reload_nginx' do
  owner 'root'
  group 'root'
  mode '0755'
end

execute 'cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime' do
  not_if 'strings /etc/localtime | grep -q "JST-9"'
end
