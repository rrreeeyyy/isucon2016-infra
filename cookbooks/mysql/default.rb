service 'mysql' do
  action :nothing
end

template '/etc/my.cnf' do
  owner 'root'
  group 'root'
  mode '0644'
  variables(memory: (node[:memory][:total].sub('kB','').to_i / 1024).floor,
            cpu: node[:cpu][:total].to_i)
  notifies :restart, 'service[mysql]'
end
