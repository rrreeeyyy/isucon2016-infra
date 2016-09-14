%w(
  redis-server
  redis-tools
).each { |p| package p }

remote_file "/etc/redis/redis.conf" do
  owner "redis"
  group "redis"
  mode "0644"
end
