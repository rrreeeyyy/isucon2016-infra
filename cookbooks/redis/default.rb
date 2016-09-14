begin
  include_recipe "#{node[:platform]}.rb"
rescue
  abort "unknown platform"
end
