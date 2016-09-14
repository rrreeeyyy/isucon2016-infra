package 'zip'

remote_file '/usr/local/src/kataribe.zip' do
  owner 'root'
  group 'root'
  mode '0755'
end

execute 'unzip /usr/local/src/kataribe.zip -d /usr/local/bin' do
  not_if 'test -f /usr/local/bin/kataribe'
end

execute 'chmod +x /usr/local/bin/kataribe' do
  not_if 'test -x /usr/local/bin/kataribe'
end

remote_file '/usr/local/kataribe.toml' do
  owner 'root'
  group 'root'
  mode '0755'
end

